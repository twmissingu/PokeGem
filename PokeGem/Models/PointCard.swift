import Foundation
//
//  PointCard.swift
//  PokeGem
//
//  Noble (point card) model - value type
//  Replaces original `PointCard` class with struct
//

/// A noble tile (point card) that awards victory points
/// - Properties:
///   - id: Unique identifier (1-10)
///   - point: Victory points awarded (always 3)
///   - cost: Required development card colors to attract this noble
struct PointCard: Identifiable, Hashable, Codable {
    let id: Int
    let point: Int
    let cost: [GemColor: Int]

    /// Asset image name for this point card
    var imageName: String { "pc\(id)" }

    /// Check if player has enough card discounts to attract this noble
    func canAttract(with discounts: [GemColor: Int]) -> Bool {
        for (color, required) in cost {
            let have = discounts[color] ?? 0
            if have < required {
                return false
            }
        }
        return true
    }
}

// MARK: - Point Card Database

extension PointCard {
    /// All 10 noble tiles from the original game
    static func allPointCards() -> [PointCard] {
        allPointCardsData
    }

    private static let allPointCardsData: [PointCard] = [
        PointCard(id: 1, point: 3, cost: [.green: 4, .red: 4]),
        PointCard(id: 2, point: 3, cost: [.blue: 4, .green: 4]),
        PointCard(id: 3, point: 3, cost: [.black: 4, .white: 4]),
        PointCard(id: 4, point: 3, cost: [.blue: 4, .white: 4]),
        PointCard(id: 5, point: 3, cost: [.black: 4, .red: 4]),
        PointCard(id: 6, point: 3, cost: [.black: 3, .red: 3, .white: 3]),
        PointCard(id: 7, point: 3, cost: [.blue: 3, .green: 3, .red: 3]),
        PointCard(id: 8, point: 3, cost: [.black: 3, .green: 3, .red: 3]),
        PointCard(id: 9, point: 3, cost: [.black: 3, .blue: 3, .white: 3]),
        PointCard(id: 10, point: 3, cost: [.blue: 3, .green: 3, .white: 3]),
    ]
}
