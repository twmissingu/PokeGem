import SwiftUI

struct HomeView: View {
    @State private var showSettings = false
    @State private var showRules = false
    @State private var showCredits = false
    @State private var activeGameViewModel: GameViewModel?
    @State private var hasSavedGame = GameArchiver.hasSavedGame
    @State private var archiveError: String?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HomeBackground()

                if geometry.size.width > geometry.size.height {
                    landscapeContent(geometry: geometry)
                } else {
                    portraitContent
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            hasSavedGame = GameArchiver.hasSavedGame
        }
        .onAppear {
            hasSavedGame = GameArchiver.hasSavedGame
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showRules) {
            RuleView()
        }
        .navigationDestination(isPresented: $showCredits) {
            CreditsView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { activeGameViewModel != nil },
            set: { if !$0 { activeGameViewModel = nil } }
        )) {
            if let viewModel = activeGameViewModel {
                GameView(viewModel: viewModel)
            }
        }
        .alert("存档错误", isPresented: Binding(
            get: { archiveError != nil },
            set: { if !$0 { archiveError = nil } }
        )) {
            Button("开始新游戏") {
                GameArchiver.clear()
                archiveError = nil
                hasSavedGame = false
                showSettings = true
            }
            Button("确定", role: .cancel) {
                archiveError = nil
            }
        } message: {
            if let error = archiveError {
                Text(error)
            }
        }
    }

    private var portraitContent: some View {
        VStack(spacing: 28) {
            titleSection
                .padding(.top, 60)
            Spacer()
            menuButtons
            Spacer()
        }
        .padding()
    }

    private func landscapeContent(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            Spacer()

            titleSection
                .frame(width: geometry.size.width * 0.4)

            Spacer()

            VStack(spacing: 12) {
                ForEach(Array(menuButtonConfigs.enumerated()), id: \.offset) { _, config in
                    landscapeMenuButton(for: config)
                }
            }
            .frame(maxWidth: 360)
            .padding(.vertical, 20)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("PokeGem")
                .font(.system(size: horizontalSizeClass == .compact ? 40 : 52, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.35),
                            Color(red: 0.95, green: 0.70, blue: 0.10),
                            Color(red: 0.80, green: 0.55, blue: 0.05),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
                .overlay(
                    Text("PokeGem")
                        .font(.system(size: horizontalSizeClass == .compact ? 40 : 52, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white.opacity(0.25), .clear, .white.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: -1)
                )

                Text("璀璨宝石")
                    .font(.system(size: horizontalSizeClass == .compact ? 18 : 24, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.85))

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .yellow.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: horizontalSizeClass == .compact ? 110 : 140, height: 1)
                .shadow(color: .yellow.opacity(0.3), radius: 2)
        }
    }

    private var menuButtons: some View {
        VStack(spacing: 16) {
            ForEach(Array(menuButtonConfigs.enumerated()), id: \.offset) { _, config in
                menuButton(for: config)
            }
        }
    }

    private struct MenuButtonConfig {
        let title: String
        let subtitle: String
        let icon: String
        let action: () -> Void
    }

    private var menuButtonConfigs: [MenuButtonConfig] {
        var configs: [MenuButtonConfig] = []
        if hasSavedGame {
            configs.append(MenuButtonConfig(
                title: "继续游戏",
                subtitle: "Continue",
                icon: "arrow.counterclockwise.circle.fill",
                action: {
                    switch GameArchiver.loadResult() {
                    case .success(let archived):
                        activeGameViewModel = GameViewModel(config: archived.config, loadSaved: true)
                    case .failure(let error):
                        archiveError = error.errorDescription
                        hasSavedGame = false
                    }
                }
            ))
        }
        configs.append(contentsOf: [
            MenuButtonConfig(
                title: "开始游戏",
                subtitle: "Start Game",
                icon: "play.circle.fill",
                action: { showSettings = true }
            ),
            MenuButtonConfig(
                title: "游戏规则",
                subtitle: "Rules",
                icon: "book.fill",
                action: { showRules = true }
            ),
            MenuButtonConfig(
                title: "制作人员",
                subtitle: "Credits",
                icon: "person.3.fill",
                action: { showCredits = true }
            )
        ])
        return configs
    }

    private func menuButton(for config: MenuButtonConfig) -> some View {
        IconButton(
            title: config.title,
            subtitle: config.subtitle,
            icon: config.icon,
            action: config.action
        )
    }

    private func landscapeMenuButton(for config: MenuButtonConfig) -> some View {
        IconButton(
            title: config.title,
            subtitle: config.subtitle,
            icon: config.icon,
            isCompact: true,
            action: config.action
        )
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
