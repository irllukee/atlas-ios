import SwiftUI
import UIKit

/// Manages link detection, editing, and formatting in rich text
class LinkManager: ObservableObject {
    
    // MARK: - Link Detection
    static func detectLinks(in text: String) -> [LinkRange] {
        var links: [LinkRange] = []
        
        // URL pattern for detection
        let urlPattern = #"(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})"#
        
        do {
            let regex = try NSRegularExpression(pattern: urlPattern, options: [])
            let range = NSRange(location: 0, length: text.count)
            
            regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
                if let match = match {
                    let linkText = (text as NSString).substring(with: match.range)
                    let link = LinkRange(
                        text: linkText,
                        url: linkText.hasPrefix("http") ? linkText : "https://\(linkText)",
                        range: match.range
                    )
                    links.append(link)
                }
            }
        } catch {
            print("Error detecting links: \(error)")
        }
        
        return links
    }
    
    /// Apply link formatting to detected URLs in attributed string
    static func applyLinkFormatting(to attributedString: NSMutableAttributedString) -> NSMutableAttributedString {
        let text = attributedString.string
        let links = detectLinks(in: text)
        
        for link in links {
            // Apply link attributes
            attributedString.addAttribute(.link, value: link.url, range: link.range)
            attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: link.range)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: link.range)
        }
        
        return attributedString
    }
    
    /// Remove link formatting from selected text
    static func removeLinkFormatting(from attributedString: NSMutableAttributedString, range: NSRange) {
        attributedString.removeAttribute(.link, range: range)
        attributedString.removeAttribute(.foregroundColor, range: range)
        attributedString.removeAttribute(.underlineStyle, range: range)
    }
    
    /// Create a link from selected text
    static func createLink(from attributedString: NSMutableAttributedString, text: String, url: String, range: NSRange) {
        attributedString.addAttribute(.link, value: url, range: range)
        attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: range)
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    }
}

// MARK: - Link Data Structures
struct LinkRange {
    let text: String
    let url: String
    let range: NSRange
}

struct LinkInfo {
    let text: String
    let url: String
    let title: String?
    let description: String?
}

// MARK: - Link Editor View
struct LinkEditorView: View {
    @Binding var text: String
    @Binding var url: String
    @Binding var title: String
    @Binding var isPresented: Bool
    
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var isValidURL = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Link Text") {
                    TextField("Link text", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("URL") {
                    TextField("https://example.com", text: $url)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: url) { _, newValue in
                            isValidURL = isValidURLString(newValue)
                        }
                }
                
                Section("Title (Optional)") {
                    TextField("Link title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                if !isValidURL && !url.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Please enter a valid URL")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Edit Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(!isValidURL && !url.isEmpty)
                }
            }
        }
    }
    
    private func isValidURLString(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme != nil && url.host != nil
    }
}

// MARK: - Link Preview View
struct LinkPreviewView: View {
    let linkInfo: LinkInfo
    @State private var isLoading = false
    @State private var previewImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = linkInfo.title {
                        Text(title)
                            .font(.headline)
                            .lineLimit(2)
                    }
                    
                    Text(linkInfo.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                }
            }
            
            if let description = linkInfo.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            if let url = URL(string: linkInfo.url) {
                UIApplication.shared.open(url)
            }
        }
        .onAppear {
            loadPreview()
        }
    }
    
    private func loadPreview() {
        // This would typically fetch link preview data from a service
        // For now, we'll just simulate loading
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            // Set preview image if available
        }
    }
}

// MARK: - Link Formatting Extensions for RichTextEditor
extension RichTextEditor {
    
    /// Toggle link formatting for selected text
    func toggleLink() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            let selectedText = (attributedText.string as NSString).substring(with: selectedRange)
            let hasLink = attributedText.attribute(.link, at: selectedRange.location, effectiveRange: nil) != nil
            
            if hasLink {
                // Remove link formatting
                let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
                LinkManager.removeLinkFormatting(from: mutableAttributedString, range: selectedRange)
                attributedText = mutableAttributedString
            } else {
                // Show link editor
                showLinkEditor(for: selectedText, range: selectedRange)
            }
        }
    }
    
    /// Check if selected text has link formatting
    func hasLinkFormatting() -> Bool {
        guard let textView = textView else { return false }
        
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            return attributedText.attribute(.link, at: selectedRange.location, effectiveRange: nil) != nil
        }
        return false
    }
    
    /// Get the URL for the selected link
    func getSelectedLinkURL() -> String? {
        guard let textView = textView else { return nil }
        
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            return attributedText.attribute(.link, at: selectedRange.location, effectiveRange: nil) as? String
        }
        return nil
    }
    
    private func showLinkEditor(for text: String, range: NSRange) {
        // This would typically show a modal or sheet with the LinkEditorView
        // For now, we'll create a simple link with the text as URL
        let url = text.hasPrefix("http") ? text : "https://\(text)"
        
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedText)
        LinkManager.createLink(from: mutableAttributedString, text: text, url: url, range: range)
        attributedText = mutableAttributedString
    }
}
