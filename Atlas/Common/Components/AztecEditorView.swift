import SwiftUI
import UIKit
import Aztec

// Controller the toolbar can call into
@MainActor
final class AztecEditorController: ObservableObject {
    weak var textView: Aztec.TextView?
    func bold()      { textView?.toggleBoldface(nil) }
    func italic()    { textView?.toggleItalics(nil) }
    func underline() { textView?.toggleUnderline(nil) }
    func focus()     { textView?.becomeFirstResponder() }
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
