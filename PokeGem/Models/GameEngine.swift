//
//  GameEngine.swift
//  PokeGem
//
//  Core game engine - pure functions operating on immutable GameState
//  Replaces original GameDesk class with value-type approach
//  All methods are static, taking GameState and returning new GameState
//

import Foundation

/// Game engine containing all rules and state transitions
struct GameEngine {

    // MARK: - Game Setup

    /// Create initial game state from configuration
    /// - Parameters:
    ///   - config: Game configuration
    /// - Returns: Fully initialized GameState
    static func setup(config: GameConfig) -> GameState {
        // Create players
        var players: [PlayerState] = []

        // Human player (index 0)
        let human = PlayerState(name: config.humanPlayerName, isHuman: true, avatar: config.humanPlayerAvatar)
        players.append(human)

        // Robot players
        for (index, avatar) in config.robotAvatars.enumerated() {
            let difficulty = index < config.robotDifficulties.count
                ? config.robotDifficulties[index]
                : .normal
            let robot = PlayerState(name: avatar.displayName, isHuman: false, avatar: avatar)
            players.append(robot)
        }

        // Calculate coin count per color based on player count
        let coinsPerColor = coinCountForPlayers(config.totalPlayers)

        // Initialize table coins (shuffled)
        let tableCoins = CoinPurse(filledWith: coinsPerColor)
        // Add 5 gold coins
        var finalTableCoins = tableCoins
        finalTableCoins.add(.gold, count: 5)

        // Shuffle and distribute cards
        let allCards = Card.allCards().shuffled()
        let level1Cards = allCards.filter { $0.level == 1 }
        let level2Cards = allCards.filter { $0.level == 2 }
        let level3Cards = allCards.filter { $0.level == 3 }

        // Validate card distribution — each level must have at least 4 cards for the display
        precondition(level1Cards.count >= 4, "Level 1 must have at least 4 cards, got \(level1Cards.count)")
        precondition(level2Cards.count >= 4, "Level 2 must have at least 4 cards, got \(level2Cards.count)")
        precondition(level3Cards.count >= 4, "Level 3 must have at least 4 cards, got \(level3Cards.count)")

        // Select nobles (playerCount + 1, max 10)
        let nobleCount = min(config.totalPlayers + 1, 10)
        let availableNobles = PointCard.allPointCards().shuffled().prefix(nobleCount).map { $0 }

        return GameState(
            players: players,
            tableCoins: finalTableCoins,
            level1Cards: level1Cards,
            level2Cards: level2Cards,
            level3Cards: level3Cards,
            availableNobles: availableNobles,
            targetScore: config.targetScore
        )
    }

    /// Calculate coin count per color based on player count
    /// - Parameter playerCount: Number of players (2-4)
    /// - Returns: Coins per color (4 for 2 players, 5 for 3, 7 for 4)
    static func coinCountForPlayers(_ playerCount: Int) -> Int {
        switch playerCount {
        case 2: return 4
        case 3: return 5
        case 4: return 7
        default: return 5  // Default to 3-player count
        }
    }

    // MARK: - Action Application

    /// Apply a game action to state, returning new state
    /// - Parameters:
    ///   - action: Action to apply
    ///   - state: Current game state
    /// - Returns: New game state after action
    static func apply(_ action: GameAction, to state: GameState) -> GameState {
        var newState = state

        switch action {
        case .takeCoins(let coins):
            newState = applyTakeCoins(coins, to: newState)

        case .purchaseCard(let card, let payment):
            newState = applyPurchaseCard(card, payment: payment, in: newState)

        case .reserveCard(let card):
            newState = applyReserveCard(card, in: newState)

        case .repayCard(let card, let payment):
            newState = applyRepayCard(card, payment: payment, in: newState)

        case .claimNoble(let noble):
            newState = applyClaimNoble(noble, in: newState)

        case .pass:
            break  // No state change
        }

        return newState
    }

    // MARK: - Action Implementations

    /// Validate coin-taking follows Splendor rules AND table has enough coins:
    ///   3 different colors (1 each) OR 2 same color (only if table >= 4) OR 1 single coin
    static func isValidCoinTake(_ coins: [GemColor: Int], in state: GameState) -> Bool {
        let total = coins.values.reduce(0, +)
        guard total >= 1 && total <= 3 else { return false }

        let colorCount = coins.keys.count

        // Check table has enough coins for each color
        for (color, count) in coins where count > 0 {
            guard state.tableCoins[color] >= count else { return false }
        }

        if colorCount == 1 {
            let count = coins.values.first!
            if count == 2 {
                let color = coins.keys.first!
                return state.tableCoins[color] >= 4
            }
            return count == 1
        }

        if colorCount == total && total == 3 {
            return true
        }

        return false
    }

    /// Apply taking coins action (atomic: validates player first)
    private static func applyTakeCoins(_ coins: [GemColor: Int], to state: GameState) -> GameState {
        let playerIndex = state.currentPlayerIndex

        guard isValidCoinTake(coins, in: state) else {
            return state
        }

        // Validate player can take coins FIRST
        guard let updatedPlayer = state.players[playerIndex].takingCoins(coins) else {
            return state // Reject: player at limit or invalid
        }

        // Only then modify table state
        var newState = state
        newState.players[playerIndex] = updatedPlayer
        for (color, count) in coins {
            guard newState.tableCoins.remove(color, count: count) else {
                return state  // Safety: reject if table doesn't have enough
            }
        }

        return newState
    }

    /// Apply purchasing card action (atomic: validates player first)
    private static func applyPurchaseCard(_ card: Card, payment: [GemColor: Int], in state: GameState) -> GameState {
        let playerIndex = state.currentPlayerIndex

        guard isCardOnTable(card, in: state) else {
            return state
        }

        // Defense-in-depth: verify payment covers card cost after discounts
        guard paymentCoversCost(card.cost, payment: payment, discounts: state.players[playerIndex].cardCounts) else {
            return state
        }

        // Validate player can purchase FIRST
        guard let updatedPlayer = state.players[playerIndex].purchasing(card, with: payment) else {
            return state // Reject: insufficient coins or invalid
        }

        // Only then modify table state
        var newState = state
        newState.players[playerIndex] = updatedPlayer
        newState = removeCardFromTable(card, in: newState)
        for (color, count) in payment {
            newState.tableCoins.add(color, count: count)
        }

        return newState
    }

    /// Apply reserving card action (atomic: validates player first)
    private static func applyReserveCard(_ card: Card, in state: GameState) -> GameState {
        let playerIndex = state.currentPlayerIndex

        guard isCardOnTable(card, in: state) else {
            return state
        }

        // Validate player can reserve FIRST
        guard let updatedPlayer = state.players[playerIndex].reserving(card, tableHasGold: state.tableHasGold) else {
            return state // Reject: reserve limit reached or invalid
        }

        // Only then modify table state
        var newState = state
        newState.players[playerIndex] = updatedPlayer
        newState = removeCardFromTable(card, in: newState)
        // Remove gold from table if reserving() actually gave gold to the player
        let goldWasGiven = updatedPlayer.purse.goldCount > state.players[playerIndex].purse.goldCount
        if goldWasGiven {
            newState.tableCoins.remove(.gold, count: 1)
        }

        return newState
    }

    /// Apply repaying reserved card action (atomic: validates player first)
    private static func applyRepayCard(_ card: Card, payment: [GemColor: Int], in state: GameState) -> GameState {
        let playerIndex = state.currentPlayerIndex

        // Defense-in-depth: verify payment covers card cost after discounts
        guard paymentCoversCost(card.cost, payment: payment, discounts: state.players[playerIndex].cardCounts) else {
            return state
        }

        // Validate player can repay FIRST
        guard let updatedPlayer = state.players[playerIndex].repaying(card, with: payment) else {
            return state // Reject: card not reserved or insufficient coins
        }

        // Only then modify table state
        var newState = state
        newState.players[playerIndex] = updatedPlayer
        for (color, count) in payment {
            newState.tableCoins.add(color, count: count)
        }

        return newState
    }

    /// Apply claiming noble action (atomic: validates player first)
    static func applyClaimNoble(_ noble: PointCard, in state: GameState) -> GameState {
        let playerIndex = state.currentPlayerIndex

        // Validate player can claim FIRST
        guard let updatedPlayer = state.players[playerIndex].claiming(noble) else {
            return state // Reject: requirements not met
        }

        // Only then modify table state
        var newState = state
        newState.players[playerIndex] = updatedPlayer
        newState.availableNobles.removeAll { $0.id == noble.id }

        return newState
    }

    // MARK: - Payment Validation

    /// Verify that a payment dictionary covers the card cost after applying discounts.
    /// Validates both total amount and color correspondence (defense-in-depth).
    private static func paymentCoversCost(_ cost: [GemColor: Int], payment: [GemColor: Int], discounts: [GemColor: Int]) -> Bool {
        let totalNetCost = cost.reduce(0) { sum, pair in
            sum + max(0, pair.value - (discounts[pair.key] ?? 0))
        }
        let totalPaid = payment.values.reduce(0, +)
        guard totalPaid >= totalNetCost else { return false }

        // Defense-in-depth: non-gold payment colors must be present in the card's cost
        let costColors = Set(cost.keys)
        for (color, count) in payment where count > 0 && color != .gold {
            guard costColors.contains(color) else { return false }
        }

        return true
    }

    // MARK: - Card Management

    /// Remove a card from the table (any level)
    private static func removeCardFromTable(_ card: Card, in state: GameState) -> GameState {
        var newState = state

        switch card.level {
        case 1:
            newState.level1Cards.removeAll { $0.id == card.id }
        case 2:
            newState.level2Cards.removeAll { $0.id == card.id }
        case 3:
            newState.level3Cards.removeAll { $0.id == card.id }
        default:
            break
        }

        return newState
    }

    /// Check if a card is available on the table
    static func isCardOnTable(_ card: Card, in state: GameState) -> Bool {
        switch card.level {
        case 1: return state.level1Cards.contains { $0.id == card.id }
        case 2: return state.level2Cards.contains { $0.id == card.id }
        case 3: return state.level3Cards.contains { $0.id == card.id }
        default: return false
        }
    }

    // MARK: - Legal Actions

    /// Get all legal actions for current player
    /// - Parameters:
    ///   - playerIndex: Index of player (defaults to current player)
    ///   - state: Current game state
    /// - Returns: Array of legal actions
    static func legalActions(for playerIndex: Int? = nil, in state: GameState) -> [GameAction] {
        let index = playerIndex ?? state.currentPlayerIndex
        let player = state.players[index]
        var actions: [GameAction] = []

        // 1. Take coins actions
        actions.append(contentsOf: legalCoinActions(for: player, in: state))

        // 2. Purchase card actions
        for card in state.cardsOnDisplay {
            if let payment = player.purse.coinsToPay(card.cost, with: player.cardCounts) {
                actions.append(.purchaseCard(card, payment))
            }
        }

        // 3. Reserve card actions
        if player.canReserveMore {
            for card in state.cardsOnDisplay {
                actions.append(.reserveCard(card))
            }
        }

        // 4. Repay reserved card actions
        for card in player.reservedCards {
            if let payment = player.purse.coinsToPay(card.cost, with: player.cardCounts) {
                actions.append(.repayCard(card, payment))
            }
        }

        // 5. Pass (always available as fallback)
        if actions.isEmpty {
            actions.append(.pass)
        }

        return actions
    }

    /// Get legal coin-taking actions
    private static func legalCoinActions(for player: PlayerState, in state: GameState) -> [GameAction] {
        guard !player.hasCoinsAtLimit else { return [] }

        var actions: [GameAction] = []
        let playerRemaining = 10 - player.purse.total
        let maxCoins = min(playerRemaining, 3)
        let tableCoins = state.tableCoins

        // Single color take (up to 2 if >= 4 on table)
        for color in GemColor.gemColors {
            let countOnTable = tableCoins[color]

            if countOnTable > 0 {
                // Take 1
                actions.append(.takeCoins([color: 1]))

                // Take 2 (only if >= 4 on table)
                if countOnTable >= 4 && maxCoins >= 2 {
                    actions.append(.takeCoins([color: 2]))
                }
            }
        }

        // Three different colors
        let availableColors = GemColor.gemColors.filter { tableCoins[$0] > 0 }
        if availableColors.count >= 3 && maxCoins >= 3 {
            // Generate combinations of 3 different colors
            for i in 0..<availableColors.count - 2 {
                for j in (i + 1)..<availableColors.count - 1 {
                    for k in (j + 1)..<availableColors.count {
                        let c1 = availableColors[i]
                        let c2 = availableColors[j]
                        let c3 = availableColors[k]
                        actions.append(.takeCoins([c1: 1, c2: 1, c3: 1]))
                    }
                }
            }
        }

        return actions
    }

    // MARK: - Turn Pipeline

    /// Apply action and run all post-action checks (nobles, win condition).
    /// This is the single entry point for processing any player action.
    static func processAction(_ action: GameAction, in state: GameState) -> GameState {
        var newState = apply(action, to: state)
        newState = autoClaimNobles(in: newState)
        newState = checkWinCondition(newState)
        return newState
    }

    // MARK: - Turn Management

    /// Advance to next player's turn
    /// - Parameter state: Current game state
    /// - Returns: New game state with advanced turn
    static func advanceTurn(_ state: GameState) -> GameState {
        var newState = state
        newState.turnNumber += 1
        let previousPlayerIndex = state.currentPlayerIndex
        newState.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.players.count

        // Standard Splendor rule: game ends after the full round completes
        // when a player has reached the target score
        if newState.currentPlayerIndex <= previousPlayerIndex
            && newState.isWinConditionMet
            && newState.phase != .gameEnded {
            newState.phase = .gameEnded
            return newState
        }

        // Determine phase based on new current player
        if newState.currentPlayer.isHuman {
            newState.phase = .playerTurn
        } else {
            newState.phase = .aiThinking
        }

        return newState
    }

    /// Auto-claim nobles for current player if requirements met
    /// - Parameter state: Current game state
    /// - Returns: New game state with claimed nobles
    static func autoClaimNobles(in state: GameState) -> GameState {
        var newState = state
        let player = state.currentPlayer

        // Find first claimable noble
        for noble in state.availableNobles {
            if player.canAttract(noble) {
                newState = applyClaimNoble(noble, in: newState)
                // Player can only claim one noble per turn
                break
            }
        }

        return newState
    }

    // MARK: - Win Condition

    /// Check and update win condition (updates leader/score, does NOT end game)
    /// Tiebreaker order: totalPoints > pointCards.count > ownedCards.count (fewest wins)
    static func checkWinCondition(_ state: GameState) -> GameState {
        var newState = state

        var bestId: UUID?
        var bestPoints = -1
        var bestNobles = -1
        var bestCards = Int.max  // Fewest cards wins ties

        for player in state.players {
            let points = player.totalPoints
            let nobles = player.pointCards.count
            let cards = player.ownedCards.count

            if points > bestPoints
                || (points == bestPoints && nobles > bestNobles)
                || (points == bestPoints && nobles == bestNobles && cards < bestCards)
            {
                bestId = player.id
                bestPoints = points
                bestNobles = nobles
                bestCards = cards
            }
        }

        newState.leaderPlayerId = bestId
        newState.highestScore = bestPoints

        return newState
    }
}
