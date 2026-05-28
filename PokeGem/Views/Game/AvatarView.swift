import SwiftUI

struct AvatarView: View {
    let player: PlayerState
    let size: CGFloat
    let showBorder: Bool

    var body: some View {
        Group {
            if let avatarImage = UIImage(named: player.avatar.assetName) {
                Image(uiImage: avatarImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: player.isHuman ? "person.fill" : "cpu.fill")
                    .font(.system(size: size * 0.5))
                    .frame(width: size, height: size)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .overlay(
            Circle()
                .stroke(showBorder ? Color(red: 0.95, green: 0.75, blue: 0.10).opacity(0.8) : Color.clear, lineWidth: showBorder ? 2.5 : 0)
        )
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        .accessibilityLabel("\(player.name)头像")
    }
}
