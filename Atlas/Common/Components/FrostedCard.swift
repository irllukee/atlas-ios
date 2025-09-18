import SwiftUI

// MARK: - Frosted Card Component
struct FrostedCard<Content: View>: View {
    let style: CardStyle
    let content: Content
    
    enum CardStyle {
        case standard
        case compact
        case floating
        case metric
    }
    
    init(style: CardStyle = .standard, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassmorphism(style: glassmorphismStyle, cornerRadius: cornerRadius)
            .scaleEffect(scaleEffect)
            .animation(AtlasTheme.Animations.smooth, value: scaleEffect)
    }
    
    // MARK: - Style Properties
    private var padding: EdgeInsets {
        switch style {
        case .standard:
            return EdgeInsets(top: AtlasTheme.Spacing.lg, leading: AtlasTheme.Spacing.lg, bottom: AtlasTheme.Spacing.lg, trailing: AtlasTheme.Spacing.lg)
        case .compact:
            return EdgeInsets(top: AtlasTheme.Spacing.md, leading: AtlasTheme.Spacing.md, bottom: AtlasTheme.Spacing.md, trailing: AtlasTheme.Spacing.md)
        case .floating:
            return EdgeInsets(top: AtlasTheme.Spacing.xl, leading: AtlasTheme.Spacing.xl, bottom: AtlasTheme.Spacing.xl, trailing: AtlasTheme.Spacing.xl)
        case .metric:
            return EdgeInsets(top: AtlasTheme.Spacing.lg, leading: AtlasTheme.Spacing.md, bottom: AtlasTheme.Spacing.lg, trailing: AtlasTheme.Spacing.md)
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard, .compact, .metric:
            return AtlasTheme.CornerRadius.medium
        case .floating:
            return AtlasTheme.CornerRadius.large
        }
    }
    
    private var glassmorphismStyle: GlassmorphismModifier.GlassStyle {
        switch style {
        case .standard, .compact, .metric:
            return .card
        case .floating:
            return .floating
        }
    }
    
    private var scaleEffect: CGFloat {
        switch style {
        case .standard, .compact, .metric:
            return 1.0
        case .floating:
            return 0.98
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        FrostedCard(style: .standard) {
            Text("Standard Card")
                .font(AtlasTheme.Typography.headline)
                .foregroundColor(AtlasTheme.Colors.text)
        }
        
        FrostedCard(style: .compact) {
            Text("Compact Card")
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.text)
        }
        
        FrostedCard(style: .floating) {
            Text("Floating Card")
                .font(AtlasTheme.Typography.title2)
                .foregroundColor(AtlasTheme.Colors.text)
        }
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}