import SwiftUI

struct RuleOverlayView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0

    private let steps: [(icon: String, title: String, description: String)] = [
        ("diamond.fill", "拿取宝石",
         "点击宝石拿取，可选择 3 种不同颜色各 1 个，或同色 2 个（桌上该颜色 ≥4 个时）。最多持有 10 个宝石。"),
        ("cart.fill", "购买发展卡",
         "支付卡牌所需的宝石，可获得永久折扣。拥有同色卡牌越多，购买折扣越大，金币可代替任意颜色。"),
        ("bookmark.fill", "保留卡牌",
         "可将展示区的卡牌保留（最多 3 张），并获得 1 个金币。保留卡可在后期使用宝石购买。"),
        ("crown.fill", "贵族与胜利",
         "当拥有的发展卡颜色组合满足贵族要求时，点击贵族即可招募（每张 3 分，每回合限 1 位）。率先达到目标分数并完成一轮者获胜！"),
    ]

    private let areaHints = [
        "查看屏幕右侧宝石区域",
        "查看屏幕中央卡牌区域",
        "查看底栏右侧预留卡槽",
        "查看屏幕最右侧贵族区域",
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 16) {
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 44))
                            .foregroundStyle(.yellow)
                            .shadow(color: .yellow.opacity(0.4), radius: 8)

                        Text(steps[currentStep].title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)

                        Text(steps[currentStep].description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(areaHints[currentStep])
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.yellow.opacity(0.7))

                        HStack(spacing: 8) {
                            ForEach(0..<steps.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentStep ? Color.yellow : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(minHeight: 260)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.12, green: 0.10, blue: 0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )

                    Button("跳过") {
                        UserDefaults.standard.set(true, forKey: "hasSeenRuleGuide")
                        isPresented = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
                .padding(.horizontal, 32)

                if currentStep < steps.count - 1 {
                    Button("下一步") {
                        withAnimation { currentStep += 1 }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.yellow.opacity(0.85))
                    )
                } else {
                    Button("开始游戏") {
                        UserDefaults.standard.set(true, forKey: "hasSeenRuleGuide")
                        isPresented = false
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.green.opacity(0.85))
                    )
                }

                Spacer()
            }
        }
    }
}
