import SwiftUI

// MARK: - Enhanced Loading States
struct LoadingView: View {
    let message: String
    let style: LoadingStyle
    
    enum LoadingStyle {
        case spinner
        case dots
        case pulse
        case shimmer
    }
    
    init(_ message: String = "Loading...", style: LoadingStyle = .spinner) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            switch style {
            case .spinner:
                spinnerView
            case .dots:
                dotsView
            case .pulse:
                pulseView
            case .shimmer:
                shimmerView
            }
            
            Text(message)
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.secondaryText)
        }
        .padding(AtlasTheme.Spacing.xl)
        .glassmorphism(style: .light)
        .accessibilityLabel("Loading")
        .accessibilityHint(message)
        .onAppear {
            startAnimations()
        }
    }
    
    private var spinnerView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: AtlasTheme.Colors.primary))
            .scaleEffect(1.2)
    }
    
    private var dotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AtlasTheme.Colors.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(dotScale(for: index))
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: dotScale(for: index)
                    )
            }
        }
    }
    
    private var pulseView: some View {
        Circle()
            .fill(AtlasTheme.Colors.primary.opacity(0.3))
            .frame(width: 40, height: 40)
            .scaleEffect(pulseScale)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: pulseScale
            )
    }
    
    private var shimmerView: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(AtlasTheme.Colors.primary.opacity(0.3))
            .frame(width: 60, height: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                AtlasTheme.Colors.primary.opacity(0.8),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmerOffset)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            )
            .clipped()
    }
    
    @State private var dotScale: [CGFloat] = [1.0, 1.0, 1.0]
    @State private var pulseScale: CGFloat = 1.0
    @State private var shimmerOffset: CGFloat = -60
    
    private func dotScale(for index: Int) -> CGFloat {
        return dotScale[index]
    }
    
    private func startAnimations() {
        // Start dot animation
        if style == .dots {
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                dotScale = [1.5, 1.0, 1.0]
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                    dotScale = [1.0, 1.5, 1.0]
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(Animation.easeInOut(duration: 0.6).repeatForever()) {
                    dotScale = [1.0, 1.0, 1.5]
                }
            }
        }
        
        // Start pulse animation
        if style == .pulse {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
        
        // Start shimmer animation
        if style == .shimmer {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 60
            }
        }
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var isAnimating = false
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AtlasTheme.Colors.glassBackground)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                AtlasTheme.Colors.primary.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let isVisible: Bool
    let message: String
    let style: LoadingView.LoadingStyle
    
    init(isVisible: Bool, message: String = "Loading...", style: LoadingView.LoadingStyle = .spinner) {
        self.isVisible = isVisible
        self.message = message
        self.style = style
    }
    
    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                LoadingView(message, style: style)
                    .transition(.scale.combined(with: .opacity))
            }
            .animation(AtlasTheme.Animations.smooth, value: isVisible)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        LoadingView("Loading data...", style: .spinner)
        
        LoadingView("Processing...", style: .dots)
        
        LoadingView("Syncing...", style: .pulse)
        
        LoadingView("Analyzing...", style: .shimmer)
        
        VStack(spacing: 12) {
            SkeletonView(width: 200, height: 16)
            SkeletonView(width: 150, height: 16)
            SkeletonView(width: 180, height: 16)
        }
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}
