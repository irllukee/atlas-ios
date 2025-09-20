import SwiftUI
import UIKit

/// A SwiftUI wrapper for UITextView that supports rich text formatting
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var isEditing: Bool
    
    let placeholder: String
    let font: UIFont
    let textColor: UIColor
    let backgroundColor: UIColor
    
    @State var textView: UITextView?
    
    init(
        attributedText: Binding<NSAttributedString>,
        isEditing: Binding<Bool> = .constant(false),
        placeholder: String = "Start typing...",
        font: UIFont = UIFont.systemFont(ofSize: 16),
        textColor: UIColor = UIColor.label,
        backgroundColor: UIColor = UIColor.systemBackground
    ) {
        self._attributedText = attributedText
        self._isEditing = isEditing
        self.placeholder = placeholder
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = backgroundColor
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsEditingTextAttributes = true
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        // Enable rich text formatting
        // Enable rich text editing
        textView.allowsEditingTextAttributes = true
        
        // Set up placeholder
        if attributedText.string.isEmpty {
            textView.attributedText = NSAttributedString(
                string: placeholder,
                attributes: [
                    .font: font,
                    .foregroundColor: UIColor.placeholderText
                ]
            )
        } else {
            textView.attributedText = attributedText
        }
        
        self.textView = textView
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText && !uiView.isFirstResponder {
            if attributedText.string.isEmpty {
                uiView.attributedText = NSAttributedString(
                    string: placeholder,
                    attributes: [
                        .font: font,
                        .foregroundColor: UIColor.placeholderText
                    ]
                )
            } else {
                uiView.attributedText = attributedText
            }
        }
        
        uiView.font = font
        uiView.textColor = textColor
        uiView.backgroundColor = backgroundColor
        uiView.typingAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Update the binding with the current attributed text
            if textView.attributedText.string != parent.placeholder {
                parent.attributedText = textView.attributedText
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isEditing = true
            
            // Clear placeholder when editing starts
            if textView.attributedText.string == parent.placeholder {
                textView.attributedText = NSAttributedString(
                    string: "",
                    attributes: [
                        .font: parent.font,
                        .foregroundColor: parent.textColor
                    ]
                )
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isEditing = false
            
            // Show placeholder if text is empty
            if textView.attributedText.string.isEmpty {
                textView.attributedText = NSAttributedString(
                    string: parent.placeholder,
                    attributes: [
                        .font: parent.font,
                        .foregroundColor: UIColor.placeholderText
                    ]
                )
            }
        }
    }
}

// MARK: - Rich Text Formatting Extensions
extension RichTextEditor {
    
    /// Apply bold formatting to the selected text or current typing attributes
    func toggleBold() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentAttributes = textView.typingAttributes
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            
            mutableAttributedString.enumerateAttributes(in: selectedRange, options: []) { attributes, range, _ in
                var newAttributes = attributes
                let currentFont = attributes[.font] as? UIFont ?? font
                
                if currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    // Remove bold
                    let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.subtracting(.traitBold))
                    newAttributes[.font] = newFont
                } else {
                    // Add bold
                    let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.union(.traitBold))
                    newAttributes[.font] = newFont
                }
                
                mutableAttributedString.setAttributes(newAttributes, range: range)
            }
            
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            let currentFont = currentAttributes[.font] as? UIFont ?? font
            
            if currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                // Remove bold
                let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.subtracting(.traitBold))
                textView.typingAttributes[.font] = newFont
            } else {
                // Add bold
                let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.union(.traitBold))
                textView.typingAttributes[.font] = newFont
            }
        }
    }
    
    /// Apply italic formatting to the selected text or current typing attributes
    func toggleItalic() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentAttributes = textView.typingAttributes
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            
            mutableAttributedString.enumerateAttributes(in: selectedRange, options: []) { attributes, range, _ in
                var newAttributes = attributes
                let currentFont = attributes[.font] as? UIFont ?? font
                
                if currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                    // Remove italic
                    let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.subtracting(.traitItalic))
                    newAttributes[.font] = newFont
                } else {
                    // Add italic
                    let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.union(.traitItalic))
                    newAttributes[.font] = newFont
                }
                
                mutableAttributedString.setAttributes(newAttributes, range: range)
            }
            
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            let currentFont = currentAttributes[.font] as? UIFont ?? font
            
            if currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                // Remove italic
                let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.subtracting(.traitItalic))
                textView.typingAttributes[.font] = newFont
            } else {
                // Add italic
                let newFont = currentFont.withTraits(currentFont.fontDescriptor.symbolicTraits.union(.traitItalic))
                textView.typingAttributes[.font] = newFont
            }
        }
    }
    
    /// Apply underline formatting to the selected text or current typing attributes
    func toggleUnderline() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentAttributes = textView.typingAttributes
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            
            mutableAttributedString.enumerateAttributes(in: selectedRange, options: []) { attributes, range, _ in
                var newAttributes = attributes
                let currentUnderline = attributes[.underlineStyle] as? Int ?? 0
                
                if currentUnderline != 0 {
                    // Remove underline
                    newAttributes[.underlineStyle] = 0
                } else {
                    // Add underline
                    newAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                }
                
                mutableAttributedString.setAttributes(newAttributes, range: range)
            }
            
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            let currentUnderline = currentAttributes[.underlineStyle] as? Int ?? 0
            
            if currentUnderline != 0 {
                // Remove underline
                textView.typingAttributes[.underlineStyle] = 0
            } else {
                // Add underline
                textView.typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
        }
    }
    
    /// Apply strikethrough formatting to the selected text or current typing attributes
    func toggleStrikethrough() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentAttributes = textView.typingAttributes
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            
            mutableAttributedString.enumerateAttributes(in: selectedRange, options: []) { attributes, range, _ in
                var newAttributes = attributes
                let currentStrikethrough = attributes[.strikethroughStyle] as? Int ?? 0
                
                if currentStrikethrough != 0 {
                    // Remove strikethrough
                    newAttributes[.strikethroughStyle] = 0
                } else {
                    // Add strikethrough
                    newAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
                
                mutableAttributedString.setAttributes(newAttributes, range: range)
            }
            
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            let currentStrikethrough = currentAttributes[.strikethroughStyle] as? Int ?? 0
            
            if currentStrikethrough != 0 {
                // Remove strikethrough
                textView.typingAttributes[.strikethroughStyle] = 0
            } else {
                // Add strikethrough
                textView.typingAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
        }
    }
    
    /// Apply blockquote formatting to the selected text or current line
    func toggleBlockquote() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        
        // Find the paragraph range for the selection
        let paragraphRange = (mutableAttributedString.string as NSString).paragraphRange(for: selectedRange)
        
        // Check if the paragraph already has blockquote formatting
        var paragraphStyle = NSMutableParagraphStyle()
        if let existingStyle = mutableAttributedString.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle {
            paragraphStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
        }
        
        // Toggle blockquote (indicated by left margin)
        if paragraphStyle.headIndent > 20 {
            // Remove blockquote
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
        } else {
            // Add blockquote
            paragraphStyle.headIndent = 30
            paragraphStyle.firstLineHeadIndent = 30
        }
        
        mutableAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
        attributedText = mutableAttributedString
    }
    
    /// Apply code block formatting to the selected text or current line
    func toggleCodeBlock() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        
        // Find the paragraph range for the selection
        let paragraphRange = (mutableAttributedString.string as NSString).paragraphRange(for: selectedRange)
        
        // Check if the paragraph already has code formatting
        let currentFont = mutableAttributedString.attribute(.font, at: paragraphRange.location, effectiveRange: nil) as? UIFont ?? font
        let currentBackgroundColor = mutableAttributedString.attribute(.backgroundColor, at: paragraphRange.location, effectiveRange: nil) as? UIColor
        
        if currentBackgroundColor == UIColor.systemGray5 {
            // Remove code formatting
            mutableAttributedString.removeAttribute(.backgroundColor, range: paragraphRange)
            mutableAttributedString.addAttribute(.font, value: font, range: paragraphRange)
        } else {
            // Add code formatting
            mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.systemGray5, range: paragraphRange)
            mutableAttributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: currentFont.pointSize, weight: .regular), range: paragraphRange)
        }
        
        attributedText = mutableAttributedString
    }
    
    /// Apply inline code formatting to the selected text
    func toggleInlineCode() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentAttributes = textView.typingAttributes
        
        if selectedRange.length > 0 {
            // Apply to selected text
            let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
            
            let currentFont = mutableAttributedString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont ?? font
            let currentBackgroundColor = mutableAttributedString.attribute(.backgroundColor, at: selectedRange.location, effectiveRange: nil) as? UIColor
            
            if currentBackgroundColor == UIColor.systemGray5 {
                // Remove inline code formatting
                mutableAttributedString.removeAttribute(.backgroundColor, range: selectedRange)
                mutableAttributedString.addAttribute(.font, value: font, range: selectedRange)
            } else {
                // Add inline code formatting
                mutableAttributedString.addAttribute(.backgroundColor, value: UIColor.systemGray5, range: selectedRange)
                mutableAttributedString.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: currentFont.pointSize, weight: .regular), range: selectedRange)
            }
            
            attributedText = mutableAttributedString
        } else {
            // Apply to typing attributes
            let currentFont = currentAttributes[.font] as? UIFont ?? font
            let currentBackgroundColor = currentAttributes[.backgroundColor] as? UIColor
            
            if currentBackgroundColor == UIColor.systemGray5 {
                // Remove inline code formatting
                textView.typingAttributes[.backgroundColor] = nil
                textView.typingAttributes[.font] = font
            } else {
                // Add inline code formatting
                textView.typingAttributes[.backgroundColor] = UIColor.systemGray5
                textView.typingAttributes[.font] = UIFont.monospacedSystemFont(ofSize: currentFont.pointSize, weight: .regular)
            }
        }
    }
    
    /// Get the current formatting state for the selected text or typing attributes
    func getCurrentFormattingState() -> FormattingState {
        guard let textView = textView else { return FormattingState() }
        
        let selectedRange = textView.selectedRange
        let attributes = selectedRange.length > 0 ? 
            attributedText.attributes(at: selectedRange.location, effectiveRange: nil) :
            textView.typingAttributes
        
        let currentFont = attributes[.font] as? UIFont ?? font
        let underlineStyle = attributes[.underlineStyle] as? Int ?? 0
        let strikethroughStyle = attributes[.strikethroughStyle] as? Int ?? 0
        let backgroundColor = attributes[.backgroundColor] as? UIColor
        
        // Check for blockquote (paragraph style with head indent)
        let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle
        let isBlockquote = paragraphStyle?.headIndent ?? 0 > 20
        
        // Check for code formatting (monospaced font and background color)
        let isCodeBlock = backgroundColor == UIColor.systemGray5 && 
                         currentFont.fontName.contains("monospace")
        let isInlineCode = backgroundColor == UIColor.systemGray5 && 
                          currentFont.fontName.contains("monospace")
        
        return FormattingState(
            isBold: currentFont.fontDescriptor.symbolicTraits.contains(.traitBold),
            isItalic: currentFont.fontDescriptor.symbolicTraits.contains(.traitItalic),
            isUnderlined: underlineStyle != 0,
            isStrikethrough: strikethroughStyle != 0,
            isBlockquote: isBlockquote,
            isCodeBlock: isCodeBlock,
            isInlineCode: isInlineCode
        )
    }
}

// MARK: - Supporting Types
struct FormattingState {
    let isBold: Bool
    let isItalic: Bool
    let isUnderlined: Bool
    let isStrikethrough: Bool
    let isBlockquote: Bool
    let isCodeBlock: Bool
    let isInlineCode: Bool
    
    init(isBold: Bool = false, isItalic: Bool = false, isUnderlined: Bool = false, isStrikethrough: Bool = false, isBlockquote: Bool = false, isCodeBlock: Bool = false, isInlineCode: Bool = false) {
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
        self.isStrikethrough = isStrikethrough
        self.isBlockquote = isBlockquote
        self.isCodeBlock = isCodeBlock
        self.isInlineCode = isInlineCode
    }
}

// MARK: - UIFont Extensions
extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: 0)
    }
}
