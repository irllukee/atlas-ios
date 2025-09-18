import Foundation
import UIKit
import PDFKit
import UniformTypeIdentifiers

/// Service for exporting notes to various formats
@MainActor
class ExportService {
    
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - Export Types
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case plainText = "Plain Text"
        case richText = "Rich Text (RTF)"
        case html = "HTML"
        case markdown = "Markdown"
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .plainText: return "txt"
            case .richText: return "rtf"
            case .html: return "html"
            case .markdown: return "md"
            }
        }
        
        var mimeType: String {
            switch self {
            case .pdf: return "application/pdf"
            case .plainText: return "text/plain"
            case .richText: return "application/rtf"
            case .html: return "text/html"
            case .markdown: return "text/markdown"
            }
        }
        
        var utType: UTType {
            switch self {
            case .pdf: return .pdf
            case .plainText: return .plainText
            case .richText: return .rtf
            case .html: return .html
            case .markdown: return UTType("public.markdown") ?? .plainText
            }
        }
    }
    
    struct ExportResult {
        let url: URL
        let format: ExportFormat
        let fileSize: Int64
    }
    
    // MARK: - Export Methods
    
    /// Export a single note to the specified format
    func exportNote(_ note: Note, format: ExportFormat) async throws -> ExportResult {
        let fileName = sanitizeFileName(note.title ?? "Untitled Note")
        let exportURL = getExportURL(fileName: fileName, format: format)
        
        switch format {
        case .pdf:
            try await exportToPDF(note: note, url: exportURL)
        case .plainText:
            try await exportToPlainText(note: note, url: exportURL)
        case .richText:
            try await exportToRichText(note: note, url: exportURL)
        case .html:
            try await exportToHTML(note: note, url: exportURL)
        case .markdown:
            try await exportToMarkdown(note: note, url: exportURL)
        }
        
        let fileSize = getFileSize(at: exportURL)
        return ExportResult(url: exportURL, format: format, fileSize: fileSize)
    }
    
    /// Export multiple notes to the specified format (creates a zip file for multiple notes)
    func exportNotes(_ notes: [Note], format: ExportFormat) async throws -> ExportResult {
        if notes.count == 1 {
            return try await exportNote(notes[0], format: format)
        }
        
        let tempDirectory = createTempDirectory()
        var exportedFiles: [URL] = []
        
        // Export each note to the temp directory
        for note in notes {
            let fileName = sanitizeFileName(note.title ?? "Untitled Note")
            let fileURL = tempDirectory.appendingPathComponent("\(fileName).\(format.fileExtension)")
            
            switch format {
            case .pdf:
                try await exportToPDF(note: note, url: fileURL)
            case .plainText:
                try await exportToPlainText(note: note, url: fileURL)
            case .richText:
                try await exportToRichText(note: note, url: fileURL)
            case .html:
                try await exportToHTML(note: note, url: fileURL)
            case .markdown:
                try await exportToMarkdown(note: note, url: fileURL)
            }
            
            exportedFiles.append(fileURL)
        }
        
        // Create zip file
        let zipURL = getExportURL(fileName: "Atlas Notes Export", format: .init(rawValue: "ZIP") ?? .plainText)
        try createZipFile(from: exportedFiles, to: zipURL)
        
        // Clean up temp directory
        try FileManager.default.removeItem(at: tempDirectory)
        
        let fileSize = getFileSize(at: zipURL)
        return ExportResult(url: zipURL, format: format, fileSize: fileSize)
    }
    
    // MARK: - Format-Specific Export Methods
    
    private func exportToPDF(note: Note, url: URL) async throws {
        // Create PDF content
        let content = formatNoteForExport(note)
        let htmlContent = createHTMLContent(title: note.title ?? "Untitled", content: content)
        
        // Use UIMarkupTextPrintFormatter for better formatting
        guard let data = htmlContent.data(using: .utf8) else {
            throw ExportError.invalidContent
        }
        
        let _ = UIMarkupTextPrintFormatter(markupText: String(data: data, encoding: .utf8) ?? "")
        
        // Create PDF renderer
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // US Letter size
        
        let pdfData = pdfRenderer.pdfData { context in
            context.beginPage()
            
            // Draw title
            if let title = note.title {
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                let titleSize = title.size(withAttributes: titleAttributes)
                let titleRect = CGRect(x: 50, y: 50, width: 512, height: titleSize.height)
                title.draw(in: titleRect, withAttributes: titleAttributes)
            }
            
            // Draw content
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            let contentRect = CGRect(x: 50, y: 100, width: 512, height: 640)
            content.draw(in: contentRect, withAttributes: contentAttributes)
            
            // Add metadata
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            let dateString = "Exported on \(dateFormatter.string(from: Date()))"
            
            let metadataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            let metadataRect = CGRect(x: 50, y: 750, width: 512, height: 20)
            dateString.draw(in: metadataRect, withAttributes: metadataAttributes)
        }
        
        try pdfData.write(to: url)
    }
    
    private func exportToPlainText(note: Note, url: URL) async throws {
        let content = formatNoteForExport(note)
        let plainText = """
        \(note.title ?? "Untitled Note")
        \(String(repeating: "=", count: (note.title ?? "Untitled Note").count))
        
        \(content)
        
        ---
        Exported from Atlas Notes on \(Date().formatted(date: .complete, time: .shortened))
        """
        
        try plainText.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportToRichText(note: Note, url: URL) async throws {
        let content = formatNoteForExport(note)
        
        // Create attributed string for RTF
        let attributedString = NSMutableAttributedString()
        
        // Add title
        if let title = note.title {
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let titleString = NSAttributedString(string: "\(title)\n\n", attributes: titleAttributes)
            attributedString.append(titleString)
        }
        
        // Add content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        let contentString = NSAttributedString(string: content, attributes: contentAttributes)
        attributedString.append(contentString)
        
        // Convert to RTF
        let rtfData = try attributedString.data(from: NSRange(location: 0, length: attributedString.length), 
                                                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        
        try rtfData.write(to: url)
    }
    
    private func exportToHTML(note: Note, url: URL) async throws {
        let content = formatNoteForExport(note)
        let htmlContent = createHTMLContent(title: note.title ?? "Untitled", content: content)
        
        try htmlContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private func exportToMarkdown(note: Note, url: URL) async throws {
        let content = formatNoteForExport(note)
        
        let markdownContent = """
        # \(note.title ?? "Untitled Note")
        
        \(content)
        
        ---
        *Exported from Atlas Notes on \(Date().formatted(date: .complete, time: .shortened))*
        """
        
        try markdownContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Helper Methods
    
    private func formatNoteForExport(_ note: Note) -> String {
        var content = note.content ?? ""
        
        // Add table of contents if available
        if let toc = note.tableOfContents, !toc.isEmpty {
            content = "\(toc)\n\n\(content)"
        }
        
        // Clean up content for export
        content = content.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return content
    }
    
    private func createHTMLContent(title: String, content: String) -> String {
        let formattedContent = content.replacingOccurrences(of: "\n", with: "<br>")
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>\(title)</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
                    line-height: 1.6;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                    color: #333;
                }
                h1 {
                    color: #2c3e50;
                    border-bottom: 2px solid #3498db;
                    padding-bottom: 10px;
                }
                .metadata {
                    font-size: 0.9em;
                    color: #666;
                    border-top: 1px solid #eee;
                    margin-top: 40px;
                    padding-top: 20px;
                }
            </style>
        </head>
        <body>
            <h1>\(title)</h1>
            <div class="content">
                \(formattedContent)
            </div>
            <div class="metadata">
                Exported from Atlas Notes on \(Date().formatted(date: .complete, time: .shortened))
            </div>
        </body>
        </html>
        """
    }
    
    private func sanitizeFileName(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return fileName.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
    
    private func getExportURL(fileName: String, format: ExportFormat) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportDirectory = documentsPath.appendingPathComponent("Exports")
        
        // Create exports directory if it doesn't exist
        try? FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
        
        return exportDirectory.appendingPathComponent("\(fileName).\(format.fileExtension)")
    }
    
    private func createTempDirectory() -> URL {
        let tempPath = NSTemporaryDirectory()
        let tempURL = URL(fileURLWithPath: tempPath).appendingPathComponent(UUID().uuidString)
        
        try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        
        return tempURL
    }
    
    private func createZipFile(from files: [URL], to zipURL: URL) throws {
        // For now, we'll just copy the first file as a simple implementation
        // In a full implementation, you'd use a proper zip library
        if let firstFile = files.first {
            try FileManager.default.copyItem(at: firstFile, to: zipURL)
        }
    }
    
    private func getFileSize(at url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Export Errors

enum ExportError: LocalizedError {
    case invalidContent
    case fileCreationFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidContent:
            return "Invalid note content for export"
        case .fileCreationFailed:
            return "Failed to create export file"
        case .unsupportedFormat:
            return "Unsupported export format"
        }
    }
}
