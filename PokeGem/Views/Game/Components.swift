import SwiftUI

// MARK: - Score Badge

struct ScoreBadge: View {
    let value: Int
    let icon: String
    @State private var bounce = false
    @State private var bounceTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundStyle(.yellow)
            Text("\(value)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(bounce ? 1.4 : 1.0)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(GameColors.goldAccent.opacity(0.15))
                .overlay(Capsule().stroke(GameColors.goldAccent.opacity(0.3), lineWidth: 1))
        )
        .onChange(of: value) { _, _ in
            bounceTask?.cancel()
            withAnimation(GameAnimation.scoreBounce) { bounce = true }
            bounceTask = Task {
                try? await Task.sleep(for: .milliseconds(200))
                withAnimation { bounce = false }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value)分")
    }
}

// MARK: - Small Stat Badge

struct SmallStatBadge: View {
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

// MARK: - Gem Counter Pill

struct GemCounterPill: View {
    let color: GemColor
    let count: Int
    @State private var pulse = false
    @State private var pulseTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 3) {
            if let image = UIImage(named: color.coinImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            } else {
                Circle()
                    .fill(color.associatedColor)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
            }

            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(pulse ? 1.3 : 1.0)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(pulse ? color.associatedColor : color.associatedColor.opacity(0.4), lineWidth: pulse ? 2 : 1)
                )
        )
        .onChange(of: count) { _, _ in
            pulseTask?.cancel()
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) { pulse = true }
            pulseTask = Task {
                try? await Task.sleep(for: .milliseconds(250))
                withAnimation { pulse = false }
            }
        }
    }
}

// MARK: - Discount Badge

struct DiscountBadge: View {
    let color: GemColor
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color.associatedColor)
                .frame(width: 10, height: 10)
            Text("\(count)")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.25))
        )
    }
}

// MARK: - Gem Summary Badge (Discount + Icon + Gems stacked)

struct GemSummaryBadge: View {
    let color: GemColor
    let discount: Int
    let gems: Int

    private var isActive: Bool { discount > 0 || gems > 0 }

    var body: some View {
        VStack(spacing: 2) {
            Text(discount > 0 ? "\(discount)" : "-")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(discount > 0 ? Color.yellow : .white.opacity(0.25))
                .lineLimit(1)

            if let img = UIImage(named: color.coinImageName) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 13, height: 13)
            } else {
                Circle()
                    .fill(color.associatedColor)
                    .frame(width: 13, height: 13)
            }

            Text(gems > 0 ? "\(gems)" : "0")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(gems > 0 ? .white : .white.opacity(0.25))
                .lineLimit(1)
        }
        .frame(width: 32)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(isActive ? Color.black.opacity(0.35) : Color.black.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isActive ? color.associatedColor.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(color.displayName)，折扣\(discount)，持有\(gems)")
    }
}

// MARK: - Casino Button

struct CasinoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(GameAnimation.cardPress, value: configuration.isPressed)
    }
}

struct CasinoButton: View {
    let title: String
    let color: Color
    var isHighlighted: Bool = false
    let action: () -> Void

    @State private var highlightPulse = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(minWidth: 44, minHeight: 44)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(isHighlighted ? 0.5 : 0.2), lineWidth: isHighlighted ? 1.5 : 1)
                        )
                )
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 2)
                .scaleEffect(highlightPulse ? 1.05 : 1.0)
        }
        .buttonStyle(CasinoButtonStyle())
        .onChange(of: isHighlighted) { _, newValue in
            if newValue {
                withAnimation(GameAnimation.highlightPulse) {
                    highlightPulse = true
                }
            } else {
                highlightPulse = false
            }
        }
    }
}

// MARK: - Section Card

struct SectionCard<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
        )
    }
}
