import SwiftUI

struct GameOverView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: GameViewModel
    @State private var show = false
    @State private var actionPending = false

    var body: some View {
        ZStack {
            TableBackground()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer(minLength: 8)

                    headerSection

                    Spacer(minLength: 8)

                    leaderboardSection

                    Spacer(minLength: 6)

                    bottomSection

                    Spacer(minLength: 8)
                }
                .frame(maxHeight: geo.size.height)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            withAnimation(GameAnimation.gameOver) {
                show = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.10))
                .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 4)
                .scaleEffect(show ? 1 : 0.3)
                .rotationEffect(.degrees(show ? 0 : -15))

            Text("游戏结束")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .opacity(show ? 1 : 0)

            if let winner = viewModel.state.winner {
                Text("\(winner.name) 获胜！")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.yellow)
                    .opacity(show ? 1 : 0)
            }
        }
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        let sorted = viewModel.state.players.sorted { p1, p2 in
            if p1.totalPoints != p2.totalPoints { return p1.totalPoints > p2.totalPoints }
            if p1.pointCards.count != p2.pointCards.count { return p1.pointCards.count > p2.pointCards.count }
            return p1.ownedCards.count < p2.ownedCards.count
        }

        return VStack(spacing: 6) {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { index, player in
                let isWinner = player.id == viewModel.state.winner?.id
                HStack(spacing: 8) {
                    Text(rankText(index))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(rankColor(index))
                        .frame(width: 36, alignment: .leading)

                    AvatarView(player: player, size: 28, showBorder: isWinner)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(player.name)
                            .font(.system(size: 13, weight: isWinner ? .bold : .medium))
                            .foregroundStyle(.white)
                        HStack(spacing: 6) {
                            Label("卡\(player.ownedCards.count)", systemImage: "rectangle.stack")
                            Label("贵\(player.pointCards.count)", systemImage: "crown.fill")
                            Label("石\(player.purse.total)", systemImage: "circle.fill")
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(player.totalPoints)")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(isWinner ? .yellow : .white.opacity(0.8))
                        Text("分")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isWinner ? Color.yellow.opacity(0.12) : Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isWinner ? Color.yellow.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                )
                .opacity(show ? 1 : 0)
                .offset(y: show ? 0 : 10)
                .animation(.easeOut(duration: 0.3).delay(0.1 + Double(index) * 0.08), value: show)
            }
        }
    }

    // MARK: - Bottom Section (Stats + Fun Stats + Buttons)

    private var bottomSection: some View {
        VStack(spacing: 8) {
            // Game Stats + Fun Stats in one row
            HStack(spacing: 12) {
                gameStatsSection
                funStatsSection
            }

            actionButtons
        }
    }

    private var gameStatsSection: some View {
        HStack(spacing: 16) {
            statItem(label: "回合", value: "\(viewModel.state.turnNumber)")
            statItem(label: "目标", value: "\(viewModel.config.targetScore)")
            statItem(label: "玩家", value: "\(viewModel.config.totalPlayers)")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
        )
        .opacity(show ? 1 : 0)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.yellow)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var funStatsSection: some View {
        let players = viewModel.state.players
        let maxCardsPlayer = players.max(by: { $0.ownedCards.count < $1.ownedCards.count })
        let maxNoblesPlayer = players.max(by: { $0.pointCards.count < $1.pointCards.count })

        return VStack(alignment: .leading, spacing: 3) {
            if let collector = maxCardsPlayer, collector.ownedCards.count > 0 {
                funStatRow(icon: "rectangle.stack.fill", text: "发展卡最多：\(collector.name)（\(collector.ownedCards.count)张）")
            }
            if let diplomat = maxNoblesPlayer, diplomat.pointCards.count > 0 {
                funStatRow(icon: "crown.fill", text: "贵族卡最多：\(diplomat.name)（\(diplomat.pointCards.count)位）")
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
        .opacity(show ? 1 : 0)
    }

    private func funStatRow(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundStyle(.yellow)
            Text(text).font(.system(size: 10)).foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                actionPending = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    GameArchiver.clear()
                    viewModel.restart()
                }
            } label: {
                Label("再来一局", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.8))
                    )
                    .opacity(actionPending ? 0.6 : 1.0)
            }
            .disabled(actionPending)

            Button {
                actionPending = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    GameArchiver.clear()
                    dismiss()
                }
            } label: {
                Label("返回主页", systemImage: "house.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.8))
                    )
                    .opacity(actionPending ? 0.6 : 1.0)
            }
            .disabled(actionPending)
        }
        .frame(maxWidth: 360)
        .opacity(show ? 1 : 0)
    }

    // MARK: - Helpers

    private func rankText(_ index: Int) -> String {
        "第\(index + 1)名"
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return Color(white: 0.75)
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.3)
        default: return .white.opacity(0.4)
        }
    }
}
