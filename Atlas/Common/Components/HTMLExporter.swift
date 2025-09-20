import SwiftUI
import UIKit

/// Handles HTML export and import functionality for rich text
class HTMLExporter: ObservableObject {
    
    /// Export NSAttributedString to HTML
    static func exportToHTML(_ attributedString: NSAttributedString) -> String {
        let options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let htmlData = try attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: options)
            return String(data: htmlData, encoding: .utf8) ?? ""
        } catch {
            print("Error exporting to HTML: \(error)")
            return ""
        }
    }
    
    /// Import HTML string to NSAttributedString
    static func importFromHTML(_ htmlString: String) -> NSAttributedString {
        guard let data = htmlString.data(using: .utf8) else {
            return NSAttributedString(string: htmlString)
        }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            return try NSAttributedString(data: data, options: options, documentAttributes: nil)
        } catch {
            print("Error importing from HTML: \(error)")
            return NSAttributedString(string: htmlString)
        }
    }
    
    /// Convert NSAttributedString to RTF (Rich Text Format) for better compatibility
    static func exportToRTF(_ attributedString: NSAttributedString) -> Data? {
        let options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.rtf,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            return try attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: options)
        } catch {
            print("Error exporting to RTF: \(error)")
            return nil
        }
    }
    
    /// Import RTF data to NSAttributedString
    static func importFromRTF(_ rtfData: Data) -> NSAttributedString {
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.rtf,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            return try NSAttributedString(data: rtfData, options: options, documentAttributes: nil)
        } catch {
            print("Error importing from RTF: \(error)")
            return NSAttributedString()
        }
    }
    
    /// Create a clean HTML version without iOS-specific attributes
    static func createCleanHTML(_ attributedString: NSAttributedString) -> String {
        let html = exportToHTML(attributedString)
        
        // Clean up iOS-specific attributes and formatting
        var cleanHTML = html
        
        // Remove iOS-specific attributes
        cleanHTML = cleanHTML.replacingOccurrences(of: "style=\"-webkit-text-size-adjust: 100%;\"", with: "")
        cleanHTML = cleanHTML.replacingOccurrences(of: "<!--StartFragment-->", with: "")
        cleanHTML = cleanHTML.replacingOccurrences(of: "<!--EndFragment-->", with: "")
        cleanHTML = cleanHTML.replacingOccurrences(of: "<html><head><meta charset=\"utf-8\">", with: "<div>")
        cleanHTML = cleanHTML.replacingOccurrences(of: "</head><body>", with: "")
        cleanHTML = cleanHTML.replacingOccurrences(of: "</body></html>", with: "</div>")
        
        // Clean up empty paragraphs
        cleanHTML = cleanHTML.replacingOccurrences(of: "<p></p>", with: "")
        
        return cleanHTML
    }
    
    /// Convert plain text to basic HTML
    static func plainTextToHTML(_ text: String) -> String {
        let escapedText = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
        
        return escapedText.replacingOccurrences(of: "\n", with: "<br>")
    }
}

// MARK: - HTML Export/Import View
struct HTMLExportImportView: View {
    @Binding var attributedText: NSAttributedString
    @Binding var isPresented: Bool
    @State private var htmlContent = ""
    @State private var showingShareSheet = false
    @State private var showingImportAlert = false
    @State private var importText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Export Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export as HTML")
                        .font(.headline)
                    
                    Text("Convert your formatted text to HTML for sharing or web use.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Button("Export to HTML") {
                            exportToHTML()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Spacer()
                        
                        Button("Share HTML") {
                            exportAndShare()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Import Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import from HTML")
                        .font(.headline)
                    
                    Text("Paste HTML content to convert it to formatted text.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Import HTML") {
                        showingImportAlert = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // HTML Preview
                if !htmlContent.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HTML Preview")
                            .font(.headline)
                        
                        ScrollView {
                            Text(htmlContent)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("HTML Export/Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .alert("Import HTML", isPresented: $showingImportAlert) {
                TextField("Paste HTML content here", text: $importText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Import") {
                    importFromHTML()
                }
                
                Button("Cancel", role: .cancel) {
                    importText = ""
                }
            } message: {
                Text("Paste your HTML content below:")
            }
            .sheet(isPresented: $showingShareSheet) {
                HTMLShareSheet(items: [htmlContent])
            }
        }
    }
    
    private func exportToHTML() {
        htmlContent = HTMLExporter.createCleanHTML(attributedText)
    }
    
    private func exportAndShare() {
        htmlContent = HTMLExporter.createCleanHTML(attributedText)
        showingShareSheet = true
    }
    
    private func importFromHTML() {
        guard !importText.isEmpty else { return }
        
        let importedText = HTMLExporter.importFromHTML(importText)
        attributedText = importedText
        importText = ""
        isPresented = false
    }
}

// MARK: - HTML Share Sheet
struct HTMLShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - RichTextEditor Extensions
extension RichTextEditor {
    
    /// Export current content to HTML
    func exportToHTML() -> String {
        return HTMLExporter.createCleanHTML(attributedText)
    }
    
    /// Import HTML content
    func importFromHTML(_ htmlString: String) {
        let importedText = HTMLExporter.importFromHTML(htmlString)
        attributedText = importedText
    }
    
    /// Export to RTF for better compatibility
    func exportToRTF() -> Data? {
        return HTMLExporter.exportToRTF(attributedText)
    }
    
    /// Import from RTF
    func importFromRTF(_ rtfData: Data) {
        let importedText = HTMLExporter.importFromRTF(rtfData)
        attributedText = importedText
    }
}
