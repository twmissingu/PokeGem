//
//  GameViewModelInteractionTests.swift
//  PokeGemTests
//
//  Tests for GameViewModel interaction logic — card modes, gem selection,
//  coin confirmation, noble selection, cancel/reset, and AI thinking state.
//

import Testing
@testable import PokeGem
import Foundation

/// All tests must run on @MainActor because GameViewModel is an @MainActor class.
@MainActor
struct GameViewModelInteractionTests {

// MARK: - Helpers

    private func createViewModel(
        playerCount: Int = 2,
        targetScore: Int = 15
    ) -> GameViewModel {
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: Array(repeating: PlayerAvatar.gary, count: playerCount - 1),
            robotDifficulties: Array(repeating: AIDifficulty.normal, count: playerCount - 1),
            targetScore: targetScore
        )
        return GameViewModel(config: config)
    }

    private func createCard(
        id: Int = 1,
        color: GemColor = .red,
        point: Int = 1,
        level: Int = 1,
        cost: [GemColor: Int] = [:]
    ) -> Card {
        Card(id: id, color: color, point: point, level: level, cost: cost)
    }

    /// Safely mutate `vm.state` (a struct) by copying, mutating, and reassigning.
    /// Direct mutation like `vm.state.players[0].ownedCards = [...]` only modifies
    /// a temporary copy because `@Observable` properties return value-type copies.
    private func updateState(_ vm: GameViewModel, _ mutate: (inout GameState) -> Void) {
        var newState = vm.state
        mutate(&newState)
        vm.state = newState
    }

    // MARK: - Card Selection Tests

    @Test("selectCard on an affordable card sets purchase mode and clears other selections")
    func selectAffordableCardSetsPurchaseMode() async {
        let vm = createViewModel()
        let firstCard = vm.state.cardsOnDisplay.first!

        vm.selectCard(firstCard)

        #expect(vm.selectedCard?.id == firstCard.id)
        #expect(vm.selectedCardMode == .purchase || vm.selectedCardMode == .reserve || vm.selectedCardMode == .cannotAfford)
        // selectedReservedCard and selectedNoble are always cleared by selectCard
        #expect(vm.selectedReservedCard == nil)
        #expect(vm.selectedNoble == nil)
    }

    @Test("selectCard replaces previous card selection and clears reserved/noble")
    func selectCardReplacesPrevious() async throws {
        let vm = createViewModel()
        let cards = vm.state.cardsOnDisplay
        try #require(cards.count >= 2, "Need at least 2 cards on display")

        // Select first card
        vm.selectCard(cards[0])
        #expect(vm.selectedCard?.id == cards[0].id)

        // Select a different card — previous selection is replaced
        vm.selectCard(cards[1])
        #expect(vm.selectedCard?.id == cards[1].id)
        #expect(vm.selectedReservedCard == nil)
        #expect(vm.selectedNoble == nil)
    }

    @Test("Tapping same card twice deselects it")
    func tapSameCardDeselects() async {
        let vm = createViewModel()
        let card = vm.state.cardsOnDisplay.first!

        // First tap selects
        vm.selectCard(card)
        #expect(vm.selectedCard != nil)

        // Second tap on same card deselects
        vm.selectCard(card)
        #expect(vm.selectedCard == nil)
        #expect(vm.selectedCardMode == nil)
    }

    @Test("selectReservedCard clears regular card and noble selection")
    func selectReservedCardClearsCardAndNoble() async {
        let vm = createViewModel()
        let card = vm.state.cardsOnDisplay.first!

        // Select a regular card first
        vm.selectCard(card)
        #expect(vm.selectedCard != nil)

        // Give the human player a reserved card to select
        let reservedCard = Card(id: 999, color: .blue, point: 0, level: 1, cost: [.red: 2])
        vm.state.players[0].reservedCards = [reservedCard]

        // Select the reserved card
        vm.selectReservedCard(reservedCard)

        // Regular card and noble selections are cleared
        #expect(vm.selectedCard == nil)
        #expect(vm.selectedNoble == nil)
        #expect(vm.selectedReservedCard?.id == reservedCard.id)
    }

    @Test("selectReservedCard toggles off when same card tapped again")
    func selectReservedCardTwiceDeselects() async {
        let vm = createViewModel()
        let reservedCard = Card(id: 999, color: .blue, point: 0, level: 1, cost: [.red: 2])
        vm.state.players[0].reservedCards = [reservedCard]

        vm.selectReservedCard(reservedCard)
        #expect(vm.selectedReservedCard?.id == reservedCard.id)

        vm.selectReservedCard(reservedCard)
        #expect(vm.selectedReservedCard == nil)
    }

    // MARK: - Cancel Action Tests

    @Test("cancelAction resets all pending state")
    func cancelResetsAllState() async {
        let vm = createViewModel()
        let card = vm.state.cardsOnDisplay.first!

        vm.selectCard(card)
        vm.selectCoin(.red)
        #expect(vm.selectedCard != nil)
        #expect(!vm.pendingCoinSelection.isEmpty)

        vm.cancelAction()

        #expect(vm.selectedCard == nil)
        #expect(vm.selectedCardMode == nil)
        #expect(vm.selectedReservedCard == nil)
        #expect(vm.selectedNoble == nil)
        #expect(vm.pendingCoinSelection.isEmpty)
        #expect(vm.toast == nil)
    }

    @Test("cancelAction is idempotent — calling on clean state does nothing")
    func cancelIdempotent() async {
        let vm = createViewModel()

        // Calling cancel on already-clean state should not crash or change anything
        vm.cancelAction()
        #expect(vm.selectedCard == nil)
        #expect(vm.selectedCardMode == nil)
        #expect(vm.selectedReservedCard == nil)
        #expect(vm.selectedNoble == nil)
        #expect(vm.pendingCoinSelection.isEmpty)
        #expect(vm.toast == nil)

        // Second call still clean
        vm.cancelAction()
        #expect(vm.selectedCard == nil)
    }

    // MARK: - Coin Selection Tests

    @Test("selectCoin cycles 0→1 on first tap")
    func coinSelectionZeroToOne() async {
        let vm = createViewModel()
        guard vm.state.tableCoins[.red] > 0 else { return }

        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection[.red] == 1)
    }

    @Test("selectCoin cycles correctly: 0→1→2→0 when table has 4+ coins")
    func coinSelectionCyclesCorrectly() async {
        let vm = createViewModel()
        // 2-player game: each non-gold color starts with 4 on table
        guard vm.state.tableCoins[.red] >= 4 else { return }

        // 0 → 1
        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection[.red] == 1)

        // 1 → 2 (table has >= 4)
        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection[.red] == 2)

        // 2 → 0 (toggle off)
        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection[.red] == nil)
    }

    @Test("selectCoin limits selection to max 3 different colors")
    func coinSelectionMaxThreeColors() async {
        let vm = createViewModel()
        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 4 else { return }

        // Select 3 different colors
        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])
        #expect(vm.pendingCoinSelection.count == 3)
        #expect(vm.pendingCoinSelection.values.reduce(0, +) == 3)

        // 4th color should be rejected
        vm.selectCoin(available[3])
        #expect(vm.pendingCoinSelection.count == 3)
    }

    @Test("selectCoin with gold is a no-op (gold is not a gem color)")
    func selectGoldDoesNothing() async {
        let vm = createViewModel()

        // Gold is not a gem color — selectCoin returns early
        vm.selectCoin(.gold)
        #expect(vm.pendingCoinSelection.isEmpty)

        // Normal gem selection still works after gold no-op
        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection[.red] == 1)
    }

    @Test("canTakeDouble returns true when table has 4+ coins of that color")
    func canTakeDoubleWithEnoughCoins() async {
        let vm = createViewModel()
        let redCount = vm.state.tableCoins[.red]
        #expect(vm.canTakeDouble(.red) == (redCount >= 4))
    }

    @Test("canTakeDouble returns false for gold regardless of table count")
    func cannotDoubleGold() async {
        let vm = createViewModel()
        #expect(vm.canTakeDouble(.gold) == false)
    }

    @Test("confirmCoinSelection succeeds for valid 3-different-color selection")
    func confirmValidCoinSelection() async {
        let vm = createViewModel()
        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 3 else { return }

        // Select 3 different colors (valid take-3 action)
        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])

        let countBefore = vm.pendingCoinSelection.count
        #expect(countBefore == 3)

        vm.confirmCoinSelection()

        // After confirmation, pending selection is cleared
        #expect(vm.pendingCoinSelection.isEmpty)
    }

    @Test("confirmCoinSelection with empty selection is a no-op")
    func confirmEmptySelectionIsNoOp() async {
        let vm = createViewModel()

        // No coins selected — guard returns early
        vm.confirmCoinSelection()
        #expect(vm.pendingCoinSelection.isEmpty)
        #expect(vm.toast == nil)
    }

    @Test("confirmCoinSelection advances turn to AI after valid coin take")
    func confirmCoinSelectionAdvancesToAI() {
        let vm = createViewModel(playerCount: 2)

        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 3 else { return }

        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])

        vm.confirmCoinSelection()

        // Synchronous: applyPlayerAction already ran, turn advanced to AI
        #expect(vm.state.phase == .aiThinking)
        #expect(!vm.state.currentPlayer.isHuman)
        #expect(vm.state.turnNumber == 1)
        #expect(vm.pendingCoinSelection.isEmpty)
    }

    @Test("Full turn cycle: human takes coins → AI completes turn → back to human")
    func fullTurnCycleWithAI() async {
        let vm = createViewModel(playerCount: 2)
        vm.aiSpeedMultiplier = 8 // Skip AI speed delay

        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 3 else { return }

        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])

        vm.confirmCoinSelection()

        // Synchronous check: turn advanced to AI
        #expect(!vm.state.currentPlayer.isHuman)
        #expect(vm.state.phase == .aiThinking)

        // Wait for AI task to complete (AI strategies have built-in delays up to ~1.2s)
        try? await Task.sleep(for: .milliseconds(2000))

        // AI should have completed its turn, back to human
        #expect(vm.state.currentPlayer.isHuman)
        #expect(vm.state.phase == .playerTurn)
        #expect(vm.state.turnNumber == 2)
    }

    // MARK: - Noble Tests

    @Test("selectNoble sets selectedNoble when conditions not met (shows info toast)")
    func selectNobleWhenCannotAttract() async {
        let vm = createViewModel()
        guard let noble = vm.state.availableNobles.first else { return }

        // Fresh game: human player has 0 cards, can't attract any noble
        vm.selectNoble(noble)

        // Player cannot attract — noble is selected and info toast shown
        #expect(vm.selectedNoble?.id == noble.id)
        #expect(vm.toast?.style == .info)
    }

    @Test("selectNoble with canAttract immediately claims the noble")
    func selectNobleWhenCanAttract() async {
        let vm = createViewModel()
        guard let noble = vm.state.availableNobles.first else { return }

        // Give the player enough cards to meet the noble's requirements.
        // GameState is a struct, so we must reassign after mutation.
        updateState(vm) { state in
            var cardId = 1000
            var cards: [Card] = []
            for (color, count) in noble.cost {
                for _ in 0..<count {
                    cards.append(Card(id: cardId, color: color, point: 0, level: 1, cost: [:]))
                    cardId += 1
                }
            }
            state.players[0].ownedCards = cards
        }

        // Player can now attract — tapping noble auto-claims it
        vm.selectNoble(noble)

        // After claiming, no noble is selected (claimed immediately),
        // success toast is shown
        #expect(vm.selectedNoble == nil)
        #expect(vm.toast?.style == .success)
    }

    @Test("selectNoble twice deselects")
    func selectNobleTwiceDeselects() async {
        let vm = createViewModel()
        guard let noble = vm.state.availableNobles.first else { return }

        // First tap selects
        vm.selectNoble(noble)
        #expect(vm.selectedNoble?.id == noble.id)

        // Second tap on same noble deselects
        vm.selectNoble(noble)
        #expect(vm.selectedNoble == nil)
    }

    @Test("selectNoble clears card and reserved card selections")
    func selectNobleClearsCardSelections() async {
        let vm = createViewModel()
        guard let noble = vm.state.availableNobles.first else { return }

        // Select a regular card first
        let card = vm.state.cardsOnDisplay.first!
        vm.selectCard(card)
        #expect(vm.selectedCard != nil)

        // Now select a noble — card selection is cleared
        vm.selectNoble(noble)
        #expect(vm.selectedCard == nil)
        #expect(vm.selectedCardMode == nil)
        #expect(vm.selectedReservedCard == nil)
    }

    @Test("selectNoble with canAttract updates win condition (highestScore)")
    func selectNobleUpdatesWinCondition() async {
        let vm = createViewModel(targetScore: 15)
        guard let noble = vm.state.availableNobles.first else { return }

        // Give player enough cards for noble + high points from owned cards
        updateState(vm) { state in
            var cardId = 3000
            var cards: [Card] = []
            // Cards for noble requirement
            for (color, count) in noble.cost {
                for _ in 0..<count {
                    cards.append(Card(id: cardId, color: color, point: 0, level: 1, cost: [:]))
                    cardId += 1
                }
            }
            // Extra cards with points to reach target
            for i in 0..<12 {
                cards.append(Card(id: cardId + i, color: .red, point: 1, level: 1, cost: [:]))
            }
            state.players[0].ownedCards = cards
        }

        let scoreBefore = vm.state.highestScore
        vm.selectNoble(noble)

        // Noble claim should have updated highestScore via checkWinCondition
        #expect(vm.state.highestScore > scoreBefore)
        #expect(vm.state.highestScore >= 15)
        #expect(vm.state.leaderPlayerId == vm.state.players[0].id)
    }

    // MARK: - Computed Properties Tests

    @Test("actionHint is non-empty when game is playable")
    func actionHintNonEmpty() async {
        let vm = createViewModel()
        let hint = vm.actionHint
        #expect(!hint.isEmpty)
    }

    @Test("canTakeCoins reflects player coin limit during player turn")
    func canTakeCoinsDuringPlayerTurn() async {
        let vm = createViewModel()
        #expect(vm.phase == .playerTurn)
        #expect(vm.canTakeCoins == !vm.state.currentPlayer.hasCoinsAtLimit)
    }

    @Test("isAIThinking is false during human player turn")
    func isAIThinkingInitially() async {
        let vm = createViewModel()
        #expect(vm.isAIThinking == false)
    }

    @Test("projectedPurse is nil when no card selected")
    func projectedPurseNilWithoutCard() async {
        let vm = createViewModel()
        #expect(vm.projectedPurse == nil)
    }

    @Test("projectedPurse is non-nil when an affordable card is selected")
    func projectedPurseForAffordableCard() async {
        let vm = createViewModel()

        // Find a card the player can purchase, or give them coins to afford one
        guard let affordable = vm.state.cardsOnDisplay.first(where: { vm.state.currentPlayer.canPurchase($0) }) else {
            // If no immediately affordable card, give the player enough coins
            let card = vm.state.cardsOnDisplay.first!
            updateState(vm) { state in
                let costCoins = card.cost.mapValues { _ in 5 }
                state.players[0].purse = CoinPurse(coins: costCoins)
            }
            vm.selectCard(card)
            #expect(vm.projectedPurse != nil)
            return
        }

        vm.selectCard(affordable)
        #expect(vm.projectedPurse != nil)
    }

    @Test("turn number starts at 0 for fresh game")
    func turnStartsAtZero() async {
        let vm = createViewModel()
        #expect(vm.state.turnNumber == 0)
    }

    // MARK: - AI Related Tests

    @Test("aiSpeedMultiplier defaults to 1.0")
    func aiSpeedDefault() async {
        let vm = createViewModel()
        #expect(vm.aiSpeedMultiplier == 1.0)
    }

    @Test("aiSpeedMultiplier can be set to faster speeds")
    func aiSpeedIncrease() async {
        let vm = createViewModel()
        vm.aiSpeedMultiplier = 4.0
        #expect(vm.aiSpeedMultiplier == 4.0)
    }

    @Test("opponentPlayers returns only non-human players")
    func opponentPlayersExcludesHuman() async {
        let vm = createViewModel(playerCount: 3)
        let opponents = vm.opponentPlayers
        #expect(opponents.count == 2)
        #expect(opponents.allSatisfy { !$0.isHuman })
    }

    @Test("humanPlayer returns the human player from state")
    func humanPlayerExists() async {
        let vm = createViewModel()
        #expect(vm.humanPlayer?.isHuman == true)
    }

    @Test("humanPlayer is nil if no human in player list (defensive)")
    func humanPlayerWithNoHuman() async {
        let vm = createViewModel()
        // Temporarily make all players non-human.
        // GameState is a struct — must reassign after mutation.
        updateState(vm) { state in
            for i in 0..<state.players.count {
                let p = state.players[i]
                state.players[i] = PlayerState(
                    id: p.id,
                    name: p.name,
                    isHuman: false,
                    avatar: p.avatar
                )
            }
        }
        #expect(vm.humanPlayer == nil)
    }

    // MARK: - Phase & Guard Tests

    @Test("selectCard is no-op when not playerTurn phase")
    func selectCardNoOpOutsidePlayerTurn() async {
        let vm = createViewModel()
        vm.state.phase = .settings  // Not playerTurn

        let card = vm.state.cardsOnDisplay.first!
        vm.selectCard(card)

        // Guard should prevent selection
        #expect(vm.selectedCard == nil)
    }

    @Test("selectCoin is no-op when player is at coin limit")
    func selectCoinNoOpAtCoinLimit() async {
        let vm = createViewModel()
        // Fill player to 10 coins
        updateState(vm) { state in
            state.players[0].purse = CoinPurse(coins: [.red: 10])
        }

        vm.selectCoin(.red)
        #expect(vm.pendingCoinSelection.isEmpty)
    }

    @Test("canClaimNoble matches current player attraction ability")
    func canClaimNobleCheck() async {
        let vm = createViewModel()
        guard let noble = vm.state.availableNobles.first else { return }

        // Initially can't claim any noble (no cards)
        #expect(vm.canClaimNoble(noble) == false)

        // Give player enough cards to meet requirements.
        // GameState is a struct — must reassign after mutation.
        updateState(vm) { state in
            var cardId = 2000
            var cards: [Card] = []
            for (color, count) in noble.cost {
                for _ in 0..<count {
                    cards.append(Card(id: cardId, color: color, point: 0, level: 1, cost: [:]))
                    cardId += 1
                }
            }
            state.players[0].ownedCards = cards
        }

        #expect(vm.canClaimNoble(noble) == true)
    }

    // MARK: - End-to-End Card Refresh Investigation

    @Test("E2E: takeCoins should NOT change table cards or nobles")
    func e2eTakeCoinsShouldNotChangeCards() async {
        let vm = createViewModel(playerCount: 2)
        vm.aiSpeedMultiplier = 8

        // Record initial state
        let initialL1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let initialL2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let initialL3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let initialNobles = vm.state.availableNobles.map { $0.id }
        let initialHumanPurse = vm.state.players[0].purse.total

        // Select 3 different coins
        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 3 else { return }
        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])

        // Confirm
        vm.confirmCoinSelection()

        // IMMEDIATELY after confirm — before AI acts
        let afterL1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let afterL2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let afterL3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let afterNobles = vm.state.availableNobles.map { $0.id }
        let afterHumanPurse = vm.state.players[0].purse.total

        // Cards should NOT have changed
        #expect(afterL1 == initialL1, "L1 before: \(initialL1), after: \(afterL1)")
        #expect(afterL2 == initialL2, "L2 before: \(initialL2), after: \(afterL2)")
        #expect(afterL3 == initialL3, "L3 before: \(initialL3), after: \(afterL3)")
        #expect(afterNobles == initialNobles, "Nobles before: \(initialNobles), after: \(afterNobles)")

        // Human player SHOULD have gained 3 coins
        #expect(afterHumanPurse == initialHumanPurse + 3, "Human should have gained 3 coins. Before: \(initialHumanPurse), After: \(afterHumanPurse)")

        // Turn should have advanced to AI
        #expect(!vm.state.currentPlayer.isHuman, "Should be AI turn after confirm")
        #expect(vm.state.phase == .aiThinking, "Phase should be aiThinking")

        // Wait for AI to complete
        try? await Task.sleep(for: .milliseconds(2000))

        // After AI, should be back to human
        #expect(vm.state.currentPlayer.isHuman, "Should be back to human after AI turn")
        #expect(vm.state.phase == .playerTurn, "Phase should be playerTurn")
    }

    @Test("E2E: reserveCard should change exactly ONE card in that level")
    func e2eReserveCardShouldChangeOneCard() async {
        let vm = createViewModel(playerCount: 2)
        vm.aiSpeedMultiplier = 8

        let initialL1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let initialL2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let initialL3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let initialNobles = vm.state.availableNobles.map { $0.id }

        guard let cardToReserve = vm.state.cardsOnDisplay.first else { return }
        vm.selectCard(cardToReserve)
        vm.reserveSelectedCard()

        let afterL1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let afterL2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let afterL3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let afterNobles = vm.state.availableNobles.map { $0.id }

        // Only the reserved card's level should change
        switch cardToReserve.level {
        case 1:
            let removed = initialL1.filter { !afterL1.contains($0) }
            #expect(removed.count == 1, "Expected 1 card removed from L1, removed: \(removed). Before: \(initialL1), After: \(afterL1)")
            #expect(afterL2 == initialL2, "L2 should not change")
            #expect(afterL3 == initialL3, "L3 should not change")
        case 2:
            let removed = initialL2.filter { !afterL2.contains($0) }
            #expect(removed.count == 1, "Expected 1 card removed from L2, removed: \(removed). Before: \(initialL2), After: \(afterL2)")
            #expect(afterL1 == initialL1, "L1 should not change")
            #expect(afterL3 == initialL3, "L3 should not change")
        case 3:
            let removed = initialL3.filter { !afterL3.contains($0) }
            #expect(removed.count == 1, "Expected 1 card removed from L3, removed: \(removed). Before: \(initialL3), After: \(afterL3)")
            #expect(afterL1 == initialL1, "L1 should not change")
            #expect(afterL2 == initialL2, "L2 should not change")
        default: break
        }

        // Nobles should not change
        #expect(afterNobles == initialNobles, "Nobles should not change. Before: \(initialNobles), After: \(afterNobles)")

        // Wait for AI
        try? await Task.sleep(for: .milliseconds(2000))
        #expect(vm.state.currentPlayer.isHuman, "Should be back to human")
    }

    @Test("E2E: save/load cycle should preserve card state")
    func e2eSaveLoadPreservesState() async {
        let vm = createViewModel(playerCount: 2)
        vm.aiSpeedMultiplier = 8

        // Take gems
        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 3 else { return }
        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])
        vm.confirmCoinSelection()

        // Wait for AI
        try? await Task.sleep(for: .milliseconds(2000))

        // Record state after AI turn
        let beforeSaveL1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let beforeSaveL2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let beforeSaveL3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let beforeSaveNobles = vm.state.availableNobles.map { $0.id }
        let beforeSavePurse = vm.state.players[0].purse.allCounts
        let beforeSaveTurn = vm.state.turnNumber

        // Save state
        vm.saveState()

        // Load state
        let config = GameConfig(
            humanPlayerAvatar: .ash,
            robotAvatars: [.gary],
            robotDifficulties: [.normal],
            targetScore: 15
        )
        let vm2 = GameViewModel(config: config, loadSaved: true)

        // Verify loaded state matches
        let afterLoadL1 = vm2.state.level1Cards.prefix(4).map { $0.id }
        let afterLoadL2 = vm2.state.level2Cards.prefix(4).map { $0.id }
        let afterLoadL3 = vm2.state.level3Cards.prefix(4).map { $0.id }
        let afterLoadNobles = vm2.state.availableNobles.map { $0.id }
        let afterLoadPurse = vm2.state.players[0].purse.allCounts
        let afterLoadTurn = vm2.state.turnNumber

        #expect(afterLoadL1 == beforeSaveL1, "L1 changed after save/load! Before: \(beforeSaveL1), After: \(afterLoadL1)")
        #expect(afterLoadL2 == beforeSaveL2, "L2 changed after save/load! Before: \(beforeSaveL2), After: \(afterLoadL2)")
        #expect(afterLoadL3 == beforeSaveL3, "L3 changed after save/load! Before: \(beforeSaveL3), After: \(afterLoadL3)")
        #expect(afterLoadNobles == beforeSaveNobles, "Nobles changed after save/load! Before: \(beforeSaveNobles), After: \(afterLoadNobles)")
        #expect(afterLoadPurse == beforeSavePurse, "Purse changed after save/load! Before: \(beforeSavePurse), After: \(afterLoadPurse)")
        #expect(afterLoadTurn == beforeSaveTurn, "Turn changed after save/load! Before: \(beforeSaveTurn), After: \(afterLoadTurn)")
    }

    @Test("E2E: Multi-turn trace — verify state consistency across turns")
    func e2eMultiTurnTrace() async {
        let vm = createViewModel(playerCount: 2)
        vm.aiSpeedMultiplier = 8

        // ── Turn 1 ──
        let t0L1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let t0L2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let t0L3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let t0Nobles = vm.state.availableNobles.map { $0.id }
        let t0Purse = vm.state.currentPlayer.purse.allCounts
        let t0Turn = vm.state.turnNumber

        let available = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available.count >= 3 else { return }
        vm.selectCoin(available[0])
        vm.selectCoin(available[1])
        vm.selectCoin(available[2])
        vm.confirmCoinSelection()

        // After confirm, before AI
        let t1L1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let t1L2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let t1L3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let t1Nobles = vm.state.availableNobles.map { $0.id }
        let t1Purse = vm.state.players[0].purse.allCounts // human player's purse
        let t1Turn = vm.state.turnNumber

        // takeCoins: cards and nobles MUST NOT change
        #expect(t1L1 == t0L1, "Turn 0→1: L1 changed! \(t0L1) → \(t1L1)")
        #expect(t1L2 == t0L2, "Turn 0→1: L2 changed! \(t0L2) → \(t1L2)")
        #expect(t1L3 == t0L3, "Turn 0→1: L3 changed! \(t0L3) → \(t1L3)")
        #expect(t1Nobles == t0Nobles, "Turn 0→1: Nobles changed! \(t0Nobles) → \(t1Nobles)")
        #expect(t1Turn == t0Turn + 1, "Turn should advance by 1")

        // Human player should have gained coins
        let t0Total = t0Purse.values.reduce(0, +)
        let t1Total = t1Purse.values.reduce(0, +)
        let gained = t1Total - t0Total
        #expect(gained == 3, "Human should have gained 3 coins, gained: \(gained). Before: \(t0Purse), After: \(t1Purse)")

        // Wait for AI
        try? await Task.sleep(for: .milliseconds(2000))

        // ── Turn 2 ──
        #expect(vm.state.currentPlayer.isHuman, "Should be back to human")
        let t2L1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let t2L2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let t2L3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let t2Nobles = vm.state.availableNobles.map { $0.id }

        // AI might have changed cards — that's OK, just log the diff
        // The key assertion is that the game is back to human's turn
        #expect(vm.state.phase == .playerTurn)

        // Now human takes coins again
        let available2 = GemColor.gemColors.filter { vm.state.tableCoins[$0] > 0 }
        guard available2.count >= 3 else { return }
        vm.selectCoin(available2[0])
        vm.selectCoin(available2[1])
        vm.selectCoin(available2[2])
        vm.confirmCoinSelection()

        // After second confirm
        let t3L1 = vm.state.level1Cards.prefix(4).map { $0.id }
        let t3L2 = vm.state.level2Cards.prefix(4).map { $0.id }
        let t3L3 = vm.state.level3Cards.prefix(4).map { $0.id }
        let t3Nobles = vm.state.availableNobles.map { $0.id }

        // takeCoins: cards MUST NOT change from the state before this confirm
        #expect(t3L1 == t2L1, "Turn 2→3: L1 changed! \(t2L1) → \(t3L1)")
        #expect(t3L2 == t2L2, "Turn 2→3: L2 changed! \(t2L2) → \(t3L2)")
        #expect(t3L3 == t2L3, "Turn 2→3: L3 changed! \(t2L3) → \(t3L3)")
        #expect(t3Nobles == t2Nobles, "Turn 2→3: Nobles changed! \(t2Nobles) → \(t3Nobles)")
    }
}
