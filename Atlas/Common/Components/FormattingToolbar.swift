import SwiftUI

/// A formatting toolbar for rich text editing
struct FormattingToolbar: View {
    @Binding var richTextEditor: RichTextEditor?
    @State private var formattingState = FormattingState()
    @State private var showingTypographyPicker = false
    @State private var showingHTMLExportImport = false
    @State private var selectedFontFamily = "System"
    @State private var selectedFontSize: CGFloat = 16
    @State private var selectedTextColor: Color = .primary
    @State private var selectedBackgroundColor: Color = .clear
    
    let onFormattingChange: ((FormattingState) -> Void)?
    
    init(
        richTextEditor: Binding<RichTextEditor?>,
        onFormattingChange: ((FormattingState) -> Void)? = nil
    ) {
        self._richTextEditor = richTextEditor
        self.onFormattingChange = onFormattingChange
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Bold Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleBold()
                updateFormattingState()
            }) {
                Image(systemName: "bold")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(formattingState.isBold ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(formattingState.isBold ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Italic Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleItalic()
                updateFormattingState()
            }) {
                Image(systemName: "italic")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(formattingState.isItalic ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(formattingState.isItalic ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Underline Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleUnderline()
                updateFormattingState()
            }) {
                Image(systemName: "underline")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(formattingState.isUnderlined ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(formattingState.isUnderlined ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Strikethrough Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleStrikethrough()
                updateFormattingState()
            }) {
                Image(systemName: "strikethrough")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(formattingState.isStrikethrough ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(formattingState.isStrikethrough ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Blockquote Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleBlockquote()
                updateFormattingState()
            }) {
                Image(systemName: "quote.bubble")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(formattingState.isBlockquote ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(formattingState.isBlockquote ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Code Block Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleCodeBlock()
                updateFormattingState()
            }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(formattingState.isCodeBlock ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(formattingState.isCodeBlock ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Inline Code Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleInlineCode()
                updateFormattingState()
            }) {
                Image(systemName: "curlybraces")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(formattingState.isInlineCode ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(formattingState.isInlineCode ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Link Button
            Button(action: {
                AtlasTheme.Haptics.light()
                richTextEditor?.toggleLink()
                updateFormattingState()
            }) {
                Image(systemName: "link")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(richTextEditor?.hasLinkFormatting() == true ? AtlasTheme.Colors.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(richTextEditor?.hasLinkFormatting() == true ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                    )
            }
            
            // Typography Button
            Button(action: {
                AtlasTheme.Haptics.light()
                showingTypographyPicker = true
            }) {
                Image(systemName: "textformat")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
            
            // HTML Export/Import Button
            Button(action: {
                AtlasTheme.Haptics.light()
                showingHTMLExportImport = true
            }) {
                Image(systemName: "globe")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
            
            Spacer()
            
            // Additional formatting options can be added here
            // For example: font size, text color, alignment, etc.
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: -1)
        )
        .onAppear {
            updateFormattingState()
        }
    }
    
    private func updateFormattingState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let editor = richTextEditor {
                let newState = editor.getCurrentFormattingState()
                if newState != formattingState {
                    formattingState = newState
                    onFormattingChange?(newState)
                }
            }
        }
    }
}

/// A more comprehensive formatting toolbar with additional options
struct AdvancedFormattingToolbar: View {
    @Binding var richTextEditor: RichTextEditor?
    @State private var formattingState = FormattingState()
    @State private var showingFontPicker = false
    @State private var showingColorPicker = false
    
    let onFormattingChange: ((FormattingState) -> Void)?
    
    init(
        richTextEditor: Binding<RichTextEditor?>,
        onFormattingChange: ((FormattingState) -> Void)? = nil
    ) {
        self._richTextEditor = richTextEditor
        self.onFormattingChange = onFormattingChange
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Primary formatting row
            HStack(spacing: 16) {
                // Bold Button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    richTextEditor?.toggleBold()
                    updateFormattingState()
                }) {
                    Image(systemName: "bold")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(formattingState.isBold ? AtlasTheme.Colors.accent : .primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(formattingState.isBold ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                        )
                }
                
                // Italic Button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    richTextEditor?.toggleItalic()
                    updateFormattingState()
                }) {
                    Image(systemName: "italic")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(formattingState.isItalic ? AtlasTheme.Colors.accent : .primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(formattingState.isItalic ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                        )
                }
                
                // Underline Button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    richTextEditor?.toggleUnderline()
                    updateFormattingState()
                }) {
                    Image(systemName: "underline")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(formattingState.isUnderlined ? AtlasTheme.Colors.accent : .primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(formattingState.isUnderlined ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                        )
                }
                
                // Strikethrough Button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    richTextEditor?.toggleStrikethrough()
                    updateFormattingState()
                }) {
                    Image(systemName: "strikethrough")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(formattingState.isStrikethrough ? AtlasTheme.Colors.accent : .primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(formattingState.isStrikethrough ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                        )
                }
                
                Spacer()
                
                // Font size button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingFontPicker.toggle()
                }) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
                
                // Text color button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingColorPicker.toggle()
                }) {
                    Image(systemName: "textformat")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Secondary formatting row (optional - can be toggled)
            if showingFontPicker || showingColorPicker {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(spacing: 16) {
                    if showingFontPicker {
                        FontSizePicker()
                    }
                    
                    if showingColorPicker {
                        TextColorPicker()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: -1)
        )
        .onAppear {
            updateFormattingState()
        }
    }
    
    private func updateFormattingState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let editor = richTextEditor {
                let newState = editor.getCurrentFormattingState()
                if newState != formattingState {
                    formattingState = newState
                    onFormattingChange?(newState)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct FontSizePicker: View {
    @State private var fontSize: CGFloat = 16
    let fontSizes: [CGFloat] = [12, 14, 16, 18, 20, 24, 28, 32]
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Size:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            ForEach(fontSizes, id: \.self) { size in
                Button(action: {
                    AtlasTheme.Haptics.light()
                    fontSize = size
                    // TODO: Apply font size to selected text
                }) {
                    Text("\(Int(size))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(fontSize == size ? AtlasTheme.Colors.accent : .primary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(fontSize == size ? AtlasTheme.Colors.accent.opacity(0.2) : Color.clear)
                        )
                }
            }
        }
    }
}

struct TextColorPicker: View {
    @State private var selectedColor: Color = .primary
    let colors: [Color] = [
        .primary, .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Color:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            ForEach(colors, id: \.self) { color in
                Button(action: {
                    AtlasTheme.Haptics.light()
                    selectedColor = color
                    // TODO: Apply color to selected text
                }) {
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                        )
                }
            }
        }
    }
}

// MARK: - FormattingState Extensions
extension FormattingState: Equatable {
    static func == (lhs: FormattingState, rhs: FormattingState) -> Bool {
        return lhs.isBold == rhs.isBold &&
               lhs.isItalic == rhs.isItalic &&
               lhs.isUnderlined == rhs.isUnderlined &&
               lhs.isStrikethrough == rhs.isStrikethrough &&
               lhs.isBlockquote == rhs.isBlockquote &&
               lhs.isCodeBlock == rhs.isCodeBlock &&
               lhs.isInlineCode == rhs.isInlineCode
    }
}
