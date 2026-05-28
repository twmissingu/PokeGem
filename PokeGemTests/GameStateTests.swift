//
//  GameStateTests.swift
//  PokeGemTests
//
//  Unit tests for GameState properties
//

import Testing
@testable import PokeGem
import Foundation

struct GameStateTests {

    private func createState(playerCount: Int = 2) -> GameState {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: Array(repeating: .gary, count: playerCount - 1),
            robotDifficulties: Array(repeating: .normal, count: playerCount - 1),
            targetScore: 15
        )
        return GameEngine.setup(config: config)
    }

    // MARK: - Computed Properties

    @Test("currentPlayer returns first player initially")
    func currentPlayerInitially() {
        let state = createState()
        #expect(state.currentPlayer.isHuman == true)
    }

    @Test("cardsOnDisplay returns max 4 per level")
    func cardsOnDisplayMax4PerLevel() {
        let state = createState()
        let display = state.cardsOnDisplay
        #expect(display.filter { $0.level == 1 }.count == 4)
        #expect(display.filter { $0.level == 2 }.count == 4)
        #expect(display.filter { $0.level == 3 }.count == 4)
        #expect(display.count == 12)
    }

    @Test("cardsByLevel returns correct 2D array")
    func cardsByLevelStructure() {
        let state = createState()
        let byLevel = state.cardsByLevel
        #expect(byLevel.count == 3)
        #expect(byLevel[0].count == 4)
        #expect(byLevel[1].count == 4)
        #expect(byLevel[2].count == 4)
        #expect(byLevel[0].allSatisfy { $0.level == 1 })
        #expect(byLevel[1].allSatisfy { $0.level == 2 })
        #expect(byLevel[2].allSatisfy { $0.level == 3 })
    }

    @Test("tableHasGold is true initially")
    func tableHasGoldInitially() {
        let state = createState()
        #expect(state.tableHasGold == true)
    }

    @Test("tableHasGold is false when no gold")
    func tableHasGoldFalse() {
        var state = createState()
        state.tableCoins = CoinPurse()  // No gold
        #expect(state.tableHasGold == false)
    }

    @Test("isGameOver is false initially")
    func isGameOverInitially() {
        let state = createState()
        #expect(state.isGameOver == false)
    }

    @Test("isGameOver is true when phase is gameEnded")
    func isGameOverWhenEnded() {
        var state = createState()
        state.phase = .gameEnded
        #expect(state.isGameOver == true)
    }

    @Test("winner returns nil when game not over")
    func winnerNilWhenNotOver() {
        let state = createState()
        #expect(state.winner == nil)
    }

    @Test("winner returns correct player")
    func winnerReturnsLeader() {
        var state = createState(playerCount: 2)
        state.players[0].ownedCards = (0..<15).map { Card(id: 100 + $0, color: .red, point: 1, level: 1, cost: [:]) }
        state.leaderPlayerId = state.players[0].id
        state.phase = .gameEnded
        #expect(state.winner?.id == state.players[0].id)
    }

    @Test("isWinConditionMet is false below target")
    func winConditionNotMet() {
        let state = createState()
        #expect(state.isWinConditionMet == false)
    }

    @Test("isWinConditionMet is true at target")
    func winConditionMet() {
        var state = createState()
        state.highestScore = 15
        #expect(state.isWinConditionMet == true)
    }

    @Test("playerCount returns correct number")
    func playerCount() {
        let state2 = createState(playerCount: 2)
        #expect(state2.playerCount == 2)
        let state4 = createState(playerCount: 4)
        #expect(state4.playerCount == 4)
    }

    // MARK: - Description

    @Test("Description contains key info")
    func descriptionContainsInfo() {
        let state = createState()
        let desc = state.description
        #expect(desc.contains("turn"))
        #expect(desc.contains("currentPlayer"))
        #expect(desc.contains("highestScore"))
        #expect(desc.contains("phase"))
    }
}
