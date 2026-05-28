//
//  GameAction.swift
//  PokeGem
//
//  Enumeration of all possible player actions in a turn
//

/// Represents a single action a player can take during their turn
enum GameAction: Hashable, Codable {
    /// Take specific coins from the table
    /// - Associated: Dictionary of color -> count to take
    case takeCoins([GemColor: Int])

    /// Purchase a development card from the table
    /// - Associated: Card to purchase, coins to pay
    case purchaseCard(Card, [GemColor: Int])

    /// Reserve a development card from the table (and receive gold)
    /// - Associated: Card to reserve
    case reserveCard(Card)

    /// Repay a reserved card (buy it using coins)
    /// - Associated: Reserved card to repay, coins to pay
    case repayCard(Card, [GemColor: Int])

    /// Claim a noble tile (automatic when requirements met)
    /// - Associated: Noble to claim
    case claimNoble(PointCard)

    /// Pass (no valid actions available)
    case pass

    // MARK: - Helpers

    /// Human-readable description of the action
    var description: String {
        switch self {
        case .takeCoins(let coins):
            let parts = coins.map { "\($0.rawValue): \($1)" }.joined(separator: ", ")
            return "Take coins: \(parts)"
        case .purchaseCard(let card, _):
            return "Purchase card #\(card.id) (\(card.color.rawValue), L\(card.level), \(card.point)pts)"
        case .reserveCard(let card):
            return "Reserve card #\(card.id)"
        case .repayCard(let card, _):
            return "Repay reserved card #\(card.id)"
        case .claimNoble(let noble):
            return "Claim noble #\(noble.id) (\(noble.point)pts)"
        case .pass:
            return "Pass"
        }
    }

    /// Whether this action is automatic (not chosen by player)
    var isAutomatic: Bool {
        switch self {
        case .claimNoble:
            return true
        default:
            return false
        }
    }
}

extension Array where Element == GameAction {
    /// Filter to only manual (player-choosable) actions, excluding automatic and pass
    var manualActions: [GameAction] {
        filter { !$0.isAutomatic && $0 != .pass }
    }
}
