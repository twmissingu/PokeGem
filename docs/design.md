# PokeGem 技术设计文档

> **Scope**: 架构设计、数据流、关键技术决策和 API 参考 — 描述 app"如何构建"。
> 产品需求见 [requirements.md](requirements.md)，横屏布局设计详情见 [landscape-layout-v2.md](landscape-layout-v2.md)。

## 1. 架构设计

### 1.1 MVVM + 纯函数引擎

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   SwiftUI   │────▶│  ViewModel   │────▶│   Engine    │
│    Views    │◀────│  (@Observable)│◀────│ (Pure Funcs)│
└─────────────┘     └──────────────┘     └─────────────┘
                           │                    │
                           ▼                    ▼
                    ┌──────────────┐     ┌─────────────┐
                    │  UI State    │     │  GameState  │
                    │ (selections, │     │ (immutable) │
                    │  errors)     │     │             │
                    └──────────────┘     └─────────────┘
```

### 1.2 数据流

```
User Action → GameViewModel.applyPlayerAction(action)
             → GameEngine.apply(action, state)
             → Returns new GameState
             → GameEngine.autoClaimNobles(in: state)
             → GameEngine.checkWinCondition(state)
             → GameEngine.advanceTurn(state)
             → GameArchiver.save(state, config)
             → ViewModel updates @Observable state
             → SwiftUI re-renders
```

### 1.3 状态机

```
playerTurn → aiThinking → aiExecuting → autoClaiming → roundComplete
     ↑                                                       │
     └───────────────────────────────────────────────────────┘

gameEnded (when win condition met at round end during advanceTurn)
```

注意：`settings` 不是 GamePhase — 配置在 SettingsView 中完成，进入游戏时调用 `GameEngine.setup(config:)` 创建初始状态。`settings` 阶段不存在于 GameState 中。

## 2. 核心设计决策

### 2.1 不可变游戏状态

- `GameState` 是值类型（struct），所有修改返回新实例
- `GameEngine` 只包含静态纯函数
- 原子操作：验证优先，成功才修改状态（validate-then-mutate）

### 2.2 观察者模式

- 使用 iOS 17 `@Observable` 宏
- ViewModel 是 `@MainActor` 类
- SwiftUI 自动响应状态变化

### 2.3 AI 并发

- AI 回合通过 `Task` 异步执行，保存 task 引用以支持取消
- 策略实现 `AIStrategy` 协议（Sendable）
- 人工延迟模拟思考时间（300ms / speedMultiplier）
- 支持 1×/2×/4×/8× 四档速度

### 2.4 自动存档

- `GameArchiver` 使用 `UserDefaults + JSONEncoder` 序列化 GameState + GameConfig
- 每次玩家和 AI 行动后自动保存
- 游戏结束后自动清除存档
- 主页检测 `GameArchiver.hasSavedGame` 显示"继续游戏"按钮

## 3. 文件结构

```
PokeGem.xcodeproj
├── PokeGem/                          # Source code
│   ├── PokeGemApp.swift              # @main 入口
│   ├── Models/                       # 数据模型和游戏引擎
│   │   ├── GameState.swift           # 完整游戏状态（+ GamePhase, GameConfig）
│   │   ├── GameEngine.swift          # 纯函数游戏逻辑
│   │   ├── GameAction.swift          # 玩家动作枚举
│   │   ├── PlayerState.swift         # 玩家状态
│   │   ├── Card.swift                # 发展卡（90张卡片数据库）
│   │   ├── PointCard.swift           # 贵族卡（10张卡片数据库）
│   │   ├── CoinPurse.swift           # 宝石钱包（O(1)字典实现）
│   │   ├── GemColor.swift            # 宝石颜色枚举（含显示名+颜色映射）
│   │   ├── PlayerAvatar.swift        # 玩家头像枚举（8个宝可梦角色）
│   │   └── GameArchiver.swift        # 自动存档（UserDefaults + Codable）
│   ├── ViewModels/                   # 视图模型
│   │   └── GameViewModel.swift       # 游戏主视图模型（+ ToastConfig, CardActionMode）
│   ├── Views/                        # SwiftUI 视图
│   │   ├── Home/                     # 主页
│   │   │   ├── HomeView.swift        # 主页（标题+菜单按钮+响应式布局）
│   │   │   ├── HomeBackground.swift  # 深色赌场背景（+ 浮动宝石粒子动画）
│   │   │   ├── RuleView.swift        # 完整游戏规则页
│   │   │   └── CreditsView.swift     # 制作人员页
│   │   ├── Game/                     # 游戏界面
│   │   │   ├── GameView.swift        # 主游戏视图（含横竖屏布局切换）
│   │   │   ├── Components.swift      # 共享UI组件（ScoreBadge, CasinoButton, SectionCard 等）
│   │   │   ├── TableBackground.swift # 深色赌桌背景 + LayoutMetrics
│   │   │   ├── ToastModifier.swift   # Toast 通知系统
│   │   │   ├── PlayerDetailView.swift# 玩家详情页
│   │   │   └── RuleOverlayView.swift # 初学引导浮层
│   │   └── Settings/                 # 设置界面
│   │       └── SettingsView.swift    # 游戏配置（角色/AI/难度/分数）
│   ├── AI/                           # AI 策略
│   │   ├── AIStrategy.swift          # 策略协议 + AIDifficulty 枚举
│   │   ├── EasyAIStrategy.swift      # 简单：随机选择
│   │   ├── NormalAIStrategy.swift    # 普通：贪心策略
│   │   └── HardAIStrategy.swift      # 困难：启发式评估
│   ├── Utilities/                    # 工具函数
│   │   ├── Colors.swift              # 颜色扩展
│   │   ├── Extensions.swift          # 数组/字典/View/Int 扩展
│   │   └── GameFeedbackService.swift # 触觉反馈服务
│   └── Assets.xcassets/              # 图片资源（卡牌、宝石、头像）
├── PokeGemTests/                     # 247 个单元测试（Swift Testing）
├── PokeGemUITests/                   # UI 测试（boilerplate）
└── docs/                             # 需求文档、技术设计、游戏规则
```

## 4. 关键接口

### 4.1 GameEngine

```swift
struct GameEngine {
    static func setup(config: GameConfig) -> GameState
    static func apply(_ action: GameAction, to state: GameState) -> GameState
    static func legalActions(for playerIndex: Int?, in state: GameState) -> [GameAction]
    static func advanceTurn(_ state: GameState) -> GameState
    static func autoClaimNobles(in state: GameState) -> GameState
    static func checkWinCondition(_ state: GameState) -> GameState
    static func isValidCoinTake(_ coins: [GemColor: Int], in state: GameState) -> Bool
    static func isCardOnTable(_ card: Card, in state: GameState) -> Bool
    static func coinCountForPlayers(_ playerCount: Int) -> Int
}
```

### 4.2 AIStrategy

```swift
protocol AIStrategy: Sendable {
    var difficulty: AIDifficulty { get }
    func chooseAction(state: GameState, playerId: UUID) async -> GameAction
}

enum AIDifficulty: String, CaseIterable, Codable {
    case easy   // 简单 - 随机选择
    case normal // 普通 - 贪心策略
    case hard   // 困难 - 启发式评估
}
```

### 4.3 CoinPurse

```swift
struct CoinPurse: Hashable, Codable {
    // 查询
    subscript(color: GemColor) -> Int
    var total: Int { get }
    var goldCount: Int { get }
    var isAtLimit: Bool { get }
    var remainingCapacity: Int { get }

    // 支付
    func canPay(_ cost: [GemColor: Int], with discounts: [GemColor: Int]) -> Bool
    func canPayExact(_ cost: [GemColor: Int]) -> Bool
    func coinsToPay(_ cost: [GemColor: Int], with discounts: [GemColor: Int]) -> [GemColor: Int]?
    func paying(_ cost: [GemColor: Int], with discounts: [GemColor: Int]) -> CoinPurse?

    // 修改
    mutating func add(_ color: GemColor, count: Int)
    mutating func add(_ additions: [GemColor: Int])
    @discardableResult mutating func remove(_ color: GemColor, count: Int) -> Bool
    @discardableResult mutating func remove(_ removals: [GemColor: Int]) -> Bool
}
```

### 4.4 GameArchiver

```swift
struct GameArchiver {
    static func save(state: GameState, config: GameConfig)
    static func load() -> ArchivedGame?
    static func clear()
    static var hasSavedGame: Bool { get }
}
```

### 4.5 GameViewModel 精选接口

```swift
@Observable @MainActor
class GameViewModel {
    var state: GameState
    var config: GameConfig
    var selectedCard: Card?
    var selectedCardMode: CardActionMode?
    var pendingCoinSelection: [GemColor: Int]
    var aiThinkingPlayerId: UUID?
    var toast: ToastConfig?
    var purchasingCardId: Int?
    var aiSpeedMultiplier: Double
    var feedback: GameFeedbackService

    // 核心方法
    func selectCoin(_ color: GemColor)          // 点选宝石（0→1→2→0 循环）
    func confirmCoinSelection()                  // 确认拿宝石
    func selectCard(_ card: Card)                // 选择卡牌
    func purchaseSelectedCard()                  // 购买选中卡牌
    func reserveSelectedCard()                   // 保留选中卡牌
    func repaySelectedCard()                     // 偿还保留卡
    func selectNoble(_ noble: PointCard)         // 选择贵族
    func cancelAction()                          // 取消当前操作
    func saveState()                             // 手动存档
    func restart()                               // 重新开始
}
```

## 5. 横屏布局关键组件

### 5.1 LayoutMetrics（TableBackground.swift）

动态布局度量，根据设备尺寸和方向计算所有 UI 元素大小：

| 属性 | 竖屏 | 横屏 |
|------|------|------|
| cardWidth | 动态计算 | 动态计算（landscapeCardWidth） |
| cardHeight | width × 1.42 | landscapeCardWidth × 1.42 |
| bottomBarHeight | 90-110pt | 72-96pt |
| aiPlayerAreaWidth | 72-100pt | 同竖屏 |
| rightPanelWidth | 85-130pt | 100-180pt（landscapeRightPanelWidth） |
| gemButtonSize | 30-48pt | 同竖屏（横屏使用 CoinsColumn 组件） |

### 5.2 横屏专用视图组件

- `RightPanelLandscape` — 右侧双列面板（宝石列 | 贵族列）
- `CoinsColumn` — 桌面宝石竖列（含选中态和 ×2 提示）
- `NoblesColumn` — 贵族卡竖列
- `bottomBarLandscape` — 精简底部操作栏
- `aiPlayersColumnLandscape` — 左侧 AI 面板 + 卡堆余量
- `cardRowLandscape` / `cardTableAreaLandscape` — 横屏卡牌区域
