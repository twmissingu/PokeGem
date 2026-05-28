//
//  CoinPurse.swift
//  PokeGem
//
//  Coin purse model - replaces original [Coin] array with dictionary-based counts
//  Fixes O(n) array scanning bugs from original implementation
//

import Foundation

/// A player's or the table's coin purse
/// Uses dictionary-based counts for O(1) operations instead of array scanning
struct CoinPurse: Hashable, Codable {
    // MARK: - Storage

    private var counts: [GemColor: Int] = [:]

    // MARK: - Initialization

    init() {}

    /// Create a purse with specific coin counts
    init(coins: [GemColor: Int]) {
        for (color, count) in coins where count > 0 {
            counts[color] = count
        }
    }

    /// Create a purse filled with equal coins per color (gold starts at 0)
    init(filledWith count: Int, includeGold: Bool = false) {
        for color in GemColor.gemColors {
            counts[color] = count
        }
        counts[.gold] = includeGold ? 5 : 0
    }

    // MARK: - Subscript

    subscript(color: GemColor) -> Int {
        get { counts[color] ?? 0 }
        set {
            if newValue > 0 {
                counts[color] = newValue
            } else {
                counts[color] = nil
            }
        }
    }

    // MARK: - Computed Properties

    /// Total number of coins in purse
    var total: Int {
        counts.values.reduce(0, +)
    }

    /// Number of gold (wildcard) coins
    var goldCount: Int {
        counts[.gold] ?? 0
    }

    /// All colors with non-zero counts
    var colors: [GemColor] {
        GemColor.allCases.filter { self[$0] > 0 }
    }

    /// Dictionary of all counts (for serialization)
    var allCounts: [GemColor: Int] {
        counts
    }

    // MARK: - Mutation

    /// Add coins to the purse
    /// - Parameters:
    ///   - color: Gem color to add
    ///   - count: Number of coins (default 1)
    mutating func add(_ color: GemColor, count: Int = 1) {
        guard count > 0 else { return }
        counts[color, default: 0] += count
    }

    /// Add multiple coins of various colors
    /// - Parameter additions: Dictionary of color -> count to add
    mutating func add(_ additions: [GemColor: Int]) {
        for (color, count) in additions where count > 0 {
            add(color, count: count)
        }
    }

    /// Remove coins from the purse
    /// - Parameters:
    ///   - color: Gem color to remove
    ///   - count: Number of coins (default 1)
    /// - Returns: True if successful, false if insufficient coins
    @discardableResult
    mutating func remove(_ color: GemColor, count: Int = 1) -> Bool {
        guard count > 0 else { return false }
        let current = counts[color] ?? 0
        guard current >= count else { return false }
        if current == count {
            counts[color] = nil
        } else {
            counts[color] = current - count
        }
        return true
    }

    /// Remove multiple coins of various colors
    /// - Parameter removals: Dictionary of color -> count to remove
    /// - Returns: True if successful, false if insufficient coins
    @discardableResult
    mutating func remove(_ removals: [GemColor: Int]) -> Bool {
        // First check if we have enough
        for (color, count) in removals where count > 0 {
            if (counts[color] ?? 0) < count {
                return false
            }
        }
        // Then remove
        for (color, count) in removals where count > 0 {
            remove(color, count: count)
        }
        return true
    }

    // MARK: - Payment Logic

    /// Check if this purse can pay the given cost
    /// - Parameter cost: Required coins by color
    /// - Returns: True if exact payment possible without gold
    func canPayExact(_ cost: [GemColor: Int]) -> Bool {
        for (color, required) in cost where required > 0 {
            if (counts[color] ?? 0) < required {
                return false
            }
        }
        return true
    }

    /// Check if this purse can pay the cost, using gold as wildcard
    /// - Parameters:
    ///   - cost: Required coins by color
    ///   - discounts: Available discounts from owned cards
    /// - Returns: True if payment possible with gold supplementation
    func canPay(_ cost: [GemColor: Int], with discounts: [GemColor: Int] = [:]) -> Bool {
        coinsToPay(cost, with: discounts) != nil
    }

    /// Calculate the coins needed to pay a cost, including gold usage
    /// - Parameters:
    ///   - cost: Required coins by color
    ///   - discounts: Available discounts from owned cards
    /// - Returns: Dictionary of coins to spend, or nil if cannot afford
    func coinsToPay(_ cost: [GemColor: Int], with discounts: [GemColor: Int] = [:]) -> [GemColor: Int]? {
        var payment: [GemColor: Int] = [:]
        var goldNeeded = 0

        for (color, required) in cost where required > 0 {
            let discount = discounts[color] ?? 0
            let stillNeeded = max(required - discount, 0)
            let have = counts[color] ?? 0
            let toSpend = min(stillNeeded, have)
            let deficit = max(stillNeeded - have, 0)

            if toSpend > 0 {
                payment[color] = toSpend
            }
            goldNeeded += deficit
        }

        if goldNeeded > goldCount {
            return nil  // Cannot afford
        }

        if goldNeeded > 0 {
            payment[.gold] = goldNeeded
        }

        return payment
    }

    /// Pay a cost, returning a new purse with coins removed
    /// - Parameters:
    ///   - cost: Required coins by color
    ///   - discounts: Available discounts from owned cards
    /// - Returns: New purse after payment, or nil if cannot afford
    func paying(_ cost: [GemColor: Int], with discounts: [GemColor: Int] = [:]) -> CoinPurse? {
        guard let payment = coinsToPay(cost, with: discounts) else {
            return nil
        }

        var newPurse = self
        guard newPurse.remove(payment) else {
            return nil
        }
        return newPurse
    }

    // MARK: - Validation

    /// Check if purse is at maximum capacity (10 coins)
    var isAtLimit: Bool {
        total >= 10
    }

    /// Maximum coins that can still be taken
    var remainingCapacity: Int {
        max(10 - total, 0)
    }
}

// MARK: - CustomStringConvertible

extension CoinPurse: CustomStringConvertible {
    var description: String {
        let parts = GemColor.allCases
            .filter { counts[$0] != nil }
            .map { "\($0.rawValue): \(counts[$0]!)" }
            .joined(separator: ", ")
        return "CoinPurse(\(parts), total: \(total))"
    }
}
