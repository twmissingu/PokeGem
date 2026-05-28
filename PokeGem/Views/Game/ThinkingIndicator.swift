import SwiftUI

struct ThinkingIndicator: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .stroke(Color.yellow.opacity(pulse ? 0.6 : 0.2), lineWidth: 2)
            .frame(width: 14, height: 14)
            .overlay(
                Circle()
                    .fill(Color.yellow.opacity(pulse ? 0.3 : 0.1))
                    .frame(width: 8, height: 8)
            )
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
            .onAppear { pulse = true }
    }
}
