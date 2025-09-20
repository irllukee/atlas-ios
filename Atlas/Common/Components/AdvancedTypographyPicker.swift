import SwiftUI
import UIKit

/// Advanced typography picker with font family, size, and color options
struct AdvancedTypographyPicker: View {
    @Binding var selectedFontFamily: String
    @Binding var selectedFontSize: CGFloat
    @Binding var selectedTextColor: Color
    @Binding var selectedBackgroundColor: Color
    @Binding var isPresented: Bool
    
    let onApply: (FontFamily, CGFloat, Color, Color) -> Void
    
    @State private var fontFamily: FontFamily = .system
    @State private var fontSize: CGFloat = 16
    @State private var textColor: Color = .primary
    @State private var backgroundColor: Color = .clear
    
    private let fontSizes: [CGFloat] = [10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 64]
    
    var body: some View {
        NavigationView {
            Form {
                // Font Family Section
                Section("Font Family") {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        HStack {
                            Text(family.displayName)
                                .font(.custom(family.fontName, size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if fontFamily == family {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            fontFamily = family
                        }
                    }
                }
                
                // Font Size Section
                Section("Font Size") {
                    HStack {
                        Text("Size: \(Int(fontSize))")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        Stepper("", value: $fontSize, in: 8...72, step: 1)
                            .labelsHidden()
                    }
                    
                    // Quick size buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(fontSizes, id: \.self) { size in
                            Button(action: {
                                fontSize = size
                            }) {
                                Text("\(Int(size))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(fontSize == size ? .white : .primary)
                                    .frame(width: 40, height: 32)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(fontSize == size ? Color.blue : Color(.systemGray6))
                                    )
                            }
                        }
                    }
                }
                
                // Text Color Section
                Section("Text Color") {
                    HStack {
                        Text("Color")
                        
                        Spacer()
                        
                        Circle()
                            .fill(textColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                            .onTapGesture {
                                // Show color picker
                            }
                    }
                    
                    // Quick color buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(quickColors, id: \.self) { color in
                            Button(action: {
                                textColor = color
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(textColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                
                // Background Color Section
                Section("Background Color") {
                    HStack {
                        Text("Background")
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(backgroundColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary, lineWidth: 1)
                            )
                            .onTapGesture {
                                // Show color picker
                            }
                    }
                    
                    // Quick background color buttons
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                        ForEach(quickBackgroundColors, id: \.self) { color in
                            Button(action: {
                                backgroundColor = color
                            }) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(backgroundColor == color ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                    }
                }
                
                // Preview Section
                Section("Preview") {
                    Text("Sample Text")
                        .font(.custom(fontFamily.fontName, size: fontSize))
                        .foregroundColor(textColor)
                        .background(backgroundColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .navigationTitle("Typography")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply(fontFamily, fontSize, textColor, backgroundColor)
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            // Initialize with current values
            fontFamily = FontFamily.fromString(selectedFontFamily)
            fontSize = selectedFontSize
            textColor = selectedTextColor
            backgroundColor = selectedBackgroundColor
        }
    }
    
    private let quickColors: [Color] = [
        .primary, .secondary, .red, .orange, .yellow, .green, .blue, .purple,
        .pink, .brown, .gray, .black, .white, .cyan, .mint, .indigo
    ]
    
    private let quickBackgroundColors: [Color] = [
        .clear, .white, .black, .red, .orange, .yellow, .green, .blue,
        .purple, .pink, .brown, .gray, .cyan, .mint, .indigo, Color(.systemGray6)
    ]
}

// MARK: - Font Family Enum
enum FontFamily: String, CaseIterable {
    case system = "System"
    case serif = "Serif"
    case monospace = "Monospace"
    case rounded = "Rounded"
    case condensed = "Condensed"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Serif"
        case .monospace: return "Monospace"
        case .rounded: return "Rounded"
        case .condensed: return "Condensed"
        }
    }
    
    var fontName: String {
        switch self {
        case .system: return "System"
        case .serif: return "Times New Roman"
        case .monospace: return "Menlo"
        case .rounded: return "Helvetica Neue"
        case .condensed: return "Helvetica Neue Condensed"
        }
    }
    
    static func fromString(_ string: String) -> FontFamily {
        return FontFamily(rawValue: string) ?? .system
    }
}

// MARK: - Typography Extensions for RichTextEditor
extension RichTextEditor {
    
    /// Apply font family to selected text or typing attributes
    func applyFontFamily(_ fontFamily: FontFamily) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentFont = textView.typingAttributes[.font] as? UIFont ?? font
        
        let newFont = UIFont(name: fontFamily.fontName, size: currentFont.pointSize) ?? currentFont
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedString.addAttribute(.font, value: newFont, range: selectedRange)
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            textView.typingAttributes[.font] = newFont
        }
    }
    
    /// Apply font size to selected text or typing attributes
    func applyFontSize(_ size: CGFloat) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentFont = textView.typingAttributes[.font] as? UIFont ?? font
        
        let newFont = currentFont.withSize(size)
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedString.addAttribute(.font, value: newFont, range: selectedRange)
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            textView.typingAttributes[.font] = newFont
        }
    }
    
    /// Apply text color to selected text or typing attributes
    func applyTextColor(_ color: Color) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let uiColor = UIColor(color)
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedString.addAttribute(.foregroundColor, value: uiColor, range: selectedRange)
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            textView.typingAttributes[.foregroundColor] = uiColor
        }
    }
    
    /// Apply background color to selected text or typing attributes
    func applyBackgroundColor(_ color: Color) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let uiColor = UIColor(color)
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedString.addAttribute(.backgroundColor, value: uiColor, range: selectedRange)
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            textView.typingAttributes[.backgroundColor] = uiColor
        }
    }
    
    /// Get current font family from selected text or typing attributes
    func getCurrentFontFamily() -> FontFamily {
        guard let textView = textView else { return .system }
        
        let selectedRange = textView.selectedRange
        let currentFont = selectedRange.length > 0 ?
            attributedText.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont :
            textView.typingAttributes[.font] as? UIFont
        
        let fontName = currentFont?.fontName ?? font.fontName
        
        for family in FontFamily.allCases {
            if fontName.contains(family.fontName) {
                return family
            }
        }
        
        return .system
    }
    
    /// Get current font size from selected text or typing attributes
    func getCurrentFontSize() -> CGFloat {
        guard let textView = textView else { return 16 }
        
        let selectedRange = textView.selectedRange
        let currentFont = selectedRange.length > 0 ?
            attributedText.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont :
            textView.typingAttributes[.font] as? UIFont
        
        return currentFont?.pointSize ?? font.pointSize
    }
    
    /// Get current text color from selected text or typing attributes
    func getCurrentTextColor() -> Color {
        guard let textView = textView else { return .primary }
        
        let selectedRange = textView.selectedRange
        let currentColor = selectedRange.length > 0 ?
            attributedText.attribute(.foregroundColor, at: selectedRange.location, effectiveRange: nil) as? UIColor :
            textView.typingAttributes[.foregroundColor] as? UIColor
        
        return currentColor.map(Color.init) ?? .primary
    }
    
    /// Get current background color from selected text or typing attributes
    func getCurrentBackgroundColor() -> Color {
        guard let textView = textView else { return .clear }
        
        let selectedRange = textView.selectedRange
        let currentColor = selectedRange.length > 0 ?
            attributedText.attribute(.backgroundColor, at: selectedRange.location, effectiveRange: nil) as? UIColor :
            textView.typingAttributes[.backgroundColor] as? UIColor
        
        return currentColor.map(Color.init) ?? .clear
    }
}
