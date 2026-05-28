import SwiftUI

struct CasinoCardView: View {
    let card: Card
    let isAffordable: Bool
    let isSelected: Bool
    let isBeingPurchased: Bool
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                cardImageArea
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow, lineWidth: 3)
                        .shadow(color: .yellow.opacity(0.5), radius: 5)
                } else if isAffordable {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .offset(y: liftOffset)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .shadow(color: isBeingPurchased ? Color.yellow.opacity(0.6) : .clear, radius: isBeingPurchased ? 16 : 0)
            .scaleEffect(isSelected ? 1.04 : (isPressed ? 0.97 : 1.0))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(GameAnimation.cardSelect, value: isSelected)
        .animation(GameAnimation.cardPress, value: isPressed)
        .animation(GameAnimation.cardSelect, value: isAffordable)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityHint(isAffordable ? "可购买" : "费用不足")
        .accessibilityAddTraits(.isButton)
    }

    private var cardAccessibilityLabel: String {
        let colorName = card.color.displayName
        let points = card.point > 0 ? "\(card.point)分" : ""
        let costStr = card.cost.map { "\($0.value)\($0.key.displayName)" }.joined(separator: "、")
        return "等级\(card.level) \(colorName)卡\(points)，费用\(costStr)"
    }

    private var liftOffset: CGFloat {
        if isSelected { return -4 }
        if isAffordable { return -2 }
        return 0
    }

    private var shadowRadius: CGFloat {
        if isSelected { return 12 }
        if isAffordable { return 6 }
        return 3
    }

    private var shadowY: CGFloat {
        if isSelected { return 6 }
        if isAffordable { return 3 }
        return 2
    }

    private var cardImageArea: some View {
        Group {
            if let image = UIImage(named: card.imageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.color.associatedColor.opacity(0.25))
                    .overlay(
                        Text("#\(card.id)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    )
                    .frame(width: cardWidth, height: cardHeight)
            }
        }
    }

    private var shadowColor: Color {
        if isSelected {
            return Color.yellow.opacity(0.35)
        } else if isAffordable {
            return Color.green.opacity(0.15)
        } else {
            return .black.opacity(0.25)
        }
    }
}
