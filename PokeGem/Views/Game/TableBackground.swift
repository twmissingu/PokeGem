//
//  TableBackground.swift
//  PokeGem
//
//  Casino-style dark purple game table background
//  Inspired by Splendor board game screenshot
//

import SwiftUI

/// Dark luxurious casino table background - deep purple/burgundy felt
struct TableBackground: View {
    var body: some View {
        ZStack {
            // Deep burgundy/purple base matching the Splendor screenshot
            RadialGradient(
                gradient: Gradient(colors: [
                    GameColors.tableCenter,
                    GameColors.tableMid,
                    GameColors.tableEdge
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 800
            )
            .ignoresSafeArea()
            
            // Subtle warm center glow for depth
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.30, green: 0.16, blue: 0.22).opacity(0.3),
                    Color.clear
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            // Fine texture overlay for felt effect
            if let textureImage = UIImage(named: "background_texture") {
                Image(uiImage: textureImage)
                    .resizable(resizingMode: .tile)
                    .opacity(0.06)
                    .ignoresSafeArea()
                    .blendMode(.overlay)
            }
            
            // Subtle vignette for focus
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.35)
                ]),
                center: .center,
                startRadius: 200,
                endRadius: 700
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Layout Metrics (Dynamic, Rotation-Safe)

struct LayoutMetrics {
    let size: CGSize
    let isCompact: Bool
    let isIPad: Bool
    let nobleCount: Int

    init(size: CGSize, horizontalSizeClass: UserInterfaceSizeClass?, nobleCount: Int = 4) {
        self.size = size
        self.isCompact = horizontalSizeClass == .compact
        self.isIPad = horizontalSizeClass == .regular && size.width > 600
        self.nobleCount = nobleCount
    }

    // MARK: - Shared Layout Constants

    let sectionPadding: CGFloat = 8
    let innerPadding: CGFloat = 6

    var landscapeHorizontalPadding: CGFloat {
        isIPad ? 24 : (isCompact ? 16 : 20)
    }

    /// Total usable width after horizontal padding
    var availableWidth: CGFloat {
        size.width - landscapeHorizontalPadding * 2
    }

    // MARK: - Landscape Layout (4-column: AI | Cards | Gems | Nobles)
    // Step 1: calculate each area width as fraction of availableWidth
    // Step 2: interAreaGap = (availableWidth - sum of areas) / 3

    var aiPlayerAreaWidth: CGFloat {
        availableWidth * 0.15
    }

    var landscapeCardsAreaWidth: CGFloat {
        availableWidth * (isIPad ? 0.50 : 0.50)
    }

    var landscapeGemAreaWidth: CGFloat {
        availableWidth * 0.10
    }

    var landscapeNobleAreaWidth: CGFloat {
        availableWidth * 0.10
    }

    /// Fixed gap between areas
    var interAreaGap: CGFloat { 30 }

    // MARK: - Landscape Card Sizing (Height-First)

    var landscapeAvailableHeight: CGFloat {
        size.height - landscapeBottomBarHeight - sectionPadding * 2
    }

    var landscapeCardRowSpacing: CGFloat {
        let base = isCompact ? 4.0 : 8.0
        return min(12, max(4, landscapeAvailableHeight * 0.02))
    }

    var landscapeCardHeight: CGFloat {
        let totalSpacing = landscapeCardRowSpacing * 2
        let availableForCards = landscapeAvailableHeight - totalSpacing
        return max(isCompact ? 70 : 80, min(isIPad ? 160 : 120, availableForCards / 3))
    }

    var landscapeCardWidth: CGFloat {
        let heightBased = landscapeCardHeight / 1.42
        let minSpacing: CGFloat = 4
        let maxHorizontal = (landscapeCardsAreaWidth - minSpacing * 3) / 4
        return min(heightBased, maxHorizontal)
    }

    var landscapeCardSpacing: CGFloat {
        let cardTotalWidth = landscapeCardWidth * 4
        let spacing = (landscapeCardsAreaWidth - cardTotalWidth) / 3
        return max(4, min(12, spacing))
    }

    // MARK: - Landscape Dynamic Metrics (Vertical Fill)

    var landscapeTableHeight: CGFloat {
        landscapeAvailableHeight
    }

    var landscapeNobleSize: CGFloat {
        let gap: CGFloat = 6
        let maxNoble = (landscapeTableHeight - gap * CGFloat(nobleCount - 1)) / CGFloat(nobleCount)
        return min(maxNoble, isCompact ? 70 : 90)
    }

    var landscapeGemSize: CGFloat {
        let maxGem = (landscapeTableHeight - 4 * 5) / 6
        return min(maxGem, isCompact ? 44 : 58)
    }

    var landscapeAvatarSize: CGFloat {
        isIPad ? 72 : (isCompact ? 56 : 64)
    }

    // MARK: - Landscape Bottom Bar

    var landscapeBottomBarHeight: CGFloat {
        isIPad ? 80 : 60
    }
}
