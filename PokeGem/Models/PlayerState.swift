import Foundation
//
//  PlayerState.swift
//  PokeGem
//
//  Player state model - value type
//  Replaces original `Player` class with struct
//

/// A player's complete game state
struct PlayerState: Identifiable, Hashable, Codable {
    // MARK: - Identity

    let id: UUID
    var name: String
    let isHuman: Bool
    var avatar: PlayerAvatar

    // MARK: - Resources

    var purse: CoinPurse
    var ownedCards: [Card]           // Development cards owned (provide discounts)
    var reservedCards: [Card]        // Reserved cards (max 3, cost points if not bought)
    var pointCards: [PointCard]      // Noble tiles collected

    // MARK: - Initialization

    init(id: UUID = UUID(), name: String, isHuman: Bool = false, avatar: PlayerAvatar? = nil) {
        self.id = id
        self.name = name
        self.isHuman = isHuman
        self.avatar = avatar ?? (isHuman ? .humanAvatar() : .robotAvatar(difficulty: .normal))
        self.purse = CoinPurse()
        self.ownedCards = []
        self.reservedCards = []
        self.pointCards = []
    }

    // MARK: - Computed Properties

    /// Card color counts (discounts for purchases)
    var cardCounts: [GemColor: Int] {
        var counts: [GemColor: Int] = [:]
        for card in ownedCards {
            counts[card.color, default: 0] += 1
        }
        return counts
    }

    /// Total victory points
    var totalPoints: Int {
        let cardPoints = ownedCards.reduce(0) { $0 + $1.point }
        let noblePoints = pointCards.reduce(0) { $0 + $1.point }
        return cardPoints + noblePoints
    }

    /// Can reserve more cards (max 3)
    var canReserveMore: Bool {
        reservedCards.count < 3
    }

    /// Has coins at maximum limit (10)
    var hasCoinsAtLimit: Bool {
        purse.isAtLimit
    }

    /// Check if can purchase a specific card
    func canPurchase(_ card: Card) -> Bool {
        purse.canPay(card.cost, with: cardCounts)
    }

    /// Check if can repay a reserved card
    func canRepay(_ card: Card) -> Bool {
        reservedCards.contains(where: { $0.id == card.id }) && purse.canPay(card.cost, with: cardCounts)
    }

    /// Check if can attract a noble
    func canAttract(_ noble: PointCard) -> Bool {
        noble.canAttract(with: cardCounts)
    }

    // MARK: - Actions

    /// Take coins from table
    /// - Parameter coins: Coins to take
    /// - Returns: New player state or nil if would exceed limit
    func takingCoins(_ coins: [GemColor: Int]) -> PlayerState? {
        let totalToAdd = coins.values.reduce(0, +)
        guard purse.total + totalToAdd <= 10 else { return nil }

        var newState = self
        newState.purse.add(coins)
        return newState
    }

    /// Purchase a development card
    /// - Parameters:
    ///   - card: Card to purchase
    ///   - payment: Coins to pay
    /// - Returns: New player state or nil if cannot afford
    func purchasing(_ card: Card, with payment: [GemColor: Int]) -> PlayerState? {
        guard let newPurse = purse.paying(payment) else { return nil }

        var newState = self
        newState.purse = newPurse
        newState.ownedCards.append(card)
        return newState
    }

    /// Reserve a development card (receive gold if table has gold)
    /// - Parameter card: Card to reserve
    /// - Parameter tableHasGold: Whether table has gold coins
    /// - Returns: New player state or nil if at reserve limit
    func reserving(_ card: Card, tableHasGold: Bool) -> PlayerState? {
        guard canReserveMore else { return nil }

        var newState = self
        newState.reservedCards.append(card)
        if tableHasGold && newState.purse.total < 10 {
            newState.purse.add(.gold, count: 1)
        }
        return newState
    }

    /// Repay a reserved card (buy it from reserved state)
    /// - Parameters:
    ///   - card: Reserved card to repay
    ///   - payment: Coins to pay
    /// - Returns: New player state or nil if cannot afford
    func repaying(_ card: Card, with payment: [GemColor: Int]) -> PlayerState? {
        guard reservedCards.contains(where: { $0.id == card.id }) else { return nil }
        guard let newPurse = purse.paying(payment) else { return nil }

        var newState = self
        newState.purse = newPurse
        newState.ownedCards.append(card)
        newState.reservedCards.removeAll { $0.id == card.id }
        return newState
    }

    /// Claim a noble tile
    /// - Parameter noble: Noble to claim
    /// - Returns: New player state or nil if requirements not met or already owned
    func claiming(_ noble: PointCard) -> PlayerState? {
        guard canAttract(noble), !pointCards.contains(where: { $0.id == noble.id }) else { return nil }

        var newState = self
        newState.pointCards.append(noble)
        return newState
    }
}

// MARK: - CustomStringConvertible

extension PlayerState: CustomStringConvertible {
    var description: String {
        """
        PlayerState(
          name: \(name),
          isHuman: \(isHuman),
          points: \(totalPoints),
          coins: \(purse.total),
          ownedCards: \(ownedCards.count),
          reservedCards: \(reservedCards.count),
          pointCards: \(pointCards.count)
        )
        """
    }
}
