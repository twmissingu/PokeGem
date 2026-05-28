# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-28

### Added
- Complete Splendor (璀璨宝石) game implementation
- SwiftUI-based UI with casino-style dark theme
- 3 AI difficulty levels (Easy, Normal, Hard)
- 8 player avatars with unique personalities
- Auto-save and game state persistence
- Haptic feedback for all interactions
- VoiceOver accessibility support
- Landscape-only 4-column layout
- Color token system (GameColors)
- Animation token system (GameAnimation)
- Unified button components (PrimaryButton, SecondaryButton, IconButton)
- Turn visual cues with border pulse
- Deck count visibility with low-stack warning
- Gem selection state differentiation
- Noble recruitment state feedback

### Technical
- MVVM architecture with pure-function engine
- 247 tests across 12 test files
- Zero external dependencies
- iOS 17+ target
- Swift Testing framework (@Test / #expect)
