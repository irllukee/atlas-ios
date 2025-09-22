import SwiftUI
import UIKit

#if canImport(Aztec)
import Aztec
#endif

// MARK: - Aztec Rich Text Editor
struct AztecRichTextEditor: UIViewRepresentable {
    @Binding var content: String
    @Binding var title: String
    let placeholder: String
    @Binding var coordinator: AztecCoordinator?
    
    func makeUIView(context: Context) -> Aztec.TextView {
        let textView = Aztec.TextView(
            defaultFont: UIFont.systemFont(ofSize: 16),
            defaultParagraphStyle: ParagraphStyle.default,
            defaultMissingImage: UIImage()
        )
        
        context.coordinator.textView = textView
        
        // Configure the text view
        textView.backgroundColor = UIColor.clear
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsEditingTextAttributes = true  // Enable rich text editing
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        
        // Set initial content
        if !content.isEmpty {
            textView.setHTML(content)
        } else if !placeholder.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.placeholderText
        }
        
        return textView
    }
    
    func updateUIView(_ textView: Aztec.TextView, context: Context) {
        // Only update if the content has actually changed
        let currentHTML = textView.getHTML()
        if currentHTML != content {
            textView.setHTML(content)
        }
        
        // Handle placeholder
        if content.isEmpty && !placeholder.isEmpty {
            if textView.text.isEmpty || textView.text == placeholder {
                textView.text = placeholder
                textView.textColor = UIColor.placeholderText
            }
        } else if !content.isEmpty {
            textView.textColor = UIColor.label
        }
    }
    
    func makeCoordinator() -> AztecCoordinator {
        let coordinator = AztecCoordinator(self)
        self.coordinator = coordinator
        return coordinator
    }
}

// MARK: - Aztec Coordinator
@MainActor
class AztecCoordinator: NSObject {
    var parent: AztecRichTextEditor
    var textView: Aztec.TextView?
    var lastAppliedHTML: String = ""
    
    init(_ parent: AztecRichTextEditor) {
        self.parent = parent
    }
    
    // MARK: - Formatting Methods
    func toggleBold() {
        print("🔧 DEBUG: AztecCoordinator.toggleBold() called")
        guard let textView = textView else { 
            print("❌ DEBUG: textView is nil in toggleBold")
            return 
        }
        
        // Use Aztec's built-in bold toggle
        let range = textView.selectedRange
        textView.toggleBold(range: range)
        print("✅ DEBUG: Bold toggled using Aztec's toggleBold for range: \(range)")
        
        // Log detailed formatting info
        logDetailedFormatting()
    }
    
    func toggleItalic() {
        print("🔧 DEBUG: AztecCoordinator.toggleItalic() called")
        guard let textView = textView else { 
            print("❌ DEBUG: textView is nil in toggleItalic")
            return 
        }
        
        // Use Aztec's built-in italic toggle
        let range = textView.selectedRange
        textView.toggleItalic(range: range)
        print("✅ DEBUG: Italic toggled using Aztec's toggleItalic for range: \(range)")
        
        // Log detailed formatting info
        logDetailedFormatting()
    }
    
    func toggleUnderline() {
        print("🔧 DEBUG: AztecCoordinator.toggleUnderline() called")
        guard let textView = textView else { 
            print("❌ DEBUG: textView is nil in toggleUnderline")
            return 
        }
        
        // Use Aztec's built-in underline toggle
        let range = textView.selectedRange
        textView.toggleUnderline(range: range)
        print("✅ DEBUG: Underline toggled using Aztec's toggleUnderline for range: \(range)")
    }
    
    func toggleStrikethrough() {
        print("🔧 DEBUG: AztecCoordinator.toggleStrikethrough() called")
        guard let textView = textView else { 
            print("❌ DEBUG: textView is nil in toggleStrikethrough")
            return 
        }
        
        // Use Aztec's built-in strikethrough toggle
        let range = textView.selectedRange
        textView.toggleStrikethrough(range: range)
        print("✅ DEBUG: Strikethrough toggled using Aztec's toggleStrikethrough for range: \(range)")
    }
    
    func insertHeader(_ level: Int) {
        print("🔧 DEBUG: AztecCoordinator.insertHeader(\(level)) called")
        guard let textView = textView else { 
            print("❌ DEBUG: textView is nil in insertHeader")
            return 
        }
        let range = textView.selectedRange
        let headerType = Header.HeaderType(rawValue: level) ?? .h1
        textView.toggleHeader(headerType, range: range)
        print("✅ DEBUG: Header H\(level) inserted successfully for range: \(range)")
    }
    
    func insertList() {
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleUnorderedList(range: range)
    }
    
    func insertOrderedList() {
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleOrderedList(range: range)
    }
    
    func insertBlockquote() {
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleBlockquote(range: range)
    }
    
    func insertCodeBlock() {
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.togglePre(range: range)
    }
    
    func insertHorizontalRule() {
        guard let textView = textView else { return }
        // Insert horizontal rule as text for now
        textView.insertText("\n---\n")
    }
    
    func insertLink() {
        guard let textView = textView else { return }
        // Insert link as text for now
        textView.insertText("[Link](https://example.com)")
    }
    
    // MARK: - Text Change Handling
    @MainActor
    func handleTextChange() {
        guard let textView = textView else { return }
        let html = textView.getHTML()
        if html != lastAppliedHTML {
            print("🔧 DEBUG: Text content changed, updating parent.content")
            print("📝 DEBUG: New HTML content length: \(html.count) characters")
            parent.content = html
            lastAppliedHTML = html
        }
    }
    
    // MARK: - Detailed Formatting Logger
    private func logDetailedFormatting() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let html = textView.getHTML()
        let plainText = textView.text ?? ""
        
        print("🔍 DETAILED FORMAT DEBUG:")
        print("   📍 Selected Range: \(selectedRange)")
        print("   📝 Plain Text: '\(plainText)'")
        print("   🌐 HTML Content: '\(html)'")
        
        // Check if selected text has formatting
        if selectedRange.length > 0 {
            let selectedText = (plainText as NSString).substring(with: selectedRange)
            print("   ✂️ Selected Text: '\(selectedText)'")
            
            // Check attributes at selection
            let attributes = textView.attributedText.attributes(at: selectedRange.location, effectiveRange: nil)
            print("   🎨 Text Attributes:")
            for (key, value) in attributes {
                print("      \(key.rawValue): \(value)")
            }
        } else {
            print("   📍 No text selected (cursor position: \(selectedRange.location))")
        }
        
        print("   📊 Content Stats:")
        print("      - Plain text length: \(plainText.count)")
        print("      - HTML length: \(html.count)")
        print("      - Has HTML tags: \(html.contains("<"))")
        print("🔍 END FORMAT DEBUG")
    }
}

// MARK: - Aztec Rich Text Editor View
struct AztecRichTextEditorView: View {
    @Binding var content: String
    @Binding var title: String
    let placeholder: String
    @State private var textViewCoordinator: AztecCoordinator?
    @State private var isKeyboardVisible = false
    @State private var showFormatBar = false
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                // Title Field
                AtlasTextField("Title", placeholder: "Note Title", text: $title, style: .floating)
                    .padding(.horizontal, AtlasTheme.Spacing.md)
                
                // Aztec Text Editor
                AztecRichTextEditor(
                    content: $content,
                    title: $title,
                    placeholder: placeholder,
                    coordinator: $textViewCoordinator
                )
                .frame(minHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .fill(AtlasTheme.Colors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, AtlasTheme.Spacing.md)
                .onTapGesture {
                    showFormatBar = true
                }
            }
            
            // Floating Format Bar (appears over keyboard)
            if showFormatBar && isKeyboardVisible {
                VStack {
                    Spacer()
                    floatingFormatBar
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
            showFormatBar = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
            showFormatBar = false
        }
    }
    
    // MARK: - Floating Format Bar
    private var floatingFormatBar: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    showFormatBar = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }
            
            // Format buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Text Formatting
                    formatButton(icon: "bold", action: { 
                        textViewCoordinator?.toggleBold()
                    })
                    formatButton(icon: "italic", action: { 
                        textViewCoordinator?.toggleItalic()
                    })
                    formatButton(icon: "underline", action: { 
                        textViewCoordinator?.toggleUnderline() 
                    })
                    formatButton(icon: "strikethrough", action: { 
                        textViewCoordinator?.toggleStrikethrough() 
                    })
                    
                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 8)
                    
                    // Headers
                    formatButton(icon: "textformat.size", action: { 
                        textViewCoordinator?.insertHeader(1) 
                    })
                    formatButton(icon: "textformat.size.larger", action: { 
                        textViewCoordinator?.insertHeader(2) 
                    })
                    formatButton(icon: "textformat.size.smaller", action: { 
                        textViewCoordinator?.insertHeader(3) 
                    })
                    
                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 8)
                    
                    // Lists
                    formatButton(icon: "list.bullet", action: { 
                        textViewCoordinator?.insertList() 
                    })
                    formatButton(icon: "list.number", action: { 
                        textViewCoordinator?.insertOrderedList() 
                    })
                    formatButton(icon: "quote.bubble", action: { 
                        textViewCoordinator?.insertBlockquote() 
                    })
                    
                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 8)
                    
                    // Code and Links
                    formatButton(icon: "chevron.left.forwardslash.chevron.right", action: { 
                        textViewCoordinator?.insertCodeBlock() 
                    })
                    formatButton(icon: "link", action: { 
                        textViewCoordinator?.insertLink() 
                    })
                    formatButton(icon: "minus", action: { 
                        textViewCoordinator?.insertHorizontalRule() 
                    })
                }
                .padding(.horizontal, AtlasTheme.Spacing.md)
            }
            .padding(.vertical, AtlasTheme.Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                .fill(AtlasTheme.Colors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, AtlasTheme.Spacing.md)
        .padding(.bottom, 10)
    }
    
    private func formatButton(icon: String, action: @escaping () -> Void) -> some View {
        return Button(action: {
            action()
            AtlasTheme.Haptics.light()
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AtlasTheme.Colors.text)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Unified Rich Text Editor
struct UnifiedRichTextEditor: View {
    @Binding var content: String
    @Binding var title: String
    let placeholder: String
    
    var body: some View {
        AztecRichTextEditorView(
            content: $content,
            title: $title,
            placeholder: placeholder
        )
        .onAppear {
            print("🚀 DEBUG: AztecRichTextEditorView appeared - Using Aztec rich text editor!")
        }
    }
}

// MARK: - Preview
#Preview {
    UnifiedRichTextEditor(
        content: .constant(""),
        title: .constant(""),
        placeholder: ""
    )
    .background(AtlasTheme.Colors.background)
}
