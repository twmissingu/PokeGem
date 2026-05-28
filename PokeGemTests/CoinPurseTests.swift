//
//  CoinPurseTests.swift
//  PokeGemTests
//
//  Unit tests for CoinPurse model
//

import Testing
@testable import PokeGem

struct CoinPurseTests {

    // MARK: - Initialization Tests

    @Test("Empty purse has zero coins")
    func emptyPurseHasZeroCoins() {
        let purse = CoinPurse()
        #expect(purse.total == 0)
        #expect(purse.goldCount == 0)
        #expect(purse.isAtLimit == false)
    }

    @Test("Purse initializes with specific coins")
    func purseWithSpecificCoins() {
        let purse = CoinPurse(coins: [.red: 3, .blue: 2])
        #expect(purse[.red] == 3)
        #expect(purse[.blue] == 2)
        #expect(purse[.green] == 0)
        #expect(purse.total == 5)
    }

    @Test("Purse fills with equal coins per color")
    func purseFilledWithEqualCoins() {
        let purse = CoinPurse(filledWith: 5)
        for color in GemColor.gemColors {
            #expect(purse[color] == 5)
        }
        #expect(purse.goldCount == 0)  // Gold excluded by default
    }

    @Test("Purse fills with gold when specified")
    func purseFilledWithGold() {
        let purse = CoinPurse(filledWith: 5, includeGold: true)
        #expect(purse.goldCount == 5)
    }

    // MARK: - Subscript Tests

    @Test("Subscript returns zero for missing colors")
    func subscriptReturnsZeroForMissing() {
        let purse = CoinPurse()
        #expect(purse[.red] == 0)
        #expect(purse[.gold] == 0)
    }

    @Test("Subscript updates coin counts")
    func subscriptUpdatesCounts() {
        var purse = CoinPurse()
        purse[.red] = 3
        #expect(purse[.red] == 3)
        purse[.red] = 0
        #expect(purse[.red] == 0)
    }

    // MARK: - Add/Remove Tests

    @Test("Add coins increases total")
    func addCoinsIncreasesTotal() {
        var purse = CoinPurse()
        purse.add(.red, count: 3)
        purse.add(.blue, count: 2)
        #expect(purse.total == 5)
        #expect(purse[.red] == 3)
        #expect(purse[.blue] == 2)
    }

    @Test("Add multiple coins at once")
    func addMultipleCoins() {
        var purse = CoinPurse()
        purse.add([.red: 2, .blue: 3])
        #expect(purse.total == 5)
    }

    @Test("Remove coins succeeds when sufficient")
    func removeCoinsSucceeds() {
        var purse = CoinPurse(coins: [.red: 3, .blue: 2])
        let success = purse.remove(.red, count: 2)
        #expect(success == true)
        #expect(purse[.red] == 1)
        #expect(purse.total == 3)  // 1 red + 2 blue = 3
    }

    @Test("Remove coins fails when insufficient")
    func removeCoinsFails() {
        var purse = CoinPurse(coins: [.red: 1])
        let success = purse.remove(.red, count: 2)
        #expect(success == false)
        #expect(purse[.red] == 1)  // Unchanged
    }

    @Test("Remove multiple coins succeeds")
    func removeMultipleCoins() {
        var purse = CoinPurse(coins: [.red: 3, .blue: 2, .green: 1])
        let success = purse.remove([.red: 2, .blue: 1])
        #expect(success == true)
        #expect(purse[.red] == 1)
        #expect(purse[.blue] == 1)
        #expect(purse.total == 3)
    }

    @Test("Remove multiple fails if any insufficient")
    func removeMultipleFails() {
        var purse = CoinPurse(coins: [.red: 1, .blue: 2])
        let success = purse.remove([.red: 2, .blue: 1])
        #expect(success == false)
        #expect(purse.total == 3)  // Unchanged
    }

    // MARK: - Payment Tests

    @Test("Can pay exact cost")
    func canPayExactCost() {
        let purse = CoinPurse(coins: [.red: 3, .blue: 2])
        #expect(purse.canPayExact([.red: 2, .blue: 2]) == true)
        #expect(purse.canPayExact([.red: 4, .blue: 2]) == false)
    }

    @Test("Can pay with discounts")
    func canPayWithDiscounts() {
        let purse = CoinPurse(coins: [.red: 1])
        // Need 3 red, have 1, but discount 2
        #expect(purse.canPay([.red: 3], with: [.red: 2]) == true)
        // Need 3 red, have 1, discount only 1
        #expect(purse.canPay([.red: 3], with: [.red: 1]) == false)
    }

    @Test("Can pay with gold as wildcard")
    func canPayWithGold() {
        let purse = CoinPurse(coins: [.red: 1, .gold: 2])
        // Need 3 red, have 1, need 2 gold
        #expect(purse.canPay([.red: 3], with: [:]) == true)
        // Need 4 red, have 1, need 3 gold but only have 2
        #expect(purse.canPay([.red: 4], with: [:]) == false)
    }

    @Test("Coins to pay calculates correctly")
    func coinsToPay() {
        let purse = CoinPurse(coins: [.red: 3, .blue: 2, .gold: 1])
        let payment = purse.coinsToPay([.red: 2, .blue: 1])
        #expect(payment?[.red] == 2)
        #expect(payment?[.blue] == 1)
        #expect(payment?[.gold] == nil)
    }

    @Test("Coins to pay uses gold when needed")
    func coinsToPayUsesGold() {
        let purse = CoinPurse(coins: [.red: 1, .gold: 2])
        let payment = purse.coinsToPay([.red: 3])
        #expect(payment?[.red] == 1)
        #expect(payment?[.gold] == 2)
    }

    @Test("Coins to pay returns nil when cannot afford")
    func coinsToPayReturnsNil() {
        let purse = CoinPurse(coins: [.red: 1])
        let payment = purse.coinsToPay([.red: 3])
        #expect(payment == nil)
    }

    @Test("Coins to pay returns empty dict when discounts fully cover cost")
    func coinsToPayReturnsEmptyDictWhenDiscountsCover() {
        let purse = CoinPurse(coins: [.red: 5, .blue: 5])
        let payment = purse.coinsToPay([.red: 3], with: [.red: 3])
        #expect(payment != nil)
        #expect(payment?[.red] == nil)
        #expect(payment?[.gold] == nil)
        #expect(payment?.isEmpty == true)
    }

    @Test("Remove rejects negative count")
    func removeRejectsNegativeCount() {
        var purse = CoinPurse(coins: [.red: 3])
        let success = purse.remove(.red, count: -1)
        #expect(success == false)
        #expect(purse[.red] == 3)
    }

    @Test("Paying returns new purse with coins removed")
    func payingReturnsNewPurse() {
        let purse = CoinPurse(coins: [.red: 3, .blue: 2])
        let newPurse = purse.paying([.red: 2, .blue: 1])
        #expect(newPurse?[.red] == 1)
        #expect(newPurse?[.blue] == 1)
        #expect(newPurse?.total == 2)
        // Original unchanged
        #expect(purse[.red] == 3)
        #expect(purse.total == 5)
    }

    @Test("Paying returns nil when cannot afford")
    func payingReturnsNil() {
        let purse = CoinPurse(coins: [.red: 1])
        let newPurse = purse.paying([.red: 3])
        #expect(newPurse == nil)
    }

    // MARK: - Limit Tests

    @Test("Is at limit when 10 or more coins")
    func isAtLimit() {
        var purse = CoinPurse()
        for _ in 0..<9 {
            purse.add(.red, count: 1)
        }
        #expect(purse.isAtLimit == false)
        purse.add(.red, count: 1)
        #expect(purse.isAtLimit == true)
    }

    @Test("Remaining capacity calculates correctly")
    func remainingCapacity() {
        var purse = CoinPurse()
        purse.add(.red, count: 7)
        #expect(purse.remainingCapacity == 3)
        purse.add(.blue, count: 3)
        #expect(purse.remainingCapacity == 0)
    }

    // MARK: - Properties Tests

    @Test("Colors returns non-zero colors")
    func colorsProperty() {
        let purse = CoinPurse(coins: [.red: 3, .blue: 0, .green: 2])
        let colors = purse.colors
        #expect(colors.contains(.red))
        #expect(!colors.contains(.blue))
        #expect(colors.contains(.green))
    }

    @Test("All counts returns full dictionary")
    func allCountsProperty() {
        let purse = CoinPurse(coins: [.red: 3, .blue: 2])
        let counts = purse.allCounts
        #expect(counts[.red] == 3)
        #expect(counts[.blue] == 2)
        #expect(counts[.green] == nil)
    }

    // MARK: - Hashable Tests

    @Test("Equal purses hash equally")
    func equalPursesHashEqually() {
        let purse1 = CoinPurse(coins: [.red: 3, .blue: 2])
        let purse2 = CoinPurse(coins: [.red: 3, .blue: 2])
        #expect(purse1 == purse2)
        #expect(purse1.hashValue == purse2.hashValue)
    }

    @Test("Different purses are not equal")
    func differentPursesNotEqual() {
        let purse1 = CoinPurse(coins: [.red: 3])
        let purse2 = CoinPurse(coins: [.red: 2])
        #expect(purse1 != purse2)
    }

    // MARK: - Description Tests

    @Test("Description is non-empty")
    func descriptionNotEmpty() {
        let purse = CoinPurse(coins: [.red: 3, .blue: 2])
        #expect(!purse.description.isEmpty)
        #expect(purse.description.contains("3"))
        #expect(purse.description.contains("total"))
    }
}
