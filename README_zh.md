[![English](https://img.shields.io/badge/English-blue.svg)](README.md)
[![中文](https://img.shields.io/badge/中文-red.svg)](README_zh.md)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

# PokeGem

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
   - `PokeGemTests/` — 12 个文件，247 项测试

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

- **玩家**：1 个人类 + 1-3 个 AI（共 2-4 人）
- **宝石**：每色 4/5/7 枚（2/3/4 人）+ 5 枚黄金。上限：10/人
- **操作**：拿 3 枚不同色、2 枚同色（桌上有 ≥4）、或 1 枚。保留（最多 3 张）可获得黄金。购买使用卡牌折扣 + 黄金万能
- **贵族**：满足卡牌颜色要求时手动招募。每回合 1 次
- **胜利**：达到目标分数 → 完成当前轮次。平局决胜：分数 → 贵族 → 卡牌数

## 贡献指南

1. Fork 本仓库
2. 创建功能分支（`git checkout -b feature/amazing-feature`）
3. 提交更改（`git commit -m 'feat: add amazing feature'`）
4. 推送分支（`git push origin feature/amazing-feature`）
5. 创建 Pull Request

## 许可证

本项目基于 MIT 许可证开源 - 详见 [LICENSE](LICENSE) 文件。

## 致谢

- [Splendor（璀璨宝石）](https://www.spacecowboys.fr/splendor) by Space Cowboys — 原版桌游
- SwiftUI 社区的灵感和最佳实践
