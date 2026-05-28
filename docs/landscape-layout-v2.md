# PokeGem Landscape Layout v2

> **Scope**: 横屏布局设计规格和决策依据 — 布局百分比、尺寸规格、组件结构。
> LayoutMetrics 技术实现见 [design.md](design.md)，产品需求见 [requirements.md](requirements.md)。

---

## 1. Layout Overview

### Three-Column Landscape Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           LANDSCAPE MODE (LOCKED)                           │
├─────────────────┬─────────────────────────────────────┬─────────────────────┤
│                 │                                     │  ┌──┬──┐            │
│   LEFT PANEL    │          CENTER CARD AREA           │  │💰│⭐│            │
│    (12%)        │             (60%)                   │  │🔴│  │            │
│                 │                                     │  │🔵│  │            │
│  ┌───────────┐  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │  │🟢│  │            │
│  │  AI 1     │  │  │ L3 │ │ L3 │ │ L3 │ │ L3 │       │  │⚪│  │            │
│  │  ⭐8      │  │  └────┘ └────┘ └────┘ └────┘       │  │🟤│  │            │
│  └───────────┘  │                                     │  └──┴──┘            │
│  ┌───────────┐  │  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │   桌币   贵族      │
│  │  AI 2     │  │  │ L2 │ │ L2 │ │ L2 │ │ L2 │       │  (竖排)  (竖排)    │
│  │  ⭐6      │  │  └────┘ └────┘ └────┘ └────┘       │                     │
│  └───────────┘  │                                     │                     │
│                 │  ┌────┐ ┌────┐ ┌────┐ ┌────┐       │                     │
│  [CARD STACKS]  │  │ L1 │ │ L1 │ │ L1 │ │ L1 │       │                     │
│  Level 3: 7     │  └────┘ └────┘ └────┘ └────┘       │                     │
│  Level 2: 12    │                                     │                     │
│  Level 1: 18    │  Cards: Dynamic sizing              │                     │
│                 │  iPhone ~70×100pt                    │                     │
│                 │  iPad ~100×142pt                     │                     │
├─────────────────┴─────────────────────────────────────┴─────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  👤小智 ⭐10  🔴2 🔵2 🟢1 ⚪2 🟤1 🟡0     [购买] [保留] [取消]   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                              BOTTOM ACTION BAR (72pt)                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Layout Specifications

| Area | Width | Height | Content |
|------|-------|--------|---------|
| **Left Panel** | 12% | Full | AI players (compact cards) + card stack counts |
| **Center Area** | 60% | Full | 3 rows of development cards (dynamic sizing) |
| **Right Panel** | 18% | Full | Left column: table coins; Right column: nobles |
| **Bottom Bar** | 100% | 72pt | Current player info + held gems + action buttons |

---

## 2. Center Card Area (Dynamic Sizing)

### Card Specifications

| Property | iPhone (compact) | iPhone (Plus/Max) | iPad (regular) |
|----------|------------------|-------------------|----------------|
| **Width** | ~70pt | ~80pt | 100pt |
| **Height** | ~100pt | ~114pt | 142pt |
| **Aspect Ratio** | 1:1.42 | 1:1.42 | 1:1.42 |

**Design Principle**: Card dimensions are dynamically calculated based on available height, ensuring 3 rows fit without scrolling on any device.

---

## 3. Right Panel (Coins + Nobles)

### Layout Structure

```
┌─────────────────┐
│ 💰 ×5  │  [NOBLE1] │
│ 🔴 ×7  │  [NOBLE2] │
│ 🔵 ×7  │  [NOBLE3] │
│ 🟢 ×7  │  [NOBLE4] │
│ ⚪ ×7  │  [NOBLE5] │
│ 🟤 ×7  │          │
└─────────────────┘
  左列桌币   右列贵族
```

### Component Specifications

| Component | iPhone Size | iPad Size |
|-----------|-------------|-----------|
| **Coin token** | 28pt circle | 36pt circle |
| **Noble tile** | 44×44pt | 64×64pt |
| **Column spacing** | 6pt | 8pt |

---

## 4. Bottom Bar (Simplified)

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│ 👤小智 ⭐10  🔴2 🔵2 🟢1 ⚪2 🟤1 🟡0     [购买] [保留] [取消]   │
└─────────────────────────────────────────────────────────────────────┘
```

### Design Principles

1. **Single row**: Player avatar + name + score on left
2. **Compact gems**: Small dots with counts (no large pills)
3. **Inline actions**: Buttons on right, no separate action panel
4. **Height**: 72pt (iPhone) / 96pt (iPad)

---

## 5. Left Panel (AI Players + Card Stacks)

### Layout Structure

```
┌───────────────┐
│  ┌───────────┐│
│  │  AI 1     ││
│  │  ⭐8      ││
│  │ 💎12 📦5  ││
│  └───────────┘│
│  ┌───────────┐│
│  │  AI 2     ││
│  │  ⭐6      ││
│  │ 💎8 📦3   ││
│  └───────────┘│
│               │
│  L3: 7        │
│  L2: 12       │
│  L1: 18       │
└───────────────┘
```

---

## 6. iPad Enhancements

On iPad, the layout scales up for better visibility:

| Element | iPhone | iPad | Enhancement |
|---------|--------|------|-------------|
| Card size | 70×100pt | 100×142pt | +43% larger |
| Noble tile | 44×44pt | 64×64pt | +45% larger |
| Coin token | 28pt | 36pt | +29% larger |
| Right panel width | 100pt | 180pt | +80% wider |
| Bottom bar height | 72pt | 96pt | +33% taller |

---

## 7. Implementation Notes

### File Changes

| File | Changes |
|------|---------|
| `TableBackground.swift` | Add `landscapeRightPanelWidth`, `landscapeCoinSize`, `landscapeNobleSize`, `landscapeBottomBarHeight`, `landscapeCardWidth`, `landscapeCardHeight` to `LayoutMetrics` |
| `GameView.swift` | Add `RightPanelLandscape`, `CoinsColumn`, `NoblesColumn`, `bottomBarLandscape`, `aiPlayersColumnLandscape`, `cardTableAreaLandscape`; Update `casinoLayout` for landscape/portrait switching |

### Priority

| Priority | Task | Estimated Time |
|----------|------|----------------|
| P0 | Dynamic card sizing | 2h |
| P0 | Bottom bar simplification | 1.5h |
| P1 | Right panel split (coins + nobles) | 2.5h |
| P1 | Left panel card stack counts | 0.5h |
| P2 | iPad enhancements | 1h |

---

*Document updated: 2026-05-19*
*Based on: Splendor board game landscape layout reference*
