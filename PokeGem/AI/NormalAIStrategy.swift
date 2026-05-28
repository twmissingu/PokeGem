//
//  NormalAIStrategy.swift
//  PokeGem
//
//  Normal AI: Greedy strategy with priority ordering
//  Ported from original Robot.aiBuyCard/aiTakeCoins/etc. logic
//

import Foundation

/// Normal difficulty AI strategy
/// Greedy approach: prefer buying cards > taking coins > repaying > reserving
struct NormalAIStrategy: AIStrategy, Sendable {
    let difficulty: AIDifficulty = .normal

    func chooseAction(state: GameState, playerId: UUID) async -> GameAction {
        // Add artificial delay for UX
        do {
            try await Task.sleep(for: .milliseconds(800 + Int.random(in: 0...400)))
        } catch is CancellationError {
            return .pass
        } catch {}

        guard !Task.isCancelled else { return .pass }

        let actions = GameEngine.legalActions(in: state)
        let manualActions = actions.manualActions

        guard !manualActions.isEmpty else {
            return .pass
        }

        // Priority 1: Buy card (prefer cheaper cards with more points)
        if let buyAction = bestPurchaseAction(from: manualActions, in: state) {
            return buyAction
        }

        // Priority 2: Take coins (prefer diverse colors)
        if let coinAction = bestCoinAction(from: manualActions, in: state) {
            return coinAction
        }

        // Priority 3: Repay reserved card
        if let repayAction = manualActions.first(where: { if case .repayCard = $0 { return true } else { return false } }) {
            return repayAction
        }

        // Priority 4: Reserve card
        if let reserveAction = manualActions.first(where: { if case .reserveCard = $0 { return true } else { return false } }) {
            return reserveAction
        }

        // Fallback: first available action
        return manualActions.first ?? .pass
    }

    /// Find best purchase action (minimize coins spent, maximize points)
    private func bestPurchaseAction(from actions: [GameAction], in state: GameState) -> GameAction? {
        var bestAction: GameAction?
        var bestScore: Int = -1

        for action in actions {
            if case .purchaseCard(let card, let payment) = action {
                // Score: higher points - coins spent = better value
                let coinsSpent = payment.values.reduce(0, +)
                let score = card.point * 10 - coinsSpent + card.level * 2

                if score > bestScore {
                    bestScore = score
                    bestAction = action
                }
            }
        }

        return bestAction
    }

    /// Find best coin-taking action (prefer diverse colors)
    private func bestCoinAction(from actions: [GameAction], in state: GameState) -> GameAction? {
        let playerIndex = state.players.firstIndex { $0.id == state.currentPlayer.id } ?? state.currentPlayerIndex
        let player = state.players[playerIndex]
        let discounts = player.cardCounts

        var bestAction: GameAction?
        var bestScore: Int = -1

        for action in actions {
            if case .takeCoins(let coins) = action {
                var score = 0
                let colorCount = coins.keys.count

                // Prefer diverse colors (3 different > 2 same)
                score += colorCount * 5

                // Prefer colors we don't have cards for yet
                for color in coins.keys {
                    if (discounts[color] ?? 0) == 0 {
                        score += 3
                    }
                }

                // Prefer colors needed for affordable cards
                for card in state.cardsOnDisplay {
                    if player.canPurchase(card) {
                        for (color, _) in coins {
                            if card.cost[color] != nil {
                                score += 2
                            }
                        }
                    }
                }

                if score > bestScore {
                    bestScore = score
                    bestAction = action
                }
            }
        }

        return bestAction
    }
}
