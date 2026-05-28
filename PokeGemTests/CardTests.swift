//
//  CardTests.swift
//  PokeGemTests
//
//  Unit tests for Card model
//

import Testing
@testable import PokeGem

struct CardTests {

    // MARK: - Properties

    @Test("Card imageName formats correctly")
    func imageNameFormat() {
        let card = Card(id: 42, color: .red, point: 2, level: 2, cost: [:])
        #expect(card.imageName == "c42")
    }

    @Test("Total cost sums all color requirements")
    func totalCost() {
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [.red: 2, .blue: 3, .green: 1])
        #expect(card.totalCost == 6)
    }

    @Test("Total cost is zero for free card")
    func totalCostZero() {
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        #expect(card.totalCost == 0)
    }

    // MARK: - Database

    @Test("allCards returns 90 cards")
    func allCardsCount() {
        let cards = Card.allCards()
        #expect(cards.count == 90)
    }

    @Test("cardsByLevel returns correct counts")
    func cardsByLevelCounts() {
        #expect(Card.cardsByLevel(1).count == 40)
        #expect(Card.cardsByLevel(2).count == 30)
        #expect(Card.cardsByLevel(3).count == 20)
    }

    @Test("All cards have valid IDs")
    func allCardsHaveValidIDs() {
        let cards = Card.allCards()
        let ids = cards.map { $0.id }
        #expect(Set(ids).count == 90)  // All unique
        #expect(ids.min() == 1)
        #expect(ids.max() == 90)
    }

    @Test("All cards have valid levels")
    func allCardsHaveValidLevels() {
        let cards = Card.allCards()
        for card in cards {
            #expect(card.level >= 1 && card.level <= 3)
        }
    }

    @Test("All cards have valid points")
    func allCardsHaveValidPoints() {
        let cards = Card.allCards()
        for card in cards {
            #expect(card.point >= 0 && card.point <= 5)
        }
    }

    // MARK: - Codable/Hashable

    @Test("Equal cards hash equally")
    func equalCardsHashEqually() {
        let card1 = Card(id: 5, color: .blue, point: 1, level: 1, cost: [.red: 2])
        let card2 = Card(id: 5, color: .blue, point: 1, level: 1, cost: [.red: 2])
        #expect(card1 == card2)
        #expect(card1.hashValue == card2.hashValue)
    }

    @Test("Different cards are not equal")
    func differentCardsNotEqual() {
        let card1 = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        let card2 = Card(id: 2, color: .blue, point: 0, level: 1, cost: [:])
        #expect(card1 != card2)
    }
}
