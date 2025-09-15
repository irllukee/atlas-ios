import SwiftUI

// MARK: - Atlas Theme System
struct AtlasTheme {
    
    // MARK: - Colors
    struct Colors {
        // Background Gradients - Sky blue, airy, modern look
        static let background = LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.7, blue: 1.0),   // Sky blue
                Color(red: 0.6, green: 0.8, blue: 1.0),   // Light sky blue
                Color(red: 0.8, green: 0.9, blue: 1.0)    // Very light blue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let backgroundDark = LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),   // Deep blue
                Color(red: 0.05, green: 0.15, blue: 0.3), // Darker blue
                Color(red: 0.02, green: 0.1, blue: 0.25)  // Deepest blue
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Primary Colors
        static let primary = Color(red: 0.2, green: 0.6, blue: 1.0)
        static let secondary = Color(red: 0.4, green: 0.8, blue: 1.0)
        static let accent = Color(red: 0.6, green: 0.9, blue: 1.0)
        
        // Semantic Colors
        static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let warning = Color(red: 1.0, green: 0.8, blue: 0.2)
        static let error = Color(red: 1.0, green: 0.4, blue: 0.4)
        static let info = Color(red: 0.2, green: 0.7, blue: 1.0)
        
        // Text Colors
        static let text = Color.white
        static let secondaryText = Color.white.opacity(0.8)
        static let tertiaryText = Color.white.opacity(0.6)
        static let textOnPrimary = Color.white
        
        // Glassmorphism Colors
        static let glassBackground = Color.white.opacity(0.1)
        static let glassBorder = Color.white.opacity(0.2)
        static let glassShadow = Color.black.opacity(0.1)
        
        // Health App Colors (for metric cards)
        static let strain = Color(red: 1.0, green: 0.4, blue: 0.4)
        static let recovery = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let sleep = Color(red: 0.4, green: 0.6, blue: 1.0)
        static let nutrition = Color(red: 1.0, green: 0.8, blue: 0.2)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let xxlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: Colors.glassShadow, radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: Colors.glassShadow, radius: 8, x: 0, y: 4)
        static let large = Shadow(color: Colors.glassShadow, radius: 16, x: 0, y: 8)
        static let xlarge = Shadow(color: Colors.glassShadow, radius: 24, x: 0, y: 12)
    }
    
    // MARK: - Animations
    struct Animations {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Glassmorphism Modifier
struct GlassmorphismModifier: ViewModifier {
    let style: GlassStyle
    
    enum GlassStyle {
        case light
        case medium
        case heavy
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .fill(AtlasTheme.Colors.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                    )
                    .blur(radius: blurRadius)
            )
    }
    
    private var blurRadius: CGFloat {
        switch style {
        case .light: return 10
        case .medium: return 20
        case .heavy: return 30
        }
    }
}

extension View {
    func glassmorphism(style: GlassmorphismModifier.GlassStyle = .medium) -> some View {
        self.modifier(GlassmorphismModifier(style: style))
    }
}