[![English](https://img.shields.io/badge/English-blue.svg)](README.md)
[![中文](https://img.shields.io/badge/中文-red.svg)](README_zh.md)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-orange.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

# PokeGem

**A polished, production-ready iOS implementation of Splendor — the award-winning strategy board game.**

Pure SwiftUI, zero dependencies, 247 tests, ready for the App Store.

## Why PokeGem?

Splendor is one of the most elegant strategy board games ever designed. PokeGem brings it to iOS with:

- **Casino-grade visuals** — deep purple table, gold accents, smooth animations
- **Smart AI opponents** — 3 difficulty levels, each with unique strategies
- **Refined UX** — haptic feedback, VoiceOver support, auto-save
- **Production quality** — 247 tests, MVVM architecture, zero dependencies

## Features

- 🎮 **1-4 Players** — Solo play against 1-3 AI opponents
- 🤖 **3 AI Difficulties** — Easy, Normal, Hard, each with distinct strategies
- 🎨 **8 Characters** — Ash, Jessie, James, Team Rocket, and more
- 💾 **Auto-Save** — Resume anytime, state persisted via UserDefaults
- 📱 **Landscape Mode** — Optimized 4-column layout, immersive experience
- ♿ **Accessibility** — Full VoiceOver support with logical navigation
- 🎯 **Custom Settings** — Adjustable target score (10-35), haptic feedback toggle

## Quick Start

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ simulator or device
- macOS 14.0+ (development environment)

### Installation

```bash
git clone https://github.com/twmissingu/PokeGem.git
cd PokeGem
open PokeGem.xcodeproj
```

### Build & Run

```bash
# Build
xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run in simulator
open -a Simulator
xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### Run Tests

```bash
# All tests
xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PokeGemTests

# Specific test class
xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PokeGemTests/GameEngineTests
```

## AI Agent Guide

This project is designed for seamless AI agent interaction:

1. **Clone and build**
   ```bash
   git clone https://github.com/twmissingu/PokeGem.git
   cd PokeGem
   xcodebuild -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' build
   ```

2. **Run tests**
   ```bash
   xcodebuild test -scheme PokeGem -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:PokeGemTests
   ```

3. **Project structure**
   - `PokeGem/Models/` — Game logic (pure functions, immutable state)
   - `PokeGem/ViewModels/` — GameViewModel (@Observable, @MainActor)
   - `PokeGem/Views/` — SwiftUI views (home, game, settings)
   - `PokeGem/AI/` — AI strategies (easy, normal, hard)
   - `PokeGem/Utilities/` — Colors, animations, haptic feedback
   - `PokeGemTests/` — 13 files, 247 tests

4. **Key patterns**
   - MVVM + pure-function engine
   - Atomic actions (validate first, return original state if invalid)
   - Auto-save after every action
   - Files auto-included via Xcode sync

## Architecture

```
SwiftUI Views → GameViewModel (@Observable) → GameEngine (pure functions)
                                                    ↕
                                              GameState (immutable)
```

**State machine**: `settings → playerTurn → aiThinking → aiExecuting → gameEnded`

## Game Rules

### Objective

Be the first player to reach the target score (default 15 points).

### Components

- **90 Development Cards** — 3 tiers, providing points and gem discounts
- **10 Noble Cards** — Each worth 3 points
- **Gem Tokens** — 5 colors (black, blue, green, red, white) + gold wildcards

### Turn Actions

Choose one action per turn:

1. **Take Gems**
   - 3 different color gems
   - Or 2 same color gems (only when ≥4 available on table)

2. **Purchase Development Card**
   - Pay required gems, gain the card and its discount

3. **Reserve Development Card**
   - Reserve a card (max 3 total)
   - Gain 1 gold (wildcard gem)

### Winning

When a player reaches the target score and completes the current round, the game ends. Tiebreakers: points → nobles → cards owned.

## Technical Architecture

### Architecture Pattern

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

### Key Technologies

| Feature | Implementation |
|---------|----------------|
| UI Framework | SwiftUI (iOS 17+) |
| State Management | @Observable |
| Concurrency | async/await + Task |
| Game Engine | Pure functions (struct) |
| AI Strategy | Protocol + multiple implementations |
| Layout | GeometryReader + responsive |

### Code Structure

```
PokeGem/
├── PokeGemApp.swift             # App lifecycle entry point
├── Models/
│   ├── GemColor.swift           # Gem color enum
│   ├── Card.swift               # Development cards (90)
│   ├── PointCard.swift          # Noble cards (10)
│   ├── CoinPurse.swift          # Wallet management
│   ├── PlayerState.swift        # Player state
│   ├── PlayerAvatar.swift       # Character avatars
│   ├── GameAction.swift         # Game actions
│   ├── GameState.swift          # Game state
│   ├── GameEngine.swift         # Game engine
│   └── GameArchiver.swift       # Auto-save
├── AI/
│   ├── AIStrategy.swift         # AI protocol
│   ├── EasyAIStrategy.swift     # Easy AI
│   ├── NormalAIStrategy.swift   # Normal AI
│   └── HardAIStrategy.swift     # Hard AI
├── ViewModels/
│   └── GameViewModel.swift      # Game view model
├── Views/
│   ├── Home/                    # Home views
│   ├── Settings/                # Settings views
│   └── Game/                    # Game views
└── Utilities/
    ├── Colors.swift             # Color utilities
    ├── Extensions.swift         # Extensions
    ├── GameAnimation.swift      # Animations
    ├── GameColors.swift         # Color tokens
    ├── GameFeedbackService.swift # Haptic feedback
    └── OrientationController.swift # Landscape control
```

## Development Guide

### Adding a New AI Strategy

1. Create a new file implementing the `AIStrategy` protocol
2. Implement the `chooseAction(state:playerId:) async` method
3. Register the new strategy in `GameViewModel`

### Modifying Game Rules

All game logic is in `GameEngine.swift`. Modify the `apply(_:to:)` method.

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 2.0 | 2026-04 | SwiftUI rewrite, iOS 17+ |
| 1.0 | 2017-02 | Original Swift 3 / UIKit version |

## Contributing

Issues and Pull Requests are welcome!

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.
