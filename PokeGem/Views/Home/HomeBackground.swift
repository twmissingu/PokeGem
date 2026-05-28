import SwiftUI

struct HomeBackground: View {
    @State private var arcRotation: Double = 0
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GameColors.homeBackground
                .ignoresSafeArea()

            AngularGradient(
                gradient: Gradient(colors: [
                    .clear,
                    Color(red: 0.95, green: 0.75, blue: 0.10).opacity(0.06),
                    .clear,
                    Color(red: 0.80, green: 0.30, blue: 0.90).opacity(0.04),
                    .clear,
                ]),
                center: .center
            )
            .rotationEffect(.degrees(arcRotation))
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                    arcRotation = 360
                }
            }

            if let textureImage = UIImage(named: "background_texture") {
                Image(uiImage: textureImage)
                    .resizable(resizingMode: .tile)
                    .opacity(0.1)
                    .ignoresSafeArea()
            }

            if scenePhase == .active {
                FloatingGemParticles()
            }
        }
    }
}

struct FloatingGemParticles: View {
    struct Particle: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
        let color: Color
        let size: CGFloat
        let speedX: Double
        let speedY: Double
        let phase: Double
    }

    @State private var particles: [Particle] = [
        Particle(x: 0.2, y: 0.3, color: .red, size: 6, speedX: 0.3, speedY: 0.2, phase: 0),
        Particle(x: 0.7, y: 0.2, color: .blue, size: 5, speedX: -0.2, speedY: 0.35, phase: 1.2),
        Particle(x: 0.5, y: 0.6, color: .green, size: 4, speedX: 0.25, speedY: -0.15, phase: 2.8),
        Particle(x: 0.8, y: 0.7, color: .yellow, size: 5, speedX: -0.15, speedY: 0.25, phase: 4.1),
        Particle(x: 0.3, y: 0.8, color: .white, size: 3, speedX: 0.2, speedY: -0.2, phase: 5.5),
        Particle(x: 0.15, y: 0.5, color: .purple, size: 4, speedX: 0.35, speedY: 0.15, phase: 3.3),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let px = (particle.x + cos(time * particle.speedX + particle.phase) * 0.08) * size.width
                    let py = (particle.y + sin(time * particle.speedY + particle.phase) * 0.08) * size.height
                    context.fill(
                        Circle().path(in: CGRect(x: px - particle.size/2, y: py - particle.size/2,
                                                  width: particle.size, height: particle.size)),
                        with: .color(particle.color.opacity(0.12))
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
}
