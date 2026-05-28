import SwiftUI

/// Centralized animation tokens for PokeGem UI
enum GameAnimation {
    static let cardSelect = Animation.spring(response: 0.25, dampingFraction: 0.7)
    static let cardPress = Animation.spring(response: 0.15, dampingFraction: 0.6)
    static let scoreBounce = Animation.spring(response: 0.15, dampingFraction: 0.5)
    static let coinSelect = Animation.spring(response: 0.25, dampingFraction: 0.6)
    static let toast = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let gameOver = Animation.spring(response: 0.6, dampingFraction: 0.65)
    static let highlightPulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    static let cardRowChange = Animation.spring(response: 0.35, dampingFraction: 0.8)
}
