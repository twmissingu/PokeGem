import Foundation
import Observation

/// Debug log helper that writes to a file in the app's Documents directory
#if DEBUG
private func debugLog(_ message: String) {
    print("[DEBUG] \(message)")
    guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    let logURL = docs.appendingPathComponent("game_debug.log")
    let timestamp = ISO8601DateFormatter().string(from: Date())
    if let handle = try? FileHandle(forWritingTo: logURL) {
        handle.seekToEndOfFile()
        handle.write("\(timestamp) \(message)\n".data(using: .utf8)!)
        handle.closeFile()
    } else {
        try? "\(timestamp) \(message)\n".write(to: logURL, atomically: true, encoding: .utf8)
    }
}
#else
private func debugLog(_: String) {}
#endif

enum CardActionMode: String {
    case purchase
    case reserve
    case cannotAfford
}

@Observable
@MainActor
class GameViewModel {
    var state: GameState
    var config: GameConfig
    var selectedCard: Card?
    var selectedCardMode: CardActionMode?
    var selectedReservedCard: Card?
    var selectedNoble: PointCard?
    var pendingCoinSelection: [GemColor: Int] = [:]
    var aiThinkingPlayerId: UUID?
    var toast: ToastConfig?
    var purchasingCardId: Int?
    var aiSpeedMultiplier: Double = 1.0
    var claimedNobleThisTurn = false

    var feedback = GameFeedbackService()

    private var aiStrategies: [UUID: any AIStrategy] = [:]
    private var aiTask: Task<Void, Never>?

    init(config: GameConfig, loadSaved: Bool = false) {
        self.config = config
        if loadSaved {
            switch GameArchiver.loadResult() {
            case .success(let archived):
                self.state = archived.state
                self.config = archived.config
            case .failure(let error):
                #if DEBUG
                print("[GameArchiver] load failed: \(error.localizedDescription)")
                #endif
                GameArchiver.clear()
                self.state = GameEngine.setup(config: config)
            }
        } else {
            self.state = GameEngine.setup(config: config)
        }
        self.feedback.hapticEnabled = config.hapticEnabled
        buildAIStrategies()
    }

    func saveState() {
        guard !state.isGameOver else {
            GameArchiver.clear()
            return
        }
        GameArchiver.save(state: state, config: config)
    }

    func restart() {
        cancelAction()
        state = GameEngine.setup(config: config)
        aiTask?.cancel()
        aiTask = nil
        aiStrategies.removeAll()
        buildAIStrategies()
    }

    private func buildAIStrategies() {
        let robotPlayers = state.players.filter { !$0.isHuman }
        for (index, player) in robotPlayers.enumerated() {
            let difficulty = index < config.robotDifficulties.count
                ? config.robotDifficulties[index]
                : .normal
            switch difficulty {
            case .easy: aiStrategies[player.id] = EasyAIStrategy()
            case .normal: aiStrategies[player.id] = NormalAIStrategy()
            case .hard: aiStrategies[player.id] = HardAIStrategy()
            }
        }
    }

    // MARK: - Coin Taking

    /// Cycle coin selection: tap cycles 0→1→2→0 (2 only if table >= 4)
    func selectCoin(_ color: GemColor) {
        guard state.currentPlayer.isHuman && state.phase == .playerTurn else { return }
        guard !state.currentPlayer.hasCoinsAtLimit else { return }
        guard color.isGemColor else { return }

        let countOnTable = state.tableCoins[color]
        guard countOnTable > 0 else { return }

        let currentTotal = pendingCoinSelection.values.reduce(0, +)
        let playerRemaining = 10 - state.currentPlayer.purse.total
        let maxCoins = min(3, playerRemaining)

        let selectedCount = pendingCoinSelection[color] ?? 0
        let selectedColorsCount = pendingCoinSelection.keys.count

        // If already selected 2 of another color, can only toggle that color off
        if let twoColor = pendingCoinSelection.first(where: { $0.value == 2 }), color != twoColor.key {
            return // Can't select any other color when 2 are selected
        }

        if selectedCount == 0 {
            // No selection yet → select 1
            guard currentTotal < maxCoins else { return }
            // Can't select more if already have 2 of same color
            if pendingCoinSelection.values.contains(2) { return }
            if selectedColorsCount >= 3 {
                return
            }
            pendingCoinSelection[color] = 1
        } else if selectedCount == 1, countOnTable >= 4 {
            // Currently 1, table has enough → upgrade to 2
            // BUT: can't upgrade if multiple colors are already selected (would be 2+1=3)
            if selectedColorsCount > 1 {
                return // Can't upgrade to 2 when other colors are selected
            }
            guard currentTotal + 1 <= maxCoins else { return }
            pendingCoinSelection[color] = 2
        } else {
            // Toggle off
            pendingCoinSelection[color] = nil
        }
    }

    /// Check if a gem color can be selected based on current selection state
    func canSelectGem(_ color: GemColor) -> Bool {
        guard state.currentPlayer.isHuman && state.phase == .playerTurn else { return false }
        guard !state.currentPlayer.hasCoinsAtLimit else { return false }
        guard color.isGemColor else { return false }
        guard state.tableCoins[color] > 0 else { return false }

        let selectedCount = pendingCoinSelection[color] ?? 0
        let selectedColorsCount = pendingCoinSelection.keys.count

        // If already selected 2 of this color, can't select more
        if selectedCount >= 2 { return false }

        // If already selected 2 of same color elsewhere, can't select anything else
        if let twoColor = pendingCoinSelection.first(where: { $0.value == 2 }) {
            return color == twoColor.key
        }

        // If already selected 3 different colors, can't select more
        if selectedColorsCount >= 3 { return false }

        // If already selected 1 and this is same color, check if can upgrade to 2
        if selectedCount == 1 {
            // Can only upgrade to 2 if no other colors are selected
            return selectedColorsCount == 1 && state.tableCoins[color] >= 4
        }

        // If different color from existing selections, check if can add
        if pendingCoinSelection.keys.contains(color) { return false }

        // General check: can add if under limit
        let currentTotal = pendingCoinSelection.values.reduce(0, +)
        let playerRemaining = 10 - state.currentPlayer.purse.total
        let maxCoins = min(3, playerRemaining)
        return currentTotal < maxCoins
    }

    /// Get the reason why a gem can't be selected (for UI feedback)
    func gemSelectionDisabledReason(_ color: GemColor) -> String? {
        guard canSelectGem(color) else {
            if pendingCoinSelection.values.contains(2) {
                return "已选2个同色"
            }
            if pendingCoinSelection.keys.count >= 3 {
                return "已选3个"
            }
            return nil
        }
        return nil
    }

    func confirmCoinSelection() {
        guard !pendingCoinSelection.isEmpty else {
            debugLog("confirmCoinSelection: empty selection")
            return
        }

        guard GameEngine.isValidCoinTake(pendingCoinSelection, in: state) else {
            debugLog("confirmCoinSelection: isValidCoinTake FAILED for \(pendingCoinSelection)")
            toast = ToastConfig(message: "不符合拿取规则", style: .error)
            feedback.onError()
            return
        }
        debugLog("confirmCoinSelection: isValidCoinTake PASSED for \(pendingCoinSelection)")

        let total = pendingCoinSelection.values.reduce(0, +)
        let playerRemaining = 10 - state.currentPlayer.purse.total
        guard total <= playerRemaining else {
            debugLog("confirmCoinSelection: player limit \(total) > \(playerRemaining)")
            toast = ToastConfig(message: "超过宝石持有上限", style: .error)
            feedback.onError()
            return
        }
        debugLog("confirmCoinSelection: player has room \(total) <= \(playerRemaining)")

        debugLog("confirmCoinSelection: before apply — table coins: \(state.tableCoins.allCounts), player coins: \(state.currentPlayer.purse.allCounts)")

        toast = nil
        let action = GameAction.takeCoins(pendingCoinSelection)
        let oldTurn = state.turnNumber
        let oldPhase = state.phase
        let applied = applyPlayerAction(action)

        debugLog("confirmCoinSelection: after apply — turn: \(oldTurn) -> \(state.turnNumber), phase: \(oldPhase) -> \(state.phase), player coins: \(state.currentPlayer.purse.allCounts) (currentPlayer is now \(state.currentPlayer.name))")
        debugLog("confirmCoinSelection: table coins after: \(state.tableCoins.allCounts)")

        pendingCoinSelection = [:]
        if applied {
            toast = ToastConfig(message: "已拿取 \(total) 个宝石", style: .success)
        }
    }

    // MARK: - Card Actions

    func selectCard(_ card: Card) {
        guard state.currentPlayer.isHuman && state.phase == .playerTurn else { return }

        selectedReservedCard = nil
        selectedNoble = nil

        if selectedCard?.id == card.id {
            selectedCard = nil
            selectedCardMode = nil
        } else {
            selectedCard = card
            let player = state.currentPlayer
            if player.canPurchase(card) {
                selectedCardMode = .purchase
            } else if player.canReserveMore {
                selectedCardMode = .reserve
            } else {
                selectedCardMode = .cannotAfford
            }
        }
    }

    func purchaseSelectedCard() {
        guard let card = selectedCard else { return }
        let player = state.currentPlayer

        guard player.canPurchase(card) else {
            toast = ToastConfig(message: "宝石数量不足，无法购买", style: .error)
            feedback.onError()
            return
        }

        guard let payment = player.purse.coinsToPay(card.cost, with: player.cardCounts) else {
            toast = ToastConfig(message: "无法计算支付方式", style: .error)
            feedback.onError()
            return
        }

        toast = nil
        let applied = applyPlayerAction(.purchaseCard(card, payment))
        selectedCard = nil
        selectedCardMode = nil
        if applied {
            toast = ToastConfig(message: "成功购买 #\(card.id) (\(card.color.displayName))", style: .success)
        }
    }

    func reserveSelectedCard() {
        guard let card = selectedCard else { return }
        let player = state.currentPlayer

        guard player.canReserveMore else {
            toast = ToastConfig(message: "保留卡数量已达上限 (3张)", style: .error)
            feedback.onError()
            return
        }

        toast = nil
        let applied = applyPlayerAction(.reserveCard(card))
        selectedCard = nil
        selectedCardMode = nil
        if applied {
            toast = ToastConfig(message: "已保留 #\(card.id)", style: .info)
        }
    }

    func selectReservedCard(_ card: Card) {
        guard state.currentPlayer.isHuman && state.phase == .playerTurn else { return }

        selectedCard = nil
        selectedNoble = nil

        if selectedReservedCard?.id == card.id {
            selectedReservedCard = nil
        } else {
            selectedReservedCard = card
        }
    }

    func repaySelectedCard() {
        guard let card = selectedReservedCard else { return }

        guard state.currentPlayer.canRepay(card) else {
            toast = ToastConfig(message: "宝石数量不足，无法偿还", style: .error)
            feedback.onError()
            return
        }

        guard let payment = state.currentPlayer.purse.coinsToPay(card.cost, with: state.currentPlayer.cardCounts) else {
            toast = ToastConfig(message: "无法计算支付方式", style: .error)
            feedback.onError()
            return
        }

        toast = nil
        let applied = applyPlayerAction(.repayCard(card, payment))
        selectedReservedCard = nil
        if applied {
            toast = ToastConfig(message: "成功偿还 #\(card.id)", style: .success)
        }
    }

    // MARK: - Noble Actions

    func selectNoble(_ noble: PointCard) {
        guard state.currentPlayer.isHuman && state.phase == .playerTurn else { return }

        if selectedNoble?.id == noble.id {
            selectedNoble = nil
            return
        }

        selectedCard = nil
        selectedCardMode = nil
        selectedReservedCard = nil

        if state.currentPlayer.canAttract(noble) {
            toast = nil
            selectedNoble = nil
            state = GameEngine.processAction(.claimNoble(noble), in: state)
            feedback.onAction(.claimNoble(noble))
            claimedNobleThisTurn = true
            toast = ToastConfig(message: "贵族 #\(noble.id) 加入队伍！", style: .success)
            saveState()
        } else {
            selectedNoble = noble
            toast = ToastConfig(message: "当前不满足此贵族的条件", style: .info)
        }
    }

    // MARK: - Cancel

    func cancelAction() {
        selectedCard = nil
        selectedCardMode = nil
        selectedReservedCard = nil
        selectedNoble = nil
        pendingCoinSelection = [:]
        toast = nil
    }

    func passTurn() {
        guard state.phase == .playerTurn && state.currentPlayer.isHuman else { return }
        cancelAction()
        applyPlayerAction(.pass)
        toast = ToastConfig(message: "已跳过回合", style: .info)
    }

    // MARK: - AI Execution

    private func executeAITurns() async {
        debugLog("executeAITurns: STARTED, currentPlayer: \(state.currentPlayer.name), phase: \(state.phase)")
        while !state.currentPlayer.isHuman && !state.isGameOver {
            guard !Task.isCancelled else {
                debugLog("executeAITurns: CANCELLED")
                return
            }

            let currentPlayer = state.currentPlayer
            aiThinkingPlayerId = currentPlayer.id
            state.phase = .aiThinking
            feedback.onPhaseChange(.aiThinking)
            debugLog("executeAITurns: processing AI '\(currentPlayer.name)' id: \(currentPlayer.id)")

            guard let strategy = aiStrategies[currentPlayer.id] else {
                debugLog("executeAITurns: NO STRATEGY for \(currentPlayer.name)!")
                assertionFailure("No AI strategy registered for player \(currentPlayer.id)")
                aiThinkingPlayerId = nil
                state = GameEngine.advanceTurn(state)
                continue
            }

            debugLog("executeAITurns: calling chooseAction for \(currentPlayer.name)")
            let action = await strategy.chooseAction(state: state, playerId: currentPlayer.id)
            debugLog("executeAITurns: chooseAction returned \(action) for \(currentPlayer.name)")
            guard !Task.isCancelled else {
                debugLog("executeAITurns: CANCELLED after chooseAction")
                return
            }

            let aiName = currentPlayer.name
            let aiToastMessage: String = {
                switch action {
                case .takeCoins(let coins):
                    let desc = coins.map { "\($0.displayName)×\($1)" }.joined(separator: " ")
                    return "\(aiName) 拿了 \(desc)"
                case .purchaseCard(let card, _): return "\(aiName) 购买了 #\(card.id)"
                case .reserveCard(let card): return "\(aiName) 保留了 #\(card.id)"
                case .repayCard(let card, _): return "\(aiName) 偿还了 #\(card.id)"
                case .claimNoble(let noble): return "\(aiName) 吸引了贵族 #\(noble.id)"
                case .pass: return "\(aiName) 跳过"
                }
            }()
            toast = ToastConfig(message: aiToastMessage, style: .info)

            debugLog("executeAITurns: applying action for \(currentPlayer.name)")
            state = GameEngine.processAction(action, in: state)
            aiThinkingPlayerId = nil
            debugLog("executeAITurns: after apply, phase: \(state.phase), currentPlayer: \(state.currentPlayer.name)")

            // Save state after each AI action to prevent data loss if app is killed
            saveState()

            // Respect speed multiplier — skip delay at max speed
            if aiSpeedMultiplier < 8 {
                let delay: UInt64 = UInt64(300 / aiSpeedMultiplier)
                try? await Task.sleep(for: .milliseconds(delay))
            }

            state = GameEngine.advanceTurn(state)
            debugLog("executeAITurns: after advanceTurn, phase: \(state.phase), currentPlayer: \(state.currentPlayer.name), turn: \(state.turnNumber)")
        }

        if !state.isGameOver {
            state.phase = .playerTurn
            debugLog("executeAITurns: loop ended, set phase to playerTurn, currentPlayer: \(state.currentPlayer.name)")
        } else {
            debugLog("executeAITurns: loop ended, isGameOver=true")
        }
    }

    @discardableResult
    private func applyPlayerAction(_ action: GameAction) -> Bool {
        aiTask?.cancel()

        debugLog("applyPlayerAction: BEFORE apply — phase: \(state.phase), player: \(state.currentPlayer.name), turn: \(state.turnNumber)")
        let stateBeforeApply = state
        state = GameEngine.processAction(action, in: state)

        // If the engine rejected the action (returned unchanged state), don't advance turn
        // .pass is a deliberate no-op that should still advance the turn
        if state == stateBeforeApply, action != .pass {
            debugLog("applyPlayerAction: action was REJECTED by engine, not advancing turn")
            toast = ToastConfig(message: "操作无效", style: .error)
            feedback.onError()
            return false
        }

        feedback.onAction(action)

        state = GameEngine.advanceTurn(state)
        claimedNobleThisTurn = false
        debugLog("applyPlayerAction: after advanceTurn — phase: \(state.phase), currentPlayer: \(state.currentPlayer.name), turn: \(state.turnNumber)")

        if case .purchaseCard(let card, _) = action {
            purchasingCardId = card.id
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(400))
                self?.purchasingCardId = nil
            }
        }

        saveState()

        if state.isGameOver {
            feedback.onPhaseChange(.gameEnded)
            return true
        }

        if !state.currentPlayer.isHuman {
            aiTask = Task {
                await executeAITurns()
            }
        }

        return true
    }

    // MARK: - Projected State

    var projectedPurse: CoinPurse? {
        guard let card = selectedCard else { return nil }
        guard let payment = state.currentPlayer.purse.coinsToPay(card.cost, with: state.currentPlayer.cardCounts) else { return nil }
        return state.currentPlayer.purse.paying(payment)
    }

    var isAIThinking: Bool {
        phase == .aiThinking
    }

    var phase: GamePhase { state.phase }

    /// Human-readable summary of available actions
    var actionHint: String {
        let actions = GameEngine.legalActions(in: state)
        let coinCount = actions.filter { if case .takeCoins = $0 { return true } else { return false } }.count
        let purchaseCount = actions.filter { if case .purchaseCard = $0 { return true } else { return false } }.count
        if purchaseCount > 0 { return "可购买 \(purchaseCount) 张卡" }
        if coinCount > 0 { return "可拿取宝石" }
        if state.currentPlayer.canReserveMore { return "可保留卡牌" }
        return "选择操作"
    }

    // MARK: - Computed Properties

    var canTakeCoins: Bool {
        !state.currentPlayer.hasCoinsAtLimit && state.phase == .playerTurn
    }

    func canClaimNoble(_ noble: PointCard) -> Bool {
        (humanPlayer ?? state.currentPlayer).canAttract(noble)
    }

    func player(id: UUID) -> PlayerState? {
        state.players.first { $0.id == id }
    }

    var opponentPlayers: [PlayerState] {
        state.players.filter { !$0.isHuman }
    }

    var humanPlayer: PlayerState? {
        state.players.first { $0.isHuman }
    }

    func canTakeDouble(_ color: GemColor) -> Bool {
        color.isGemColor && state.tableCoins[color] >= 4
    }

    /// Whether the player has no valid actions and should see a pass button
    var canPass: Bool {
        guard state.phase == .playerTurn && state.currentPlayer.isHuman else { return false }
        return selectedCard == nil && selectedReservedCard == nil && selectedNoble == nil && pendingCoinSelection.isEmpty
    }

}
