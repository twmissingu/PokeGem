//
//  PointCardTests.swift
//  PokeGemTests
//
//  Unit tests for PointCard (noble) model
//

import Testing
@testable import PokeGem

struct PointCardTests {

    // MARK: - Properties

    @Test("PointCard imageName formats correctly")
    func imageNameFormat() {
        let noble = PointCard(id: 7, point: 3, cost: [:])
        #expect(noble.imageName == "pc7")
    }

    // MARK: - canAttract

    @Test("canAttract returns true when discounts meet requirements")
    func canAttractSufficient() {
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4, .blue: 4])
        let discounts: [GemColor: Int] = [.red: 4, .blue: 4, .green: 2]
        #expect(noble.canAttract(with: discounts) == true)
    }

    @Test("canAttract returns false when one color is short")
    func canAttractInsufficient() {
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4, .blue: 4])
        let discounts: [GemColor: Int] = [.red: 3, .blue: 4]
        #expect(noble.canAttract(with: discounts) == false)
    }

    @Test("canAttract returns true for empty cost")
    func canAttractEmptyCost() {
        let noble = PointCard(id: 1, point: 3, cost: [:])
        #expect(noble.canAttract(with: [:]) == true)
    }

    @Test("canAttract ignores extra colors")
    func canAttractIgnoresExtra() {
        let noble = PointCard(id: 1, point: 3, cost: [.red: 4])
        let discounts: [GemColor: Int] = [.red: 4, .blue: 10, .green: 10]
        #expect(noble.canAttract(with: discounts) == true)
    }

    // MARK: - Database

    @Test("allPointCards returns 10 nobles")
    func allPointCardsCount() {
        let nobles = PointCard.allPointCards()
        #expect(nobles.count == 10)
    }

    @Test("All nobles have 3 points")
    func allNoblesHaveThreePoints() {
        let nobles = PointCard.allPointCards()
        for noble in nobles {
            #expect(noble.point == 3)
        }
    }

    // MARK: - Codable/Hashable

    @Test("Equal nobles hash equally")
    func equalNoblesHashEqually() {
        let noble1 = PointCard(id: 3, point: 3, cost: [.green: 4, .red: 4])
        let noble2 = PointCard(id: 3, point: 3, cost: [.green: 4, .red: 4])
        #expect(noble1 == noble2)
    }

    @Test("Different nobles are not equal")
    func differentNoblesNotEqual() {
        let noble1 = PointCard(id: 1, point: 3, cost: [.red: 4])
        let noble2 = PointCard(id: 2, point: 3, cost: [.blue: 4])
        #expect(noble1 != noble2)
    }
}
