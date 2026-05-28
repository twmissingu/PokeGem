import SwiftUI

struct AIPlayerCompactCard: View {
    let player: PlayerState
    let avatarSize: CGFloat
    let isThinking: Bool
    let cardWidth: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(player.name)，\(player.totalPoints)分")
        .accessibilityValue("持有\(player.ownedCards.count)张卡，\(player.purse.total)枚宝石")
        .accessibilityHint(isThinking ? "正在思考" : "点击查看详情")
        .accessibilityAddTraits(.isButton)
    }

    private var cardContent: some View {
        HStack(alignment: .top, spacing: 4) {
            if avatarSize >= 36 {
                gemInfoColumns
            }
            playerInfoColumn
        }
        .padding(6)
        .background(cardBackground)
    }

    private var gemInfoColumns: some View {
        let allGems = GemColor.gemColors + [.gold]
        let row1 = Array(allGems.prefix(3))
        let row2 = Array(allGems.suffix(3))

        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(row1) { color in
                    AIGemBadge(
                        color: color,
                        discount: player.cardCounts[color] ?? 0,
                        gems: player.purse[color] ?? 0
                    )
                }
            }
            HStack(spacing: 0) {
                ForEach(row2) { color in
                    AIGemBadge(
                        color: color,
                        discount: color == .gold ? 0 : player.cardCounts[color] ?? 0,
                        gems: player.purse[color] ?? 0
                    )
                }
            }
        }
    }

    private var playerInfoColumn: some View {
        VStack(spacing: 2) {
            avatarSection
            nameSection
        }
        .frame(maxWidth: .infinity)
    }

    private var avatarSection: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                AvatarView(player: player, size: avatarSize, showBorder: true)

                if isThinking {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2.5)
                        .blur(radius: 0.5)
                        .frame(width: avatarSize + 8, height: avatarSize + 8)
                }
            }

            scoreBadge
                .offset(x: 6, y: -6)

            if isThinking {
                ThinkingIndicator()
                    .offset(x: -6, y: 6)
            }
        }
    }

    private var scoreBadge: some View {
        ZStack {
            Circle()
                .fill(GameColors.goldAccent)
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            Text("\(player.totalPoints)")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.black)
        }
    }

    private var nameSection: some View {
        Text(player.name)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(isThinking ? .yellow : .white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isThinking ? Color.yellow.opacity(0.1) : Color.black.opacity(0.25))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isThinking ? Color.yellow.opacity(0.5) : Color.yellow.opacity(0.15), lineWidth: 1)
            )
    }

}

// MARK: - AI Gem Badge (Simplified 3-row layout)

struct AIGemBadge: View {
    let color: GemColor
    let discount: Int
    let gems: Int

    private var isActive: Bool { discount > 0 || gems > 0 }

    var body: some View {
        VStack(spacing: 2) {
            // 第一行：折扣数量，没有则为"-"
            Text(discount > 0 ? "\(discount)" : "-")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(discount > 0 ? Color.yellow : .white.opacity(0.25))
                .lineLimit(1)

            // 第二行：简化版颜色圆形代表宝石
            Circle()
                .fill(color.associatedColor)
                .frame(width: 10, height: 10)

            // 第三行：持有宝石数量
            Text(gems > 0 ? "\(gems)" : "0")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(gems > 0 ? .white : .white.opacity(0.25))
                .lineLimit(1)
        }
        .frame(width: 24)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isActive ? Color.black.opacity(0.35) : Color.black.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isActive ? color.associatedColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(color.displayName)，折扣\(discount)，持有\(gems)")
    }
}
