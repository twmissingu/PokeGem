//
//  GameActionTests.swift
//  PokeGemTests
//
//  Unit tests for GameAction enum
//

import Testing
@testable import PokeGem

struct GameActionTests {

    // MARK: - Description

    @Test("takeCoins description contains colors")
    func takeCoinsDescription() {
        let action = GameAction.takeCoins([.red: 2, .blue: 1])
        #expect(action.description.contains("Take coins"))
        #expect(action.description.contains("red"))
        #expect(action.description.contains("blue"))
    }

    @Test("purchaseCard description contains card info")
    func purchaseCardDescription() {
        let card = Card(id: 5, color: .green, point: 2, level: 2, cost: [:])
        let action = GameAction.purchaseCard(card, [.red: 2])
        #expect(action.description.contains("Purchase card"))
        #expect(action.description.contains("5"))
        #expect(action.description.contains("green"))
    }

    @Test("reserveCard description contains card ID")
    func reserveCardDescription() {
        let card = Card(id: 10, color: .blue, point: 0, level: 1, cost: [:])
        let action = GameAction.reserveCard(card)
        #expect(action.description.contains("Reserve card"))
        #expect(action.description.contains("10"))
    }

    @Test("repayCard description contains card ID")
    func repayCardDescription() {
        let card = Card(id: 20, color: .red, point: 1, level: 1, cost: [:])
        let action = GameAction.repayCard(card, [.blue: 2])
        #expect(action.description.contains("Repay"))
        #expect(action.description.contains("20"))
    }

    @Test("claimNoble description contains points")
    func claimNobleDescription() {
        let noble = PointCard(id: 3, point: 3, cost: [:])
        let action = GameAction.claimNoble(noble)
        #expect(action.description.contains("Claim noble"))
        #expect(action.description.contains("3"))
    }

    @Test("pass description is correct")
    func passDescription() {
        let action = GameAction.pass
        #expect(action.description == "Pass")
    }

    // MARK: - isAutomatic

    @Test("claimNoble is automatic")
    func claimNobleIsAutomatic() {
        let noble = PointCard(id: 1, point: 3, cost: [:])
        let action = GameAction.claimNoble(noble)
        #expect(action.isAutomatic == true)
    }

    @Test("pass is not automatic")
    func passIsAutomatic() {
        #expect(GameAction.pass.isAutomatic == false)
    }

    @Test("takeCoins is not automatic")
    func takeCoinsIsNotAutomatic() {
        let action = GameAction.takeCoins([.red: 1])
        #expect(action.isAutomatic == false)
    }

    @Test("purchaseCard is not automatic")
    func purchaseCardIsNotAutomatic() {
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        let action = GameAction.purchaseCard(card, [:])
        #expect(action.isAutomatic == false)
    }

    @Test("reserveCard is not automatic")
    func reserveCardIsNotAutomatic() {
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        let action = GameAction.reserveCard(card)
        #expect(action.isAutomatic == false)
    }

    @Test("repayCard is not automatic")
    func repayCardIsNotAutomatic() {
        let card = Card(id: 1, color: .red, point: 0, level: 1, cost: [:])
        let action = GameAction.repayCard(card, [:])
        #expect(action.isAutomatic == false)
    }

    // MARK: - Hashable

    @Test("Equal actions hash equally")
    func equalActionsHashEqually() {
        let action1 = GameAction.takeCoins([.red: 2])
        let action2 = GameAction.takeCoins([.red: 2])
        #expect(action1 == action2)
    }
}
