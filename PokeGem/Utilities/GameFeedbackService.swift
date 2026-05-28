import UIKit
import SwiftUI

@Observable
final class GameFeedbackService {
    var hapticEnabled = true

    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private static let notification = UINotificationFeedbackGenerator()

    func onAction(_ action: GameAction) {
        guard hapticEnabled else { return }
        switch action {
        case .takeCoins:
            Self.lightImpact.impactOccurred()
        case .purchaseCard, .repayCard:
            Self.mediumImpact.impactOccurred()
        case .reserveCard:
            Self.softImpact.impactOccurred()
        case .claimNoble:
            Self.notification.notificationOccurred(.success)
        case .pass:
            break
        }
    }

    func onPress() {
        guard hapticEnabled else { return }
        Self.lightImpact.impactOccurred(intensity: 0.5)
    }

    func onError() {
        guard hapticEnabled else { return }
        Self.notification.notificationOccurred(.error)
    }

    func onPhaseChange(_ phase: GamePhase) {
        guard hapticEnabled else { return }
        switch phase {
        case .aiThinking:
            Self.lightImpact.impactOccurred()
        case .gameEnded:
            Self.notification.notificationOccurred(.success)
        default:
            break
        }
    }
}
