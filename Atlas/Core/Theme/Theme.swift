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
        
        // Enhanced Glassmorphism Colors
        static let glassBackground = Color.white.opacity(0.12)
        static let glassBackgroundLight = Color.white.opacity(0.08)
        static let glassBackgroundHeavy = Color.white.opacity(0.18)
        static let glassBorder = Color.white.opacity(0.25)
        static let glassBorderLight = Color.white.opacity(0.15)
        static let glassBorderHeavy = Color.white.opacity(0.35)
        static let glassShadow = Color.black.opacity(0.15)
        static let glassShadowLight = Color.black.opacity(0.08)
        static let glassShadowHeavy = Color.black.opacity(0.25)
        
        // Gradient Overlays for Enhanced Glass Effect
        static let glassGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.2),
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Health App Colors (for metric cards)
        static let strain = Color(red: 1.0, green: 0.4, blue: 0.4)
        static let recovery = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let sleep = Color(red: 0.4, green: 0.6, blue: 1.0)
        static let nutrition = Color(red: 1.0, green: 0.8, blue: 0.2)
        
        // Enhanced Semantic Colors
        static let positive = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let negative = Color(red: 1.0, green: 0.4, blue: 0.4)
        static let neutral = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let highlight = Color(red: 0.6, green: 0.9, blue: 1.0)
        
        // Status Colors
        static let online = Color(red: 0.2, green: 0.8, blue: 0.4)
        static let offline = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let pending = Color(red: 1.0, green: 0.8, blue: 0.2)
        static let completed = Color(red: 0.2, green: 0.7, blue: 1.0)
    }
    
    // MARK: - Enhanced Typography
    struct Typography {
        // Display Styles
        static let display = Font.system(size: 40, weight: .bold, design: .rounded)
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body Styles
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let bodyEmphasized = Font.system(size: 17, weight: .medium, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        
        // Small Styles
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .rounded)
        
        // Special Styles
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let label = Font.system(size: 14, weight: .medium, design: .rounded)
        static let code = Font.system(size: 14, weight: .regular, design: .monospaced)
        static let quote = Font.system(size: 16, weight: .regular, design: .serif)
        
        // Weight Variants
        static func custom(size: CGFloat, weight: Font.Weight, design: Font.Design = .rounded) -> Font {
            return Font.system(size: size, weight: weight, design: design)
        }
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
    
    // MARK: - Animations (Optimized for Performance)
    struct Animations {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let gentle = SwiftUI.Animation.easeOut(duration: 0.4)
        static let snappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.9)
        
        // Performance-optimized animations
        static let optimizedSpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.85)
        static let optimizedGentle = SwiftUI.Animation.easeOut(duration: 0.3)
    }
    
    // MARK: - Haptic Feedback
    struct Haptics {
        @MainActor
        static func light() {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        @MainActor
        static func medium() {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        @MainActor
        static func heavy() {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
        
        @MainActor
        static func success() {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }
        
        @MainActor
        static func warning() {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
        
        @MainActor
        static func error() {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
        
        @MainActor
        static func selection() {
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        }
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Enhanced Glassmorphism Modifier
struct GlassmorphismModifier: ViewModifier {
    let style: GlassStyle
    let cornerRadius: CGFloat
    
    enum GlassStyle {
        case light
        case medium
        case heavy
        case floating
        case card
    }
    
    init(style: GlassStyle = .medium, cornerRadius: CGFloat = AtlasTheme.CornerRadius.medium) {
        self.style = style
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Main glass background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(backgroundFill)
                    
                    // Gradient overlay for enhanced glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AtlasTheme.Colors.glassGradient)
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: borderWidth)
                }
                .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            )
    }
    
    private var backgroundFill: some ShapeStyle {
        switch style {
        case .light:
            return AtlasTheme.Colors.glassBackgroundLight
        case .medium:
            return AtlasTheme.Colors.glassBackground
        case .heavy:
            return AtlasTheme.Colors.glassBackgroundHeavy
        case .floating:
            return AtlasTheme.Colors.glassBackground.opacity(0.8)
        case .card:
            return AtlasTheme.Colors.glassBackground
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .light:
            return AtlasTheme.Colors.glassBorderLight
        case .medium:
            return AtlasTheme.Colors.glassBorder
        case .heavy:
            return AtlasTheme.Colors.glassBorderHeavy
        case .floating:
            return AtlasTheme.Colors.glassBorder.opacity(0.6)
        case .card:
            return AtlasTheme.Colors.glassBorder
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .light, .medium, .card:
            return 1.0
        case .heavy:
            return 1.5
        case .floating:
            return 0.5
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .light:
            return AtlasTheme.Colors.glassShadowLight
        case .medium, .card:
            return AtlasTheme.Colors.glassShadow
        case .heavy:
            return AtlasTheme.Colors.glassShadowHeavy
        case .floating:
            return AtlasTheme.Colors.glassShadow.opacity(0.3)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .light:
            return 6
        case .medium, .card:
            return 12
        case .heavy:
            return 20
        case .floating:
            return 24
        }
    }
    
    private var shadowOffset: CGFloat {
        switch style {
        case .light:
            return 3
        case .medium, .card:
            return 6
        case .heavy:
            return 10
        case .floating:
            return 12
        }
    }
}

extension View {
    func glassmorphism(style: GlassmorphismModifier.GlassStyle = .medium, cornerRadius: CGFloat = AtlasTheme.CornerRadius.medium) -> some View {
        self.modifier(GlassmorphismModifier(style: style, cornerRadius: cornerRadius))
    }
}