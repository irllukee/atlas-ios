import SwiftUI

// MARK: - Enhanced Atlas Text Field
struct AtlasTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let style: TextFieldStyle
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let icon: String?
    let errorMessage: String?
    let onCommit: (() -> Void)?
    
    @State private var isFocused = false
    @State private var showPassword = false
    
    enum TextFieldStyle {
        case standard
        case filled
        case outlined
        case floating
    }
    
    init(
        _ title: String,
        placeholder: String = "",
        text: Binding<String>,
        style: TextFieldStyle = .standard,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        icon: String? = nil,
        errorMessage: String? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.style = style
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.icon = icon
        self.errorMessage = errorMessage
        self.onCommit = onCommit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            // Title
            if style == .floating {
                Text(title)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(isFocused ? AtlasTheme.Colors.primary : AtlasTheme.Colors.tertiaryText)
                    .animation(AtlasTheme.Animations.quick, value: isFocused)
            } else {
                Text(title)
                    .font(AtlasTheme.Typography.callout)
                    .foregroundColor(AtlasTheme.Colors.text)
            }
            
            // Text Field Container
            HStack(spacing: AtlasTheme.Spacing.md) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 20)
                }
                
                // Text Field
                Group {
                    if isSecure && !showPassword {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.text)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
                .onTapGesture {
                    withAnimation(AtlasTheme.Animations.quick) {
                        isFocused = true
                    }
                    AtlasTheme.Haptics.light()
                }
                .onSubmit {
                    onCommit?()
                }
                .accessibilityLabel(title)
                .accessibilityHint(accessibilityHint)
                .accessibilityValue(text.isEmpty ? "Empty" : text)
                
                // Password Toggle
                if isSecure {
                    Button(action: {
                        withAnimation(AtlasTheme.Animations.quick) {
                            showPassword.toggle()
                        }
                        AtlasTheme.Haptics.selection()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AtlasTheme.Colors.tertiaryText)
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundView)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .animation(AtlasTheme.Animations.quick, value: isFocused)
            .animation(AtlasTheme.Animations.quick, value: errorMessage != nil)
            
            // Error Message
            if let errorMessage = errorMessage {
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AtlasTheme.Colors.error)
                    
                    Text(errorMessage)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.error)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onTapGesture {
            // Allow tapping anywhere in the container to focus
            withAnimation(AtlasTheme.Animations.quick) {
                isFocused = true
            }
        }
    }
    
    // MARK: - Style Properties
    private var horizontalPadding: CGFloat {
        switch style {
        case .standard, .filled, .outlined:
            return AtlasTheme.Spacing.md
        case .floating:
            return AtlasTheme.Spacing.lg
        }
    }
    
    private var verticalPadding: CGFloat {
        switch style {
        case .standard, .filled, .outlined:
            return AtlasTheme.Spacing.md
        case .floating:
            return AtlasTheme.Spacing.lg
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .standard, .filled, .outlined:
            return AtlasTheme.CornerRadius.medium
        case .floating:
            return AtlasTheme.CornerRadius.large
        }
    }
    
    private var iconColor: Color {
        if errorMessage != nil {
            return AtlasTheme.Colors.error
        } else if isFocused {
            return AtlasTheme.Colors.primary
        } else {
            return AtlasTheme.Colors.tertiaryText
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(backgroundColor)
    }
    
    private var backgroundColor: some ShapeStyle {
        switch style {
        case .standard:
            return AtlasTheme.Colors.glassBackground
        case .filled:
            return AtlasTheme.Colors.glassBackgroundHeavy
        case .outlined:
            return Color.clear
        case .floating:
            return AtlasTheme.Colors.glassBackground
        }
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return AtlasTheme.Colors.error
        } else if isFocused {
            return AtlasTheme.Colors.primary
        } else {
            switch style {
            case .standard, .filled, .floating:
                return AtlasTheme.Colors.glassBorder
            case .outlined:
                return AtlasTheme.Colors.glassBorder.opacity(0.5)
            }
        }
    }
    
    private var borderWidth: CGFloat {
        if isFocused || errorMessage != nil {
            return 2.0
        } else {
            return 1.0
        }
    }
    
    private var accessibilityHint: String {
        if isSecure {
            return "Secure text field for \(title.lowercased())"
        } else {
            return "Text field for \(title.lowercased())"
        }
    }
}

// MARK: - Atlas Text Editor
struct AtlasTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let style: TextFieldStyle
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let errorMessage: String?
    
    @State private var isFocused = false
    
    enum TextFieldStyle {
        case standard
        case filled
        case outlined
    }
    
    init(
        _ title: String,
        placeholder: String = "",
        text: Binding<String>,
        style: TextFieldStyle = .standard,
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 200,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.style = style
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
            // Title
            Text(title)
                .font(AtlasTheme.Typography.callout)
                .foregroundColor(AtlasTheme.Colors.text)
            
            // Text Editor Container
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                
                // Text Editor
                TextEditor(text: $text)
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.text)
                    .padding(AtlasTheme.Spacing.md)
                    .background(Color.clear)
                    .onTapGesture {
                        withAnimation(AtlasTheme.Animations.quick) {
                            isFocused = true
                        }
                        AtlasTheme.Haptics.light()
                    }
                
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.tertiaryText)
                        .padding(AtlasTheme.Spacing.md)
                        .allowsHitTesting(false)
                }
            }
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .animation(AtlasTheme.Animations.quick, value: isFocused)
            .animation(AtlasTheme.Animations.quick, value: errorMessage != nil)
            
            // Error Message
            if let errorMessage = errorMessage {
                HStack(spacing: AtlasTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AtlasTheme.Colors.error)
                    
                    Text(errorMessage)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.error)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var backgroundColor: some ShapeStyle {
        switch style {
        case .standard:
            return AtlasTheme.Colors.glassBackground
        case .filled:
            return AtlasTheme.Colors.glassBackground
        case .outlined:
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if errorMessage != nil {
            return AtlasTheme.Colors.error
        } else if isFocused {
            return AtlasTheme.Colors.primary
        } else {
            switch style {
            case .standard, .filled:
                return AtlasTheme.Colors.glassBorder
            case .outlined:
                return AtlasTheme.Colors.glassBorder.opacity(0.5)
            }
        }
    }
    
    private var borderWidth: CGFloat {
        if isFocused || errorMessage != nil {
            return 2.0
        } else {
            return 1.0
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AtlasTextField("Email", placeholder: "Enter your email", text: .constant(""), icon: "envelope.fill")
        
        AtlasTextField("Password", placeholder: "Enter your password", text: .constant(""), isSecure: true, icon: "lock.fill")
        
        AtlasTextField("Search", placeholder: "Search...", text: .constant(""), style: .filled, icon: "magnifyingglass")
        
        AtlasTextEditor("Notes", placeholder: "Write your notes here...", text: .constant(""), minHeight: 80)
    }
    .padding()
    .background(AtlasTheme.Colors.background)
}
