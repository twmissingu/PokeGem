import Foundation
//
//  AIStrategy.swift
//  PokeGem
//
//  Protocol for AI strategies
//

/// AI difficulty levels
enum AIDifficulty: String, CaseIterable, Codable {
    case easy
    case normal
    case hard

    /// Display name
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .normal: return "普通"
        case .hard: return "困难"
        }
    }
}

/// Protocol for AI strategy implementations
protocol AIStrategy: Sendable {
    /// Difficulty level of this AI
    var difficulty: AIDifficulty { get }

    /// Choose an action given current game state
    /// - Parameters:
    ///   - state: Current game state
    ///   - playerId: ID of the AI player
    /// - Returns: Chosen game action
    func chooseAction(state: GameState, playerId: UUID) async -> GameAction
}
