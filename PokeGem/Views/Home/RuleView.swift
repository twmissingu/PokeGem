import SwiftUI

struct RuleView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("游戏规则")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text("Splendor / 璀璨宝石")
                    .font(.title3)
                    .foregroundStyle(.yellow.opacity(0.8))

                // Game overview
                RuleSection(
                    title: "游戏概述",
                    content: "《PokeGem 璀璨宝石》是一款融合宝可梦元素的策略卡牌游戏。玩家扮演宝可梦世界的宝石训练家，通过收集属性宝石、购买宝可梦发展卡和吸引传说贵族来获得胜利。每张发展卡都代表一只宝可梦，拥有独特的属性加成能力。"
                )

                RuleSection(
                    title: "游戏目标",
                    content: "成为第一个达到 15 点胜利分数的玩家。分数来源于发展卡和贵族卡。"
                )

                // Gem colors
                SectionCard(title: "宝石颜色") {
                    Text("游戏包含 5 种宝石颜色，另外还有黄金作为万能宝石。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineSpacing(4)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(GemColor.gemColors) { color in
                            GemColorBadge(color: color)
                        }
                        GemColorBadge(color: .gold, label: "黄金（万能）")
                    }
                }

                // Actions
                SectionCard(title: "回合动作") {
                    Text("每回合玩家可以选择以下一个动作：")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    ActionRow(icon: "circle.hexagongrid.fill", title: "拿取宝石", description: "拿取 3 个不同颜色的宝石，或 2 个相同颜色的宝石（仅当桌上该颜色≥4 时）")
                    ActionRow(icon: "cart.fill", title: "购买发展卡", description: "支付所需宝石，购买桌上的一张发展卡")
                    ActionRow(icon: "bookmark.fill", title: "保留发展卡", description: "将一张发展卡保留起来（最多 3 张），并获得 1 个黄金")
                }

                RuleSection(
                    title: "发展卡",
                    content: "共 90 张发展卡，分为 3 个等级。每张卡提供一定的胜利分数和宝石折扣。等级越高，分数和折扣越高。"
                )

                RuleSection(
                    title: "贵族卡",
                    content: "共 10 张贵族卡，每张价值 3 分。当玩家拥有的发展卡颜色组合满足贵族卡要求时，可以自动获得该贵族卡。"
                )

                SectionCard(title: "宝可梦元素") {
                    Text("本作将经典桌游与宝可梦世界融合：")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    PokemonElementRow(icon: "flame.fill", title: "宝可梦卡牌", description: "每张发展卡代表一只宝可梦，拥有属性颜色和数值")
                    PokemonElementRow(icon: "bolt.fill", title: "属性加成", description: "拥有宝可梦卡牌后，购买同属性卡牌可享受折扣优惠")
                    PokemonElementRow(icon: "star.fill", title: "传说贵族", description: "传说宝可梦贵族会被强大的训练家吸引，自动加入队伍")
                }

                SectionCard(title: "限制") {
                    LimitRow(text: "玩家最多持有 10 个宝石")
                    LimitRow(text: "最多保留 3 张发展卡")
                }

                RuleSection(
                    title: "胜利条件",
                    content: "当有玩家达到或超过目标分数（默认 15 分），并且完成当前轮次后，游戏结束。分数最高的玩家获胜。"
                )

                Text("基于《Splendor》桌游规则改编")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.top, 20)
            }
            .padding()
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .background(TableBackground())
        .navigationTitle("游戏规则")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

// MARK: - Components

struct RuleSection: View {
    let title: String
    let content: String
    var badges: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
                .foregroundStyle(.white)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .lineSpacing(4)

            if !badges.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(badges, id: \.self) { badge in
                        Text(badge)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow.opacity(0.15))
                            .foregroundStyle(.yellow)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow.opacity(0.15), lineWidth: 1))
    }
}

struct ActionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description).font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

struct LimitRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(text).font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

struct PokemonElementRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description).font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

struct GemColorBadge: View {
    let color: GemColor
    var label: String?

    init(color: GemColor, label: String? = nil) {
        self.color = color
        self.label = label
    }

    var body: some View {
        HStack(spacing: 8) {
            if let image = UIImage(named: color.coinImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .fill(gemDisplayColor)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }

            Text(label ?? color.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
    }

    private var gemDisplayColor: Color {
        color == .white ? Color(.systemGray5) : color.associatedColor
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: position, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let width = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return (CGSize(width: width, height: currentY + lineHeight), positions)
    }
}

#Preview {
    NavigationStack {
        RuleView()
    }
}
