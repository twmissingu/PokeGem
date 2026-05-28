//
//  GameState.swift
//  PokeGem
//
//  Complete game state snapshot - value type
//  Replaces original scattered state across GameDesk and view controller
//

import Foundation

/// Game phase for state machine
enum GamePhase: String, Codable {
    case settings       // Configuring game
    case playerTurn     // Human player's turn
    case aiThinking     // AI is computing
    case aiExecuting    // AI action being applied
    case gameEnded      // Game over
}

/// Game configuration for starting a new game
struct GameConfig: Identifiable, Codable {
    let id = UUID()
    var humanPlayerAvatar: PlayerAvatar
    var robotAvatars: [PlayerAvatar]
    var robotDifficulties: [AIDifficulty]
    var targetScore: Int
    var hapticEnabled: Bool = true

    var humanPlayerName: String { humanPlayerAvatar.displayName }
    var robotNames: [String] { robotAvatars.map { $0.displayName } }
    var totalPlayers: Int { 1 + robotAvatars.count }
}

/// Complete game state - immutable snapshot
struct GameState: Hashable, Codable {
    // MARK: - Players

    var players: [PlayerState]
    var currentPlayerIndex: Int

    // MARK: - Table Resources

    var tableCoins: CoinPurse
    var level1Cards: [Card]       // Deck level 1 (40 cards initially)
    var level2Cards: [Card]       // Deck level 2 (30 cards initially)
    var level3Cards: [Card]       // Deck level 3 (20 cards initially)
    var availableNobles: [PointCard]  // Nobles available to claim

    // MARK: - Game Progress

    var turnNumber: Int
    var leaderPlayerId: UUID?
    var highestScore: Int
    var targetScore: Int
    var phase: GamePhase

    // MARK: - Computed Properties

    /// Current player whose turn it is
    var currentPlayer: PlayerState {
        precondition(currentPlayerIndex >= 0 && currentPlayerIndex < players.count,
                     "currentPlayerIndex \(currentPlayerIndex) out of range 0..<\(players.count)")
        return players[currentPlayerIndex]
    }

    /// Cards visible on table (max 4 per level)
    var cardsOnDisplay: [Card] {
        let l1 = Array(level1Cards.prefix(4))
        let l2 = Array(level2Cards.prefix(4))
        let l3 = Array(level3Cards.prefix(4))
        return l1 + l2 + l3
    }

    /// Cards on display by level
    var cardsByLevel: [[Card]] {
        [
            Array(level1Cards.prefix(4)),
            Array(level2Cards.prefix(4)),
            Array(level3Cards.prefix(4)),
        ]
    }

    /// Number of cards remaining in deck (not on display) for a given level
    func deckCount(for level: Int) -> Int {
        switch level {
        case 1: return max(0, level1Cards.count - 4)
        case 2: return max(0, level2Cards.count - 4)
        case 3: return max(0, level3Cards.count - 4)
        default: return 0
        }
    }

    /// Whether table has gold coins
    var tableHasGold: Bool {
        tableCoins.goldCount > 0
    }

    /// Whether game is over
    var isGameOver: Bool {
        phase == .gameEnded
    }

    /// Winner if game is over
    var winner: PlayerState? {
        guard isGameOver, let leaderId = leaderPlayerId else { return nil }
        return players.first { $0.id == leaderId }
    }

    /// Check if win condition is met (target reached and round complete)
    var isWinConditionMet: Bool {
        highestScore >= targetScore
    }

    /// Number of players
    var playerCount: Int {
        players.count
    }

    // MARK: - Initialization

    init(
        players: [PlayerState],
        tableCoins: CoinPurse,
        level1Cards: [Card],
        level2Cards: [Card],
        level3Cards: [Card],
        availableNobles: [PointCard],
        targetScore: Int
    ) {
        self.players = players
        self.currentPlayerIndex = 0
        self.tableCoins = tableCoins
        self.level1Cards = level1Cards
        self.level2Cards = level2Cards
        self.level3Cards = level3Cards
        self.availableNobles = availableNobles
        self.turnNumber = 0
        self.leaderPlayerId = nil
        self.highestScore = 0
        self.targetScore = targetScore
        self.phase = .playerTurn
    }
}

// MARK: - CustomStringConvertible

extension GameState: CustomStringConvertible {
    var description: String {
        """
        GameState(
          turn: \(turnNumber),
          currentPlayer: \(currentPlayer.name),
          highestScore: \(highestScore),
          targetScore: \(targetScore),
          leader: \(leaderPlayerId?.uuidString ?? "none"),
          phase: \(phase.rawValue),
          tableCoins: \(tableCoins.total),
          nobles: \(availableNobles.count)
        )
        """
    }
}
