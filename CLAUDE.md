# PokeGem

iOS implementation of Splendor (璀璨宝石). SwiftUI, iOS 17+, landscape-only, zero external dependencies.

## Build & Test

```bash
xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PokeGemTests
```

Specific test class or method:
```
-only-testing:PokeGemTests/GameEngineTests
-only-testing:PokeGemTests/GameEngineTests/setupCreatesCorrectPlayers
```

- **247 tests** across 12 files, Swift Testing (`@Test` / `#expect`), no XCTest
- Files auto-included via `PBXFileSystemSynchronizedRootGroup` — add `.swift` files to existing directories, no project file edits needed
- No CI, no pre-commit hooks, no formatter — all verification via `xcodebuild`

## Architecture

**Entrypoint**: `PokeGem/PokeGemApp.swift` (inside `PokeGem/` source dir) → `HomeView` (inside NavigationStack)

```
HomeView → SettingsView → GameView
                  ↕ (NavigationStack)
           RuleView, CreditsView
```

**MVVM with pure-function engine**:

```
SwiftUI Views → GameViewModel (@Observable, @MainActor) → GameEngine (static pure funcs)
                                                            ↕
                                                      GameState (value type, immutable)
```

**State machine**: `settings → playerTurn → aiThinking → aiExecuting → gameEnded`

Noble claiming is automatic via `autoClaimNobles` (not a discrete phase). Win condition triggers game end during `advanceTurn` — standard Splendor round-completion rule.

**Key patterns**:
- **Atomic actions**: `GameEngine.apply(_:to:)` validates first, returns original state if invalid — no partial updates
- **Auto-save**: `GameArchiver` persists state via `UserDefaults` + `Codable` after every action
- **AI**: `AIStrategy` protocol (`Sendable`), runs in `Task` with cancellation support. Speed: 1×/2×/4×/8× via `aiSpeedMultiplier`
- **Haptics**: `GameFeedbackService` dispatches `UIImpactFeedbackGenerator` per action type
- **Layout**: `LayoutMetrics` struct (in `TableBackground.swift`) computes all sizes dynamically per device
- **Landscape-only**: 4-column layout (AI | Cards | Gems | Nobles), bottom bar 60-80pt

## Project Layout

```
PokeGem.xcodeproj
├── PokeGem/                    # Source code
│   ├── Models/             # GameState, GameEngine (pure funcs), GameAction, PlayerState,
│   │                       # Card (90 cards DB), PointCard (10 nobles DB), CoinPurse,
│   │                       # GemColor, PlayerAvatar (8 chars), GameArchiver
│   ├── ViewModels/         # GameViewModel (+ToastConfig, CardActionMode)
│   ├── Views/Home/         # HomeView, HomeBackground, RuleView, CreditsView
│   ├── Views/Game/         # GameView (landscape-only), Components, TableBackground,
│   │                       # ToastModifier, PlayerDetailView, RuleOverlayView
│   ├── Views/Settings/     # SettingsView
│   ├── AI/                 # AIStrategy + Easy/Normal/Hard implementations
│   └── Utilities/          # Colors, Extensions, GameFeedbackService
├── PokeGemTests/           # 12 test files, 247 tests
└── docs/
```

## Player Avatars (8)

| Enum Case | Name | Default AI |
|-----------|------|------------|
| `.ash` | 小智 | Human |
| `.jessie` | 武藏 | Easy |
| `.james` | 小次郎 | Normal |
| `.teamRocket` | 火箭队 | Hard |
| `.misty`, `.brock`, `.gary`, `.oak` | — | Random fill |

Asset names match enum raw values: `avatar_ash`, `avatar_misty`, etc. `PlayerAvatar.humanAvatar()` returns `.ash`, `robotAvatar(difficulty:)` returns mapped default.

## Adding Features

- **New game rule**: add private static method in `GameEngine`, wire into `apply(_:to:)` switch, add test
- **New AI difficulty**: create file implementing `AIStrategy`, register in `GameViewModel.init` switch
- **New view**: add `.swift` file to existing `Views/` subdirectory — auto-included by Xcode sync

## Game Rules Quick Reference

- **Players**: 1 human + 1-3 AI (2-4 total)
- **Coins**: 4/5/7 per color (2/3/4 players) + 5 gold. Cap: 10/player
- **Actions**: take 3 different colors, 2 same color (table ≥4), or 1 single. Reserve (max 3) gives gold if available. Purchase/repay uses card discounts + gold wildcard
- **Nobles**: manually claimed when card color requirements met. 1 per turn
- **Win**: target score → complete the round. Tiebreak: points → nobles → cards

## 行为准则

### 核心原则

首要目标是"少犯错"，而非"表现得更聪明"。宁可保守，不可冒险。

### 禁令规则

1. **NEVER 凭记忆或猜测编辑文件** — 必须先读取文件内容，确认理解后再动笔。改文章前，先复述原文要点，经确认后再改。
2. **NEVER 添加未要求的内容** — 只给用户问的东西，不要"顺便"补充。
3. **NEVER 为不可能发生的情况做预防性处理** — 过早抽象是混乱的根源。三处重复好过一个"通用框架"。
4. **NEVER 在子任务结果未知时编造或预测进展** — 不知道就说"不知道，需要进一步检查"。
5. **NEVER 将理解工作外包** — 必须先消化信息，再给子任务明确方向，给足上下文。
6. **NEVER 扩大授权范围** — 每次授权仅对当次、当个对象有效，没有永久授权。
7. **NEVER 在没读源文件的情况下说"看起来没问题"** — 没检查就没有发言权。

### 汇报规范

- 没做好就说没做好，附具体哪里没做好、卡在哪里。
- 做好了就不要额外免责。
- 目标：准确报告，不是防御性报告。

### 沟通格式

- 能用一句话说清的，不准说三句。
- 先说结论，再说理由。
- 不准用冒号作为句子开头的连接符号。
- 不准在回复末尾加总结性废话。

### 子任务分配规范

每条描述必须包含：做什么、为什么、排除了什么。格式："做X，因为需要Y，不包含Z。"

### 自检机制

每次给出重要输出前，内部执行一次反驳检查：结论有没有证据支撑？有没有遗漏的边界情况？自检发现问题时，直接修正输出。

### 信息加载策略

先告知工具名称和用途，等用户决定使用时再给详细说明。信息按需给、用到再给。

### 工具使用限制

- 调用工具时要说明理由。
- 不准连续调用超过3个工具而不中途汇报进展。
- 工具返回异常结果时，立即停止并报告。

### 规则优先级

禁令规则优先级最高。根据当前任务类型激活对应模块，不相关的规则不需要额外关注。
