import SwiftUI

final class OrientationController {
    static let shared = OrientationController()

    var supportedOrientations: UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]

    private init() {}

    @MainActor
    func lockToLandscape() {
        updateSupportedOrientations([.landscapeLeft, .landscapeRight])
        requestGeometryUpdate(.landscapeRight, allowedOrientations: supportedOrientations)
    }

    @MainActor
    func unlock() {
        updateSupportedOrientations([.portrait, .landscapeLeft, .landscapeRight])
    }

    @MainActor
    private func updateSupportedOrientations(_ orientations: UIInterfaceOrientationMask) {
        supportedOrientations = orientations
        refreshSupportedOrientations()
    }

    @MainActor
    private func requestGeometryUpdate(_ orientation: UIInterfaceOrientation, allowedOrientations: UIInterfaceOrientationMask) {
        guard let windowScene = foregroundWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: allowedOrientations))
        // Force orientation update without private API (iOS 16+)
        refreshSupportedOrientations()
    }

    @MainActor
    private var foregroundWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { scene in
            scene.activationState == .foregroundActive && scene.windows.contains { $0.isKeyWindow }
        } ?? scenes.first { $0.activationState == .foregroundActive }
    }

    @MainActor
    private func refreshSupportedOrientations() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .compactMap(\.rootViewController)
            .forEach { $0.setNeedsUpdateOfSupportedInterfaceOrientations() }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        OrientationController.shared.supportedOrientations
    }
}
