//
//  EasyAIStrategy.swift
//  PokeGem
//
//  Easy AI: Random action selection with basic priority
//

import Foundation

/// Easy difficulty AI strategy
/// Randomly selects from legal actions with slight preference for purchases
struct EasyAIStrategy: AIStrategy, Sendable {
    let difficulty: AIDifficulty = .easy

    func chooseAction(state: GameState, playerId: UUID) async -> GameAction {
        // Add artificial delay for UX (simulates "thinking")
        do {
            try await Task.sleep(for: .milliseconds(500 + Int.random(in: 0...500)))
        } catch is CancellationError {
            return .pass
        } catch {}

        guard !Task.isCancelled else { return .pass }

        let actions = GameEngine.legalActions(in: state)

        // Filter out automatic actions and pass
        let manualActions = actions.manualActions

        guard !manualActions.isEmpty else {
            return actions.first ?? .pass
        }

        // Slight priority: purchase > reserve > repay > take coins
        var weightedActions: [GameAction] = []

        for action in manualActions {
            switch action {
            case .purchaseCard:
                weightedActions.append(contentsOf: [action, action, action])  // 3x weight
            case .reserveCard:
                weightedActions.append(contentsOf: [action, action])  // 2x weight
            case .repayCard:
                weightedActions.append(action)
            case .takeCoins:
                weightedActions.append(action)
            default:
                weightedActions.append(action)
            }
        }

        return weightedActions.randomElement() ?? .pass
    }
}
