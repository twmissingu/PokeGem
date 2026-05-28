import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.system(size: 80))
                        .foregroundStyle(.yellow, .indigo)
                        .symbolRenderingMode(.multicolor)

                    Text("PokeGem")
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)

                    Text("璀璨宝石")
                        .font(.title3)
                        .foregroundStyle(.yellow.opacity(0.8))
                }
                .padding(.top, 40)

                Divider()
                    .background(.white.opacity(0.15))

                SectionCard {
                    VStack(spacing: 20) {
                        CreditItem(
                            icon: "building.2.fill",
                            title: "工作室",
                            content: "XYZ工作室"
                        )
                        CreditItem(
                            icon: "person.2.fill",
                            title: "制作人员",
                            content: "twzhan，jcye"
                        )
                    }
                }

                Spacer(minLength: 60)
            }
            .padding()
        }
        .contentMargins(.top, 0, for: .scrollContent)
        .background(TableBackground())
        .navigationTitle("制作人员")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct CreditItem: View {
    let icon: String
    let title: String
    let content: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color.yellow.opacity(0.1))
                .clipShape(Circle())
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Text(content)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        CreditsView()
    }
}
