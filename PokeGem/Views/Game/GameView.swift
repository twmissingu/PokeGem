//
//  GameView.swift
//  PokeGem
//
//  Redesigned casino-style game screen
//  Inspired by Splendor screenshot - dark purple felt, compact info, rich visuals
//

import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let viewModel: GameViewModel
    @State private var selectedPlayer: PlayerState?
    @State private var showRuleGuide = !UserDefaults.standard.bool(forKey: "hasSeenRuleGuide")
    @State private var turnPulse = false

    private var isMyTurn: Bool {
        viewModel.phase == .playerTurn && (viewModel.humanPlayer ?? viewModel.state.currentPlayer).isHuman
    }

    var body: some View {
        ZStack {
            // Force ZStack to fill full screen — critical for fullScreenCover without NavigationStack
            Color.clear.ignoresSafeArea()

            Group {
                if viewModel.state.isGameOver {
                    GameOverView(viewModel: viewModel)
                } else {
                    casinoLayout
                }
            }
            .background(TableBackground())

            // Manual close button — top-right to avoid overlapping AI players
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.saveState()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("关闭游戏")
                    .padding(.trailing, 0)
                    .padding(.top, 2)
                }
                Spacer()
            }
        }
        .onAppear {
            OrientationController.shared.lockToLandscape()
        }
        .onDisappear {
            viewModel.saveState()
            OrientationController.shared.unlock()
        }
        .overlay {
            if showRuleGuide {
                RuleOverlayView(isPresented: $showRuleGuide)
            }
        }
        .sheet(item: $selectedPlayer) { player in
            PlayerDetailView(
                isPresented: Binding(
                    get: { selectedPlayer != nil },
                    set: { if !$0 { selectedPlayer = nil } }
                ),
                player: player
            )
        }
        .modifier(ToastModifier(toast: Binding(
            get: { viewModel.toast },
            set: { viewModel.toast = $0 }
        )))
    }
    
    // MARK: - Main Casino Layout
    
    private var casinoLayout: some View {
        GeometryReader { geometry in
            let lm = LayoutMetrics(
                size: geometry.size,
                horizontalSizeClass: horizontalSizeClass,
                nobleCount: viewModel.state.availableNobles.count
            )

            VStack(spacing: 0) {
                cardTableAreaLandscape(lm: lm)
                bottomBarLandscape(lm: lm)

                // 回合指示器（dock下方）
                if isMyTurn {
                    Text("你的回合")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .scaleEffect(turnPulse ? 1.08 : 1.0)
                        .animation(GameAnimation.highlightPulse, value: turnPulse)
                        .onAppear { turnPulse = true }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    
    private func cardBackPlaceholder(level: Int, lm: LayoutMetrics, deckCount: Int = 0) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.black.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(levelBorderColor(level).opacity(0.4), lineWidth: 1.5)
            )
            .overlay(
                Text("\(deckCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(deckCount <= 3 ? Color.red.opacity(0.8) : Color.white.opacity(0.5))
            )
            .frame(width: lm.landscapeCardWidth, height: lm.landscapeCardHeight)
    }
    
    private func levelBorderColor(_ level: Int) -> Color {
        switch level {
        case 1: return GameColors.level1Border
        case 2: return GameColors.level2Border
        case 3: return GameColors.level3Border
        default: return .gray
        }
    }
    
    
    // MARK: - Landscape Layout
    
    private func cardTableAreaLandscape(lm: LayoutMetrics) -> some View {
        HStack(alignment: .top, spacing: lm.interAreaGap) {
            // Left: AI players
            aiPlayersColumnLandscape(lm: lm)
                .frame(width: lm.aiPlayerAreaWidth)
                .frame(maxHeight: lm.landscapeTableHeight)
                .accessibilitySortPriority(1)

            // Center: Card grid (3 rows × 4 cards)
            VStack(spacing: lm.landscapeCardRowSpacing) {
                let l3Cards = viewModel.state.cardsByLevel[2]
                let l2Cards = viewModel.state.cardsByLevel[1]
                let l1Cards = viewModel.state.cardsByLevel[0]
                let l3Deck = viewModel.state.deckCount(for: 3)
                let l2Deck = viewModel.state.deckCount(for: 2)
                let l1Deck = viewModel.state.deckCount(for: 1)

                if !l3Cards.isEmpty || l3Deck > 0 {
                    cardRowLandscape(level: 3, cards: l3Cards, lm: lm)
                }
                if !l2Cards.isEmpty || l2Deck > 0 {
                    cardRowLandscape(level: 2, cards: l2Cards, lm: lm)
                }
                if !l1Cards.isEmpty || l1Deck > 0 {
                    cardRowLandscape(level: 1, cards: l1Cards, lm: lm)
                }
            }
            .frame(width: lm.landscapeCardsAreaWidth)
            .accessibilitySortPriority(3)
            .overlay(alignment: .topTrailing) {
                if viewModel.isAIThinking {
                    Button(action: {
                        viewModel.aiSpeedMultiplier = min(viewModel.aiSpeedMultiplier * 2, 8)
                    }) {
                        HStack(spacing: 2) {
                            Text("快进")
                            Text("\(Int(viewModel.aiSpeedMultiplier))×")
                                .foregroundStyle(.yellow)
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(minWidth: 44, minHeight: 32)
                        .padding(.horizontal, 6)
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(4)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.aiSpeedMultiplier) // Fast feedback for speed button
                }
            }
            .frame(maxHeight: .infinity)

            // Right: Gems column
            gemsColumnLandscape(lm: lm)
                .frame(width: lm.landscapeGemAreaWidth, height: lm.landscapeTableHeight)
                .accessibilitySortPriority(2)

            // Far right: Nobles column
            noblesColumnLandscape(lm: lm)
                .frame(width: lm.landscapeNobleAreaWidth, height: lm.landscapeTableHeight)
                .accessibilitySortPriority(1)
        }
        .padding(.horizontal, lm.landscapeHorizontalPadding)
    }
    
    private func cardRowLandscape(level: Int, cards: [Card], lm: LayoutMetrics) -> some View {
        let deckCount = viewModel.state.deckCount(for: level)
        let displayCards = Array(cards.prefix(4))
        return HStack(spacing: lm.landscapeCardSpacing) {
            ForEach(displayCards) { card in
                CasinoCardView(
                    card: card,
                    isAffordable: (viewModel.humanPlayer ?? viewModel.state.currentPlayer).canPurchase(card),
                    isSelected: viewModel.selectedCard?.id == card.id,
                    isBeingPurchased: viewModel.purchasingCardId == card.id,
                    cardWidth: lm.landscapeCardWidth,
                    cardHeight: lm.landscapeCardHeight,
                    action: {
                        viewModel.selectCard(card)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            if deckCount > 0 {
                ForEach(displayCards.count..<4, id: \.self) { _ in
                    cardBackPlaceholder(level: level, lm: lm, deckCount: deckCount)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .frame(height: lm.landscapeCardHeight)
        .animation(GameAnimation.cardRowChange, value: cards.map(\.id))
    }
    
    // MARK: - Landscape Left Panel (AI Players + Card Stacks)
    
    private func aiPlayersColumnLandscape(lm: LayoutMetrics) -> some View {
        let aiPlayers = viewModel.state.players.filter { !$0.isHuman }
        
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            ForEach(aiPlayers) { player in
                AIPlayerCompactCard(
                    player: player,
                    avatarSize: lm.landscapeAvatarSize,
                    isThinking: viewModel.aiThinkingPlayerId == player.id,
                    cardWidth: lm.aiPlayerAreaWidth - 4,
                    onTap: { selectedPlayer = player }
                )
            }
            Spacer(minLength: 0)
        }
        .frame(width: lm.aiPlayerAreaWidth)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Landscape Gems Column (independent column)

    private func gemsColumnLandscape(lm: LayoutMetrics) -> some View {
        CoinsColumn(
            tableCoins: viewModel.state.tableCoins,
            pendingSelection: viewModel.pendingCoinSelection,
            canTakeCoins: viewModel.canTakeCoins,
            canTakeDouble: { viewModel.canTakeDouble($0) },
            canSelectGem: { viewModel.canSelectGem($0) },
            onTap: { viewModel.selectCoin($0) },
            coinSize: lm.landscapeGemSize
        )
    }

    // MARK: - Landscape Nobles Column (independent column)

    private func noblesColumnLandscape(lm: LayoutMetrics) -> some View {
        NoblesColumn(
            nobles: viewModel.state.availableNobles,
            onTap: { viewModel.selectNoble($0) },
            nobleSize: lm.landscapeNobleSize,
            claimedThisTurn: viewModel.claimedNobleThisTurn
        )
    }
    
    // MARK: - Landscape Bottom Bar (Two-Row Redesigned)

    private func bottomBarLandscape(lm: LayoutMetrics) -> some View {
        let player = viewModel.humanPlayer ?? viewModel.state.currentPlayer
        return HStack(spacing: 12) {
            // Left: Player Info (Avatar + Name + Score + Turn indicator)
            HStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    AvatarView(
                        player: player,
                        size: 42,
                        showBorder: true
                    )
                    .onTapGesture { selectedPlayer = player }

                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                    ScoreBadge(value: player.totalPoints, icon: "star.fill")
                }
            }
            .frame(width: 130, alignment: .leading)

            // Center: Gem Summary (single row, discount + gems in each badge)
            HStack(spacing: 4) {
                VStack(spacing: 0) {
                    Text("\(player.purse.total)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("/10")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(width: 36)

                ForEach(GemColor.gemColors) { color in
                    GemSummaryBadge(
                        color: color,
                        discount: player.cardCounts[color] ?? 0,
                        gems: player.purse[color] ?? 0
                    )
                }

                GemSummaryBadge(
                    color: .gold,
                    discount: 0,
                    gems: player.purse[.gold] ?? 0
                )
            }
            .layoutPriority(1)

            // Reserved cards — larger touch targets
            if !player.reservedCards.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(player.reservedCards) { card in
                            Button { viewModel.selectReservedCard(card) } label: {
                                HStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(card.color.associatedColor.opacity(0.6))
                                        .frame(width: 8, height: 28)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(viewModel.selectedReservedCard?.id == card.id ? Color.blue : card.color.associatedColor, lineWidth: 1.5)
                                        )

                                    VStack(spacing: 1) {
                                        if card.point > 0 {
                                            HStack(spacing: 1) {
                                                Image(systemName: "star.fill").font(.system(size: 5)).foregroundStyle(.yellow)
                                                Text("\(card.point)").font(.system(size: 6, weight: .bold)).foregroundStyle(.yellow)
                                            }
                                        }
                                        ForEach(card.cost.sorted { $0.key.rawValue < $1.key.rawValue }, id: \.key) { costColor, amount in
                                            HStack(spacing: 1) {
                                                Circle().fill(costColor.associatedColor).frame(width: 5, height: 5)
                                                Text("\(amount)")
                                                    .font(.system(size: 7, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                }
                                .frame(minHeight: 44)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(viewModel.selectedReservedCard?.id == card.id ? Color.blue.opacity(0.3) : Color.black.opacity(0.3))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: 140)
            }

            Spacer(minLength: 0)

            // Right: Action hint + buttons
            if let card = viewModel.selectedCard, let mode = viewModel.selectedCardMode {
                HStack(spacing: 8) {
                    switch mode {
                    case .purchase:
                        CasinoButton(title: "购买", color: .green, isHighlighted: true, action: { viewModel.purchaseSelectedCard() })
                    case .reserve:
                        CasinoButton(title: "保留", color: .blue, isHighlighted: true, action: { viewModel.reserveSelectedCard() })
                    case .cannotAfford:
                        if viewModel.state.currentPlayer.canReserveMore {
                            CasinoButton(title: "保留", color: .blue, isHighlighted: true, action: { viewModel.reserveSelectedCard() })
                        }
                    }
                    CasinoButton(title: "取消", color: .gray, action: { viewModel.cancelAction() })
                }
            } else if viewModel.selectedReservedCard != nil {
                HStack(spacing: 8) {
                    CasinoButton(title: "偿还", color: .green, isHighlighted: true, action: { viewModel.repaySelectedCard() })
                    CasinoButton(title: "取消", color: .gray, action: { viewModel.cancelAction() })
                }
            } else if viewModel.selectedNoble != nil {
                CasinoButton(title: "取消", color: .gray, action: { viewModel.cancelAction() })
            } else if !viewModel.pendingCoinSelection.isEmpty {
                HStack(spacing: 8) {
                    CasinoButton(title: "确认", color: .green, isHighlighted: true, action: { viewModel.confirmCoinSelection() })
                    CasinoButton(title: "取消", color: .gray, action: { viewModel.cancelAction() })
                }
            } else if isMyTurn {
                CasinoButton(title: "跳过", color: .gray.opacity(0.6), action: { viewModel.passTurn() })
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 0)
        .frame(height: lm.landscapeBottomBarHeight)
        .background(
            LinearGradient(
                colors: [
                    GameColors.bottomBarStart,
                    GameColors.bottomBarEnd
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [GameColors.goldAccent.opacity(0.5), GameColors.goldAccent.opacity(0.1), GameColors.goldAccent.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.6), radius: 8, y: 4)
        )
        .padding(.horizontal, lm.landscapeHorizontalPadding)
        .accessibilitySortPriority(4)
    }

}
