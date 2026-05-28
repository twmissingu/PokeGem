import SwiftUI

struct CoinsColumn: View {
    let tableCoins: CoinPurse
    let pendingSelection: [GemColor: Int]
    let canTakeCoins: Bool
    let canTakeDouble: (GemColor) -> Bool
    let canSelectGem: (GemColor) -> Bool
    let onTap: (GemColor) -> Void
    let coinSize: CGFloat

    var body: some View {
        let allColors: [GemColor] = [.gold] + GemColor.gemColors
        VStack(spacing: 5) {
            ForEach(allColors) { color in
                let count = tableCoins[color]
                coinRow(color: color, count: count)
                    .opacity(count > 0 ? 1.0 : 0.25)
                    .disabled(count == 0)
            }
            Spacer(minLength: 0)
        }
    }

    private func coinRow(color: GemColor, count: Int) -> some View {
        let selectedCount = pendingSelection[color, default: 0]
        let isSelected = selectedCount > 0
        let canDouble = canTakeDouble(color)
        let isGem = color.isGemColor
        let canSelect = isGem ? canSelectGem(color) : false
        let isEmpty = count == 0
        let isRuleBlocked = !canSelect && !isEmpty && !pendingSelection.isEmpty
        let isDisabled = !canSelect && !isSelected

        return ZStack {
            if let img = UIImage(named: color.coinImageName) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: coinSize - 4, height: coinSize - 4)
                    .shadow(color: color.associatedColor.opacity(isSelected ? 0.7 : 0.3),
                            radius: isSelected ? 8 : 2)
                    .opacity(isDisabled ? 0.3 : 1.0)
            } else {
                Circle()
                    .fill(color.associatedColor)
                    .frame(width: coinSize - 4, height: coinSize - 4)
                    .overlay(Circle().stroke(Color.white.opacity(color == .black ? 0.3 : 0), lineWidth: 0.5))
                    .opacity(isDisabled ? 0.3 : 1.0)
            }

            if isSelected {
                Circle()
                    .stroke(Color.yellow, lineWidth: 2.5)
                    .frame(width: coinSize, height: coinSize)
                    .shadow(color: .yellow.opacity(0.6), radius: 4)

                if selectedCount == 2 {
                    Text("2")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 12, height: 12)
                        .background(Circle().fill(Color.yellow))
                        .offset(x: -coinSize * 0.35, y: -coinSize * 0.35)
                }
            }

            if isDisabled {
                Circle()
                    .fill(Color.black.opacity(isRuleBlocked ? 0.65 : 0.5))
                    .frame(width: coinSize, height: coinSize)
            }

            ZStack {
                Capsule().fill(Color.black.opacity(0.75))
                    .frame(width: 20, height: 14)
                Text("\(count)")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.white)
            }
            .offset(x: coinSize * 0.35, y: coinSize * 0.35)
        }
        .frame(width: coinSize, height: coinSize)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .opacity(isDisabled ? 0.4 : 1.0)
        .onTapGesture { onTap(color) }
        .disabled(!canSelect && !isSelected)
        .animation(GameAnimation.coinSelect, value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(color.displayName)宝石，剩余\(count)枚")
        .accessibilityValue(isSelected ? "已选\(selectedCount)枚" : "")
        .accessibilityHint(isDisabled ? "不可选择" : "点击选择")
        .accessibilityAddTraits(.isButton)
    }
}
