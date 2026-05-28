import SwiftUI

/// Primary action button with gold gradient background
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [GameColors.goldAccent.opacity(0.8), Color.orange.opacity(0.7)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: GameColors.goldAccent.opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }
}

/// Secondary action button with material background
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GameColors.goldAccent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// Icon button for menu items with icon circle, text, and chevron
struct IconButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isCompact: Bool
    let action: () -> Void

    init(title: String, subtitle: String, icon: String, isCompact: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isCompact = isCompact
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 14 : 16) {
                Image(systemName: icon)
                    .font(.system(size: isCompact ? 24 : 28))
                    .frame(width: isCompact ? 44 : 50, height: isCompact ? 44 : 50)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(GameColors.goldAccent.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(GameColors.goldAccent)

                VStack(alignment: .leading, spacing: isCompact ? 1 : 2) {
                    Text(title)
                        .font(isCompact ? .body.weight(.semibold) : .title3.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(isCompact ? .caption2 : .caption)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GameColors.goldAccent.opacity(0.8))
            }
            .padding(.horizontal, isCompact ? 16 : 0)
            .padding(.vertical, isCompact ? 12 : 0)
            .background(
                RoundedRectangle(cornerRadius: isCompact ? 10 : 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: isCompact ? 10 : 12)
                            .stroke(
                                LinearGradient(
                                    colors: [GameColors.goldAccent.opacity(0.5), Color.orange.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: isCompact ? 4 : 5, x: 0, y: 2)
        }
    }
}
