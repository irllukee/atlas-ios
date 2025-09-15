import SwiftUI

// MARK: - Data Visualization Component
struct DataVisualization: View {
    let data: [Double]
    let lineColor: Color
    let gradientColors: [Color]
    let showIcons: Bool
    let icons: [String]
    
    @State private var animatedData: [Double] = []
    
    init(data: [Double], lineColor: Color = AtlasTheme.Colors.primary, gradientColors: [Color] = [AtlasTheme.Colors.primary.opacity(0.5), AtlasTheme.Colors.primary.opacity(0.0)], showIcons: Bool = false, icons: [String] = []) {
        self.data = data
        self.lineColor = lineColor
        self.gradientColors = gradientColors
        self.showIcons = showIcons
        self.icons = icons
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background grid
                GridLines(width: geometry.size.width, height: geometry.size.height)
                
                // Gradient fill
                Path { path in
                    createPath(in: geometry.size, path: &path)
                }
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line
                Path { path in
                    createPath(in: geometry.size, path: &path)
                }
                .stroke(lineColor, lineWidth: 2)
                
                // Data points with icons
                if showIcons && !icons.isEmpty {
                    ForEach(Array(animatedData.enumerated()), id: \.offset) { index, value in
                        if index < icons.count {
                            DataPoint(
                                value: value,
                                icon: icons[index],
                                maxValue: animatedData.max() ?? 1,
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                        }
                    }
                } else {
                    // Simple data points
                    ForEach(Array(animatedData.enumerated()), id: \.offset) { index, value in
                        Circle()
                            .fill(lineColor)
                            .frame(width: 6, height: 6)
                            .position(
                                x: CGFloat(index) * (geometry.size.width / CGFloat(animatedData.count - 1)),
                                y: geometry.size.height - (value / (animatedData.max() ?? 1)) * geometry.size.height
                            )
                    }
                }
            }
        }
        .onAppear {
            animateData()
        }
    }
    
    private func createPath(in size: CGSize, path: inout Path) {
        guard !animatedData.isEmpty else { return }
        
        let stepX = size.width / CGFloat(animatedData.count - 1)
        
        path.move(to: CGPoint(x: 0, y: size.height - (animatedData[0] / (animatedData.max() ?? 1)) * size.height))
        
        for i in 1..<animatedData.count {
            let x = CGFloat(i) * stepX
            let y = size.height - (animatedData[i] / (animatedData.max() ?? 1)) * size.height
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close path for gradient fill
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
    }
    
    private func animateData() {
        animatedData = Array(repeating: 0, count: data.count)
        
        withAnimation(.easeInOut(duration: 1.5)) {
            animatedData = data
        }
    }
}

// MARK: - Grid Lines
struct GridLines: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Path { path in
            // Horizontal lines
            for i in 0...4 {
                let y = height * CGFloat(i) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            
            // Vertical lines
            for i in 0...6 {
                let x = width * CGFloat(i) / 6
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(AtlasTheme.Colors.glassBorder.opacity(0.3), lineWidth: 0.5)
    }
}

// MARK: - Data Point with Icon
struct DataPoint: View {
    let value: Double
    let icon: String
    let maxValue: Double
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(AtlasTheme.Colors.primary)
            
            Circle()
                .fill(AtlasTheme.Colors.primary)
                .frame(width: 8, height: 8)
        }
        .position(
            x: width * 0.5, // Center for demo
            y: height - (value / maxValue) * height
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        DataVisualization(
            data: [10, 20, 15, 25, 30, 20, 35],
            lineColor: AtlasTheme.Colors.primary,
            gradientColors: [AtlasTheme.Colors.primary.opacity(0.5), AtlasTheme.Colors.primary.opacity(0.0)],
            showIcons: true,
            icons: ["moon.fill", "lightbulb.fill", "checkmark.circle.fill", "moon.fill", "lightbulb.fill", "checkmark.circle.fill", "moon.fill"]
        )
        .frame(height: 100)
        
        DataVisualization(
            data: [5, 15, 10, 20, 25, 30, 35],
            lineColor: AtlasTheme.Colors.success,
            gradientColors: [AtlasTheme.Colors.success.opacity(0.3), AtlasTheme.Colors.success.opacity(0.0)]
        )
        .frame(height: 80)
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}