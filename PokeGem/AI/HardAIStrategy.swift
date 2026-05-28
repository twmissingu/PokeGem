//
//  HardAIStrategy.swift
//  PokeGem
//
//  Hard AI: Heuristic evaluation with look-ahead and opponent awareness
//  NEW - not present in original implementation
//

import Foundation

/// Hard difficulty AI strategy
/// Uses heuristic evaluation, opponent tracking, and strategic planning
struct HardAIStrategy: AIStrategy, Sendable {
    let difficulty: AIDifficulty = .hard

    // MARK: - Weights

    private enum Weights {
        static let pointValue: Int = 10          // Points are king
        static let discountValue: Int = 6        // Future discounts are valuable
        static let colorSynergy: Int = 4         // Colors that help buy nobles
        static let nobleProgress: Int = 8        // Progress toward nobles
        static let opponentPressure: Int = 3     // Competing with opponents
        static let coinEfficiency: Int = 2       // Saving coins for later
        static let level3Target: Int = 15        // Bonus for working toward L3 cards
    }

    func chooseAction(state: GameState, playerId: UUID) async -> GameAction {
        // Shorter delay (hard AI "thinks" faster but more effectively)
        do {
            try await Task.sleep(for: .milliseconds(600 + Int.random(in: 0...300)))
        } catch is CancellationError {
            return .pass
        } catch {}

        guard !Task.isCancelled else { return .pass }

        let actions = GameEngine.legalActions(in: state)
        let manualActions = actions.manualActions

        guard !manualActions.isEmpty else {
            return .pass
        }

        // Evaluate all actions and pick the best
        var bestAction: GameAction?
        var bestScore: Int = .min

        for action in manualActions {
            let score = evaluateAction(action, in: state)
            if score > bestScore {
                bestScore = score
                bestAction = action
            }
        }

        return bestAction ?? .pass
    }

    // MARK: - Evaluation

    /// Evaluate an action's strategic value
    private func evaluateAction(_ action: GameAction, in state: GameState) -> Int {
        switch action {
        case .purchaseCard(let card, let payment):
            return evaluatePurchase(card, payment: payment, in: state)

        case .takeCoins(let coins):
            return evaluateCoinTake(coins, in: state)

        case .reserveCard(let card):
            return evaluateReserve(card, in: state)

        case .repayCard(let card, let payment):
            return evaluateRepay(card, payment: payment, in: state)

        case .claimNoble(let noble):
            return Weights.pointValue * noble.point  // Always good to claim nobles

        case .pass:
            return -100
        }
    }

    /// Evaluate purchasing a card
    private func evaluatePurchase(_ card: Card, payment: [GemColor: Int], in state: GameState) -> Int {
        let playerIndex = state.currentPlayerIndex
        let player = state.players[playerIndex]
        let discounts = player.cardCounts

        var score = 0

        // Base value: points
        score += card.point * Weights.pointValue

        // Discount value: this card provides future discounts
        let futureDiscount = 3  // Each card provides at least 1 discount worth ~3 coins over game
        score += futureDiscount * Weights.discountValue

        // Color synergy: how well does this color help with nobles?
        let colorCount = (discounts[card.color] ?? 0) + 1
        score += colorCount * Weights.colorSynergy

        // Noble progress: does this bring us closer to any noble?
        for noble in state.availableNobles {
            let currentProgress = nobleProgress(player, toward: noble)
            // Simulate having this card
            var simulatedDiscounts = discounts
            simulatedDiscounts[card.color, default: 0] += 1
            let newProgress = nobleProgress(discounts: simulatedDiscounts, toward: noble)
            score += (newProgress - currentProgress) * Weights.nobleProgress
        }

        // Coin efficiency: did we spend efficiently?
        let coinsSpent = payment.values.reduce(0, +)
        let goldUsed = payment[.gold] ?? 0
        // Penalize spending gold (save for emergencies)
        score -= goldUsed * 5
        // Small penalty for spending coins (less flexibility later)
        score -= coinsSpent * Weights.coinEfficiency

        // Level bonus: working toward higher level cards (uses level3Target weight for L3)
        score += card.level == 3 ? Weights.level3Target : card.level * 3

        // Opponent pressure: are we racing opponents for this color?
        let opponentDemand = opponentDemandForColor(card.color, in: state)
        score += opponentDemand * Weights.opponentPressure

        // Strategic bonus for cards that unlock expensive cards
        let unlocksNewCards = countNewlyAffordableCards(after: card, in: state, for: player)
        score += unlocksNewCards * 8

        return score
    }

    /// Evaluate taking coins
    private func evaluateCoinTake(_ coins: [GemColor: Int], in state: GameState) -> Int {
        let playerIndex = state.currentPlayerIndex
        let player = state.players[playerIndex]
        let discounts = player.cardCounts

        var score = 0

        // Diversity bonus
        let colorCount = coins.keys.count
        score += colorCount * 5  // Prefer 3 different over 2 same

        // Color need: prefer colors we're missing cards for
        for color in coins.keys {
            if (discounts[color] ?? 0) == 0 {
                score += 4  // High value for new colors
            }
        }

        // Noble alignment: prefer colors that help with available nobles
        for noble in state.availableNobles {
            for (color, _) in coins {
                if let required = noble.cost[color], (discounts[color] ?? 0) < required {
                    score += 3
                }
            }
        }

        // Affordability check: do these coins help buy something soon?
        for card in state.cardsOnDisplay {
            let currentCanAfford = player.canPurchase(card)
            // Simulate having these coins
            var simulatedPurse = player.purse
            for (color, count) in coins {
                simulatedPurse.add(color, count: count)
            }
            var simulatedPlayer = player
            simulatedPlayer.purse = simulatedPurse
            let newCanAfford = simulatedPlayer.canPurchase(card)

            if !currentCanAfford && newCanAfford {
                score += 15  // Big bonus for unlocking a purchase
            }
        }

        // Penalize taking gold (it's a last resort indicator)
        if coins.keys.contains(.gold) {
            score -= 5
        }

        return score
    }

    /// Evaluate reserving a card
    private func evaluateReserve(_ card: Card, in state: GameState) -> Int {
        var score = 0

        // Base value of the card
        score += card.point * Weights.pointValue
        score += card.level * 5

        // Only reserve if we can't afford it now (otherwise buying is better)
        let playerIndex = state.currentPlayerIndex
        let player = state.players[playerIndex]

        if player.canPurchase(card) {
            score -= 20  // Should buy instead of reserve
        }

        // High level cards are worth reserving (they're valuable)
        if card.level == 3 {
            score += 10
        }

        // Get gold bonus
        if state.tableHasGold {
            score += 8  // Gold is valuable
        } else {
            score -= 5  // Reserving without gold is less valuable
        }

        // Color value
        let discounts = player.cardCounts
        if (discounts[card.color] ?? 0) == 0 {
            score += 6  // New color is valuable
        }

        return score
    }

    /// Evaluate repaying a reserved card
    private func evaluateRepay(_ card: Card, payment: [GemColor: Int], in state: GameState) -> Int {
        var score = 0

        // Same as purchase evaluation
        score += evaluatePurchase(card, payment: payment, in: state)

        // Bonus for freeing reserve slot and gaining discount
        score += card.level * 5

        return score
    }

    // MARK: - Helper Calculations

    /// Calculate progress toward a noble (0 to total required)
    private func nobleProgress(_ player: PlayerState, toward noble: PointCard) -> Int {
        nobleProgress(discounts: player.cardCounts, toward: noble)
    }

    private func nobleProgress(discounts: [GemColor: Int], toward noble: PointCard) -> Int {
        var progress = 0
        for (color, required) in noble.cost {
            progress += min(discounts[color] ?? 0, required)
        }
        return progress
    }

    /// How many opponents are collecting a specific color? (excludes self)
    private func opponentDemandForColor(_ color: GemColor, in state: GameState) -> Int {
        var demand = 0
        for player in state.players where player.id != state.currentPlayer.id {
            let count = player.cardCounts[color] ?? 0
            demand += count
        }
        return demand
    }

    /// Count how many new cards become affordable after getting this card
    private func countNewlyAffordableCards(after card: Card, in state: GameState, for player: PlayerState) -> Int {
        var simulatedDiscounts = player.cardCounts
        simulatedDiscounts[card.color, default: 0] += 1

        var count = 0
        for tableCard in state.cardsOnDisplay {
            let wasAffordable = player.canPurchase(tableCard)

            // Check if affordable with new discount (considering gold as wildcard)
            var goldNeeded = 0
            for (color, required) in tableCard.cost {
                let have = simulatedDiscounts[color] ?? 0
                let stillNeeded = max(required - have, 0)
                let purseHave = player.purse[color] ?? 0
                goldNeeded += max(stillNeeded - purseHave, 0)
            }
            let canAfford = goldNeeded <= (player.purse[.gold] ?? 0)

            if !wasAffordable && canAfford {
                count += 1
            }
        }

        return count
    }
}
