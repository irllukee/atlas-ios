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

            // Frosted "plates" that drift with parallax
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    )
                    .blur(radius: 8)
                    .frame(width: 280 + CGFloat(i)*80, height: 180 + CGFloat(i)*60)
                    .offset(
                        x: parallaxOffset.width * (0.06 + CGFloat(i)*0.02) + CGFloat(i*40) - 120,
                        y: parallaxOffset.height * (0.06 + CGFloat(i)*0.02) - CGFloat(i*50)
                    )
                    .opacity(0.25 - Double(i)*0.05)
            }

            // Soft bokeh orbs using Atlas theme colors
            Circle()
                .fill(AtlasTheme.Colors.primary.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -140 + parallaxOffset.width * 0.03,
                        y: 220 + parallaxOffset.height * 0.02)

            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 180 + parallaxOffset.width * -0.02,
                        y: -160 + parallaxOffset.height * -0.03)
        }
        .drawingGroup()
    }
}

// MARK: - Preview
#Preview {
    GlassBackgroundView(parallaxOffset: CGSize(width: 50, height: 30))
}
