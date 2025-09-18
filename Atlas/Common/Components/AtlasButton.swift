import SwiftUI

// MARK: - Enhanced Atlas Button Component
struct AtlasButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        case destructive
        case success
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            AtlasTheme.Haptics.light()
            action()
        }) {
            HStack(spacing: spacing) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(iconFont)
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(textFont)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundView)
            .scaleEffect(scale)
            .animation(AtlasTheme.Animations.snappy, value: scale)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(AtlasTheme.Animations.snappy) {
                scale = pressing ? 0.95 : 1.0
                isPressed = pressing
            }
            
            if pressing {
                AtlasTheme.Haptics.light()
            }
        }, perform: {})
    }
    
    // MARK: - Style Properties
    private var spacing: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    private var textFont: Font {
        switch size {
        case .small: return AtlasTheme.Typography.caption
        case .medium: return AtlasTheme.Typography.callout
        case .large: return AtlasTheme.Typography.body
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small: return .system(size: 12, weight: .medium)
        case .medium: return .system(size: 14, weight: .medium)
        case .large: return .system(size: 16, weight: .medium)
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return AtlasTheme.Spacing.md
        case .medium: return AtlasTheme.Spacing.lg
        case .large: return AtlasTheme.Spacing.xl
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return AtlasTheme.Spacing.sm
        case .medium: return AtlasTheme.Spacing.md
        case .large: return AtlasTheme.Spacing.lg
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return AtlasTheme.Colors.textOnPrimary
        case .secondary:
            return AtlasTheme.Colors.text
        case .ghost:
            return AtlasTheme.Colors.text
        case .destructive:
            return AtlasTheme.Colors.textOnPrimary
        case .success:
            return AtlasTheme.Colors.textOnPrimary
        }
    }
    
    private var iconColor: Color {
        return textColor
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small: return AtlasTheme.CornerRadius.small
        case .medium: return AtlasTheme.CornerRadius.medium
        case .large: return AtlasTheme.CornerRadius.large
        }
    }
    
    private var backgroundColor: some ShapeStyle {
        switch style {
        case .primary:
            return AtlasTheme.Colors.primary
        case .secondary:
            return AtlasTheme.Colors.glassBackground
        case .ghost:
            return Color.clear
        case .destructive:
            return AtlasTheme.Colors.error
        case .success:
            return AtlasTheme.Colors.success
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary, .destructive, .success:
            return Color.clear
        case .secondary:
            return AtlasTheme.Colors.glassBorder
        case .ghost:
            return AtlasTheme.Colors.glassBorder.opacity(0.5)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary, .destructive, .success:
            return 0
        case .secondary, .ghost:
            return 1
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .primary, .destructive, .success:
            return Color.black.opacity(0.2)
        case .secondary:
            return AtlasTheme.Colors.glassShadow
        case .ghost:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .primary, .destructive, .success:
            return 8
        case .secondary:
            return 4
        case .ghost:
            return 0
        }
    }
    
    private var shadowOffset: CGFloat {
        switch style {
        case .primary, .destructive, .success:
            return 4
        case .secondary:
            return 2
        case .ghost:
            return 0
        }
    }
    
    private var accessibilityHint: String {
        switch style {
        case .primary:
            return "Primary action button"
        case .secondary:
            return "Secondary action button"
        case .ghost:
            return "Ghost action button"
        case .destructive:
            return "Destructive action button"
        case .success:
            return "Success action button"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AtlasButton("Primary Button", icon: "star.fill", style: .primary, size: .large) {
            print("Primary tapped")
        }
        
        AtlasButton("Secondary Button", icon: "heart.fill", style: .secondary, size: .medium) {
            print("Secondary tapped")
        }
        
        AtlasButton("Ghost Button", style: .ghost, size: .small) {
            print("Ghost tapped")
        }
        
        HStack(spacing: 12) {
            AtlasButton("Success", style: .success, size: .small) {
                print("Success tapped")
            }
            
            AtlasButton("Destructive", style: .destructive, size: .small) {
                print("Destructive tapped")
            }
        }
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}
