import SwiftUI

// MARK: - Progress Ring Component
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    let backgroundColor: Color
    let size: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, lineWidth: CGFloat = 8, color: Color = AtlasTheme.Colors.primary, backgroundColor: Color = AtlasTheme.Colors.glassBorder, size: CGFloat = 60) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
        self.backgroundColor = backgroundColor
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Circular Progress (Alternative)
struct CircularProgress: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(progress: Double, color: Color = AtlasTheme.Colors.primary, size: CGFloat = 20, lineWidth: CGFloat = 2) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ProgressRing(progress: 0.7, color: AtlasTheme.Colors.success)
            ProgressRing(progress: 0.5, color: AtlasTheme.Colors.warning)
            ProgressRing(progress: 0.3, color: AtlasTheme.Colors.error)
        }
        
        HStack(spacing: 20) {
            CircularProgress(progress: 0.8, color: AtlasTheme.Colors.primary, size: 30)
            CircularProgress(progress: 0.6, color: AtlasTheme.Colors.success, size: 25)
            CircularProgress(progress: 0.4, color: AtlasTheme.Colors.warning, size: 20)
        }
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}
