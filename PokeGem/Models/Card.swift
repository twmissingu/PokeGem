import Foundation
//
//  Card.swift
//  PokeGem
//
//  Development card model - value type
//  Replaces original `Card` class with struct
//

/// A development card in Splendor
/// - Properties:
///   - id: Unique card identifier (1-90)
///   - color: The gem color this card provides when owned
///   - point: Victory points this card awards (0-5)
///   - level: Card tier (1-3), also used for borrowed card penalty
///   - cost: Required gem colors and quantities to purchase
struct Card: Identifiable, Hashable, Codable {
    let id: Int
    let color: GemColor
    let point: Int
    let level: Int
    let cost: [GemColor: Int]

    /// Asset image name for this card
    var imageName: String { "c\(id)" }

    /// Total cost in coins (sum of all color requirements)
    var totalCost: Int {
        cost.values.reduce(0, +)
    }

}

// MARK: - Card Database

extension Card {
    /// All 90 development cards from the original game
    static func allCards() -> [Card] {
        allCardsData
    }

    /// Cards by level
    static func cardsByLevel(_ level: Int) -> [Card] {
        allCardsData.filter { $0.level == level }
    }

    // MARK: - Level 1 Cards (40 cards, 0-1 points)

    private static let allCardsData: [Card] = [
        // White cards (Level 1)
        Card(id: 1, color: .white, point: 0, level: 1, cost: [.black: 1, .blue: 1, .white: 3]),
        Card(id: 2, color: .white, point: 0, level: 1, cost: [.black: 2, .blue: 2]),
        Card(id: 3, color: .white, point: 0, level: 1, cost: [.blue: 3]),
        Card(id: 4, color: .white, point: 0, level: 1, cost: [.black: 1, .blue: 2, .green: 2]),
        Card(id: 5, color: .white, point: 0, level: 1, cost: [.black: 1, .red: 2]),
        Card(id: 6, color: .white, point: 1, level: 1, cost: [.green: 4]),
        Card(id: 7, color: .white, point: 0, level: 1, cost: [.black: 1, .blue: 1, .green: 2, .red: 1]),
        Card(id: 8, color: .white, point: 0, level: 1, cost: [.black: 1, .blue: 1, .green: 1, .red: 1]),

        // Green cards (Level 1)
        Card(id: 9, color: .green, point: 0, level: 1, cost: [.black: 2, .blue: 1, .red: 1, .white: 1]),
        Card(id: 10, color: .green, point: 0, level: 1, cost: [.black: 1, .blue: 1, .red: 1, .white: 1]),
        Card(id: 11, color: .green, point: 0, level: 1, cost: [.white: 2]),
        Card(id: 12, color: .green, point: 1, level: 1, cost: [.black: 4]),
        Card(id: 13, color: .green, point: 0, level: 1, cost: [.black: 2, .blue: 1, .red: 2]),
        Card(id: 14, color: .green, point: 0, level: 1, cost: [.red: 3]),
        Card(id: 15, color: .green, point: 0, level: 1, cost: [.blue: 2, .red: 2]),
        Card(id: 16, color: .green, point: 0, level: 1, cost: [.blue: 3, .green: 1, .white: 1]),

        // Black cards (Level 1)
        Card(id: 17, color: .black, point: 0, level: 1, cost: [.blue: 2, .green: 1, .red: 1, .white: 1]),
        Card(id: 18, color: .black, point: 0, level: 1, cost: [.blue: 1, .green: 1, .red: 1, .white: 1]),
        Card(id: 19, color: .black, point: 0, level: 1, cost: [.blue: 2, .red: 1, .white: 2]),
        Card(id: 20, color: .black, point: 0, level: 1, cost: [.black: 1, .green: 1, .red: 3]),
        Card(id: 21, color: .black, point: 0, level: 1, cost: [.green: 2, .red: 1]),
        Card(id: 22, color: .black, point: 0, level: 1, cost: [.green: 3]),
        Card(id: 23, color: .black, point: 1, level: 1, cost: [.blue: 4]),
        Card(id: 24, color: .black, point: 0, level: 1, cost: [.green: 2, .white: 2]),

        // Red cards (Level 1)
        Card(id: 25, color: .red, point: 0, level: 1, cost: [.blue: 2, .green: 1]),
        Card(id: 26, color: .red, point: 0, level: 1, cost: [.white: 3]),
        Card(id: 27, color: .red, point: 0, level: 1, cost: [.black: 1, .blue: 1, .green: 1, .white: 2]),
        Card(id: 28, color: .red, point: 1, level: 1, cost: [.white: 4]),
        Card(id: 29, color: .red, point: 0, level: 1, cost: [.black: 3, .red: 1, .white: 1]),
        Card(id: 30, color: .red, point: 0, level: 1, cost: [.red: 2, .white: 2]),
        Card(id: 31, color: .red, point: 0, level: 1, cost: [.black: 1, .blue: 1, .green: 1, .red: 1, .white: 1]),
        Card(id: 32, color: .red, point: 0, level: 1, cost: [.black: 2, .green: 1, .white: 2]),

        // Blue cards (Level 1)
        Card(id: 33, color: .blue, point: 0, level: 1, cost: [.black: 2, .white: 1]),
        Card(id: 34, color: .blue, point: 0, level: 1, cost: [.black: 3]),
        Card(id: 35, color: .blue, point: 1, level: 1, cost: [.red: 4]),
        Card(id: 36, color: .blue, point: 0, level: 1, cost: [.black: 2, .green: 2]),
        Card(id: 37, color: .blue, point: 0, level: 1, cost: [.green: 2, .red: 2, .white: 1]),
        Card(id: 38, color: .blue, point: 0, level: 1, cost: [.black: 1, .green: 1, .red: 1, .white: 1]),
        Card(id: 39, color: .blue, point: 0, level: 1, cost: [.black: 1, .green: 1, .red: 2, .white: 1]),
        Card(id: 40, color: .blue, point: 0, level: 1, cost: [.blue: 1, .green: 3, .red: 1]),

        // White cards (Level 2)
        Card(id: 41, color: .white, point: 1, level: 2, cost: [.blue: 3, .red: 3, .white: 2]),
        Card(id: 42, color: .white, point: 1, level: 2, cost: [.black: 2, .green: 3, .red: 2]),
        Card(id: 43, color: .white, point: 2, level: 2, cost: [.black: 2, .green: 1, .red: 4]),
        Card(id: 44, color: .white, point: 2, level: 2, cost: [.red: 5]),
        Card(id: 45, color: .white, point: 2, level: 2, cost: [.black: 3, .red: 5]),
        Card(id: 46, color: .white, point: 3, level: 2, cost: [.white: 6]),

        // Green cards (Level 2)
        Card(id: 47, color: .green, point: 1, level: 2, cost: [.green: 2, .red: 3, .white: 3]),
        Card(id: 48, color: .green, point: 1, level: 2, cost: [.black: 2, .blue: 3, .white: 2]),
        Card(id: 49, color: .green, point: 2, level: 2, cost: [.black: 1, .blue: 2, .white: 4]),
        Card(id: 50, color: .green, point: 2, level: 2, cost: [.green: 5]),
        Card(id: 51, color: .green, point: 2, level: 2, cost: [.blue: 5, .green: 3]),
        Card(id: 52, color: .green, point: 3, level: 2, cost: [.green: 6]),

        // Black cards (Level 2)
        Card(id: 53, color: .black, point: 1, level: 2, cost: [.blue: 2, .green: 2, .white: 3]),
        Card(id: 54, color: .black, point: 1, level: 2, cost: [.black: 2, .green: 3, .white: 3]),
        Card(id: 55, color: .black, point: 2, level: 2, cost: [.green: 5, .red: 3]),
        Card(id: 56, color: .black, point: 2, level: 2, cost: [.blue: 1, .green: 4, .red: 2]),
        Card(id: 57, color: .black, point: 2, level: 2, cost: [.white: 5]),
        Card(id: 58, color: .black, point: 3, level: 2, cost: [.black: 6]),

        // Red cards (Level 2)
        Card(id: 59, color: .red, point: 1, level: 2, cost: [.black: 3, .red: 2, .white: 2]),
        Card(id: 60, color: .red, point: 1, level: 2, cost: [.black: 3, .blue: 3, .red: 2]),
        Card(id: 61, color: .red, point: 2, level: 2, cost: [.black: 5, .white: 3]),
        Card(id: 62, color: .red, point: 2, level: 2, cost: [.black: 5]),
        Card(id: 63, color: .red, point: 2, level: 2, cost: [.blue: 4, .green: 2, .red: 1]),
        Card(id: 64, color: .red, point: 3, level: 2, cost: [.red: 6]),

        // Blue cards (Level 2)
        Card(id: 65, color: .blue, point: 1, level: 2, cost: [.black: 3, .blue: 2, .green: 3]),
        Card(id: 66, color: .blue, point: 1, level: 2, cost: [.blue: 2, .green: 2, .red: 3]),
        Card(id: 67, color: .blue, point: 2, level: 2, cost: [.blue: 3, .white: 5]),
        Card(id: 68, color: .blue, point: 2, level: 2, cost: [.blue: 5]),
        Card(id: 69, color: .blue, point: 2, level: 2, cost: [.black: 4, .red: 1, .white: 2]),
        Card(id: 70, color: .blue, point: 3, level: 2, cost: [.blue: 6]),

        // White cards (Level 3)
        Card(id: 71, color: .white, point: 4, level: 3, cost: [.black: 6, .red: 3, .white: 3]),
        Card(id: 72, color: .white, point: 3, level: 3, cost: [.black: 3, .blue: 3, .green: 3, .red: 5]),
        Card(id: 73, color: .white, point: 4, level: 3, cost: [.black: 7]),
        Card(id: 74, color: .white, point: 5, level: 3, cost: [.black: 7, .white: 3]),

        // Green cards (Level 3)
        Card(id: 75, color: .green, point: 3, level: 3, cost: [.black: 3, .blue: 3, .red: 3, .white: 5]),
        Card(id: 76, color: .green, point: 4, level: 3, cost: [.blue: 7]),
        Card(id: 77, color: .green, point: 4, level: 3, cost: [.blue: 6, .green: 3, .white: 3]),
        Card(id: 78, color: .green, point: 5, level: 3, cost: [.blue: 7, .green: 3]),

        // Black cards (Level 3)
        Card(id: 79, color: .black, point: 3, level: 3, cost: [.blue: 3, .green: 5, .red: 3, .white: 3]),
        Card(id: 80, color: .black, point: 4, level: 3, cost: [.red: 7]),
        Card(id: 81, color: .black, point: 4, level: 3, cost: [.black: 3, .green: 3, .red: 6]),
        Card(id: 82, color: .black, point: 5, level: 3, cost: [.black: 3, .red: 7]),

        // Red cards (Level 3)
        Card(id: 83, color: .red, point: 3, level: 3, cost: [.black: 3, .blue: 5, .green: 3, .white: 3]),
        Card(id: 84, color: .red, point: 4, level: 3, cost: [.green: 7]),
        Card(id: 85, color: .red, point: 4, level: 3, cost: [.blue: 3, .green: 6, .red: 3]),
        Card(id: 86, color: .red, point: 5, level: 3, cost: [.green: 7, .red: 3]),

        // Blue cards (Level 3)
        Card(id: 87, color: .blue, point: 3, level: 3, cost: [.black: 5, .blue: 3, .green: 3, .white: 3]),
        Card(id: 88, color: .blue, point: 4, level: 3, cost: [.white: 7]),
        Card(id: 89, color: .blue, point: 4, level: 3, cost: [.black: 3, .blue: 3, .white: 6]),
        Card(id: 90, color: .blue, point: 5, level: 3, cost: [.blue: 3, .white: 7]),
    ]
}
