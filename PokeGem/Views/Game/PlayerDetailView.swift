import SwiftUI

struct PlayerDetailView: View {
    @Binding var isPresented: Bool
    let player: PlayerState

    // Match game-board card sizing
    private let cardWidth: CGFloat = 62
    private var cardHeight: CGFloat { cardWidth * 1.42 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    totalPointsSection
                    gemsSection
                    ownedCardsSection
                    reservedCardsSection
                    nobleCardsSection
                }
                .padding()
            }
            .background(TableBackground())
            .navigationTitle(player.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回") { isPresented = false }
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    private var totalPointsSection: some View {
        VStack(spacing: 6) {
            Text("总分")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
            Text("\(player.totalPoints) 分")
                .font(.title.bold())
                .foregroundStyle(.yellow)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.2), lineWidth: 1))
    }

    private var gemsSection: some View {
        SectionCard(title: nil) {
            VStack(spacing: 8) {
                Text("宝石")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 0) {
                    ForEach(GemColor.gemColors) { color in
                        gemIconWithCount(color: color, count: player.purse[color])
                    }
                    gemIconWithCount(color: .gold, count: player.purse[.gold])
                }
            }
        }
    }

    private func gemIconWithCount(color: GemColor, count: Int) -> some View {
        VStack(spacing: 4) {
            if let image = UIImage(named: color.coinImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
            } else {
                Circle()
                    .fill(color.associatedColor)
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            }
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(count > 0 ? .white : .white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
    }

    private var ownedCardsSection: some View {
        SectionCard(title: nil) {
            VStack(spacing: 8) {
                Text("发展卡 (\(player.ownedCards.count)张)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                if player.ownedCards.isEmpty {
                    Text("无")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    let grouped = Dictionary(grouping: player.ownedCards, by: { $0.color })
                    HStack(alignment: .top, spacing: 4) {
                        ForEach(GemColor.gemColors) { color in
                            if let cards = grouped[color], !cards.isEmpty {
                                cardStackColumn(cards: cards, color: color)
                            } else {
                                Color.clear.frame(width: cardWidth, height: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cardStackColumn(cards: [Card], color: GemColor) -> some View {
        let overlap = cardHeight * 2 / 3
        let totalHeight = cardHeight + CGFloat(max(0, cards.count - 1)) * overlap

        return VStack(spacing: 0) {
            ZStack(alignment: .top) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    cardImageView(for: card, color: color)
                        .offset(y: CGFloat(index) * overlap)
                }
            }
            .frame(height: totalHeight)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func cardImageView(for card: Card, color: GemColor) -> some View {
        if let image = UIImage(named: card.imageName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.associatedColor.opacity(0.3))
                .frame(width: cardWidth, height: cardHeight)
                .overlay(
                    VStack {
                        HStack {
                            if card.point > 0 {
                                Text("\(card.point)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.yellow)
                            }
                            Spacer()
                            Circle()
                                .fill(color.associatedColor)
                                .frame(width: 12, height: 12)
                        }
                        Spacer()
                    }
                    .padding(4)
                )
        }
    }

    private var reservedCardsSection: some View {
        SectionCard(title: nil) {
            VStack(spacing: 8) {
                Text("保留卡 (\(player.reservedCards.count)/3张)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                if player.reservedCards.isEmpty {
                    Text("无")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    HStack(spacing: 12) {
                        ForEach(player.reservedCards) { card in
                            cardImageView(for: card, color: card.color)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var nobleCardsSection: some View {
        SectionCard(title: nil) {
            VStack(spacing: 8) {
                Text("贵族卡 (\(player.pointCards.count)张)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                if player.pointCards.isEmpty {
                    Text("无")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    HStack(spacing: 12) {
                        ForEach(player.pointCards) { noble in
                            nobleImageView(for: noble)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func nobleImageView(for noble: PointCard) -> some View {
        if let image = UIImage(named: noble.imageName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cardWidth, height: cardWidth)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.yellow.opacity(0.15))
                .frame(width: cardWidth, height: cardWidth)
                .overlay(
                    Text("\(noble.point)分")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.yellow)
                )
        }
    }
}

#Preview {
    PlayerDetailView(
        isPresented: .constant(true),
        player: PlayerState(name: "测试玩家", isHuman: true)
    )
}
