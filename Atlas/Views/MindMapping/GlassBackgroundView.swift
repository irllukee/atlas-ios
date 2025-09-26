import SwiftUI

/// Glass Background View with parallax effects - adapted to use Atlas theme
struct GlassBackgroundView: View {
    // Parallax offset driven by the map camera
    var parallaxOffset: CGSize

    var body: some View {
        ZStack {
            // Dark base gradient using Atlas theme
            LinearGradient(
                colors: [.black, AtlasTheme.Colors.primary.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Optimized frosted "plates" using static gradients instead of expensive materials
            ForEach(0..<2, id: \.self) { i in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.06), lineWidth: 0.5)
                    )
                    // Removed blur for better performance - using gradient instead
                    .frame(width: 240 + CGFloat(i)*60, height: 160 + CGFloat(i)*40)
                    .offset(
                        x: parallaxOffset.width * (0.05 + CGFloat(i)*0.015) + CGFloat(i*30) - 80,
                        y: parallaxOffset.height * (0.05 + CGFloat(i)*0.015) - CGFloat(i*40)
                    )
                    .opacity(0.2 - Double(i)*0.08)
            }

            // Optimized bokeh orbs using radial gradients instead of blur
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AtlasTheme.Colors.primary.opacity(0.15),
                            AtlasTheme.Colors.primary.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -120 + parallaxOffset.width * 0.025,
                        y: 180 + parallaxOffset.height * 0.015)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .offset(x: 150 + parallaxOffset.width * -0.015,
                        y: -140 + parallaxOffset.height * -0.025)
        }
        // Only use drawingGroup for complex compositions - gradients are already optimized
        // .drawingGroup() // Removed for better performance
    }
}

// MARK: - Preview
#Preview {
    GlassBackgroundView(parallaxOffset: CGSize(width: 50, height: 30))
}
