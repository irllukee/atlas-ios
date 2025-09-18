import SwiftUI

struct GalaxyIcon: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Outer ring of stars
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.15, weight: .medium))
                    .foregroundColor(color.opacity(0.7))
                    .offset(
                        x: cos(Double(index) * .pi / 4) * size * 0.35,
                        y: sin(Double(index) * .pi / 4) * size * 0.35
                    )
            }
            
            // Inner ring of stars
            ForEach(0..<6, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                    .offset(
                        x: cos(Double(index) * .pi / 3) * size * 0.2,
                        y: sin(Double(index) * .pi / 3) * size * 0.2
                    )
            }
            
            // Central bright core
            Image(systemName: "circle.fill")
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(color)
            
            // Central sparkle
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

// Alternative galaxy icon with spiral pattern
struct SpiralGalaxyIcon: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Spiral arm 1
            ForEach(0..<4, id: \.self) { index in
                let angle = Double(index) * .pi / 6 + .pi / 4
                let radius = size * 0.15 + CGFloat(index) * size * 0.08
                let xOffset = cos(angle) * radius
                let yOffset = sin(angle) * radius
                
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundColor(color.opacity(0.6))
                    .offset(x: xOffset, y: yOffset)
            }
            
            // Spiral arm 2
            ForEach(0..<4, id: \.self) { index in
                let angle = Double(index) * .pi / 6 - .pi / 4
                let radius = size * 0.15 + CGFloat(index) * size * 0.08
                let xOffset = cos(angle) * radius
                let yOffset = sin(angle) * radius
                
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundColor(color.opacity(0.6))
                    .offset(x: xOffset, y: yOffset)
            }
            
            // Central bright core
            Image(systemName: "circle.fill")
                .font(.system(size: size * 0.25, weight: .bold))
                .foregroundColor(color)
            
            // Central sparkle
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.15, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

// Simple galaxy icon using circle.grid
struct SimpleGalaxyIcon: View {
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 20, color: Color = .white) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
            
            // Grid pattern
            Image(systemName: "circle.grid.3x3.fill")
                .font(.system(size: size * 0.7, weight: .medium))
                .foregroundColor(color)
            
            // Central bright point
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            GalaxyIcon(size: 30, color: .blue)
            SpiralGalaxyIcon(size: 30, color: .purple)
            SimpleGalaxyIcon(size: 30, color: .cyan)
        }
        
        HStack(spacing: 20) {
            GalaxyIcon(size: 20, color: .yellow)
            SpiralGalaxyIcon(size: 20, color: .pink)
            SimpleGalaxyIcon(size: 20, color: .green)
        }
    }
    .padding()
    .background(Color.black)
}
