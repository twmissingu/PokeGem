import SwiftUI

struct SettingsView: View {
    @State private var selectedAvatar: PlayerAvatar = .ash
    @State private var playerCount: Int = 2
    @State private var difficulty: AIDifficulty = .normal
    @State private var targetScore: Int = 15
    @State private var hapticEnabled = true
    @State private var activeGameViewModel: GameViewModel?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                if horizontalSizeClass == .compact || geometry.size.height > geometry.size.width {
                    portraitContent
                } else {
                    landscapeContent
                }
            }
            .contentMargins(.top, 0, for: .scrollContent)
            .background(HomeBackground())
        }
        .navigationTitle("游戏设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: Binding(
            get: { activeGameViewModel != nil },
            set: { if !$0 { activeGameViewModel = nil } }
        )) {
            if let viewModel = activeGameViewModel {
                GameView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitContent: some View {
        VStack(spacing: 16) {
            characterSelectionSection
            difficultySection
            victorySection
            hapticSection
            startButton
        }
        .padding()
    }

    // MARK: - Landscape Layout

    private var landscapeContent: some View {
        HStack(alignment: .top, spacing: 20) {
            // Left column: Character selection
            VStack {
                characterSelectionSection
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right column: Settings + Start
            VStack(spacing: 16) {
                difficultySection
                victorySection
                hapticSection
                startButton
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }

    // MARK: - Sections

    private var characterSelectionSection: some View {
        SectionCard(title: "选择角色") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                ForEach(PlayerAvatar.allCases, id: \.self) { avatar in
                    VStack(spacing: 4) {
                        Image(avatar.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(selectedAvatar == avatar ? Color.yellow : Color.clear, lineWidth: 3)
                            )
                        Text(avatar.displayName)
                            .font(.caption2)
                            .foregroundStyle(selectedAvatar == avatar ? .yellow : .white.opacity(0.6))
                    }
                    .scaleEffect(selectedAvatar == avatar ? 1.1 : 1.0)
                    .grayscale(selectedAvatar == avatar ? 0 : 0.4)
                    .shadow(color: selectedAvatar == avatar ? .yellow.opacity(0.5) : .clear, radius: 6)
                    .animation(.spring(response: 0.25), value: selectedAvatar)
                    .onTapGesture { selectedAvatar = avatar }
                }
            }

            Stepper("AI 对手数量: \(playerCount)", value: $playerCount, in: 1...3)
                .foregroundStyle(.white)
                .tint(.yellow)
        }
    }

    private var difficultySection: some View {
        SectionCard(title: "难度设置") {
            Picker("AI 难度", selection: $difficulty) {
                ForEach(AIDifficulty.allCases, id: \.self) { diff in
                    Text(diff.displayName).tag(diff)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var victorySection: some View {
        SectionCard(title: "胜利条件") {
            Stepper("目标分数: \(targetScore)", value: $targetScore, in: 10...35, step: 5)
                .foregroundStyle(.white)
                .tint(.yellow)
            Text("首先达到目标分数并完成当前轮次的玩家获胜")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(timeEstimate)
                .font(.caption)
                .foregroundStyle(.yellow.opacity(0.7))
        }
    }

    private var timeEstimate: String {
        switch targetScore {
        case 10...15: return "快速局 (~15分钟)"
        case 20...25: return "标准局 (~25分钟)"
        default: return "持久战 (~40分钟)"
        }
    }

    private var hapticSection: some View {
        SectionCard(title: "游戏体验") {
            Toggle("触觉反馈", isOn: $hapticEnabled)
                .foregroundStyle(.white)
                .tint(.yellow)
        }
    }

    private var startButton: some View {
        PrimaryButton(title: "开始游戏", icon: "play.fill") {
            startGame()
        }
    }

    private func startGame() {
        let aiAvatars = PlayerAvatar.randomAvatars(count: playerCount, excluding: [selectedAvatar])
        let difficulties = mixedDifficulties(base: difficulty, count: playerCount)
        let config = GameConfig(
            humanPlayerAvatar: selectedAvatar,
            robotAvatars: aiAvatars,
            robotDifficulties: difficulties,
            targetScore: targetScore,
            hapticEnabled: hapticEnabled
        )
        activeGameViewModel = GameViewModel(config: config)
    }

    /// Generate varied difficulties: first AI uses selected difficulty,
    /// subsequent AIs step down (hard→normal→easy) for variety
    private func mixedDifficulties(base: AIDifficulty, count: Int) -> [AIDifficulty] {
        let all = AIDifficulty.allCases
        guard let baseIndex = all.firstIndex(of: base) else {
            return Array(repeating: base, count: count)
        }
        return (0..<count).map { i in
            all[max(0, baseIndex - i)]
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
