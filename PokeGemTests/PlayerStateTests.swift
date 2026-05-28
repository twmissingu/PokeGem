//
//  PlayerStateTests.swift
//  PokeGemTests
//
//  Unit tests for PlayerState model
//

import Testing
@testable import PokeGem
import Foundation

struct PlayerStateTests {

    // MARK: - Initialization Tests

    @Test("Player initializes with default values")
    func playerInitializesWithDefaults() {
        let player = PlayerState(name: "TestPlayer", isHuman: true)
        #expect(player.name == "TestPlayer")
        #expect(player.isHuman == true)
        #expect(player.purse.total == 0)
        #expect(player.ownedCards.isEmpty)
        #expect(player.reservedCards.isEmpty)
        #expect(player.pointCards.isEmpty)
        #expect(player.totalPoints == 0)
    }

    @Test("Player ID is unique")
    func playerIDIsUnique() {
        let player1 = PlayerState(name: "P1", isHuman: true)
        let player2 = PlayerState(name: "P2", isHuman: false)
        #expect(player1.id != player2.id)
    }

    // MARK: - Card Counts Tests

    @Test("Card counts returns color discounts from owned cards")
    func cardCountsReturnsDiscounts() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.ownedCards = [
            Card(id: 1, color: .red, point: 0, level: 1, cost: [:]),
            Card(id: 2, color: .red, point: 0, level: 1, cost: [:]),
            Card(id: 3, color: .blue, point: 0, level: 1, cost: [:]),
        ]
        let counts = player.cardCounts
        #expect(counts[.red] == 2)
        #expect(counts[.blue] == 1)
        #expect(counts[.green] == nil)
    }

    // MARK: - Points Tests

    @Test("Total points includes card points")
    func totalPointsIncludesCards() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.ownedCards = [
            Card(id: 1, color: .red, point: 1, level: 1, cost: [:]),
            Card(id: 2, color: .blue, point: 2, level: 2, cost: [:]),
        ]
        #expect(player.totalPoints == 3)
    }

    @Test("Total points includes noble points")
    func totalPointsIncludesNobles() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.pointCards = [
            PointCard(id: 1, point: 3, cost: [:]),
            PointCard(id: 2, point: 3, cost: [:]),
        ]
        #expect(player.totalPoints == 6)
    }

    @Test("Total points does not deduct for reserved cards")
    func totalPointsDoesNotDeductReserved() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.reservedCards = [
            Card(id: 1, color: .red, point: 0, level: 1, cost: [:]),
            Card(id: 2, color: .blue, point: 0, level: 2, cost: [:]),
        ]
        #expect(player.totalPoints == 0)  // Reserved cards don't deduct points
    }

    @Test("Total points calculates mixed sources")
    func totalPointsMixed() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.ownedCards = [Card(id: 1, color: .red, point: 2, level: 1, cost: [:])]
        player.pointCards = [PointCard(id: 1, point: 3, cost: [:])]
        player.reservedCards = [Card(id: 2, color: .blue, point: 0, level: 1, cost: [:])]
        #expect(player.totalPoints == 2 + 3)  // 5 (no reserved penalty)
    }

    // MARK: - Reserve Limit Tests

    @Test("Can reserve more when under limit")
    func canReserveMoreUnderLimit() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.reservedCards = [Card(id: 1, color: .red, point: 0, level: 1, cost: [:])]
        #expect(player.canReserveMore == true)
    }

    @Test("Cannot reserve more at limit")
    func cannotReserveMoreAtLimit() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.reservedCards = (0..<3).map { i in
            Card(id: i, color: .red, point: 0, level: 1, cost: [:])
        }
        #expect(player.canReserveMore == false)
    }

    // MARK: - Coin Limit Tests

    @Test("Has coins at limit when 10 or more")
    func hasCoinsAtLimit() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 10])
        #expect(player.hasCoinsAtLimit == true)
    }

    @Test("No coins at limit when under 10")
    func noCoinsAtLimit() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 9])
        #expect(player.hasCoinsAtLimit == false)
    }

    // MARK: - Purchase Tests

    @Test("Can purchase with sufficient coins")
    func canPurchaseSufficient() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 5])
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [.red: 3])
        #expect(player.canPurchase(card) == true)
    }

    @Test("Cannot purchase with insufficient coins")
    func cannotPurchaseInsufficient() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 1])
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [.red: 3])
        #expect(player.canPurchase(card) == false)
    }

    @Test("Can purchase with card discounts")
    func canPurchaseWithDiscounts() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 1])
        player.ownedCards = [
            Card(id: 10, color: .red, point: 0, level: 1, cost: [:]),
            Card(id: 11, color: .red, point: 0, level: 1, cost: [:]),
        ]
        let card = Card(id: 1, color: .blue, point: 0, level: 1, cost: [.red: 3])
        #expect(player.canPurchase(card) == true)  // Need 1, have 1 (3 required - 2 discount)
    }

    @Test("Purchasing adds card and removes coins")
    func purchasingUpdatesState() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 5, .blue: 3])
        let card = Card(id: 1, color: .red, point: 1, level: 1, cost: [.red: 2, .blue: 1])
        let payment: [GemColor: Int] = [.red: 2, .blue: 1]

        let newPlayer = player.purchasing(card, with: payment)
        #expect(newPlayer != nil)
        #expect(newPlayer?.ownedCards.count == 1)
        #expect(newPlayer?.ownedCards[0].id == card.id)
        #expect(newPlayer?.purse[.red] == 3)
        #expect(newPlayer?.purse[.blue] == 2)
    }

    @Test("Purchasing returns nil when cannot afford")
    func purchasingReturnsNil() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 1])
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [.red: 3])
        let payment: [GemColor: Int] = [.red: 3]
        #expect(player.purchasing(card, with: payment) == nil)
    }

    // MARK: - Reserve Tests

    @Test("Reserving adds card to reserved")
    func reservingAddsCard() {
        var player = PlayerState(name: "Test", isHuman: true)
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        let newPlayer = player.reserving(card, tableHasGold: true)
        #expect(newPlayer != nil)
        #expect(newPlayer?.reservedCards.count == 1)
        #expect(newPlayer?.reservedCards[0].id == card.id)
        #expect(newPlayer?.purse.goldCount == 1)  // Got gold
    }

    @Test("Reserving without gold does not add gold")
    func reservingWithoutGold() {
        var player = PlayerState(name: "Test", isHuman: true)
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        let newPlayer = player.reserving(card, tableHasGold: false)
        #expect(newPlayer?.purse.goldCount == 0)
    }

    @Test("Reserving at limit returns nil")
    func reservingAtLimit() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.reservedCards = (0..<3).map { i in
            Card(id: i, color: .red, point: 0, level: 1, cost: [:])
        }
        let card = Card(id: 99, color: .blue, point: 0, level: 1, cost: [:])
        #expect(player.reserving(card, tableHasGold: true) == nil)
    }

    @Test("Reserving at coin limit does not add gold")
    func reservingAtCoinLimitNoGold() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 10])
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        let newPlayer = player.reserving(card, tableHasGold: true)
        #expect(newPlayer?.purse.goldCount == 0)  // At limit, no gold
    }

    // MARK: - Repay Tests

    @Test("Repaying moves from reserved to owned")
    func repayingMovesCard() {
        var player = PlayerState(name: "Test", isHuman: true)
        let card = Card(id: 1, color: .red, point: 1, level: 1, cost: [.blue: 2])
        player.reservedCards = [card]
        player.purse = CoinPurse(coins: [.blue: 5])
        let payment: [GemColor: Int] = [.blue: 2]

        let newPlayer = player.repaying(card, with: payment)
        #expect(newPlayer != nil)
        #expect(newPlayer?.ownedCards.count == 1)
        #expect(newPlayer?.ownedCards[0].id == card.id)
        #expect(newPlayer?.reservedCards.isEmpty == true)
        #expect(newPlayer?.purse[.blue] == 3)
    }

    @Test("Repaying non-reserved card returns nil")
    func repayingNonReservedReturnsNil() {
        var player = PlayerState(name: "Test", isHuman: true)
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        player.purse = CoinPurse(coins: [.red: 5])
        #expect(player.repaying(card, with: [:]) == nil)
    }

    @Test("Repaying without sufficient coins returns nil")
    func repayingInsufficientCoins() {
        var player = PlayerState(name: "Test", isHuman: true)
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [.blue: 5])
        player.reservedCards = [card]
        player.purse = CoinPurse(coins: [.blue: 2])
        let payment: [GemColor: Int] = [.blue: 5]
        #expect(player.repaying(card, with: payment) == nil)
    }

    // MARK: - Claim Noble Tests

    @Test("Claiming noble adds to pointCards")
    func claimingNoble() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.ownedCards = (0..<4).map { index in
            Card(id: 100 + index, color: .red, point: 0, level: 1, cost: [:])
        }
        player.ownedCards.append(contentsOf: (0..<4).map { index in
            Card(id: 200 + index, color: .blue, point: 0, level: 1, cost: [:])
        })
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4, .blue: 4])

        let newPlayer = player.claiming(noble)
        #expect(newPlayer != nil)
        #expect(newPlayer?.pointCards.count == 1)
        #expect(newPlayer?.pointCards[0].id == noble.id)
    }

    @Test("Claiming noble without requirements returns nil")
    func claimingNobleWithoutRequirements() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.ownedCards = []
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4, .blue: 4])
        #expect(player.claiming(noble) == nil)
    }

    // MARK: - Take Coins Tests

    @Test("Taking coins adds to purse")
    func takingCoins() {
        var player = PlayerState(name: "Test", isHuman: true)
        let newPlayer = player.takingCoins([.red: 3, .blue: 2])
        #expect(newPlayer != nil)
        #expect(newPlayer?.purse[.red] == 3)
        #expect(newPlayer?.purse[.blue] == 2)
        #expect(newPlayer?.purse.total == 5)
    }

    @Test("Taking coins at limit returns nil")
    func takingCoinsAtLimit() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 9])
        #expect(player.takingCoins([.blue: 2]) == nil)  // Would be 11
    }

    @Test("Taking coins exactly at limit succeeds")
    func takingCoinsExactlyAtLimit() {
        var player = PlayerState(name: "Test", isHuman: true)
        player.purse = CoinPurse(coins: [.red: 7])
        let newPlayer = player.takingCoins([.blue: 3])
        #expect(newPlayer != nil)
        #expect(newPlayer?.purse.total == 10)
    }

    // MARK: - Hashable Tests

    @Test("Equal players hash equally")
    func equalPlayersHashEqually() {
        let id = UUID()
        var player1 = PlayerState(id: id, name: "Test", isHuman: true)
        var player2 = PlayerState(id: id, name: "Test", isHuman: true)
        player1.purse = CoinPurse(coins: [.red: 3])
        player2.purse = CoinPurse(coins: [.red: 3])
        #expect(player1 == player2)
        #expect(player1.hashValue == player2.hashValue)
    }

    @Test("Different players are not equal")
    func differentPlayersNotEqual() {
        let player1 = PlayerState(name: "P1", isHuman: true)
        let player2 = PlayerState(name: "P2", isHuman: false)
        #expect(player1 != player2)
    }

    @Test("Player has avatar assigned")
func playerHasAvatar() {
    let player = PlayerState(name: "TestPlayer", isHuman: true)
    // Human player should get ash avatar by default
    #expect(player.avatar == .ash)
}

@Test("Robot player gets avatar based on difficulty")
func robotPlayerGetsAvatar() {
    let player = PlayerState(name: "Bot", isHuman: false)
    // Robot player should get a robot avatar
    #expect(player.avatar != .ash)
}

// MARK: - Description Tests

    @Test("Description is non-empty")
    func descriptionNotEmpty() {
        let player = PlayerState(name: "TestPlayer", isHuman: true)
        #expect(!player.description.isEmpty)
        #expect(player.description.contains("TestPlayer"))
    }
}
