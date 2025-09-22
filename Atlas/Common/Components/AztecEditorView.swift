import SwiftUI
import UIKit
import Aztec

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
        // TODO: Implement image picker
        print("🖼️ Image insertion not yet implemented")
    }
    
    func insertHorizontalRule() {
        guard let textView = textView else { return }
        textView.insertText("\n---\n")
    }
    
    // MARK: - Links
    func insertLink() {
        // TODO: Implement link insertion
        print("🔗 Link insertion not yet implemented")
    }
    
    // MARK: - Text Colors
    func textColor() {
        // TODO: Implement color picker
        print("🎨 Text color not yet implemented")
    }
    
    func backgroundColor() {
        // TODO: Implement background color
        print("🎨 Background color not yet implemented")
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
