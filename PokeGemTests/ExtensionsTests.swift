//
//  ExtensionsTests.swift
//  PokeGemTests
//
//  Unit tests for utility extensions
//

import Testing
@testable import PokeGem

struct ExtensionsTests {

    // MARK: - Array uniqued

    @Test("uniqued removes duplicates")
    func arrayUniqued() {
        let arr = [1, 2, 2, 3, 3, 3]
        #expect(arr.uniqued() == [1, 2, 3])
    }

    @Test("uniqued preserves order")
    func arrayUniquedOrder() {
        let arr = [3, 1, 2, 1, 3]
        #expect(arr.uniqued() == [3, 1, 2])
    }

    @Test("uniqued on empty array")
    func arrayUniquedEmpty() {
        let arr: [Int] = []
        #expect(arr.uniqued().isEmpty)
    }

    // MARK: - Dictionary total

    @Test("dictionary total sums values")
    func dictTotal() {
        let dict: [GemColor: Int] = [.red: 3, .blue: 2, .green: 1]
        #expect(dict.total == 6)
    }

    @Test("dictionary total is zero when empty")
    func dictTotalEmpty() {
        let dict: [GemColor: Int] = [:]
        #expect(dict.total == 0)
    }

    // MARK: - Int clamped

    @Test("clamped within range returns self")
    func clampedWithin() {
        #expect(5.clamped(to: 0...10) == 5)
    }

    @Test("clamped below lower bound")
    func clampedBelow() {
        #expect((-5).clamped(to: 0...10) == 0)
    }

    @Test("clamped above upper bound")
    func clampedAbove() {
        #expect(15.clamped(to: 0...10) == 10)
    }

    @Test("clamped at boundaries")
    func clampedAtBoundaries() {
        #expect(0.clamped(to: 0...10) == 0)
        #expect(10.clamped(to: 0...10) == 10)
    }
}
