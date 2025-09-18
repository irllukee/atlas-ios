import SwiftUI
import UniformTypeIdentifiers

/// View for exporting notes in various formats
struct ExportNotesView: View {
    
    // MARK: - Properties
    let notes: [Note]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: ExportService.ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportResult: ExportService.ExportResult?
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Same blue gradient background as the rest of the app
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Export info
                            exportInfoView
                            
                            // Format selection
                            formatSelectionView
                            
                            // Export button
                            exportButtonView
                            
                            // Result view
                            if let result = exportResult {
                                exportResultView(result)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Export Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let result = exportResult {
                ShareSheet(items: [result.url])
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
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
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Title
            Text("Export Notes")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Share Button
            if exportResult != nil {
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            } else {
                Color.clear
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Export Info View
    private var exportInfoView: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "square.and.arrow.up.on.square")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.8))
            
            // Title and description
            VStack(spacing: 8) {
                Text("Export \(notes.count) \(notes.count == 1 ? "Note" : "Notes")")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Choose a format to export your notes for sharing or backup")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Format Selection View
    private var formatSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Format")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ExportService.ExportFormat.allCases, id: \.rawValue) { format in
                    formatCard(format)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }
    
    private func formatCard(_ format: ExportService.ExportFormat) -> some View {
        Button(action: {
            selectedFormat = format
            AtlasTheme.Haptics.light()
        }) {
            VStack(spacing: 8) {
                // Format icon
                Image(systemName: formatIcon(for: format))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(selectedFormat == format ? AtlasTheme.Colors.accent : .white.opacity(0.7))
                
                // Format name
                Text(format.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Format description
                Text(formatDescription(for: format))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedFormat == format ? AtlasTheme.Colors.accent.opacity(0.2) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedFormat == format ? AtlasTheme.Colors.accent : Color.white.opacity(0.2), lineWidth: selectedFormat == format ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatIcon(for format: ExportService.ExportFormat) -> String {
        switch format {
        case .pdf: return "doc.richtext"
        case .plainText: return "doc.plaintext"
        case .richText: return "doc.text"
        case .html: return "globe"
        case .markdown: return "text.quote"
        }
    }
    
    private func formatDescription(for format: ExportService.ExportFormat) -> String {
        switch format {
        case .pdf: return "Formatted document with layout"
        case .plainText: return "Simple text without formatting"
        case .richText: return "Rich text with basic formatting"
        case .html: return "Web page format"
        case .markdown: return "Markdown syntax"
        }
    }
    
    // MARK: - Export Button View
    private var exportButtonView: some View {
        Button(action: {
            _Concurrency.Task {
                await performExport()
            }
        }) {
            HStack(spacing: 12) {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                }
                
                Text(isExporting ? "Exporting..." : "Export Notes")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                AtlasTheme.Colors.accent,
                                AtlasTheme.Colors.accent.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: AtlasTheme.Colors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isExporting)
        .opacity(isExporting ? 0.7 : 1.0)
    }
    
    // MARK: - Export Result View
    private func exportResultView(_ result: ExportService.ExportResult) -> some View {
        VStack(spacing: 16) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.green)
            
            // Success message
            VStack(spacing: 8) {
                Text("Export Successful!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Exported to \(result.format.rawValue) format")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("File size: \(formatFileSize(result.fileSize))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // Share button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingShareSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        Text("Share")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Export another button
                Button(action: {
                    exportResult = nil
                    AtlasTheme.Haptics.light()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Export Again")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AtlasTheme.Colors.accent.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AtlasTheme.Colors.accent, lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }
    
    // MARK: - Helper Methods
    
    private func performExport() async {
        isExporting = true
        errorMessage = nil
        
        do {
            let result = try await ExportService.shared.exportNotes(notes, format: selectedFormat)
            await MainActor.run {
                exportResult = result
                AtlasTheme.Haptics.success()
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                AtlasTheme.Haptics.error()
            }
        }
        
        isExporting = false
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}


// MARK: - Preview

struct ExportNotesView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let context = dataManager.coreDataStack.viewContext
        
        // Create sample notes
        let note1 = Note(context: context)
        note1.title = "Sample Note 1"
        note1.content = "This is a sample note for testing export functionality."
        
        let note2 = Note(context: context)
        note2.title = "Sample Note 2"
        note2.content = "Another sample note with different content."
        
        return ExportNotesView(notes: [note1, note2])
    }
}
