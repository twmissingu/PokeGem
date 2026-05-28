//
//  AIStrategyTests.swift
//  PokeGemTests
//
//  Unit tests for AI strategies
//

import Testing
@testable import PokeGem
import Foundation

struct AIStrategyTests {

    private func createState(playerCount: Int = 2) -> GameState {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: Array(repeating: .gary, count: playerCount - 1),
            robotDifficulties: Array(repeating: .normal, count: playerCount - 1),
            targetScore: 15
        )
        return GameEngine.setup(config: config)
    }

    // MARK: - Easy AI

    @Test("EasyAI returns a valid action")
    func easyAIReturnsValidAction() async {
        var state = createState()
        state.currentPlayerIndex = 1
        let ai = EasyAIStrategy()
        let action = await ai.chooseAction(state: state, playerId: state.players[1].id)
        let legal = GameEngine.legalActions(in: state)
        #expect(legal.contains(action) || action == .pass)
    }

    @Test("EasyAI returns pass when no manual actions")
    func easyAIReturnsPass() async {
        var state = createState()
        state.currentPlayerIndex = 1
        state.level1Cards = []
        state.level2Cards = []
        state.level3Cards = []
        state.availableNobles = []
        state.players[1].purse = CoinPurse(coins: [.red: 10])
        state.players[1].reservedCards = []
        let ai = EasyAIStrategy()
        let action = await ai.chooseAction(state: state, playerId: state.players[1].id)
        #expect(action == .pass)
    }

    // MARK: - Normal AI

    @Test("NormalAI returns a valid action")
    func normalAIReturnsValidAction() async {
        var state = createState()
        state.currentPlayerIndex = 1
        let ai = NormalAIStrategy()
        let action = await ai.chooseAction(state: state, playerId: state.players[1].id)
        let legal = GameEngine.legalActions(in: state)
        #expect(legal.contains(action) || action == .pass)
    }

    @Test("NormalAI returns pass when no manual actions")
    func normalAIReturnsPass() async {
        var state = createState()
        state.currentPlayerIndex = 1
        state.level1Cards = []
        state.level2Cards = []
        state.level3Cards = []
        state.availableNobles = []
        state.players[1].purse = CoinPurse(coins: [.red: 10])
        state.players[1].reservedCards = []
        let ai = NormalAIStrategy()
        let action = await ai.chooseAction(state: state, playerId: state.players[1].id)
        #expect(action == .pass)
    }

    // MARK: - Hard AI

    @Test("HardAI returns a valid action")
    func hardAIReturnsValidAction() async {
        var state = createState()
        state.currentPlayerIndex = 1
        let ai = HardAIStrategy()
        let action = await ai.chooseAction(state: state, playerId: state.players[1].id)
        let legal = GameEngine.legalActions(in: state)
        #expect(legal.contains(action) || action == .pass)
    }

    @Test("HardAI returns pass when no manual actions")
    func hardAIReturnsPass() async {
        var state = createState()
        state.currentPlayerIndex = 1
        state.level1Cards = []
        state.level2Cards = []
        state.level3Cards = []
        state.availableNobles = []
        state.players[1].purse = CoinPurse(coins: [.red: 10])
        state.players[1].reservedCards = []
        let ai = HardAIStrategy()
        let action = await ai.chooseAction(state: state, playerId: state.players[1].id)
        #expect(action == .pass)
    }

    // MARK: - Difficulty Property

    @Test("EasyAI has easy difficulty")
    func easyDifficulty() {
        let ai = EasyAIStrategy()
        #expect(ai.difficulty == .easy)
    }

    @Test("NormalAI has normal difficulty")
    func normalDifficulty() {
        let ai = NormalAIStrategy()
        #expect(ai.difficulty == .normal)
    }

    @Test("HardAI has hard difficulty")
    func hardDifficulty() {
        let ai = HardAIStrategy()
        #expect(ai.difficulty == .hard)
    }
}
