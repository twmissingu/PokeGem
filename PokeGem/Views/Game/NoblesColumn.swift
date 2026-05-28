import SwiftUI

struct NoblesColumn: View {
    let nobles: [PointCard]
    let onTap: (PointCard) -> Void
    let nobleSize: CGFloat
    let claimedThisTurn: Bool

    init(nobles: [PointCard], onTap: @escaping (PointCard) -> Void, nobleSize: CGFloat, claimedThisTurn: Bool = false) {
        self.nobles = nobles
        self.onTap = onTap
        self.nobleSize = nobleSize
        self.claimedThisTurn = claimedThisTurn
    }

    var body: some View {
        VStack(spacing: 5) {
            ForEach(nobles) { noble in
                Button { onTap(noble) } label: {
                    if let img = UIImage(named: noble.imageName) {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: nobleSize, height: nobleSize)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.yellow.opacity(0.2))
                            .frame(width: nobleSize, height: nobleSize)
                            .overlay(
                                Text("#\(noble.id)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.white.opacity(0.6))
                            )
                    }
                }
                .buttonStyle(.plain)
                .opacity(claimedThisTurn ? 0.5 : 1.0)
                .overlay(
                    claimedThisTurn ?
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                        : nil
                )
                .accessibilityLabel(nobleAccessibilityLabel(noble))
                .accessibilityAddTraits(.isButton)
            }
            Spacer(minLength: 0)
        }
    }

    private func nobleAccessibilityLabel(_ noble: PointCard) -> String {
        let costStr = noble.cost.map { "\($0.value)张\($0.key.displayName)卡" }.joined(separator: "、")
        return "贵族卡，\(noble.point)分，需要\(costStr)"
    }
}
