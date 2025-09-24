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

            // Optimized frosted "plates" with reduced blur complexity
            ForEach(0..<2, id: \.self) { i in
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.thinMaterial) // Changed from ultraThinMaterial for better performance
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.06), lineWidth: 0.5)
                    )
                    .blur(radius: 4) // Reduced from 8
                    .frame(width: 240 + CGFloat(i)*60, height: 160 + CGFloat(i)*40)
                    .offset(
                        x: parallaxOffset.width * (0.05 + CGFloat(i)*0.015) + CGFloat(i*30) - 80,
                        y: parallaxOffset.height * (0.05 + CGFloat(i)*0.015) - CGFloat(i*40)
                    )
                    .opacity(0.2 - Double(i)*0.08)
            }

            // Optimized bokeh orbs with reduced blur
            Circle()
                .fill(AtlasTheme.Colors.primary.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 40) // Reduced from 60
                .offset(x: -120 + parallaxOffset.width * 0.025,
                        y: 180 + parallaxOffset.height * 0.015)

            Circle()
                .fill(.white.opacity(0.1))
                .frame(width: 180, height: 180)
                .blur(radius: 35) // Reduced from 50
                .offset(x: 150 + parallaxOffset.width * -0.015,
                        y: -140 + parallaxOffset.height * -0.025)
        }
        .drawingGroup()
    }
}

// MARK: - Preview
#Preview {
    GlassBackgroundView(parallaxOffset: CGSize(width: 50, height: 30))
}
