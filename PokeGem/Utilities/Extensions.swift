//
//  Extensions.swift
//  PokeGem
//
//  Swift and SwiftUI utility extensions
//

import SwiftUI

// MARK: - Array Extensions

extension Array where Element: Hashable {
    /// Return array with duplicates removed
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }

}

// MARK: - Dictionary Extensions

extension Dictionary where Value: Numeric {
    /// Sum all values
    var total: Value {
        values.reduce(0, +)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply conditional modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Int Extensions

extension Int {
    /// Clamp value to range
    func clamped(to limits: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, limits.lowerBound), limits.upperBound)
    }
}
