//
//  GameEngineTests.swift
//  PokeGemTests
//
//  Unit tests for GameEngine core logic
//

import Testing
@testable import PokeGem
import Foundation

struct GameEngineTests {

    // MARK: - Helper Methods

    private func createTestConfig(
        humanAvatar: PlayerAvatar = .ash,
        robotCount: Int = 2,
        targetScore: Int = 15
    ) -> GameConfig {
        let robotAvatars: [PlayerAvatar] = [.gary, .teamRocket, .jessie, .james]
        let difficulties = (0..<robotCount).map { index in AIDifficulty.normal }
        return GameConfig(
            humanPlayerAvatar: humanAvatar,
            robotAvatars: Array(robotAvatars.prefix(robotCount)),
            robotDifficulties: difficulties,
            targetScore: targetScore
        )
    }

    private func createTestState(
        playerCount: Int = 2,
        tableCoins: CoinPurse? = nil,
        targetScore: Int = 15
    ) -> GameState {
        let config = createTestConfig(robotCount: playerCount - 1, targetScore: targetScore)
        var state = GameEngine.setup(config: config)
        if let coins = tableCoins {
            state.tableCoins = coins
        }
        return state
    }

    // MARK: - Setup Tests

    @Test("Setup creates correct number of players")
    func setupCreatesCorrectPlayers() {
        let config = createTestConfig(robotCount: 3)
        let state = GameEngine.setup(config: config)
        #expect(state.players.count == 4)
        #expect(state.players[0].isHuman == true)
        #expect(state.players[1].isHuman == false)
        #expect(state.players[2].isHuman == false)
        #expect(state.players[3].isHuman == false)
    }

    @Test("Setup initializes first player as current")
    func setupInitializesFirstPlayer() {
        let config = createTestConfig()
        let state = GameEngine.setup(config: config)
        #expect(state.currentPlayerIndex == 0)
        #expect(state.currentPlayer.isHuman == true)
    }

    @Test("Setup initializes table coins")
    func setupInitializesTableCoins() {
        let config = createTestConfig(robotCount: 2)  // 3 players -> 5 coins per color
        let state = GameEngine.setup(config: config)
        #expect(state.tableCoins[.red] == 5)
        #expect(state.tableCoins[.blue] == 5)
        #expect(state.tableCoins[.gold] == 5)  // Gold always 5
    }

    @Test("Setup shuffles cards onto table")
    func setupShufflesCards() {
        let config = createTestConfig()
        let state = GameEngine.setup(config: config)
        #expect(state.level1Cards.count > 0)
        #expect(state.level2Cards.count > 0)
        #expect(state.level3Cards.count > 0)
    }

    @Test("Setup assigns avatars to players")
    func setupAssignsAvatars() {
        let config = createTestConfig(robotCount: 2)
        let state = GameEngine.setup(config: config)
        
        // First player is human, should get ash avatar
        #expect(state.players[0].avatar == .ash)
        
        // Other players are robots, should get robot avatars
        #expect(state.players[1].avatar != .ash)
        #expect(state.players[2].avatar != .ash)
    }

    @Test("Setup selects correct noble count")
    func setupSelectsNobles() {
        // 2 players + 1 human = 3 total -> 3 + 1 = 4 nobles
        let config = createTestConfig(robotCount: 2)
        let state = GameEngine.setup(config: config)
        #expect(state.availableNobles.count == 4)
    }

    // MARK: - Coin Count Tests

    @Test("Coin count for 2 players is 4")
    func coinCountFor2Players() {
        #expect(GameEngine.coinCountForPlayers(2) == 4)
    }

    @Test("Coin count for 3 players is 5")
    func coinCountFor3Players() {
        #expect(GameEngine.coinCountForPlayers(3) == 5)
    }

    @Test("Coin count for 4 players is 7")
    func coinCountFor4Players() {
        #expect(GameEngine.coinCountForPlayers(4) == 7)
    }

    @Test("Coin count defaults to 5")
    func coinCountDefault() {
        #expect(GameEngine.coinCountForPlayers(1) == 5)
        #expect(GameEngine.coinCountForPlayers(5) == 5)
    }

    // MARK: - Turn Management Tests

    @Test("Advance turn moves to next player")
    func advanceTurnMovesToNextPlayer() {
        let state = createTestState(playerCount: 3)
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.currentPlayerIndex == 1)
        #expect(newState.turnNumber == 1)
    }

    @Test("Advance turn wraps around")
    func advanceTurnWrapsAround() {
        var state = createTestState(playerCount: 2)
        state.currentPlayerIndex = 1  // Last player
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.currentPlayerIndex == 0)
    }

    @Test("Advance turn sets AI phase for robot")
    func advanceTurnSetsAIPhase() {
        var state = createTestState(playerCount: 3)
        state.currentPlayerIndex = 1  // Robot
        state.phase = .playerTurn
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.phase == .aiThinking)
    }

    // MARK: - Take Coins Tests

    @Test("Apply take coins adds to player")
    func applyTakeCoins() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 5, .blue: 5, .green: 5])
        let action: GameAction = .takeCoins([.red: 2])
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.players[0].purse[.red] == 2)
        #expect(newState.players[0].purse[.blue] == 0)
        #expect(newState.tableCoins[.red] == 3)
        #expect(newState.tableCoins[.blue] == 5)
    }

    // MARK: - Purchase Card Tests

    @Test("Apply purchase card removes card and updates player")
    func applyPurchaseCard() {
        var state = createTestState()
        // Card 11: green, cost [.white: 2]
        let card = Card.allCards().first { $0.id == 11 }!
        state.level1Cards = [card]
        state.players[0].purse = CoinPurse(coins: [.white: 5])
        state.tableCoins = CoinPurse()

        let payment: [GemColor: Int] = [.white: 2]
        let action: GameAction = .purchaseCard(card, payment)
        let newState = GameEngine.apply(action, to: state)

        #expect(!newState.level1Cards.contains { $0.id == card.id })
        #expect(newState.players[0].ownedCards.count == 1)
        #expect(newState.players[0].ownedCards[0].id == card.id)
        #expect(newState.players[0].purse[.white] == 3)
        #expect(newState.tableCoins[.white] == 2)  // Coins returned to table
    }

    // MARK: - Reserve Card Tests

    @Test("Apply reserve card adds to reserved")
    func applyReserveCard() {
        var state = createTestState()
        let card = Card.allCards().first { $0.level == 1 }!
        state.level1Cards = [card]
        state.tableCoins = CoinPurse(coins: [.gold: 3])

        let action: GameAction = .reserveCard(card)
        let newState = GameEngine.apply(action, to: state)

        #expect(!newState.level1Cards.contains { $0.id == card.id })
        #expect(newState.players[0].reservedCards.count == 1)
        #expect(newState.players[0].reservedCards[0].id == card.id)
        #expect(newState.players[0].purse.goldCount == 1)  // Got gold
        #expect(newState.tableCoins.goldCount == 2)  // Gold removed from table
    }

    // MARK: - Repay Card Tests

    @Test("Apply repay card moves from reserved to owned")
    func applyRepayCard() {
        var state = createTestState()
        let card = Card(id: 99, color: .red, point: 0, level: 1, cost: [.blue: 2])
        state.players[0].reservedCards = [card]
        state.players[0].purse = CoinPurse(coins: [.blue: 5])
        state.tableCoins = CoinPurse()

        let payment: [GemColor: Int] = [.blue: 2]
        let action: GameAction = .repayCard(card, payment)
        let newState = GameEngine.apply(action, to: state)

        #expect(newState.players[0].reservedCards.isEmpty)
        #expect(newState.players[0].ownedCards.count == 1)
        #expect(newState.players[0].ownedCards[0].id == card.id)
        #expect(newState.players[0].purse[.blue] == 3)
        #expect(newState.tableCoins[.blue] == 2)
    }

    // MARK: - Claim Noble Tests

    @Test("Apply claim noble adds to player")
    func applyClaimNoble() {
        var state = createTestState()
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4, .blue: 4])
        state.availableNobles = [noble]
        // Create cards that meet the noble's requirements: 4 red + 4 blue
        state.players[0].ownedCards = (0..<4).map { index in
            Card(id: 100 + index, color: .red, point: 0, level: 1, cost: [:])
        }
        state.players[0].ownedCards.append(contentsOf: (0..<4).map { index in
            Card(id: 200 + index, color: .blue, point: 0, level: 1, cost: [:])
        })

        let action: GameAction = .claimNoble(noble)
        let newState = GameEngine.apply(action, to: state)

        #expect(newState.players[0].pointCards.count == 1)
        #expect(newState.players[0].pointCards[0].id == noble.id)
        #expect(newState.availableNobles.isEmpty)
    }

    // MARK: - Legal Actions Tests

    @Test("Legal actions include pass when no actions available")
    func legalActionsIncludePass() {
        // Create a state with no available actions
        var state = createTestState()
        // Remove all cards from table
        state.level1Cards = []
        state.level2Cards = []
        state.level3Cards = []
        // Remove all nobles
        state.availableNobles = []
        // Player at coin limit (10 coins)
        state.players[0].purse = CoinPurse(coins: [.red: 10])
        // Player has no reserved cards
        state.players[0].reservedCards = []

        let actions = GameEngine.legalActions(in: state)
        #expect(actions == [.pass])
    }

    @Test("Legal actions include coin takes when table has coins")
    func legalActionsIncludeCoinTakes() {
        var state = createTestState()
        state.tableCoins = CoinPurse(filledWith: 5)
        let actions = GameEngine.legalActions(in: state)
        let hasTakeAction = actions.contains { action in
            if case .takeCoins = action { return true }
            return false
        }
        #expect(hasTakeAction == true)
    }

    @Test("Legal actions include reserve when cards on table")
    func legalActionsIncludeReserve() {
        var state = createTestState()
        state.players[0].reservedCards = []  // Can reserve
        let card = Card.allCards().first { $0.level == 1 }!
        state.level1Cards = [card]
        let actions = GameEngine.legalActions(in: state)
        let hasReserveAction = actions.contains { action in
            if case .reserveCard(let c) = action { return c.id == card.id }
            return false
        }
        #expect(hasReserveAction == true)
    }

    // MARK: - Win Condition Tests

    @Test("Check win condition updates leader and score")
    func checkWinConditionUpdatesLeader() {
        var state = createTestState(targetScore: 10)
        state.players[0].ownedCards = (0..<10).map { i in
            Card(id: 100 + i, color: .red, point: 1, level: 1, cost: [:])
        }
        state.currentPlayerIndex = 0
        let newState = GameEngine.checkWinCondition(state)
        #expect(newState.highestScore >= 10)
        #expect(newState.leaderPlayerId == state.players[0].id)
    }

    @Test("Check win condition does not trigger below target")
    func checkWinConditionBelowTarget() {
        var state = createTestState(targetScore: 15)
        state.players[0].ownedCards = (0..<5).map { i in
            Card(id: 100 + i, color: .red, point: 1, level: 1, cost: [:])
        }
        let newState = GameEngine.checkWinCondition(state)
        #expect(newState.highestScore < 15)
    }

    // MARK: - Auto Claim Noble Tests

    @Test("Auto claim noble claims when eligible")
    func autoClaimNoble() {
        var state = createTestState()
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4, .blue: 4])
        state.availableNobles = [noble]
        state.players[0].ownedCards = (0..<4).map { index in
            Card(id: 100 + index, color: .red, point: 0, level: 1, cost: [:])
        }
        // Add more red cards to meet the blue requirement too
        state.players[0].ownedCards.append(contentsOf: (0..<4).map { index in
            Card(id: 200 + index, color: .blue, point: 0, level: 1, cost: [:])
        })

        let newState = GameEngine.autoClaimNobles(in: state)
        #expect(newState.players[0].pointCards.count == 1)
        #expect(newState.availableNobles.isEmpty)
    }

    @Test("Auto claim noble does nothing when not eligible")
    func autoClaimNobleNotEligible() {
        var state = createTestState()
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4, .blue: 4])
        state.availableNobles = [noble]
        state.players[0].ownedCards = []  // No cards

        let newState = GameEngine.autoClaimNobles(in: state)
        #expect(newState.players[0].pointCards.isEmpty)
        #expect(newState.availableNobles.count == 1)
    }

    // MARK: - Card Table Management Tests

    @Test("Is card on table returns true for table cards")
    func isCardOnTableTrue() {
        var state = createTestState()
        let card = state.level1Cards.first!
        #expect(GameEngine.isCardOnTable(card, in: state) == true)
    }

    @Test("Is card on table returns false for non-table cards")
    func isCardOnTableFalse() {
        let state = createTestState()
        let card = Card(id: 999, color: .red, point: 0, level: 1, cost: [:])
        #expect(GameEngine.isCardOnTable(card, in: state) == false)
    }

    // MARK: - GameState Properties Tests

    @Test("Cards on display returns max 4 per level")
    func cardsOnDisplayMax4PerLevel() {
        var state = createTestState()
        // Add extra cards to test capping
        let extraCards = (0..<10).map { i in
            Card(id: 100 + i, color: .red, point: 0, level: 1, cost: [:])
        }
        state.level1Cards.append(contentsOf: extraCards)
        #expect(state.cardsOnDisplay.filter { $0.level == 1 }.count == 4)
    }

    @Test("Table has gold detection")
    func tableHasGoldDetection() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.gold: 1])
        #expect(state.tableHasGold == true)
        state.tableCoins = CoinPurse(coins: [.gold: 0])
        #expect(state.tableHasGold == false)
    }

    @Test("Is game over detection")
    func isGameOverDetection() {
        var state = createTestState()
        #expect(state.isGameOver == false)
        state.phase = .gameEnded
        #expect(state.isGameOver == true)
    }

    @Test("Winner returns nil when game not over")
    func winnerNilWhenNotOver() {
        let state = createTestState()
        #expect(state.winner == nil)
    }

    @Test("Player count returns correct number")
    func playerCount() {
        let state = createTestState(playerCount: 3)
        #expect(state.playerCount == 3)
    }

    // MARK: - Round Completion Tests

    @Test("Advance turn ends game when win condition met at round boundary")
    func advanceTurnEndsGameAtRoundBoundary() {
        var state = createTestState(playerCount: 2)
        // Give player 0 enough points to win
        state.players[0].ownedCards = (0..<15).map { i in
            Card(id: 100 + i, color: .red, point: 1, level: 1, cost: [:])
        }
        state.highestScore = 15
        state.targetScore = 15
        // Simulate round complete: last player just played, advancing wraps to player 0
        state.currentPlayerIndex = 1
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.phase == .gameEnded)
    }

    // MARK: - Atomic Action Validation Tests

    @Test("applyTakeCoins rejects when player at coin limit")
    func applyTakeCoinsRejectsAtLimit() {
        var state = createTestState()
        state.players[0].purse = CoinPurse(coins: [.red: 10])
        let originalTable = state.tableCoins.total
        let action: GameAction = .takeCoins([.red: 1])
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.players[0].purse.total == 10)
        #expect(newState.tableCoins.total == originalTable)
    }

    @Test("applyPurchaseCard rejects when player cannot afford")
    func applyPurchaseCardRejectsUnaffordable() {
        var state = createTestState()
        let card = Card(id: 999, color: .blue, point: 1, level: 1, cost: [.red: 5])
        state.level1Cards = [card]
        state.players[0].purse = CoinPurse(coins: [.red: 1])
        let action: GameAction = .purchaseCard(card, [.red: 5])
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.level1Cards.contains { $0.id == card.id })
        #expect(newState.players[0].ownedCards.isEmpty)
    }

    @Test("applyReserveCard rejects when reserve limit reached")
    func applyReserveCardRejectsAtLimit() {
        var state = createTestState()
        let card = Card(id: 999, color: .blue, point: 0, level: 1, cost: [:])
        state.level1Cards = [card]
        state.players[0].reservedCards = (0..<3).map { Card(id: $0, color: .red, point: 0, level: 1, cost: [:]) }
        let action: GameAction = .reserveCard(card)
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.level1Cards.contains { $0.id == card.id })
        #expect(newState.players[0].reservedCards.count == 3)
    }

    @Test("applyRepayCard rejects for non-reserved card")
    func applyRepayCardRejectsNonReserved() {
        var state = createTestState()
        let card = Card(id: 999, color: .red, point: 0, level: 1, cost: [:])
        state.players[0].purse = CoinPurse(coins: [.red: 5])
        let originalTable = state.tableCoins.total
        let action: GameAction = .repayCard(card, [.red: 1])
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.players[0].ownedCards.isEmpty)
        #expect(newState.tableCoins.total == originalTable)
    }

    @Test("applyClaimNoble rejects when ineligible")
    func applyClaimNobleRejectsIneligible() {
        var state = createTestState()
        let noble = PointCard(id: 99, point: 3, cost: [.red: 4, .blue: 4])
        state.availableNobles = [noble]
        let action: GameAction = .claimNoble(noble)
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.players[0].pointCards.isEmpty)
        #expect(newState.availableNobles.count == 1)
    }

    @Test("apply pass returns identical state")
    func applyPassUnchanged() {
        let state = createTestState()
        let newState = GameEngine.apply(.pass, to: state)
        #expect(newState == state)
    }

    // MARK: - Legal Actions Edge Cases

    @Test("legalActions excludes takeCoins when player at limit")
    func legalActionsNoCoinsAtLimit() {
        var state = createTestState()
        state.players[0].purse = CoinPurse(coins: [.red: 10])
        let actions = GameEngine.legalActions(in: state)
        let hasTake = actions.contains { if case .takeCoins = $0 { return true } else { return false } }
        #expect(hasTake == false)
    }

    @Test("legalActions includes purchase when affordable")
    func legalActionsIncludesPurchase() {
        var state = createTestState()
        let card = Card(id: 999, color: .red, point: 1, level: 1, cost: [.red: 2])
        state.level1Cards = [card]
        state.players[0].purse = CoinPurse(coins: [.red: 5])
        let actions = GameEngine.legalActions(in: state)
        let hasPurchase = actions.contains { if case .purchaseCard(let c, _) = $0 { return c.id == card.id } else { return false } }
        #expect(hasPurchase == true)
    }

    @Test("legalActions includes repay for reserved card")
    func legalActionsIncludesRepay() {
        var state = createTestState()
        let card = Card(id: 999, color: .red, point: 1, level: 1, cost: [.blue: 2])
        state.players[0].reservedCards = [card]
        state.players[0].purse = CoinPurse(coins: [.blue: 5])
        let actions = GameEngine.legalActions(in: state)
        let hasRepay = actions.contains { if case .repayCard(let c, _) = $0 { return c.id == card.id } else { return false } }
        #expect(hasRepay == true)
    }

    @Test("legalActions excludes claimNoble (auto-claimed via processAction)")
    func legalActionsExcludesClaimNoble() {
        let human = PlayerState(name: "Test", isHuman: true, avatar: .ash)
        var player = human
        player.ownedCards = (0..<4).map { Card(id: 9000 + $0, color: .red, point: 0, level: 1, cost: [:]) }
        let noble = PointCard(id: 99, point: 3, cost: [.red: 4])
        let state = GameState(
            players: [player],
            tableCoins: CoinPurse(filledWith: 4),
            level1Cards: [],
            level2Cards: [],
            level3Cards: [],
            availableNobles: [noble],
            targetScore: 15
        )
        let actions = GameEngine.legalActions(in: state)
        let hasNoble = actions.contains { if case .claimNoble = $0 { return true } else { return false } }
        #expect(hasNoble == false)
    }

    @Test("legalActions falls back to pass when empty")
    func legalActionsFallbackToPass() {
        var state = createTestState()
        state.level1Cards = []
        state.level2Cards = []
        state.level3Cards = []
        state.availableNobles = []
        state.players[0].purse = CoinPurse(coins: [.red: 10])
        state.players[0].reservedCards = []
        let actions = GameEngine.legalActions(in: state)
        #expect(actions == [.pass])
    }

    // MARK: - Turn Management

    @Test("advanceTurn to human sets playerTurn phase")
    func advanceTurnToHuman() {
        var state = createTestState(playerCount: 3)
        state.currentPlayerIndex = 2 // Last player (robot in 3-player)
        state.phase = .playerTurn
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.currentPlayerIndex == 0)
        #expect(newState.phase == .playerTurn)
    }

    @Test("advanceTurn to robot sets aiThinking phase")
    func advanceTurnToRobot() {
        var state = createTestState(playerCount: 3)
        state.currentPlayerIndex = 0 // Human
        state.phase = .playerTurn
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.currentPlayerIndex == 1)
        #expect(newState.phase == .aiThinking)
    }

    // MARK: - Win Condition

    @Test("checkWinCondition updates leader to highest scoring player")
    func checkWinNonLeader() {
        var state = createTestState(playerCount: 3)
        state.players[0].ownedCards = (0..<15).map { Card(id: 100 + $0, color: .red, point: 1, level: 1, cost: [:]) }
        state.players[1].ownedCards = (0..<20).map { Card(id: 200 + $0, color: .blue, point: 1, level: 1, cost: [:]) }
        state.currentPlayerIndex = 0
        let newState = GameEngine.checkWinCondition(state)
        #expect(newState.leaderPlayerId == state.players[1].id)
    }

    @Test("checkWinCondition tracks score correctly")
    func checkWinLeaderCurrent() {
        var state = createTestState(playerCount: 2)
        state.players[0].ownedCards = (0..<15).map { Card(id: 100 + $0, color: .red, point: 1, level: 1, cost: [:]) }
        state.currentPlayerIndex = 0
        let newState = GameEngine.checkWinCondition(state)
        #expect(newState.highestScore >= 15)
        #expect(newState.leaderPlayerId == state.players[0].id)
    }

    @Test("Advance turn does not end game when win condition not met at round boundary")
    func advanceTurnDoesNotEndGameWhenWinNotMet() {
        var state = createTestState(playerCount: 2)
        state.players[0].ownedCards = (0..<5).map { Card(id: 100 + $0, color: .red, point: 1, level: 1, cost: [:]) }
        state.highestScore = 5
        state.targetScore = 15
        state.currentPlayerIndex = 1
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.phase != .gameEnded)
    }

    @Test("Advance turn continues when win condition met mid-round")
    func advanceTurnContinuesWhenWinMetMidRound() {
        var state = createTestState(playerCount: 3)
        state.players[0].ownedCards = (0..<15).map { Card(id: 100 + $0, color: .red, point: 1, level: 1, cost: [:]) }
        state.highestScore = 15
        state.targetScore = 15
        // Player 0 just played, advancing to player 1 (mid-round, not boundary)
        state.currentPlayerIndex = 0
        let newState = GameEngine.advanceTurn(state)
        #expect(newState.currentPlayerIndex == 1)
        #expect(newState.phase != .gameEnded)
    }

    @Test("Apply reserve card does not give gold when player at coin limit")
    func applyReserveCardNoGoldAtCoinLimit() {
        var state = createTestState()
        let card = Card(id: 999, color: .blue, point: 0, level: 1, cost: [:])
        state.level1Cards = [card]
        state.tableCoins = CoinPurse(coins: [.gold: 5])
        state.players[0].purse = CoinPurse(coins: [.red: 10])
        let action: GameAction = .reserveCard(card)
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.players[0].purse.goldCount == 0)
        #expect(newState.tableCoins.goldCount == 5)
    }

    @Test("Apply reserve card gives gold when player has room")
    func applyReserveCardGivesGoldWhenRoom() {
        var state = createTestState()
        let card = Card(id: 999, color: .blue, point: 0, level: 1, cost: [:])
        state.level1Cards = [card]
        state.tableCoins = CoinPurse(coins: [.gold: 5])
        state.players[0].purse = CoinPurse(coins: [.red: 9])
        let action: GameAction = .reserveCard(card)
        let newState = GameEngine.apply(action, to: state)
        #expect(newState.players[0].purse.goldCount == 1)
        #expect(newState.tableCoins.goldCount == 4)
    }

    // MARK: - Full Turn Cycle Tests

    @Test("Full turn cycle: human takes coins → AI phase → AI takes coins → back to human")
    func fullTurnCycleWithTakeCoins() {
        var state = createTestState(playerCount: 2)
        let initialCoinsOnTable = state.tableCoins.total

        // ── Turn 0: Human's turn ──
        #expect(state.currentPlayer.isHuman)
        #expect(state.phase == .playerTurn)
        #expect(state.turnNumber == 0)

        // Human takes 3 different coins
        let available = GemColor.gemColors.filter { state.tableCoins[$0] >= 1 }
        let coins: [GemColor: Int] = [available[0]: 1, available[1]: 1, available[2]: 1]

        state = GameEngine.apply(.takeCoins(coins), to: state)
        state = GameEngine.autoClaimNobles(in: state)
        state = GameEngine.checkWinCondition(state)
        state = GameEngine.advanceTurn(state)

        // ── Turn 1: AI's turn ──
        #expect(!state.currentPlayer.isHuman)
        #expect(state.phase == .aiThinking)
        #expect(state.turnNumber == 1)
        #expect(state.players[0].purse.total == 3) // Human now has 3 coins
        #expect(state.tableCoins.total == initialCoinsOnTable - 3) // Table lost 3 coins

        // AI takes 3 different coins
        let aiAvailable = GemColor.gemColors.filter { state.tableCoins[$0] >= 1 }
        let aiCoins: [GemColor: Int] = [aiAvailable[0]: 1, aiAvailable[1]: 1, aiAvailable[2]: 1]

        state = GameEngine.apply(.takeCoins(aiCoins), to: state)
        state = GameEngine.autoClaimNobles(in: state)
        state = GameEngine.checkWinCondition(state)
        state = GameEngine.advanceTurn(state)

        // ── Turn 2: Back to human ──
        #expect(state.currentPlayer.isHuman)
        #expect(state.phase == .playerTurn)
        #expect(state.turnNumber == 2)
        #expect(state.players[1].purse.total == 3) // AI now has 3 coins
        #expect(state.tableCoins.total == initialCoinsOnTable - 6) // Table lost 6 coins total
    }

    // MARK: - isValidCoinTake Edge Cases

    @Test("isValidCoinTake rejects empty coins")
    func isValidCoinTakeRejectsEmpty() {
        let state = createTestState()
        #expect(GameEngine.isValidCoinTake([:], in: state) == false)
    }

    @Test("isValidCoinTake rejects taking more than 3 coins")
    func isValidCoinTakeRejectsMoreThan3() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 5, .blue: 5, .green: 5, .white: 5])
        #expect(GameEngine.isValidCoinTake([.red: 1, .blue: 1, .green: 1, .white: 1], in: state) == false)
    }

    @Test("isValidCoinTake rejects 2 of same color when table has only 3")
    func isValidCoinTakeRejects2WhenTableHas3() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 3, .blue: 5])
        #expect(GameEngine.isValidCoinTake([.red: 2], in: state) == false)
    }

    @Test("isValidCoinTake accepts 2 of same color when table has 4")
    func isValidCoinTakeAccepts2WhenTableHas4() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 4, .blue: 5])
        #expect(GameEngine.isValidCoinTake([.red: 2], in: state) == true)
    }

    @Test("isValidCoinTake rejects 2 different colors (not valid pattern)")
    func isValidCoinTakeRejects2Different() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 5, .blue: 5])
        #expect(GameEngine.isValidCoinTake([.red: 1, .blue: 1], in: state) == false)
    }

    @Test("isValidCoinTake rejects when table lacks coins")
    func isValidCoinTakeRejectsInsufficientTable() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 0, .blue: 5, .green: 5])
        #expect(GameEngine.isValidCoinTake([.red: 1, .blue: 1, .green: 1], in: state) == false)
    }

    @Test("isValidCoinTake accepts single coin")
    func isValidCoinTakeAcceptsSingle() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 1])
        #expect(GameEngine.isValidCoinTake([.red: 1], in: state) == true)
    }

    @Test("isValidCoinTake rejects 3 coins with 2 same color")
    func isValidCoinTakeRejects3WithDuplicate() {
        var state = createTestState()
        state.tableCoins = CoinPurse(coins: [.red: 5, .blue: 5])
        #expect(GameEngine.isValidCoinTake([.red: 2, .blue: 1], in: state) == false)
    }

    // MARK: - processAction Integration Tests

    @Test("processAction auto-claims noble after purchase")
    func processActionAutoClaimsNoble() {
        var state = createTestState()
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4])
        state.availableNobles = [noble]

        // Give player 3 red cards
        state.players[0].ownedCards = (0..<3).map {
            Card(id: 100 + $0, color: .red, point: 0, level: 1, cost: [:])
        }

        // Buy a 4th red card
        let card = Card(id: 999, color: .red, point: 1, level: 1, cost: [.blue: 1])
        state.level1Cards = [card]
        state.players[0].purse = CoinPurse(coins: [.blue: 5])
        state.tableCoins = CoinPurse()

        let newState = GameEngine.processAction(.purchaseCard(card, [.blue: 1]), in: state)

        // Noble should be auto-claimed
        #expect(newState.players[0].pointCards.count == 1)
        #expect(newState.availableNobles.isEmpty)
    }

    @Test("processAction checks win condition after noble claim")
    func processActionChecksWinAfterNoble() {
        var state = createTestState(targetScore: 15)
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4])
        state.availableNobles = [noble]

        // Give player enough cards for noble + enough points to win
        state.players[0].ownedCards = (0..<4).map {
            Card(id: 100 + $0, color: .red, point: 3, level: 1, cost: [:])
        }

        // Buy a card that triggers noble
        let card = Card(id: 999, color: .red, point: 1, level: 1, cost: [.blue: 1])
        state.level1Cards = [card]
        state.players[0].purse = CoinPurse(coins: [.blue: 5])
        state.tableCoins = CoinPurse()

        let newState = GameEngine.processAction(.purchaseCard(card, [.blue: 1]), in: state)

        // Should have noble + high score
        #expect(newState.players[0].pointCards.count == 1)
        #expect(newState.highestScore >= 15)
        #expect(newState.leaderPlayerId == state.players[0].id)
    }

    // MARK: - Tiebreaker Tests

    @Test("checkWinCondition favors more nobles on points tie")
    func checkWinConditionFavorsNobles() {
        var state = createTestState(playerCount: 2, targetScore: 10)

        // Player 0: 10 points from cards, 0 nobles
        state.players[0].ownedCards = (0..<10).map {
            Card(id: 100 + $0, color: .red, point: 1, level: 1, cost: [:])
        }

        // Player 1: 10 points from cards, 1 noble (more total)
        state.players[1].ownedCards = (0..<7).map {
            Card(id: 200 + $0, color: .blue, point: 1, level: 1, cost: [:])
        }
        state.players[1].pointCards = [PointCard(id: 99, point: 3, cost: [:])]

        let newState = GameEngine.checkWinCondition(state)
        #expect(newState.leaderPlayerId == state.players[1].id)
    }

    @Test("checkWinCondition favors fewer cards on points+nobles tie")
    func checkWinConditionFavorsFewerCards() {
        var state = createTestState(playerCount: 2, targetScore: 10)

        // Player 0: 10 points, 0 nobles, 10 cards (1 pt each)
        state.players[0].ownedCards = (0..<10).map {
            Card(id: 100 + $0, color: .red, point: 1, level: 1, cost: [:])
        }

        // Player 1: 10 points, 0 nobles, 5 cards (2 pts each = fewer cards wins tie)
        state.players[1].ownedCards = (0..<5).map {
            Card(id: 200 + $0, color: .blue, point: 2, level: 2, cost: [:])
        }

        let newState = GameEngine.checkWinCondition(state)
        #expect(newState.leaderPlayerId == state.players[1].id)
    }

    // MARK: - manualActions Filter Tests

    @Test("manualActions excludes claimNoble and pass")
    func manualActionsExcludesAutomatic() {
        var state = createTestState()
        let noble = PointCard(id: 99, point: 3, cost: [.red: 4])
        state.availableNobles = [noble]
        state.players[0].ownedCards = (0..<4).map {
            Card(id: 100 + $0, color: .red, point: 0, level: 1, cost: [:])
        }

        let actions = GameEngine.legalActions(in: state)
        let manual = actions.manualActions

        // Should not contain claimNoble
        let hasNoble = manual.contains { if case .claimNoble = $0 { return true } else { return false } }
        #expect(hasNoble == false)

        // Should not contain pass
        #expect(manual.contains(.pass) == false)
    }

    // MARK: - applyClaimNoble Tests

    @Test("applyClaimNoble adds noble to player and removes from available")
    func applyClaimNobleCorrect() {
        var state = createTestState()
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4])
        state.availableNobles = [noble]
        state.players[0].ownedCards = (0..<4).map {
            Card(id: 100 + $0, color: .red, point: 0, level: 1, cost: [:])
        }

        let newState = GameEngine.applyClaimNoble(noble, in: state)

        #expect(newState.players[0].pointCards.count == 1)
        #expect(newState.players[0].pointCards[0].id == noble.id)
        #expect(newState.availableNobles.isEmpty)
        // Noble points should be reflected
        #expect(newState.players[0].totalPoints == 3)
    }

    @Test("applyClaimNoble is idempotent for same noble (no double claim)")
    func applyClaimNobleNoDoubleClaim() {
        var state = createTestState()
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4])
        state.availableNobles = [noble]
        state.players[0].ownedCards = (0..<4).map {
            Card(id: 100 + $0, color: .red, point: 0, level: 1, cost: [:])
        }

        // First claim succeeds
        let state1 = GameEngine.applyClaimNoble(noble, in: state)
        #expect(state1.players[0].pointCards.count == 1)

        // Second claim with same noble is a no-op (noble not in availableNobles)
        let state2 = GameEngine.applyClaimNoble(noble, in: state1)
        #expect(state2.players[0].pointCards.count == 1)
        #expect(state2 == state1)
    }
}
