[![English](https://img.shields.io/badge/English-blue.svg)](README.md)
[![中文](https://img.shields.io/badge/中文-red.svg)](README_zh.md)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

# PokeGem 璀璨宝石

**一款精美、打磨细致的 iOS 璀璨宝石（Splendor）实现 — 获奖策略桌游的数字版。**

纯 SwiftUI，零外部依赖，247 项测试，可直接上架 App Store。

## 为什么选择 PokeGem？

璀璨宝石是最优雅的策略桌游之一。PokeGem 为 iOS 带来：

- **赌场级视觉效果** — 深紫色牌桌、金色点缀、流畅动画
- **智能 AI 对手** — 3 种难度，各有独特策略
- **精致用户体验** — 触觉反馈、VoiceOver 支持、自动存档
- **生产级质量** — 247 项测试、MVVM 架构、零依赖

## 功能特性

- 🎮 **1-4 人游戏** — 单人对战 1-3 个 AI 对手
- 🤖 **3 种 AI 难度** — 简单、普通、困难，各有独特策略
- 🎨 **8 个角色** — 小智、武藏、小次郎、火箭队等
- 💾 **自动存档** — 随时继续游戏，状态通过 UserDefaults 持久化
- 📱 **横屏模式** — 优化的 4 列布局，沉浸式体验
- ♿ **无障碍支持** — 完整的 VoiceOver 支持，逻辑清晰的导航
- 🎯 **自定义设置** — 可调目标分数（10-35）、触觉反馈开关

## 快速开始

### 前置要求

- Xcode 15.0+
- iOS 17.0+ 模拟器或设备
- macOS 14.0+（开发环境）

### 安装

```bash
git clone https://github.com/twmissingu/PokeGem.git
cd PokeGem
open PokeGem.xcodeproj
```

### 构建与运行

```bash
# 构建
xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' build

# 在模拟器运行
open -a Simulator
xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### 运行测试

```bash
# 全部测试
xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PokeGemTests

# 指定测试类
xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PokeGemTests/GameEngineTests
```

## AI Agent 指南

本项目为 AI agent 无缝交互而设计：

1. **克隆并构建**
   ```bash
   git clone https://github.com/twmissingu/PokeGem.git
   cd PokeGem
   xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' build
   ```

2. **运行测试**
   ```bash
   xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PokeGemTests
   ```

3. **项目结构**
   - `PokeGem/Models/` — 游戏逻辑（纯函数、不可变状态）
   - `PokeGem/ViewModels/` — GameViewModel（@Observable、@MainActor）
   - `PokeGem/Views/` — SwiftUI 视图（主页、游戏、设置）
   - `PokeGem/AI/` — AI 策略（简单、普通、困难）
   - `PokeGem/Utilities/` — 颜色、动画、触觉反馈
   - `PokeGemTests/` — 13 个文件，247 项测试

4. **关键模式**
   - MVVM + 纯函数引擎
   - 原子操作（先验证，无效则返回原状态）
   - 每次操作后自动存档
   - 文件通过 Xcode 同步自动包含

## 架构设计

```
SwiftUI Views → GameViewModel (@Observable) → GameEngine (纯函数)
                                                    ↕
                                              GameState (不可变)
```

**状态机**：`settings → playerTurn → aiThinking → aiExecuting → gameEnded`

## 游戏规则

### 游戏目标

成为第一个达到目标分数（默认 15 分）的玩家。

### 游戏组件

- **90 张发展卡**：分为 3 个等级，提供分数和宝石折扣
- **10 张贵族卡**：每张价值 3 分
- **宝石代币**：5 种颜色（黑、蓝、绿、红、白）+ 金色万能

### 回合动作

每回合选择一个动作：

1. **拿取宝石**
   - 3 个不同颜色的宝石
   - 或 2 个相同颜色的宝石（仅当桌上该颜色 ≥4 时）

2. **购买发展卡**
   - 支付所需宝石，获得卡牌及其折扣

3. **保留发展卡**
   - 将一张卡保留（最多 3 张）
   - 获得 1 个黄金（万能宝石）

### 胜利条件

当有玩家达到目标分数并完成当前轮次后，游戏结束，分数最高者获胜。平局决胜：分数 → 贵族 → 卡牌数。

## 技术架构

### 架构模式

```
┌─────────────────────────────────────────────────────┐
│                     SwiftUI Views                    │
│  HomeView → SettingsView → GameView → Components    │
├─────────────────────────────────────────────────────┤
│                   @Observable VM                     │
│           GameViewModel (MainActor)                  │
├─────────────────────────────────────────────────────┤
│                  Pure Functions                      │
│              GameEngine (structs)                    │
├─────────────────────────────────────────────────────┤
│                   Domain Models                      │
│  GemColor | Card | CoinPurse | PlayerState          │
└─────────────────────────────────────────────────────┘
```

### 关键技术

| 特性 | 实现 |
|------|------|
| UI 框架 | SwiftUI (iOS 17+) |
| 状态管理 | @Observable |
| 并发 | async/await + Task |
| 游戏引擎 | 纯函数 (struct) |
| AI 策略 | 协议 + 多实现 |
| 布局 | GeometryReader + 响应式 |

### 代码结构

```
PokeGem/
├── PokeGemApp.swift             # 生命周期入口
├── Models/
│   ├── GemColor.swift           # 宝石颜色枚举
│   ├── Card.swift               # 发展卡 (90张)
│   ├── PointCard.swift          # 贵族卡 (10张)
│   ├── CoinPurse.swift          # 钱包管理
│   ├── PlayerState.swift        # 玩家状态
│   ├── PlayerAvatar.swift       # 角色头像
│   ├── GameAction.swift         # 游戏动作
│   ├── GameState.swift          # 游戏状态
│   ├── GameEngine.swift         # 游戏引擎
│   └── GameArchiver.swift       # 自动存档
├── AI/
│   ├── AIStrategy.swift         # AI 协议
│   ├── EasyAIStrategy.swift     # 简单 AI
│   ├── NormalAIStrategy.swift   # 普通 AI
│   └── HardAIStrategy.swift     # 困难 AI
├── ViewModels/
│   └── GameViewModel.swift      # 游戏 VM
├── Views/
│   ├── Home/                    # 主页视图
│   ├── Settings/                # 设置视图
│   └── Game/                    # 游戏视图
└── Utilities/
    ├── Colors.swift             # 颜色工具
    ├── Extensions.swift         # 扩展
    ├── GameAnimation.swift      # 动画
    ├── GameColors.swift         # 颜色 token
    ├── GameFeedbackService.swift # 触觉反馈
    └── OrientationController.swift # 横屏控制
```

## 开发指南

### 添加新的 AI 策略

1. 创建新文件实现 `AIStrategy` 协议
2. 实现 `chooseAction(state:playerId:) async` 方法
3. 在 `GameViewModel` 中注册新策略

### 修改游戏规则

所有游戏逻辑在 `GameEngine.swift` 中，修改 `apply(_:to:)` 方法即可。

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 2.0 | 2026-04 | SwiftUI 重构版，iOS 17+ |
| 1.0 | 2017-02 | 原始 Swift 3 / UIKit 版本 |

## 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/amazing-feature`）
3. 提交更改（`git commit -m 'feat: add amazing feature'`）
4. 推送分支（`git push origin feature/amazing-feature`）
5. 创建 Pull Request

## 许可证

本项目基于 MIT 许可证开源 - 详见 [LICENSE](LICENSE) 文件。
