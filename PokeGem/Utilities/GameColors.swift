import SwiftUI

/// Centralized color tokens for PokeGem UI
enum GameColors {
    // MARK: - Backgrounds
    static let homeBackground = Color(red: 0.12, green: 0.10, blue: 0.15)
    static let tableCenter = Color(red: 0.22, green: 0.12, blue: 0.28)
    static let tableMid = Color(red: 0.14, green: 0.08, blue: 0.18)
    static let tableEdge = Color(red: 0.08, green: 0.04, blue: 0.10)
    static let bottomBarStart = Color(red: 0.12, green: 0.06, blue: 0.18)
    static let bottomBarEnd = Color(red: 0.08, green: 0.04, blue: 0.12)

    // MARK: - Accent
    static let goldAccent = Color(red: 0.95, green: 0.75, blue: 0.10)

    // MARK: - Level Borders
    static let level1Border = Color(red: 0.35, green: 0.75, blue: 0.35)
    static let level2Border = Color(red: 0.30, green: 0.50, blue: 0.90)
    static let level3Border = Color(red: 0.75, green: 0.30, blue: 0.90)

    // MARK: - Toast
    static let toastError = Color(red: 0.85, green: 0.20, blue: 0.20)
    static let toastSuccess = Color(red: 0.20, green: 0.75, blue: 0.30)
    static let toastInfo = Color(red: 0.20, green: 0.50, blue: 0.90)
}
