import SwiftUI

struct DockGemBadge: View {
    let color: GemColor
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            if let img = UIImage(named: color.coinImageName) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
            } else {
                Circle()
                    .fill(color.associatedColor)
                    .frame(width: 14, height: 14)
            }
            Text("\(count)")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(count > 0 ? .white : .white.opacity(0.4))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(count > 0 ? Color.black.opacity(0.35) : Color.black.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(count > 0 ? color.associatedColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
