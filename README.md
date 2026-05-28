# PokeGem 璀璨宝石

> 《Splendor 璀璨宝石》桌游的 iOS 实现 - 现代 SwiftUI 版本

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)]()
[![Swift](https://img.shields.io/badge/Swift-5.10-orange)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()

## 项目介绍

PokeGem 是一款基于经典桌游《Splendor 璀璨宝石》开发的 iOS 游戏。玩家扮演文艺复兴时期的宝石商人，通过收集宝石、购买发展卡和吸引贵族来获得胜利。

本项目最初于 2017 年使用 Swift 3 和 UIKit 开发，现已全面重构为现代 SwiftUI 应用，采用 MVVM 架构和 iOS 17+ 最新特性。

## 截图

*(待添加应用截图)*

## 功能特性

- **单人游戏**：与 2-4 个 AI 对手对战
- **三种难度**：简单（随机）、普通（贪婪策略）、困难（启发式评估）
- **现代 UI**：SwiftUI 构建，支持暗黑模式
- **响应式布局**：完美适配 iPhone 各尺寸屏幕
- **流畅体验**：AI 异步执行，不阻塞 UI

## 游戏规则

### 游戏目标

成为第一个达到 **15 分** 胜利分数的玩家。

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

当有玩家达到目标分数并完成当前轮次后，游戏结束，分数最高者获胜。

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
├── App/
│   └── PokeGemApp.swift           # 生命周期入口
├── Models/
│   ├── GemColor.swift             # 宝石颜色枚举
│   ├── Card.swift                 # 发展卡 (90张)
│   ├── PointCard.swift            # 贵族卡 (10张)
│   ├── CoinPurse.swift            # 钱包管理
│   ├── PlayerState.swift          # 玩家状态
│   ├── GameAction.swift           # 游戏动作
│   ├── GameState.swift            # 游戏状态
│   └── GameEngine.swift           # 游戏引擎
├── AI/
│   ├── AIStrategy.swift           # AI 协议
│   ├── EasyAIStrategy.swift       # 简单 AI
│   ├── NormalAIStrategy.swift     # 普通 AI
│   └── HardAIStrategy.swift       # 困难 AI (新增)
├── ViewModels/
│   ├── GameViewModel.swift        # 游戏 VM
│   ├── SettingsViewModel.swift    # 设置 VM
│   └── HomeViewModel.swift        # 主页 VM
├── Views/
│   ├── Home/                      # 主页视图
│   ├── Settings/                  # 设置视图
│   └── Game/                      # 游戏视图
└── Utilities/
    └── Extensions.swift           # 扩展
```

## 安装与构建

### 系统要求

- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 5.10+

### 构建步骤

1. 克隆仓库
```bash
git clone https://github.com/twmissingu/PokeGem.git
cd PokeGem
```

2. 打开项目
```bash
open PokeGem.xcodeproj
```
*(注：需要创建 Xcode 项目文件，或从 Xcode 打开目录)*

3. 选择模拟器或真机，点击运行 (⌘R)

### 命令行构建

```bash
# 构建项目
xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 15' build

# 运行测试
xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 开发指南

### 添加新的 AI 策略

1. 创建新文件实现 `AIStrategy` 协议
2. 实现 `chooseAction(state:playerId:) async` 方法
3. 在 `GameViewModel` 中注册新策略

### 修改游戏规则

所有游戏逻辑在 `GameEngine.swift` 中，修改 `apply(_:to:)` 方法即可。

### 自定义 UI

视图组件使用 SwiftUI 构建，支持通过修改颜色方案和布局参数来自定义。

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 2.0 | 2026-04 | SwiftUI 重构版，iOS 17+ |
| 1.0 | 2017-02 | 原始 Swift 3 / UIKit 版本 |

## 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 致谢

- **Space Cowboys** - 《Splendor》桌游原作者
- **詹廷蔚 (Zhan Tingwei)** - 原始 iOS 版本开发者
- **Qoder** - AI 辅助重构工具

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

📧 有问题？欢迎提 Issue 或联系开发者。
