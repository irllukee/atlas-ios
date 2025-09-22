import SwiftUI
import UIKit
import Aztec
import PhotosUI

// MARK: - Notification Names
extension Notification.Name {
    static let insertImage = Notification.Name("insertImage")
    static let insertLink = Notification.Name("insertLink")
    static let selectTextColor = Notification.Name("selectTextColor")
    static let showFindReplace = Notification.Name("showFindReplace")
}

// Controller the toolbar can call into
@MainActor
final class AztecEditorController: ObservableObject {
    weak var textView: Aztec.TextView?
    
    // MARK: - Text Formatting
    func bold()      { textView?.toggleBoldface(nil) }
    func italic()    { textView?.toggleItalics(nil) }
    func underline() { textView?.toggleUnderline(nil) }
    func strikethrough() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleStrikethrough(range: range)
    }
    
    // MARK: - Lists
    func bulletList() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleUnorderedList(range: range)
    }
    func numberedList() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleOrderedList(range: range)
    }
    
    // MARK: - Headers
    func header1() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleHeader(.h1, range: range)
    }
    func header2() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleHeader(.h2, range: range)
    }
    func header3() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleHeader(.h3, range: range)
    }
    
    // MARK: - Advanced Formatting
    func quote() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleBlockquote(range: range)
    }
    func code() { 
        guard let textView = textView else { return }
        let range = textView.selectedRange
        textView.toggleCode(range: range)
    }
    
    // MARK: - Media & Content
    func insertImage() {
        // Trigger image picker
        NotificationCenter.default.post(name: .insertImage, object: nil)
    }
    
    func insertHorizontalRule() {
        guard let textView = textView else { return }
        textView.insertText("\n---\n")
    }
    
    // MARK: - Links
    func insertLink() {
        // Trigger link creation dialog
        NotificationCenter.default.post(name: .insertLink, object: nil)
    }
    
    func insertLinkWithURL(_ url: String, text: String? = nil) {
        guard let textView = textView else { return }
        
        let linkText = text ?? url
        let attributedString = NSMutableAttributedString(string: linkText)
        let range = NSRange(location: 0, length: linkText.count)
        
        // Add link attribute
        attributedString.addAttribute(.link, value: url, range: range)
        attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: range)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        
        // Insert at current cursor position
        let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableString.insert(attributedString, at: textView.selectedRange.location)
        
        textView.attributedText = mutableString
        textView.selectedRange = NSRange(location: textView.selectedRange.location + linkText.count, length: 0)
    }
    
    // MARK: - Text Colors
    func textColor() {
        // Trigger color picker
        NotificationCenter.default.post(name: .selectTextColor, object: nil)
    }
    
    func applyTextColor(_ color: UIColor) {
        guard let textView = textView else { return }
        
        let range = textView.selectedRange
        if range.length > 0 {
            // Apply color to selected text
            let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
            mutableString.addAttribute(.foregroundColor, value: color, range: range)
            textView.attributedText = mutableString
        } else {
            // Apply color to future typing
            var attributes = textView.typingAttributes
            attributes[.foregroundColor] = color
            textView.typingAttributes = attributes
        }
    }
    
    // MARK: - Advanced Lists
    func indentList() {
        // TODO: Implement list indentation
        print("📋 List indent not yet implemented")
    }
    
    func outdentList() {
        // TODO: Implement list outdentation
        print("📋 List outdent not yet implemented")
    }
    
    // MARK: - History & Navigation
    func undo() {
        textView?.undoManager?.undo()
    }
    
    func redo() {
        textView?.undoManager?.redo()
    }
    
    func focus() { textView?.becomeFirstResponder() }
    
    // MARK: - Statistics
    func getWordCount() -> Int {
        guard let textView = textView else { return 0 }
        let text = textView.text ?? ""
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    func getCharacterCount() -> Int {
        guard let textView = textView else { return 0 }
        return textView.text?.count ?? 0
    }
    
    func getReadingTime() -> String {
        let wordCount = getWordCount()
        let readingTimeMinutes = max(1, wordCount / 200) // Average 200 words per minute
        return "\(readingTimeMinutes) min read"
    }
    
    // MARK: - Find & Replace
    func findText(_ searchText: String) -> [NSRange] {
        guard let textView = textView,
              let text = textView.text,
              !searchText.isEmpty else { return [] }
        
        var ranges: [NSRange] = []
        let searchString = text as NSString
        var searchRange = NSRange(location: 0, length: searchString.length)
        
        while searchRange.location < searchString.length {
            let foundRange = searchString.range(of: searchText, options: .caseInsensitive, range: searchRange)
            if foundRange.location != NSNotFound {
                ranges.append(foundRange)
                searchRange = NSRange(location: foundRange.location + foundRange.length, 
                                    length: searchString.length - (foundRange.location + foundRange.length))
            } else {
                break
            }
        }
        
        return ranges
    }
    
    func replaceText(_ searchText: String, with replacementText: String) -> Int {
        guard let textView = textView,
              !searchText.isEmpty else { return 0 }
        
        let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
        let searchString = mutableString.string as NSString
        var replacementCount = 0
        var searchRange = NSRange(location: 0, length: searchString.length)
        
        while searchRange.location < searchString.length {
            let foundRange = searchString.range(of: searchText, options: .caseInsensitive, range: searchRange)
            if foundRange.location != NSNotFound {
                mutableString.replaceCharacters(in: foundRange, with: replacementText)
                replacementCount += 1
                searchRange = NSRange(location: foundRange.location + replacementText.count, 
                                    length: mutableString.length - (foundRange.location + replacementText.count))
            } else {
                break
            }
        }
        
        if replacementCount > 0 {
            textView.attributedText = mutableString
        }
        
        return replacementCount
    }
    
    func selectText(at range: NSRange) {
        guard let textView = textView else { return }
        textView.selectedRange = range
        textView.scrollRangeToVisible(range)
    }
    
    // MARK: - Image Handling
    func insertImageFromData(_ imageData: Data) {
        guard let textView = textView,
              let image = UIImage(data: imageData) else { return }
        
        // Create an attachment for the image
        let attachment = NSTextAttachment()
        attachment.image = image
        
        // Resize image to fit nicely in the text
        let maxWidth: CGFloat = 300
        let aspectRatio = image.size.height / image.size.width
        let newSize = CGSize(width: min(maxWidth, image.size.width), 
                           height: min(maxWidth * aspectRatio, image.size.height))
        
        attachment.bounds = CGRect(origin: .zero, size: newSize)
        
        // Insert the image at the current cursor position
        let attributedString = NSAttributedString(attachment: attachment)
        let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableString.insert(attributedString, at: textView.selectedRange.location)
        
        textView.attributedText = mutableString
        textView.selectedRange = NSRange(location: textView.selectedRange.location + 1, length: 0)
    }
}

struct AztecEditorView: UIViewRepresentable {
    @Binding var html: String
    @ObservedObject var controller: AztecEditorController
    var placeholder: String = "Start writing your note..."

    func makeUIView(context: Context) -> Aztec.TextView {
        let tv = Aztec.TextView(
            defaultFont: .systemFont(ofSize: 17),
            defaultParagraphStyle: ParagraphStyle.default,
            defaultMissingImage: UIImage()
        )
        tv.delegate = context.coordinator
        tv.backgroundColor = UIColor.clear
        tv.allowsEditingTextAttributes = true
        tv.isEditable = true
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        // Load initial HTML
        tv.attributedText = html.htmlToAttributedString(
            defaultFont: tv.font ?? .systemFont(ofSize: 17),
            defaultColor: .label
        )

        controller.textView = tv
        return tv
    }

    func updateUIView(_ tv: Aztec.TextView, context: Context) {
        // Only push new HTML in if it actually changed externally
        if context.coordinator.lastHTMLPushed != html {
            let newAttr = html.htmlToAttributedString(
                defaultFont: tv.font ?? .systemFont(ofSize: 17),
                defaultColor: .label
            )
            if tv.attributedText != newAttr {
                tv.attributedText = newAttr
            }
            context.coordinator.lastHTMLPushed = html
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: AztecEditorView
        var lastHTMLPushed: String = ""

        init(_ parent: AztecEditorView) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            guard let tv = textView as? Aztec.TextView else { return }
            let htmlOut = tv.attributedText.attributedStringToHTML()
            if htmlOut != lastHTMLPushed {
                lastHTMLPushed = htmlOut
                parent.html = htmlOut
            }
        }
    }
}

// MARK: - HTML <-> Attributed helpers

private extension String {
    func htmlToAttributedString(defaultFont: UIFont, defaultColor: UIColor) -> NSAttributedString {
        guard let data = self.data(using: .utf8) else {
            return NSAttributedString(string: "", attributes: [.font: defaultFont, .foregroundColor: defaultColor])
        }
        let opts: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        let attr = try? NSMutableAttributedString(data: data, options: opts, documentAttributes: nil)
        let full = NSRange(location: 0, length: attr?.length ?? 0)
        if let attr {
            // Ensure a base font and color so we do not get odd defaults
            attr.addAttributes([.font: defaultFont, .foregroundColor: defaultColor], range: full)
            return attr
        } else {
            return NSAttributedString(string: "", attributes: [.font: defaultFont, .foregroundColor: defaultColor])
        }
    }
}

private extension NSAttributedString {
    func attributedStringToHTML() -> String {
        let range = NSRange(location: 0, length: length)
        let opts: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        guard let data = try? data(from: range, documentAttributes: opts),
              let html = String(data: data, encoding: .utf8) else {
            return ""
        }
        return html
    }
}
