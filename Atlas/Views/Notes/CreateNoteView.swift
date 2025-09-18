import SwiftUI
import CoreData
import PhotosUI
import AVFoundation
import AVKit

// MARK: - NoteImage Model
struct NoteImage: Identifiable, Equatable {
    let id = UUID()
    var imageData: Data // Store as Data for memory efficiency
    var position: CGPoint
    var size: CGSize
    var textWrap: TextWrapMode
    var isSelected: Bool = false
    
    // Computed property for UIImage (lazy loading)
    var image: UIImage? {
        return UIImage(data: imageData)
    }
    
    enum TextWrapMode: String, CaseIterable {
        case inline = "Inline"
        case square = "Square"
        case tight = "Tight"
        case through = "Through"
        case topAndBottom = "Top and Bottom"
        case behind = "Behind Text"
        case inFront = "In Front of Text"
    }
}

/// Modern iOS Notes-style view for creating and editing notes
struct CreateNoteView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Optional note for editing mode
    let noteToEdit: Note?
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isEncrypted: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var images: [NoteImage] = []
    @State private var selectedImageId: UUID?
    @State private var isImagePickerPresented = false
    @State private var showingVoiceRecording = false
    
           // Formatting states
           @State private var isBold = false
           @State private var isItalic = false
           @State private var isUnderlined = false
           @State private var isStrikethrough = false
           @State private var isSuperscript = false
           @State private var isSubscript = false
           
           // Text alignment states
           @State private var textAlignment: TextAlignment = .leading
           @State private var lineSpacing: CGFloat = 1.2
           
           // List states
           @State private var listType: ListType = .none
           @State private var listLevel: Int = 0
           
           enum ListType: String, CaseIterable {
               case none = "None"
               case bullet = "Bullet"
               case numbered = "Numbered"
               case checkbox = "Checkbox"
           }
           
           // Header states
           @State private var headerLevel: HeaderLevel = .none
           
           enum HeaderLevel: String, CaseIterable {
               case none = "None"
               case h1 = "H1"
               case h2 = "H2"
               case h3 = "H3"
           }
           
           // Audio recording states
           @State private var audioRecorder: AVAudioRecorder?
           @State private var audioPlayer: AVAudioPlayer?
           @State private var isRecording = false
           @State private var isPlaying = false
           @State private var recordingURL: URL?
           @State private var recordingDuration: TimeInterval = 0
           @State private var showingAudioRecorder = false
           
           // Video states
           @State private var selectedVideoItem: PhotosPickerItem?
           @State private var videoURL: URL?
           @State private var isVideoPickerPresented = false
           
           // File attachment states
           @State private var attachedFiles: [AttachedFile] = []
           @State private var showingDocumentPicker = false
           
           // Drawing states
           @State private var drawings: [Drawing] = []
           @State private var showingDrawingCanvas = false
           @State private var currentDrawing = Drawing()
           @State private var selectedDrawingTool: DrawingTool = .pen
           @State private var selectedColor: Color = .black
           @State private var selectedLineWidth: CGFloat = 3.0
           
           // Screenshot states
           @State private var screenshots: [Screenshot] = []
           @State private var showingScreenshotPicker = false
           @State private var isCapturingScreenshot = false
           
           // Table states
           @State private var tables: [NoteTable] = []
           @State private var showingTableCreator = false
           
    // Bookmark states
    @State private var showingBookmarks = false
    @State private var showingAddBookmark = false
    @State private var currentCursorPosition: Int32 = 0
    
    // Auto-save
    @StateObject private var autoSaveService = AutoSaveService.shared
    @State private var noteId: String = UUID().uuidString
           
           struct NoteTable: Identifiable {
               let id = UUID()
               var rows: Int
               var columns: Int
               var cells: [[String]]
               var position: CGPoint
               var isSelected: Bool = false
               
               init(rows: Int, columns: Int, position: CGPoint = CGPoint(x: 200, y: 200)) {
                   self.rows = rows
                   self.columns = columns
                   self.position = position
                   self.cells = Array(repeating: Array(repeating: "", count: columns), count: rows)
               }
           }
           
           struct Screenshot: Identifiable {
               let id = UUID()
               let image: UIImage
               let timestamp: Date
               let title: String
           }
           
           struct Drawing: Identifiable {
               let id = UUID()
               var paths: [DrawingPath] = []
               var tool: DrawingTool = .pen
               var color: Color = .black
               var lineWidth: CGFloat = 3.0
               var timestamp: Date = Date()
           }
           
           struct DrawingPath: Identifiable {
               let id = UUID()
               var points: [CGPoint] = []
               var tool: DrawingTool
               var color: Color
               var lineWidth: CGFloat
           }
           
           enum DrawingTool: String, CaseIterable {
               case pen = "Pen"
               case marker = "Marker"
               case highlighter = "Highlighter"
               case eraser = "Eraser"
               
               var icon: String {
                   switch self {
                   case .pen: return "pencil"
                   case .marker: return "pencil.tip"
                   case .highlighter: return "highlighter"
                   case .eraser: return "eraser"
                   }
               }
           }
           
           struct AttachedFile: Identifiable {
               let id = UUID()
               let name: String
               let url: URL
               let type: FileType
               
               enum FileType: String, CaseIterable {
                   case pdf = "PDF"
                   case doc = "DOC"
                   case docx = "DOCX"
                   case txt = "TXT"
                   case other = "Other"
                   
                   var icon: String {
                       switch self {
                       case .pdf: return "doc.text.fill"
                       case .doc, .docx: return "doc.fill"
                       case .txt: return "doc.plaintext.fill"
                       case .other: return "doc.fill"
                       }
                   }
               }
           }
    
    // Font and styling states
    @State private var fontSize: CGFloat = 16
    @State private var fontFamily: String = "System"
    @State private var textColor: Color = .white
    @State private var backgroundColor: Color = .clear
    @State private var showingFontPicker = false
    @State private var showingColorPicker = false
    
    // Cursor animation
    @State private var showCursor = true
    
    // Text selection
    @State private var selectedTextRange: Range<String.Index>?
    @State private var selectionStart: CGPoint?
    @State private var selectionEnd: CGPoint?
    @State private var isSelecting = false
    
    // Undo/Redo system
    @State private var editHistory: [String] = []
    @State private var currentHistoryIndex: Int = -1
    @State private var maxHistorySize: Int = 50
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    // MARK: - Initialization
    init(viewModel: NotesViewModel, noteToEdit: Note? = nil) {
        self.viewModel = viewModel
        self.noteToEdit = noteToEdit
    }
    
    // MARK: - Computed Properties
    private var attributedContent: AttributedString {
        var attributedString = AttributedString(content)
        
        // Apply formatting based on current states
        var font: Font = .system(size: fontSize, weight: .regular)
        
        if isBold && isItalic {
            font = .system(size: fontSize, weight: .bold, design: .serif)
        } else if isBold {
            font = .system(size: fontSize, weight: .bold)
        } else if isItalic {
            font = .system(size: fontSize, weight: .regular, design: .serif)
        }
        
        attributedString.font = font
        attributedString.foregroundColor = textColor
        
               if isUnderlined {
                   attributedString.underlineStyle = .single
               }
               
               if isStrikethrough {
                   attributedString.strikethroughStyle = .single
               }
               
               if isSuperscript {
                   attributedString.baselineOffset = fontSize * 0.3
                   attributedString.font = .system(size: fontSize * 0.7, weight: .regular)
               }
               
               if isSubscript {
                   attributedString.baselineOffset = -fontSize * 0.2
                   attributedString.font = .system(size: fontSize * 0.7, weight: .regular)
               }
               
               if backgroundColor != .clear {
                   attributedString.backgroundColor = backgroundColor
               }
        
        return attributedString
    }
    
    private var hasSelectedText: Bool {
        return selectedTextRange != nil
    }
    
    private var canPaste: Bool {
        return UIPasteboard.general.hasStrings
    }
    
    private var canUndo: Bool {
        return currentHistoryIndex > 0
    }
    
    private var canRedo: Bool {
        return currentHistoryIndex < editHistory.count - 1
    }
    
    // MARK: - Formatting Methods
    private func applyBoldFormatting() {
        isBold.toggle()
        applyFormattingToSelectedText(format: .bold)
    }
    
    private func applyItalicFormatting() {
        isItalic.toggle()
        applyFormattingToSelectedText(format: .italic)
    }
    
    private func applyUnderlineFormatting() {
        isUnderlined.toggle()
        applyFormattingToSelectedText(format: .underline)
    }
    
    private func applyStrikethroughFormatting() {
        isStrikethrough.toggle()
        applyFormattingToSelectedText(format: .strikethrough)
    }
    
    private enum TextFormat {
        case bold
        case italic
        case underline
        case strikethrough
    }
    
    private func applyFormattingToSelectedText(format: TextFormat) {
        // For now, we'll apply formatting to the current line or add formatting markers
        // In a full implementation, this would work with text selection
        let lines = content.components(separatedBy: .newlines)
        
        if lines.isEmpty {
            // If no content, add formatting markers for new text
            let marker = getFormatMarker(for: format)
            content = "\(marker) \(marker)"
            return
        }
        
        // Get the last line (where cursor likely is)
        let lastLineIndex = lines.count - 1
        var newLines = lines
        let currentLine = lines[lastLineIndex]
        
        // Check if the current line already has this formatting
        let hasFormatting = checkForFormatting(in: currentLine, format: format)
        
        if hasFormatting {
            // Remove formatting
            newLines[lastLineIndex] = removeFormatting(from: currentLine, format: format)
        } else {
            // Add formatting markers for new text
            let marker = getFormatMarker(for: format)
            if currentLine.isEmpty {
                newLines[lastLineIndex] = "\(marker) \(marker)"
            } else {
                // Add markers at the end for new text
                newLines[lastLineIndex] = currentLine + " \(marker)\(marker)"
            }
        }
        
        content = newLines.joined(separator: "\n")
        AtlasTheme.Haptics.light()
    }
    
    private func getFormatMarker(for format: TextFormat) -> String {
        switch format {
        case .bold:
            return "**"
        case .italic:
            return "*"
        case .underline:
            return "__"
        case .strikethrough:
            return "~~"
        }
    }
    
    private func checkForFormatting(in text: String, format: TextFormat) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        
        switch format {
        case .bold:
            return trimmedText.hasPrefix("**") && trimmedText.hasSuffix("**")
        case .italic:
            return trimmedText.hasPrefix("*") && trimmedText.hasSuffix("*") && !trimmedText.hasPrefix("**")
        case .underline:
            return trimmedText.hasPrefix("__") && trimmedText.hasSuffix("__")
        case .strikethrough:
            return trimmedText.hasPrefix("~~") && trimmedText.hasSuffix("~~")
        }
    }
    
    private func removeFormatting(from text: String, format: TextFormat) -> String {
        let marker = getFormatMarker(for: format)
        return text.replacingOccurrences(of: marker, with: "")
    }
    
    private func applySuperscriptFormatting() {
        isSuperscript.toggle()
        if isSuperscript {
            isSubscript = false // Can't be both
        }
    }
    
    private func applySubscriptFormatting() {
        isSubscript.toggle()
        if isSubscript {
            isSuperscript = false // Can't be both
        }
    }
    
    private func setTextAlignment(_ alignment: TextAlignment) {
        textAlignment = alignment
        AtlasTheme.Haptics.light()
    }
    
    private func adjustLineSpacing(_ spacing: CGFloat) {
        lineSpacing = spacing
        AtlasTheme.Haptics.light()
    }
    
    private func addNumberedList() {
        if content.isEmpty {
            content = "1. "
        } else {
            content += "\n1. "
        }
        listType = .numbered
        AtlasTheme.Haptics.light()
    }
    
    private func addCheckboxList() {
        if content.isEmpty {
            content = "☐ "
        } else {
            content += "\n☐ "
        }
        listType = .checkbox
        AtlasTheme.Haptics.light()
    }
    
    private func toggleCheckbox(at location: Int) {
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        var currentPosition = 0
        
        for line in lines {
            let lineLength = line.count + 1 // +1 for newline
            let lineStart = currentPosition
            let lineEnd = currentPosition + line.count
            
            if location >= lineStart && location <= lineEnd {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix("☐") {
                    // Toggle to checked
                    let newLine = line.replacingOccurrences(of: "☐", with: "☑", options: .anchored)
                    newLines.append(newLine)
                } else if trimmedLine.hasPrefix("☑") {
                    // Toggle to unchecked
                    let newLine = line.replacingOccurrences(of: "☑", with: "☐", options: .anchored)
                    newLines.append(newLine)
                } else {
                    newLines.append(line)
                }
            } else {
                newLines.append(line)
            }
            
            currentPosition += lineLength
        }
        
        content = newLines.joined(separator: "\n")
        AtlasTheme.Haptics.light()
    }
    
    private func toggleAllCheckboxes() {
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("☐") {
                // Toggle to checked
                let newLine = line.replacingOccurrences(of: "☐", with: "☑", options: .anchored)
                newLines.append(newLine)
            } else if trimmedLine.hasPrefix("☑") {
                // Toggle to unchecked
                let newLine = line.replacingOccurrences(of: "☑", with: "☐", options: .anchored)
                newLines.append(newLine)
            } else {
                newLines.append(line)
            }
        }
        
        content = newLines.joined(separator: "\n")
        AtlasTheme.Haptics.light()
    }
    
    private func toggleListType(_ type: ListType) {
        listType = type
        AtlasTheme.Haptics.light()
    }
    
    private func setHeaderLevel(_ level: HeaderLevel) {
        headerLevel = level
        applyHeaderFormatting(level: level)
        AtlasTheme.Haptics.light()
    }
    
    private func applyHeaderFormatting(level: HeaderLevel) {
        let lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check if line already has header formatting
            let hasH1 = trimmedLine.hasPrefix("# ") && !trimmedLine.hasPrefix("## ") && !trimmedLine.hasPrefix("### ")
            let hasH2 = trimmedLine.hasPrefix("## ") && !trimmedLine.hasPrefix("### ")
            let hasH3 = trimmedLine.hasPrefix("### ")
            
            var formattedLine = line
            
            if level == .none {
                // Remove all header formatting
                if hasH1 {
                    formattedLine = line.replacingOccurrences(of: "# ", with: "")
                } else if hasH2 {
                    formattedLine = line.replacingOccurrences(of: "## ", with: "")
                } else if hasH3 {
                    formattedLine = line.replacingOccurrences(of: "### ", with: "")
                }
            } else if !trimmedLine.isEmpty {
                // Apply header formatting
                let headerPrefix: String
                switch level {
                case .h1:
                    headerPrefix = "# "
                case .h2:
                    headerPrefix = "## "
                case .h3:
                    headerPrefix = "### "
                case .none:
                    headerPrefix = ""
                }
                
                // Remove existing header formatting first
                var cleanLine = line
                if hasH1 {
                    cleanLine = line.replacingOccurrences(of: "# ", with: "")
                } else if hasH2 {
                    cleanLine = line.replacingOccurrences(of: "## ", with: "")
                } else if hasH3 {
                    cleanLine = line.replacingOccurrences(of: "### ", with: "")
                }
                
                // Add new header formatting
                let trimmedCleanLine = cleanLine.trimmingCharacters(in: .whitespaces)
                if !trimmedCleanLine.isEmpty {
                    formattedLine = cleanLine.replacingOccurrences(of: trimmedCleanLine, with: "\(headerPrefix)\(trimmedCleanLine)")
                }
            }
            
            newLines.append(formattedLine)
        }
        
        content = newLines.joined(separator: "\n")
    }
    
    private func getHeaderFontSize() -> CGFloat {
        switch headerLevel {
        case .none:
            return fontSize
        case .h1:
            return fontSize * 2.0
        case .h2:
            return fontSize * 1.5
        case .h3:
            return fontSize * 1.25
        }
    }
    
    // MARK: - Audio Recording Methods
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            recordingURL = audioFilename
            AtlasTheme.Haptics.success()
            
        } catch {
            print("Failed to start recording: \(error)")
            AtlasTheme.Haptics.error()
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        AtlasTheme.Haptics.light()
    }
    
    private func playRecording() {
        guard let url = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
            AtlasTheme.Haptics.success()
        } catch {
            print("Failed to play recording: \(error)")
            AtlasTheme.Haptics.error()
        }
    }
    
    private func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
        AtlasTheme.Haptics.light()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Video Methods
    private func loadVideo(from item: PhotosPickerItem) {
        _Concurrency.Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let videoFilename = documentsPath.appendingPathComponent("video_\(Date().timeIntervalSince1970).mp4")
                
                do {
                    try data.write(to: videoFilename)
                    await MainActor.run {
                        videoURL = videoFilename
                        AtlasTheme.Haptics.success()
                    }
                } catch {
                    print("Failed to save video: \(error)")
                    await MainActor.run {
                        AtlasTheme.Haptics.error()
                    }
                }
            }
        }
    }
    
    private func removeVideo() {
        videoURL = nil
        AtlasTheme.Haptics.light()
    }
    
    // MARK: - File Attachment Methods
    private func addFileAttachment(_ url: URL) {
        let fileName = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        
        let fileType: AttachedFile.FileType
        switch fileExtension {
        case "pdf":
            fileType = .pdf
        case "doc":
            fileType = .doc
        case "docx":
            fileType = .docx
        case "txt":
            fileType = .txt
        default:
            fileType = .other
        }
        
        let attachedFile = AttachedFile(name: fileName, url: url, type: fileType)
        attachedFiles.append(attachedFile)
        AtlasTheme.Haptics.success()
    }
    
    private func removeFileAttachment(_ fileId: UUID) {
        attachedFiles.removeAll { $0.id == fileId }
        AtlasTheme.Haptics.light()
    }
    
    private func getFileType(from url: URL) -> AttachedFile.FileType {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "pdf": return .pdf
        case "doc": return .doc
        case "docx": return .docx
        case "txt": return .txt
        default: return .other
        }
    }
    
    // MARK: - Drawing Methods
    private func startDrawing() {
        showingDrawingCanvas = true
        currentDrawing = Drawing()
        AtlasTheme.Haptics.light()
    }
    
    private func saveDrawing() {
        if !currentDrawing.paths.isEmpty {
            drawings.append(currentDrawing)
            AtlasTheme.Haptics.success()
        }
        showingDrawingCanvas = false
    }
    
    private func cancelDrawing() {
        showingDrawingCanvas = false
        currentDrawing = Drawing()
        AtlasTheme.Haptics.light()
    }
    
    private func deleteDrawing(_ drawingId: UUID) {
        drawings.removeAll { $0.id == drawingId }
        AtlasTheme.Haptics.light()
    }
    
    private func addDrawingPath(_ path: DrawingPath) {
        currentDrawing.paths.append(path)
    }
    
    private func clearCurrentDrawing() {
        currentDrawing.paths.removeAll()
        AtlasTheme.Haptics.light()
    }
    
    // MARK: - Screenshot Methods
    private func captureScreenshot() {
        isCapturingScreenshot = true
        
        // Add a small delay to allow UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                
                let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
                let screenshot = renderer.image { context in
                    window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
                }
                
                let screenshotData = Screenshot(
                    image: screenshot,
                    timestamp: Date(),
                    title: "Screenshot \(screenshots.count + 1)"
                )
                
                screenshots.append(screenshotData)
                AtlasTheme.Haptics.success()
            }
            
            isCapturingScreenshot = false
        }
    }
    
    private func deleteScreenshot(_ screenshotId: UUID) {
        screenshots.removeAll { $0.id == screenshotId }
        AtlasTheme.Haptics.light()
    }
    
    private func addScreenshotFromLibrary() {
        showingScreenshotPicker = true
    }
    
    // MARK: - Table Methods
    private func createTable(rows: Int, columns: Int) {
        let table = NoteTable(rows: rows, columns: columns)
        tables.append(table)
        AtlasTheme.Haptics.success()
    }
    
    private func deleteTable(_ tableId: UUID) {
        tables.removeAll { $0.id == tableId }
        AtlasTheme.Haptics.light()
    }
    
    private func updateTableCell(_ tableId: UUID, row: Int, column: Int, text: String) {
        if let tableIndex = tables.firstIndex(where: { $0.id == tableId }) {
            if row < tables[tableIndex].rows && column < tables[tableIndex].columns {
                tables[tableIndex].cells[row][column] = text
            }
        }
    }
    
    // MARK: - Table of Contents Methods
    private func generateTableOfContents() {
        let lines = content.components(separatedBy: "\n")
        var tocLines: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for headers (lines that start with # or are in all caps)
            if trimmedLine.hasPrefix("#") {
                let level = trimmedLine.prefix(while: { $0 == "#" }).count
                let headerText = String(trimmedLine.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                let indent = String(repeating: "  ", count: level - 1)
                tocLines.append("\(indent)• \(headerText)")
            } else if trimmedLine.count > 3 && trimmedLine == trimmedLine.uppercased() && !trimmedLine.contains(" ") {
                // All caps single words (likely headers)
                tocLines.append("• \(trimmedLine)")
            }
        }
        
        if !tocLines.isEmpty {
            let toc = "Table of Contents:\n" + tocLines.joined(separator: "\n") + "\n\n"
            content = toc + content
            AtlasTheme.Haptics.success()
        } else {
            AtlasTheme.Haptics.light()
        }
    }
    
    // MARK: - Note Linking Methods
    private func insertNoteLink() {
        // Simple note linking - insert a placeholder link
        let linkText = "[Link to Note]"
        if content.isEmpty {
            content = linkText
        } else {
            content += "\n" + linkText
        }
        AtlasTheme.Haptics.success()
    }
    
    private func addBulletPoint() {
        // Add a bullet point to the content
        if content.isEmpty {
            content = "• "
        } else {
            content += "\n• "
        }
        listType = .bullet
        AtlasTheme.Haptics.light()
    }
    
    // MARK: - Text Processing for Lists
    private func processTextInput(_ newValue: String) -> String {
        // Check if we're in bullet list mode and handle return key
        if listType == .bullet {
            return processBulletListInput(newValue)
        } else if listType == .numbered {
            return processNumberedListInput(newValue)
        } else if listType == .checkbox {
            return processCheckboxListInput(newValue)
        }
        return newValue
    }
    
    private func processBulletListInput(_ newValue: String) -> String {
        let lines = newValue.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var previousLineWasBullet = false
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let isCurrentLineBullet = trimmedLine.hasPrefix("•")
            
            // If previous line was a bullet and current line is empty (return pressed)
            if previousLineWasBullet && trimmedLine.isEmpty {
                // Add new bullet point
                processedLines.append("• ")
            }
            // If previous line was a bullet and current line doesn't start with bullet
            else if previousLineWasBullet && !isCurrentLineBullet && !trimmedLine.isEmpty {
                // Check if it's a double return (empty line after bullet)
                if index > 0 && lines[index - 1].trimmingCharacters(in: .whitespaces).hasPrefix("•") {
                    // Exit bullet mode
                    processedLines.append(line)
                    listType = .none
                } else {
                    // Add bullet to current line
                    processedLines.append("• " + line)
                }
            }
            else {
                processedLines.append(line)
            }
            
            previousLineWasBullet = isCurrentLineBullet
        }
        
        return processedLines.joined(separator: "\n")
    }
    
    private func processNumberedListInput(_ newValue: String) -> String {
        let lines = newValue.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var previousLineWasNumbered = false
        var currentNumber = 1
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let isCurrentLineNumbered = trimmedLine.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
            
            // If previous line was numbered and current line is empty (return pressed)
            if previousLineWasNumbered && trimmedLine.isEmpty {
                // Add new numbered item
                processedLines.append("\(currentNumber). ")
                currentNumber += 1
            }
            // If previous line was numbered and current line doesn't start with number
            else if previousLineWasNumbered && !isCurrentLineNumbered && !trimmedLine.isEmpty {
                // Check if it's a double return (empty line after numbered item)
                if index > 0 && lines[index - 1].trimmingCharacters(in: .whitespaces).range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                    // Exit numbered mode
                    processedLines.append(line)
                    listType = .none
                } else {
                    // Add number to current line
                    processedLines.append("\(currentNumber). " + line)
                    currentNumber += 1
                }
            }
            else {
                processedLines.append(line)
                // Extract number from current line if it's numbered
                if isCurrentLineNumbered {
                    if let numberMatch = trimmedLine.range(of: #"^\d+"#, options: .regularExpression) {
                        let numberString = String(trimmedLine[numberMatch])
                        currentNumber = (Int(numberString) ?? currentNumber) + 1
                    }
                }
            }
            
            previousLineWasNumbered = isCurrentLineNumbered
        }
        
        return processedLines.joined(separator: "\n")
    }
    
    private func processCheckboxListInput(_ newValue: String) -> String {
        let lines = newValue.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var previousLineWasCheckbox = false
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let isCurrentLineCheckbox = trimmedLine.hasPrefix("☐") || trimmedLine.hasPrefix("☑")
            
            // If previous line was a checkbox and current line is empty (return pressed)
            if previousLineWasCheckbox && trimmedLine.isEmpty {
                // Add new checkbox
                processedLines.append("☐ ")
            }
            // If previous line was a checkbox and current line doesn't start with checkbox
            else if previousLineWasCheckbox && !isCurrentLineCheckbox && !trimmedLine.isEmpty {
                // Check if it's a double return (empty line after checkbox)
                if index > 0 && (lines[index - 1].trimmingCharacters(in: .whitespaces).hasPrefix("☐") || lines[index - 1].trimmingCharacters(in: .whitespaces).hasPrefix("☑")) {
                    // Exit checkbox mode
                    processedLines.append(line)
                    listType = .none
                } else {
                    // Add checkbox to current line
                    processedLines.append("☐ " + line)
                }
            }
            else {
                processedLines.append(line)
            }
            
            previousLineWasCheckbox = isCurrentLineCheckbox
        }
        
        return processedLines.joined(separator: "\n")
    }
    
    // MARK: - Image Methods
    private func addImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let noteImage = NoteImage(
            imageData: imageData,
            position: CGPoint(x: 200, y: 200 + CGFloat(images.count * 50)),
            size: CGSize(width: 150, height: 150),
            textWrap: .square
        )
        images.append(noteImage)
        AtlasTheme.Haptics.success()
    }
    
    private func removeImage(_ imageId: UUID) {
        images.removeAll { $0.id == imageId }
        if selectedImageId == imageId {
            selectedImageId = nil
        }
        AtlasTheme.Haptics.light()
    }
    
    private func resizeImage(_ imageId: UUID, corner: CGPoint, translation: CGSize) {
        guard let index = images.firstIndex(where: { $0.id == imageId }) else { return }
        
        let scaleFactor: CGFloat = 0.01
        let newWidth = max(50, images[index].size.width + translation.width * scaleFactor)
        let newHeight = max(50, images[index].size.height + translation.height * scaleFactor)
        
        images[index].size = CGSize(width: newWidth, height: newHeight)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Same blue background as the rest of the app
                AtlasTheme.Colors.background
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader
                    
                    // Content Area
                    VStack(spacing: 0) {
                        // Title Field
                        titleField
                        
                               // Content Field
                               contentField
                               
                               // Audio Player (if recording exists)
                               if recordingURL != nil {
                                   audioPlayerView
                               }
                               
                               // Video Player (if video exists)
                               if videoURL != nil {
                                   videoPlayerView
                               }
                               
                               // File Attachments (if files exist)
                               if !attachedFiles.isEmpty {
                                   fileAttachmentsView
                               }
                               
                               // Drawings (if drawings exist)
                               if !drawings.isEmpty {
                                   drawingsView
                               }
                               
                               // Screenshots (if screenshots exist)
                               if !screenshots.isEmpty {
                                   screenshotsView
                               }
                               
                               // Tables (if tables exist)
                               if !tables.isEmpty {
                                   tablesView
                               }
                               
                               Spacer()
                    }
                    
                    // Modern Formatting Toolbar
                    modernFormattingToolbar
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
               .onAppear {
                   print("🟢 CreateNoteView appeared!")
                   if let note = noteToEdit {
                       loadNoteData(note)
                       viewModel.markNoteAsAccessed(note)
                   }
                   startCursorAnimation()
                   initializeHistory()
               }
               .onChange(of: content) { _, newContent in
                   // Debounce history saving to avoid saving on every keystroke
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                       if newContent == content {
                           saveToHistory()
                       }
                   }
               }
               .onChange(of: selectedPhotoItem) { _, newItem in
                   if let newItem = newItem {
                       loadPhoto(from: newItem)
                   }
               }
               .onChange(of: selectedVideoItem) { _, newItem in
                   if let newItem = newItem {
                       loadVideo(from: newItem)
                   }
               }
               .sheet(isPresented: $isImagePickerPresented) {
                   ImagePicker { image in
                       addImage(image)
                   }
               }
               .sheet(isPresented: $showingFontPicker) {
                   fontPickerSheet
               }
               .sheet(isPresented: $showingColorPicker) {
                   colorPickerSheet
               }
               .sheet(isPresented: $showingDocumentPicker) {
                   DocumentPicker { url in
                       addFileAttachment(url)
                   }
               }
               .fullScreenCover(isPresented: $showingDrawingCanvas) {
                   DrawingCanvasView(
                       currentDrawing: $currentDrawing,
                       selectedTool: $selectedDrawingTool,
                       selectedColor: $selectedColor,
                       selectedLineWidth: $selectedLineWidth,
                       onSave: saveDrawing,
                       onCancel: cancelDrawing
                   )
               }
               .sheet(isPresented: $showingScreenshotPicker) {
                   ScreenshotPickerView { image in
                       let screenshot = Screenshot(
                           image: image,
                           timestamp: Date(),
                           title: "Screenshot \(screenshots.count + 1)"
                       )
                       screenshots.append(screenshot)
                       AtlasTheme.Haptics.success()
                   }
               }
               .sheet(isPresented: $showingTableCreator) {
                   TableCreatorView { rows, columns in
                       createTable(rows: rows, columns: columns)
                   }
               }
               .sheet(isPresented: $showingBookmarks) {
                   if let note = noteToEdit {
                       BookmarkView(note: note)
                   }
               }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack {
            // Back Button
            Button(action: {
                        AtlasTheme.Haptics.light()
                        dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Title and Save Status
            VStack(spacing: 2) {
                Text(noteToEdit != nil ? "Edit Note" : "New Note")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(autoSaveService.saveStatusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(autoSaveService.saveStatusColor)
            }
            
            Spacer()
            
            // Save Button
            Button(action: {
                AtlasTheme.Haptics.medium()
                        saveNote()
            }) {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(title.isEmpty && content.isEmpty)
            .opacity(title.isEmpty && content.isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 15)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
    
    // MARK: - Title Field
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $title)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.white)
                .focused($isTitleFocused)
                .submitLabel(.next)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(false)
                .onSubmit {
                    isContentFocused = true
                }
                .onChange(of: title) { _, newValue in
                    autoSaveService.registerChange(for: noteId, key: "title", value: newValue)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
        }
    }
    
    // MARK: - Content Field
    private var contentField: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Native TextEditor with proper text selection support
            ZStack(alignment: .topLeading) {
                // Background placeholder text
                if content.isEmpty && !isContentFocused {
                    Text("Start writing...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
                
                // Native TextEditor with full iOS text selection support
                TextEditor(text: $content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .focused($isContentFocused)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .onChange(of: content) { _, newValue in
                        let processedContent = processTextInput(newValue)
                        if processedContent != newValue {
                            content = processedContent
                        }
                        autoSaveService.registerChange(for: noteId, key: "content", value: processedContent)
                    }
                    .onTapGesture {
                        selectedImageId = nil
                    }
            }
            
            // Images overlay (if any)
            if !images.isEmpty {
                ZStack {
                    ForEach(images) { noteImage in
                        imageView(noteImage)
                            .position(noteImage.position)
                    }
                }
                .allowsHitTesting(true)
            }
        }
        .background(AtlasTheme.Colors.background)
    }
    
    // MARK: - Rich Text with Images
    private var richTextWithImages: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Text content with dynamic wrapping
                dynamicTextFlow(in: geometry)
                
                // Overlay images at their positions
                ForEach(images) { noteImage in
                    imageView(noteImage)
                        .position(noteImage.position)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
           // MARK: - Dynamic Text Flow
           private func dynamicTextFlow(in geometry: GeometryProxy) -> some View {
               let textWidth = geometry.size.width - 40 // Account for padding
               let lineHeight: CGFloat = 20
               let lines = content.components(separatedBy: "\n")
               
               return VStack(alignment: .leading, spacing: 0) {
                   ForEach(Array(lines.enumerated()), id: \.offset) { lineIndex, line in
                       let lineY = CGFloat(lineIndex) * lineHeight
                       let lineText = line.isEmpty ? " " : line
                       
                       // Check if this line intersects with any images
                       let intersectingImages = images.filter { image in
                           let imageTop = image.position.y - image.size.height / 2
                           let imageBottom = image.position.y + image.size.height / 2
                           return lineY >= imageTop && lineY <= imageBottom
                       }
                       
                       if intersectingImages.isEmpty {
                           // No images on this line - full width text
                           HStack(alignment: .top, spacing: 0) {
                               Text(lineText)
                                   .font(.system(size: getHeaderFontSize(), weight: headerLevel != .none ? .bold : .regular))
                                   .foregroundColor(textColor)
                                   .multilineTextAlignment(textAlignment)
                                   .lineLimit(nil)
                                   .fixedSize(horizontal: false, vertical: true)
                                   .background(
                                       // Selection highlighting
                                       Group {
                                           if let range = selectedTextRange,
                                              let lineRange = getLineRange(for: lineIndex, in: content),
                                              range.overlaps(lineRange) {
                                               Rectangle()
                                                   .fill(Color.blue.opacity(0.3))
                                                   .cornerRadius(2)
                                           }
                                       }
                                   )
                               
                               // Add blinking cursor at end of content
                               if lineIndex == lines.count - 1 && isContentFocused {
                                   Text("|")
                                       .font(.system(size: 16, weight: .regular))
                                       .foregroundColor(.white)
                                       .opacity(showCursor ? 1.0 : 0.0)
                                       .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showCursor)
                               }
                               
                               Spacer()
                           }
                           .frame(maxWidth: .infinity, alignment: .leading)
                           .frame(minHeight: lineHeight)
                       } else {
                           // Images on this line - wrap text around them
                           wrappedTextLine(lineText, images: intersectingImages, lineY: lineY, textWidth: textWidth)
                               .frame(height: lineHeight)
                       }
                   }
               }
           }
    
    // MARK: - Wrapped Text Line
    private func wrappedTextLine(_ text: String, images: [NoteImage], lineY: CGFloat, textWidth: CGFloat) -> some View {
        let sortedImages = images.sorted { $0.position.x < $1.position.x }
        var textSegments: [(String, CGFloat, CGFloat)] = [] // (text, x, width)
        
        var currentX: CGFloat = 0
        var remainingText = text
        
        for image in sortedImages {
            // More accurate image boundaries based on actual size
            let imageLeft = max(0, image.position.x - image.size.width / 2 - 5) // 5pt margin
            let imageRight = min(textWidth, image.position.x + image.size.width / 2 + 5)
            
            // Add text segment before image
            if currentX < imageLeft && !remainingText.isEmpty {
                let segmentWidth = imageLeft - currentX
                // More accurate character width calculation
                let charWidth: CGFloat = 9 // More accurate character width
                let maxChars = Int(segmentWidth / charWidth)
                let segmentText = String(remainingText.prefix(maxChars))
                textSegments.append((segmentText, currentX, segmentWidth))
                remainingText = String(remainingText.dropFirst(segmentText.count))
                currentX = imageRight
            } else {
                currentX = max(currentX, imageRight)
            }
        }
        
        // Add remaining text
        if !remainingText.isEmpty && currentX < textWidth {
            textSegments.append((remainingText, currentX, textWidth - currentX))
        }
        
        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(textSegments.enumerated()), id: \.offset) { index, segment in
                HStack(alignment: .top, spacing: 0) {
                              Text(segment.0)
                                  .font(.system(size: getHeaderFontSize(), weight: headerLevel != .none ? .bold : .regular))
                                  .foregroundColor(textColor)
                                  .frame(width: segment.2, alignment: .leading)
                               .lineLimit(nil)
                               .fixedSize(horizontal: false, vertical: true)
                    
                    // Add cursor at end of last segment if focused
                    if index == textSegments.count - 1 && isContentFocused {
                        Text("|")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                            .opacity(showCursor ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: showCursor)
                    }
                }
                .position(x: segment.1 + segment.2 / 2, y: 10)
            }
        }
    }
    
    // MARK: - Image View
    private func imageView(_ noteImage: NoteImage) -> some View {
        ZStack {
            MemoryEfficientImageView(
                imageData: noteImage.imageData,
                id: noteImage.id.uuidString,
                maxSize: noteImage.size
            )
                .aspectRatio(contentMode: .fit)
                .frame(width: noteImage.size.width, height: noteImage.size.height)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(noteImage.isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                .onTapGesture {
                    // Deselect all other images
                    for i in images.indices {
                        images[i].isSelected = false
                    }
                    
                    // Select this image
                    selectedImageId = noteImage.id
                    withAnimation {
                        if let index = images.firstIndex(where: { $0.id == noteImage.id }) {
                            images[index].isSelected = true
                        }
                    }
                }
            
            // Image controls when selected
            if noteImage.isSelected {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            removeImage(noteImage.id)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding(4)
                
                // Resize handles
                resizeHandles(for: noteImage)
            }
        }
        .position(noteImage.position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if let index = images.firstIndex(where: { $0.id == noteImage.id }) {
                        images[index].position = value.location
                    }
                }
        )
    }
    
    // MARK: - Resize Handles
    private func resizeHandles(for noteImage: NoteImage) -> some View {
        ZStack {
            // Corner resize handles
            ForEach(0..<4, id: \.self) { index in
                let corner = CGPoint(
                    x: index % 2 == 0 ? 0 : 1,
                    y: index < 2 ? 0 : 1
                )
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .position(
                        x: noteImage.position.x + (corner.x - 0.5) * noteImage.size.width,
                        y: noteImage.position.y + (corner.y - 0.5) * noteImage.size.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                resizeImage(noteImage.id, corner: corner, translation: value.translation)
                            }
                    )
            }
        }
    }
    
           // MARK: - Audio Player View
           private var audioPlayerView: some View {
               HStack(spacing: 15) {
                   // Play/Pause Button
                   Button(action: {
                       if isPlaying {
                           stopPlaying()
                       } else {
                           playRecording()
                       }
                   }) {
                       Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                           .font(.system(size: 24, weight: .medium))
                           .foregroundColor(AtlasTheme.Colors.accent)
                   }
                   
                   // Audio Waveform (placeholder)
                   HStack(spacing: 2) {
                       ForEach(0..<20, id: \.self) { index in
                           Rectangle()
                               .fill(AtlasTheme.Colors.accent)
                               .frame(width: 3, height: CGFloat.random(in: 4...20))
                               .cornerRadius(1.5)
                       }
                   }
                   .frame(height: 20)
                   
                   // Duration
                   Text(formatDuration(recordingDuration))
                       .font(.system(size: 14, weight: .medium))
                       .foregroundColor(.white.opacity(0.8))
                   
                   Spacer()
                   
                   // Delete Button
                   Button(action: {
                       recordingURL = nil
                       audioPlayer?.stop()
                       isPlaying = false
                       AtlasTheme.Haptics.light()
                   }) {
                       Image(systemName: "trash")
                           .font(.system(size: 16, weight: .medium))
                           .foregroundColor(.red)
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 12)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.white.opacity(0.1))
                       .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
               )
               .padding(.horizontal, 20)
               .padding(.top, 10)
           }
           
           // MARK: - Video Player View
           private var videoPlayerView: some View {
               VStack(spacing: 10) {
                   if let videoURL = videoURL {
                       VideoPlayer(player: AVPlayer(url: videoURL))
                           .frame(height: 200)
                           .cornerRadius(12)
                           .overlay(
                               RoundedRectangle(cornerRadius: 12)
                                   .stroke(Color.white.opacity(0.2), lineWidth: 1)
                           )
                   }
                   
                   HStack {
                       Image(systemName: "video.fill")
                           .foregroundColor(AtlasTheme.Colors.accent)
                       
                       Text("Video Attachment")
                           .font(.system(size: 14, weight: .medium))
                           .foregroundColor(.white.opacity(0.8))
                       
                       Spacer()
                       
                       Button(action: {
                           removeVideo()
                       }) {
                           Image(systemName: "trash")
                               .font(.system(size: 16, weight: .medium))
                               .foregroundColor(.red)
                       }
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 12)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.white.opacity(0.1))
                       .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
               )
               .padding(.horizontal, 20)
               .padding(.top, 10)
           }
           
           // MARK: - File Attachments View
           private var fileAttachmentsView: some View {
               VStack(alignment: .leading, spacing: 10) {
                   HStack {
                       Image(systemName: "doc.text.fill")
                           .foregroundColor(AtlasTheme.Colors.accent)
                       
                       Text("Attached Files")
                           .font(.system(size: 16, weight: .semibold))
                           .foregroundColor(.white)
                       
                       Spacer()
                   }
                   
                   ForEach(attachedFiles) { file in
                       HStack(spacing: 12) {
                           Image(systemName: file.type.icon)
                               .font(.system(size: 20, weight: .medium))
                               .foregroundColor(AtlasTheme.Colors.accent)
                               .frame(width: 24, height: 24)
                           
                           VStack(alignment: .leading, spacing: 2) {
                               Text(file.name)
                                   .font(.system(size: 14, weight: .medium))
                                   .foregroundColor(.white)
                                   .lineLimit(1)
                               
                               Text(file.type.rawValue)
                                   .font(.system(size: 12, weight: .regular))
                                   .foregroundColor(.white.opacity(0.6))
                           }
                           
                           Spacer()
                           
                           Button(action: {
                               removeFileAttachment(file.id)
                           }) {
                               Image(systemName: "trash")
                                   .font(.system(size: 14, weight: .medium))
                                   .foregroundColor(.red)
                           }
                       }
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(
                           RoundedRectangle(cornerRadius: 8)
                               .fill(Color.white.opacity(0.05))
                       )
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 12)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.white.opacity(0.1))
                       .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
               )
               .padding(.horizontal, 20)
               .padding(.top, 10)
           }
           
           // MARK: - Drawings View
           private var drawingsView: some View {
               VStack(alignment: .leading, spacing: 10) {
                   HStack {
                       Image(systemName: "pencil.and.outline")
                           .foregroundColor(AtlasTheme.Colors.accent)
                       
                       Text("Drawings")
                           .font(.system(size: 16, weight: .semibold))
                           .foregroundColor(.white)
                       
                       Spacer()
                   }
                   
                   ForEach(drawings) { drawing in
                       HStack(spacing: 12) {
                           // Drawing thumbnail
                           DrawingThumbnail(drawing: drawing)
                               .frame(width: 60, height: 40)
                               .background(Color.white.opacity(0.1))
                               .cornerRadius(8)
                           
                           VStack(alignment: .leading, spacing: 2) {
                               Text("Drawing")
                                   .font(.system(size: 14, weight: .medium))
                                   .foregroundColor(.white)
                               
                               Text("\(drawing.paths.count) strokes")
                                   .font(.system(size: 12, weight: .regular))
                                   .foregroundColor(.white.opacity(0.6))
                           }
                           
                           Spacer()
                           
                           Button(action: {
                               deleteDrawing(drawing.id)
                           }) {
                               Image(systemName: "trash")
                                   .font(.system(size: 14, weight: .medium))
                                   .foregroundColor(.red)
                           }
                       }
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(
                           RoundedRectangle(cornerRadius: 8)
                               .fill(Color.white.opacity(0.05))
                       )
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 12)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.white.opacity(0.1))
                       .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
               )
               .padding(.horizontal, 20)
               .padding(.top, 10)
           }
           
           // MARK: - Drawing Thumbnail
           private func DrawingThumbnail(drawing: Drawing) -> some View {
               Canvas { context, size in
                   for path in drawing.paths {
                       if path.points.count > 1 {
                           var drawingPath = Path()
                           drawingPath.move(to: path.points[0])
                           
                           for i in 1..<path.points.count {
                               drawingPath.addLine(to: path.points[i])
                           }
                           
                           context.stroke(drawingPath, with: .color(path.color), lineWidth: path.lineWidth)
                       }
                   }
               }
           }
           
           // MARK: - Screenshots View
           private var screenshotsView: some View {
               VStack(alignment: .leading, spacing: 10) {
                   HStack {
                       Image(systemName: "camera.fill")
                           .foregroundColor(AtlasTheme.Colors.accent)
                       
                       Text("Screenshots")
                           .font(.system(size: 16, weight: .semibold))
                           .foregroundColor(.white)
                       
                       Spacer()
                   }
                   
                   ForEach(screenshots) { screenshot in
                       HStack(spacing: 12) {
                           // Screenshot thumbnail
                           Image(uiImage: screenshot.image)
                               .resizable()
                               .aspectRatio(contentMode: .fill)
                               .frame(width: 60, height: 40)
                               .clipped()
                               .cornerRadius(8)
                               .overlay(
                                   RoundedRectangle(cornerRadius: 8)
                                       .stroke(Color.white.opacity(0.2), lineWidth: 1)
                               )
                           
                           VStack(alignment: .leading, spacing: 2) {
                               Text(screenshot.title)
                                   .font(.system(size: 14, weight: .medium))
                                   .foregroundColor(.white)
                               
                               Text(screenshot.timestamp, style: .time)
                                   .font(.system(size: 12, weight: .regular))
                                   .foregroundColor(.white.opacity(0.6))
                           }
                           
                           Spacer()
                           
                           Button(action: {
                               deleteScreenshot(screenshot.id)
                           }) {
                               Image(systemName: "trash")
                                   .font(.system(size: 14, weight: .medium))
                                   .foregroundColor(.red)
                           }
                       }
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(
                           RoundedRectangle(cornerRadius: 8)
                               .fill(Color.white.opacity(0.05))
                       )
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 12)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.white.opacity(0.1))
                       .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
               )
               .padding(.horizontal, 20)
               .padding(.top, 10)
           }
           
           // MARK: - Tables View
           private var tablesView: some View {
               VStack(alignment: .leading, spacing: 10) {
                   HStack {
                       Image(systemName: "tablecells")
                           .foregroundColor(AtlasTheme.Colors.accent)
                       
                       Text("Tables")
                           .font(.system(size: 16, weight: .semibold))
                           .foregroundColor(.white)
                       
                       Spacer()
                   }
                   
                   ForEach(tables) { table in
                       VStack(spacing: 8) {
                           // Table preview
                           TablePreviewView(table: table, onUpdateCell: { row, column, text in
                               updateTableCell(table.id, row: row, column: column, text: text)
                           })
                           .frame(height: 120)
                           .background(Color.white.opacity(0.1))
                           .cornerRadius(8)
                           
                           HStack {
                               Text("\(table.rows) × \(table.columns) Table")
                                   .font(.system(size: 14, weight: .medium))
                                   .foregroundColor(.white)
                               
                               Spacer()
                               
                               Button(action: {
                                   deleteTable(table.id)
                               }) {
                                   Image(systemName: "trash")
                                       .font(.system(size: 14, weight: .medium))
                                       .foregroundColor(.red)
                               }
                           }
                       }
                       .padding(.horizontal, 12)
                       .padding(.vertical, 8)
                       .background(
                           RoundedRectangle(cornerRadius: 8)
                               .fill(Color.white.opacity(0.05))
                       )
                   }
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 12)
               .background(
                   RoundedRectangle(cornerRadius: 12)
                       .fill(Color.white.opacity(0.1))
                       .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
               )
               .padding(.horizontal, 20)
               .padding(.top, 10)
           }
           
           // MARK: - Modern Formatting Toolbar
           private var modernFormattingToolbar: some View {
        HStack(spacing: 0) {
            // Text Formatting Menu
            Menu {
                Button(action: {
                    AtlasTheme.Haptics.light()
                    applyBoldFormatting()
                }) {
                    Label("Bold", systemImage: "bold")
                }
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    applyItalicFormatting()
                }) {
                    Label("Italic", systemImage: "italic")
                }
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    applyUnderlineFormatting()
                }) {
                    Label("Underline", systemImage: "underline")
                }
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    applyStrikethroughFormatting()
                }) {
                    Label("Strikethrough", systemImage: "strikethrough")
                }
                
                Divider()
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    applySuperscriptFormatting()
                }) {
                    Label("Superscript", systemImage: "textformat.superscript")
                }
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    applySubscriptFormatting()
                }) {
                    Label("Subscript", systemImage: "textformat.subscript")
                }
            } label: {
                Image(systemName: "textformat")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Lists Menu
            Menu {
                Button(action: {
                    addBulletPoint()
                }) {
                    Label("Bullet List", systemImage: "list.bullet")
                }
                
                Button(action: {
                    addNumberedList()
                }) {
                    Label("Numbered List", systemImage: "list.number")
                }
                
                Button(action: {
                    addCheckboxList()
                }) {
                    Label("Checkbox List", systemImage: "checklist")
                }
                
                Button(action: {
                    toggleAllCheckboxes()
                }) {
                    Label("Toggle All Checkboxes", systemImage: "checkmark.circle")
                }
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Headers Menu
            Menu {
                Button(action: {
                    setHeaderLevel(.h1)
                }) {
                    Label("Header 1", systemImage: "textformat.size")
                }
                
                Button(action: {
                    setHeaderLevel(.h2)
                }) {
                    Label("Header 2", systemImage: "textformat.size")
                }
                
                Button(action: {
                    setHeaderLevel(.h3)
                }) {
                    Label("Header 3", systemImage: "textformat.size")
                }
            } label: {
                Text("H")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Media Menu
            Menu {
                Button(action: {
                    AtlasTheme.Haptics.light()
                    isImagePickerPresented = true
                }) {
                    Label("Add Photo", systemImage: "camera")
                }
                
                PhotosPicker(
                    selection: $selectedVideoItem,
                    matching: .videos,
                    photoLibrary: .shared()
                ) {
                    Label("Add Video", systemImage: "video")
                }
                
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    Label("Add Document", systemImage: "doc.badge.plus")
                }
                
                Divider()
                
                Button(action: {
                    startDrawing()
                }) {
                    Label("Draw", systemImage: "pencil.and.outline")
                }
                
                Menu {
                    Button(action: {
                        captureScreenshot()
                    }) {
                        Label("Capture Screenshot", systemImage: "camera")
                    }
                    
                    Button(action: {
                        addScreenshotFromLibrary()
                    }) {
                        Label("Add from Library", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Label("Screenshot", systemImage: "camera")
                }
            } label: {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Audio Recording Button
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isRecording ? .red : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Advanced Features Menu
            Menu {
                Button(action: {
                    showingTableCreator = true
                }) {
                    Label("Insert Table", systemImage: "tablecells")
                }
                
                Button(action: {
                    generateTableOfContents()
                }) {
                    Label("Table of Contents", systemImage: "list.bullet.rectangle")
                }
                
                Button(action: {
                    insertNoteLink()
                }) {
                    Label("Link to Note", systemImage: "link")
                }
                
                Divider()
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingBookmarks.toggle()
                }) {
                    Label("Add Bookmark", systemImage: "bookmark")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Edit Menu
            Menu {
                Button(action: {
                    AtlasTheme.Haptics.light()
                    copySelectedText()
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .disabled(!hasSelectedText)
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    pasteText()
                }) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .disabled(!canPaste)
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    selectAllText()
                }) {
                    Label("Select All", systemImage: "textformat.abc")
                }
                .disabled(content.isEmpty)
                
                Divider()
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    undo()
                }) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(!canUndo)
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    redo()
                }) {
                    Label("Redo", systemImage: "arrow.uturn.forward")
                }
                .disabled(!canRedo)
            } label: {
                Image(systemName: "doc.text")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Style Menu
            Menu {
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingFontPicker.toggle()
                }) {
                    Label("Font Size (\(Int(fontSize)))", systemImage: "textformat.size")
                }
                
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingColorPicker.toggle()
                }) {
                    Label("Text Color", systemImage: "textformat")
                }
                
                Divider()
                
                Button(action: {
                    setTextAlignment(.leading)
                }) {
                    Label("Align Left", systemImage: "text.alignleft")
                }
                
                Button(action: {
                    setTextAlignment(.center)
                }) {
                    Label("Align Center", systemImage: "text.aligncenter")
                }
                
                Button(action: {
                    setTextAlignment(.trailing)
                }) {
                    Label("Align Right", systemImage: "text.alignright")
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            
            // Keyboard Dismiss Button
            Button(action: {
                AtlasTheme.Haptics.light()
                dismissKeyboard()
            }) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: -1)
        )
    }
    
    
    private func loadPhoto(from item: PhotosPickerItem) {
        _Concurrency.Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    addImage(image)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func saveNote() {
        guard !title.isEmpty || !content.isEmpty else { return }
        
        if let note = noteToEdit {
            // Update existing note
            viewModel.updateNote(
                note,
                title: title.isEmpty ? "Untitled Note" : title,
                content: content
            )
        } else {
            // Create new note
        viewModel.createNote(
                title: title.isEmpty ? "Untitled Note" : title,
            content: content,
            isEncrypted: isEncrypted
        )
    }
        
        dismiss()
    }
    
    private func loadNoteData(_ note: Note) {
        title = note.title ?? ""
        content = note.content ?? ""
        isEncrypted = note.isEncrypted
        noteId = note.uuid?.uuidString ?? UUID().uuidString
        // TODO: Load images from note if they exist
    }
    
    private func startCursorAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { _ in
            DispatchQueue.main.async {
                showCursor.toggle()
            }
        }
    }
    
    private func dismissKeyboard() {
        isTitleFocused = false
        isContentFocused = false
    }
    
    // MARK: - Clipboard Operations
    private func copySelectedText() {
        guard let range = selectedTextRange else { return }
        let selectedText = String(content[range])
        UIPasteboard.general.string = selectedText
        AtlasTheme.Haptics.success()
    }
    
    private func pasteText() {
        guard let pastedText = UIPasteboard.general.string else { return }
        
        if let range = selectedTextRange {
            // Replace selected text
            content.replaceSubrange(range, with: pastedText)
            selectedTextRange = nil
        } else {
            // Insert at cursor position (end of content for now)
            content += pastedText
        }
        
        AtlasTheme.Haptics.success()
    }
    
    private func selectAllText() {
        if !content.isEmpty {
            selectedTextRange = content.startIndex..<content.endIndex
            AtlasTheme.Haptics.light()
        }
    }
    
    private func clearSelection() {
        selectedTextRange = nil
        selectionStart = nil
        selectionEnd = nil
        isSelecting = false
    }
    
    // MARK: - Text Selection Helpers
    private func getLineRange(for lineIndex: Int, in text: String) -> Range<String.Index>? {
        let lines = text.components(separatedBy: "\n")
        guard lineIndex < lines.count else { return nil }
        
        var currentIndex = text.startIndex
        for _ in 0..<lineIndex {
            if let newlineIndex = text[currentIndex...].firstIndex(of: "\n") {
                currentIndex = text.index(after: newlineIndex)
            } else {
                return nil
            }
        }
        
        let lineStart = currentIndex
        if let newlineIndex = text[currentIndex...].firstIndex(of: "\n") {
            return lineStart..<newlineIndex
        } else {
            return lineStart..<text.endIndex
        }
    }
    
    // MARK: - Undo/Redo System
    private func saveToHistory() {
        // Don't save if content hasn't changed
        if !editHistory.isEmpty && editHistory[currentHistoryIndex] == content {
            return
        }
        
        // Remove any history after current index (when user makes new changes after undo)
        if currentHistoryIndex < editHistory.count - 1 {
            editHistory.removeSubrange((currentHistoryIndex + 1)...)
        }
        
        // Add new state to history
        editHistory.append(content)
        currentHistoryIndex = editHistory.count - 1
        
        // Limit history size
        if editHistory.count > maxHistorySize {
            editHistory.removeFirst()
            currentHistoryIndex -= 1
        }
    }
    
    private func undo() {
        guard canUndo else { return }
        
        currentHistoryIndex -= 1
        content = editHistory[currentHistoryIndex]
        AtlasTheme.Haptics.success()
    }
    
    private func redo() {
        guard canRedo else { return }
        
        currentHistoryIndex += 1
        content = editHistory[currentHistoryIndex]
        AtlasTheme.Haptics.success()
    }
    
    private func initializeHistory() {
        if editHistory.isEmpty {
            editHistory.append(content)
            currentHistoryIndex = 0
        }
    }
    
    // MARK: - Font and Color Pickers
    private var fontPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Font Size")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("Size: \(Int(fontSize))")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Slider(value: $fontSize, in: 8...32, step: 1)
                        .accentColor(AtlasTheme.Colors.accent)
                    
                    HStack {
                        Text("8")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("32")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Font Family Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Font Family")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        ForEach(["System", "Times New Roman", "Helvetica", "Courier"], id: \.self) { family in
                            Button(action: {
                                fontFamily = family
                                AtlasTheme.Haptics.light()
                            }) {
                                Text(family)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(fontFamily == family ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(fontFamily == family ? AtlasTheme.Colors.accent : Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Font Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingFontPicker = false
            })
        }
    }
    
    private var colorPickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Text Colors")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Text Color Selection
                textColorSection
                
                // Background Color Selection
                backgroundColorSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Color Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showingColorPicker = false
            })
        }
    }
    
    private var textColorSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Text Color")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(textColors, id: \.self) { color in
                    Button(action: {
                        textColor = color
                        AtlasTheme.Haptics.light()
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(textColor == color ? Color.primary : Color.clear, lineWidth: 3)
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var backgroundColorSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Background Color")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(backgroundColors, id: \.self) { color in
                    Button(action: {
                        backgroundColor = color
                        AtlasTheme.Haptics.light()
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(backgroundColor == color ? Color.primary : Color.clear, lineWidth: 3)
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var textColors: [Color] {
        [Color.white, Color.black, Color.red, Color.blue, Color.green, Color.orange, Color.purple, Color.pink, Color.yellow, Color.gray, Color.cyan, Color.mint]
    }
    
    private var backgroundColors: [Color] {
        [Color.clear, Color.yellow.opacity(0.3), Color.blue.opacity(0.3), Color.green.opacity(0.3), Color.red.opacity(0.3), Color.purple.opacity(0.3), Color.orange.opacity(0.3), Color.pink.opacity(0.3), Color.cyan.opacity(0.3), Color.mint.opacity(0.3), Color.gray.opacity(0.3), Color.black.opacity(0.3)]
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText, .rtf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onDocumentPicked(url)
        }
    }
}

// MARK: - Drawing Canvas View
struct DrawingCanvasView: View {
    @Binding var currentDrawing: CreateNoteView.Drawing
    @Binding var selectedTool: CreateNoteView.DrawingTool
    @Binding var selectedColor: Color
    @Binding var selectedLineWidth: CGFloat
    
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var currentPath = CreateNoteView.DrawingPath(
        points: [],
        tool: .pen,
        color: .black,
        lineWidth: 3.0
    )
    
    @State private var isDrawing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Drawing Canvas
                Canvas { context, size in
                    // Draw all completed paths
                    for path in currentDrawing.paths {
                        if path.points.count > 1 {
                            var drawingPath = Path()
                            drawingPath.move(to: path.points[0])
                            
                            for i in 1..<path.points.count {
                                drawingPath.addLine(to: path.points[i])
                            }
                            
                            context.stroke(drawingPath, with: .color(path.color), lineWidth: path.lineWidth)
                        }
                    }
                    
                    // Draw current path
                    if currentPath.points.count > 1 {
                        var drawingPath = Path()
                        drawingPath.move(to: currentPath.points[0])
                        
                        for i in 1..<currentPath.points.count {
                            drawingPath.addLine(to: currentPath.points[i])
                        }
                        
                        context.stroke(drawingPath, with: .color(currentPath.color), lineWidth: currentPath.lineWidth)
                    }
                }
                .background(Color.white)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDrawing {
                                isDrawing = true
                                currentPath = CreateNoteView.DrawingPath(
                                    points: [value.location],
                                    tool: selectedTool,
                                    color: selectedColor,
                                    lineWidth: selectedLineWidth
                                )
                            } else {
                                currentPath.points.append(value.location)
                            }
                        }
                        .onEnded { _ in
                            if isDrawing {
                                currentDrawing.paths.append(currentPath)
                                isDrawing = false
                                currentPath = CreateNoteView.DrawingPath(
                                    points: [],
                                    tool: selectedTool,
                                    color: selectedColor,
                                    lineWidth: selectedLineWidth
                                )
                            }
                        }
                )
                
                // Drawing Tools
                VStack(spacing: 15) {
                    // Tool Selection
                    HStack(spacing: 20) {
                        ForEach(CreateNoteView.DrawingTool.allCases, id: \.self) { tool in
                            Button(action: {
                                selectedTool = tool
                                AtlasTheme.Haptics.light()
                            }) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(selectedTool == tool ? AtlasTheme.Colors.accent : .gray)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(selectedTool == tool ? Color.white.opacity(0.2) : Color.clear)
                                    )
                            }
                        }
                    }
                    
                    // Color Selection
                    HStack(spacing: 15) {
                        ForEach(drawingColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                                AtlasTheme.Haptics.light()
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    
                    // Line Width Slider
                    VStack(spacing: 8) {
                        HStack {
                            Text("Line Width")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(Int(selectedLineWidth))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Slider(value: $selectedLineWidth, in: 1...20, step: 1)
                            .accentColor(AtlasTheme.Colors.accent)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
            }
            .navigationTitle("Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onCancel()
                },
                trailing: HStack {
                    Button("Clear") {
                        currentDrawing.paths.removeAll()
                        AtlasTheme.Haptics.light()
                    }
                    .disabled(currentDrawing.paths.isEmpty)
                    
                    Button("Save") {
                        onSave()
                    }
                    .disabled(currentDrawing.paths.isEmpty)
                }
            )
        }
    }
    
    private let drawingColors: [Color] = [
        .black, .red, .blue, .green, .orange, .purple, .pink, .yellow
    ]
}

// MARK: - Screenshot Picker View
struct ScreenshotPickerView: View {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Screenshot")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Choose a screenshot from your photo library")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 20, weight: .medium))
                        
                        Text("Browse Photos")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AtlasTheme.Colors.accent)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Add Screenshot")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            if let newItem = newItem {
                loadImage(from: newItem)
            }
        }
    }
    
    private func loadImage(from item: PhotosPickerItem) {
        _Concurrency.Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    onImageSelected(image)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Table Components
struct TablePreviewView: View {
    let table: CreateNoteView.NoteTable
    let onUpdateCell: (Int, Int, String) -> Void
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<table.rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<table.columns, id: \.self) { column in
                        TextField("", text: Binding(
                            get: { 
                                if row < table.cells.count && column < table.cells[row].count {
                                    return table.cells[row][column]
                                }
                                return ""
                            },
                            set: { newValue in
                                onUpdateCell(row, column, newValue)
                            }
                        ))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 40, minHeight: 30)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(2)
                    }
                }
            }
        }
        .padding(8)
    }
}

struct TableCreatorView: View {
    let onCreateTable: (Int, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRows = 3
    @State private var selectedColumns = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Create Table")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 20) {
                    // Rows Selection
                    VStack(spacing: 10) {
                        Text("Rows: \(selectedRows)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Slider(value: Binding(
                            get: { Double(selectedRows) },
                            set: { selectedRows = Int($0) }
                        ), in: 1...10, step: 1)
                        .accentColor(AtlasTheme.Colors.accent)
                    }
                    
                    // Columns Selection
                    VStack(spacing: 10) {
                        Text("Columns: \(selectedColumns)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Slider(value: Binding(
                            get: { Double(selectedColumns) },
                            set: { selectedColumns = Int($0) }
                        ), in: 1...10, step: 1)
                        .accentColor(AtlasTheme.Colors.accent)
                    }
                }
                
                // Preview
                VStack(spacing: 8) {
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TablePreview(rows: selectedRows, columns: selectedColumns)
                        .frame(height: 120)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Create Button
                Button(action: {
                    onCreateTable(selectedRows, selectedColumns)
                    dismiss()
                }) {
                    Text("Create Table")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AtlasTheme.Colors.accent)
                        .cornerRadius(12)
                }
            }
            .padding(20)
            .navigationTitle("New Table")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

struct TablePreview: View {
    let rows: Int
    let columns: Int
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<columns, id: \.self) { column in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(minWidth: 30, minHeight: 25)
                            .overlay(
                                Text("\(row + 1),\(column + 1)")
                                    .font(.system(size: 8, weight: .regular))
                                    .foregroundColor(.gray)
                            )
                    }
                }
            }
        }
        .padding(8)
    }
}

// MARK: - Preview
struct CreateNoteView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = NotesViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        return CreateNoteView(viewModel: viewModel, noteToEdit: nil)
    }
}