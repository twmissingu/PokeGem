import SwiftUI

enum ToastStyle {
    case error
    case success
    case info

    var color: Color {
        switch self {
        case .error: return GameColors.toastError
        case .success: return GameColors.toastSuccess
        case .info: return GameColors.toastInfo
        }
    }

    var icon: String {
        switch self {
        case .error: return "exclamationmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastConfig: Equatable, Identifiable {
    let id: UUID
    let message: String
    let style: ToastStyle

    init(message: String, style: ToastStyle) {
        self.id = UUID()
        self.message = message
        self.style = style
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastConfig?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                if let toast = toast {
                    HStack(spacing: 8) {
                        Image(systemName: toast.style.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                        Text(toast.message)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(toast.style.color.opacity(0.9))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    .padding(.bottom, 68)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(GameAnimation.toast, value: toast.id)
                    .accessibilityAddTraits(.updatesFrequently)
                    .onAppear {
                        UIAccessibility.post(notification: .announcement, argument: toast.message)
                    }
                }
            }
            .onChange(of: toast?.id) { _, _ in
                workItem?.cancel()
                if let currentToast = toast {
                    let toastId = currentToast.id
                    let task = DispatchWorkItem {
                        // Only dismiss if the toast hasn't changed
                        if self.toast?.id == toastId {
                            self.toast = nil
                        }
                    }
                    workItem = task
                    let duration = max(2.0, min(4.0, 2.0 + Double(currentToast.message.count) * 0.05))
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
                }
            }
            .onDisappear {
                workItem?.cancel()
                workItem = nil
            }
    }
}

extension View {
    func toast(_ toast: Binding<ToastConfig?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
