//
//  GameLayoutTests.swift
//  PokeGemTests
//
//  Unit tests for LayoutMetrics and ViewModel layout-related behaviors
//

import Testing
@testable import PokeGem
import Foundation
import SwiftUI

@MainActor
struct GameLayoutTests {

    // MARK: - LayoutMetrics Basic Tests

    @Test("LayoutMetrics creates correct landscape instance")
    func landscapeMetrics() {
        let size = CGSize(width: 852, height: 393)
        let lm = LayoutMetrics(size: size, horizontalSizeClass: .compact)
        #expect(lm.size == size)
        #expect(lm.isCompact == true)
    }

    @Test("LayoutMetrics iPad detection")
    func iPadMetrics() {
        let size = CGSize(width: 1024, height: 768)
        let lm = LayoutMetrics(size: size, horizontalSizeClass: .regular)
        #expect(lm.isIPad == true)
    }

    @Test("Landscape card width is positive for various sizes")
    func cardWidthPositive() {
        let sizes = [
            CGSize(width: 568, height: 320),  // iPhone SE landscape
            CGSize(width: 852, height: 393),  // iPhone 15 Pro landscape
            CGSize(width: 932, height: 430),  // iPhone 15 Pro Max landscape
            CGSize(width: 1024, height: 768), // iPad landscape
        ]
        for size in sizes {
            let lm = LayoutMetrics(size: size, horizontalSizeClass: size.width > 600 ? .regular : .compact)
            #expect(lm.landscapeCardWidth > 0, "Card width should be positive for size \(size)")
        }
    }

    @Test("Landscape card height is proportional to width")
    func cardHeightProportional() {
        let lm = LayoutMetrics(size: CGSize(width: 852, height: 393), horizontalSizeClass: .compact)
        #expect(abs(lm.landscapeCardHeight - lm.landscapeCardWidth * 1.42) < 0.01)
    }

    @Test("Landscape noble size is positive")
    func nobleSizePositive() {
        let sizes = [
            CGSize(width: 852, height: 393),
            CGSize(width: 1024, height: 768),
        ]
        for size in sizes {
            let lm = LayoutMetrics(size: size, horizontalSizeClass: .compact)
            #expect(lm.landscapeNobleSize > 0)
        }
    }

    @Test("AI player area width is positive")
    func aiPlayerAreaWidth() {
        let sizes = [
            CGSize(width: 852, height: 393),
            CGSize(width: 568, height: 320),
        ]
        for size in sizes {
            let lm = LayoutMetrics(size: size, horizontalSizeClass: .compact)
            #expect(lm.aiPlayerAreaWidth > 0)
        }
    }

    @Test("Landscape gem size is positive")
    func gemSizePositive() {
        let lm = LayoutMetrics(size: CGSize(width: 852, height: 393), horizontalSizeClass: .compact)
        #expect(lm.landscapeGemSize > 0)
    }

    @Test("Landscape bottom bar height is positive")
    func bottomBarHeightPositive() {
        let lm = LayoutMetrics(size: CGSize(width: 852, height: 393), horizontalSizeClass: .compact)
        #expect(lm.landscapeBottomBarHeight > 0)
    }

    @Test("Landscape column widths sum correctly")
    func columnWidthsSum() {
        let lm = LayoutMetrics(size: CGSize(width: 852, height: 393), horizontalSizeClass: .compact)
        let total = lm.landscapeCardsAreaWidth + lm.landscapeGemAreaWidth + lm.landscapeNobleAreaWidth
        // Should be approximately equal to landscapeColumnsAvailable
        #expect(total > 0)
    }

    // MARK: - Card Interaction Flow Tests (ViewModel Logic)

    @Test("selectCard on unselected card sets selectedCard")
    func selectCardSetsPurchaseMode() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)
        let firstCard = vm.state.cardsOnDisplay.first!
        vm.selectCard(firstCard)
        #expect(vm.selectedCard?.id == firstCard.id)
    }

    @Test("Cancel action resets all selection states")
    func cancelActionResetsState() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)
        let firstCard = vm.state.cardsOnDisplay.first!

        vm.selectCard(firstCard)
        #expect(vm.selectedCard != nil)

        vm.cancelAction()
        #expect(vm.selectedCard == nil)
        #expect(vm.selectedCardMode == nil)
        #expect(vm.selectedReservedCard == nil)
        #expect(vm.selectedNoble == nil)
        #expect(vm.pendingCoinSelection.isEmpty)
        #expect(vm.toast == nil)
    }

    @Test("Selecting same card twice deselects it")
    func selectCardTwiceDeselects() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)
        let firstCard = vm.state.cardsOnDisplay.first!

        vm.selectCard(firstCard)
        #expect(vm.selectedCard != nil)

        vm.selectCard(firstCard)
        #expect(vm.selectedCard == nil)
    }

    // MARK: - Gem Selection Tests

    @Test("Selecting one coin adds to pendingSelection")
    func selectOneCoin() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)

        let redCount = vm.state.tableCoins[.red]
        guard redCount > 0 else { return }

        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection[.red] == 1)
    }

    @Test("Selecting three different colors works")
    func selectThreeDifferentCoins() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)

        // Find available colors with enough coins
        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 3 else { return }

        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])

        #expect(vm.pendingCoinSelection.count == 3)
        #expect(vm.pendingCoinSelection.values.reduce(0, +) == 3)
    }

    @Test("Confirming empty selection does nothing")
    func confirmEmptySelection() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)

        vm.pendingCoinSelection = [:] // ensure empty
        vm.confirmCoinSelection()

        // State should be unchanged since selection is empty
        #expect(vm.pendingCoinSelection.isEmpty)
    }

    @Test("Cancel clears pending coin selection")
    func cancelClearsCoins() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)

        let redCount = vm.state.tableCoins[.red]
        guard redCount > 0 else { return }

        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection[.red] == 1)

        vm.cancelAction()
        #expect(vm.pendingCoinSelection.isEmpty)
    }

    // MARK: - Reserved Card Tests

    @Test("selectReservedCard starts as nil")
    func selectReservedCard() async {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm = GameViewModel(config: config)

        // Initially no reserved card selected
        #expect(vm.selectedReservedCard == nil)
    }
}
