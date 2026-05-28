//
//  GemColor.swift
//  PokeGem
//
//  Gem color enumeration for Splendor game
//  Replaces original `Color` enum to avoid conflict with SwiftUI.Color
//

import SwiftUI

/// The six gem colors in Splendor, plus gold as wildcard
enum GemColor: String, CaseIterable, Identifiable, Codable, Hashable {
    case black
    case blue
    case green
    case red
    case white
    case gold

    var id: String { rawValue }

    /// Display name in Chinese
    var displayName: String {
        switch self {
        case .black: return "黑曜石"
        case .blue: return "蓝宝石"
        case .green: return "翡翠"
        case .red: return "红宝石"
        case .white: return "钻石"
        case .gold: return "黄金"
        }
    }

    /// Associated SwiftUI color for UI rendering
    /// Professional gem color palette matching Splendor board game
    var associatedColor: Color {
        switch self {
        case .black: return Color(red: 0.55, green: 0.48, blue: 0.62)  // Onyx — enhanced contrast
        case .blue: return Color(red: 0.20, green: 0.40, blue: 0.80)   // Sapphire blue
        case .green: return Color(red: 0.15, green: 0.60, blue: 0.25)  // Emerald green
        case .red: return Color(red: 0.80, green: 0.20, blue: 0.15)    // Ruby red
        case .white: return Color(red: 0.95, green: 0.95, blue: 0.95)  // Diamond white
        case .gold: return Color(red: 1.00, green: 0.84, blue: 0.00)  // Golden yellow
        }
    }

    /// Asset image name for coin icon
    var coinImageName: String {
        switch self {
        case .black: return "blackCoin"
        case .blue: return "blueCoin"
        case .green: return "greenCoin"
        case .red: return "redCoin"
        case .white: return "whiteCoin"
        case .gold: return "goldCoin"
        }
    }

    /// Asset image name for card back indicator
    var cardImageName: String {
        switch self {
        case .black: return "blackCard"
        case .blue: return "blueCard"
        case .green: return "greenCard"
        case .red: return "redCard"
        case .white: return "whiteCard"
        case .gold: return "goldCoin"
        }
    }

    /// Non-gem colors (gold is wildcard, not a gem color)
    var isGemColor: Bool {
        self != .gold
    }

    /// All gem colors excluding gold
    static let gemColors: [GemColor] = [.black, .blue, .green, .red, .white]
}
