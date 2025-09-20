import SwiftUI
import UniformTypeIdentifiers

// MARK: - Export Format
enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case json = "JSON"
    case pdf = "PDF"
    case excel = "Excel"
    
    var id: String { rawValue }
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        case .pdf: return "pdf"
        case .excel: return "xlsx"
        }
    }
    
    var utType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        case .pdf: return .pdf
        case .excel: return .spreadsheet
        }
    }
}

// MARK: - Export Data Type
enum ExportDataType: String, CaseIterable, Identifiable {
    case tasks = "Tasks"
    case notes = "Notes"
    case journal = "Journal Entries"
    case mood = "Mood Data"
    case analytics = "Analytics"
    case all = "All Data"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .tasks: return "checkmark.circle.fill"
        case .notes: return "note.text"
        case .journal: return "book.fill"
        case .mood: return "face.smiling.fill"
        case .analytics: return "chart.bar.fill"
        case .all: return "square.and.arrow.down.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .tasks: return .blue
        case .notes: return .green
        case .journal: return .purple
        case .mood: return .orange
        case .analytics: return .red
        case .all: return .indigo
        }
    }
}

// MARK: - Export Configuration
struct ExportConfiguration: Equatable {
    var dataTypes: Set<ExportDataType>
    var format: ExportFormat
    var dateRange: DateInterval
    var includeMetadata: Bool
    var includeCharts: Bool
    var compressionEnabled: Bool
    
    init() {
        self.dataTypes = [.all]
        self.format = .csv
        self.dateRange = DateInterval(start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(), end: Date())
        self.includeMetadata = true
        self.includeCharts = false
        self.compressionEnabled = false
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @StateObject private var viewModel = DataExportViewModel()
    @State private var configuration = ExportConfiguration()
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Export Configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Export Configuration")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Data Types Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data Types")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(ExportDataType.allCases) { dataType in
                                    DataTypeSelectionCard(
                                        dataType: dataType,
                                        isSelected: configuration.dataTypes.contains(dataType),
                                        onToggle: {
                                            if dataType == .all {
                                                configuration.dataTypes = [.all]
                                            } else {
                                                configuration.dataTypes.remove(.all)
                                                if configuration.dataTypes.contains(dataType) {
                                                    configuration.dataTypes.remove(dataType)
                                                } else {
                                                    configuration.dataTypes.insert(dataType)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Export Format
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Format")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Picker("Format", selection: $configuration.format) {
                                ForEach(ExportFormat.allCases) { format in
                                    Text(format.rawValue).tag(format)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Date Range
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date Range")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DateRangePicker(
                                startDate: Binding(
                                    get: { configuration.dateRange.start },
                                    set: { configuration.dateRange = DateInterval(start: $0, end: configuration.dateRange.end) }
                                ),
                                endDate: Binding(
                                    get: { configuration.dateRange.end },
                                    set: { configuration.dateRange = DateInterval(start: configuration.dateRange.start, end: $0) }
                                )
                            )
                        }
                        
                        // Export Options
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Options")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 8) {
                                Toggle("Include Metadata", isOn: $configuration.includeMetadata)
                                Toggle("Include Charts", isOn: $configuration.includeCharts)
                                Toggle("Compress Export", isOn: $configuration.compressionEnabled)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Export Preview
                    if !viewModel.exportPreview.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Export Preview")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                ForEach(viewModel.exportPreview, id: \.dataType) { preview in
                                    ExportPreviewCard(preview: preview)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    
                    // Export Button
                    Button(action: {
                        isExporting = true
                        viewModel.exportData(configuration: configuration) { url in
                            DispatchQueue.main.async {
                                self.exportedFileURL = url
                                self.isExporting = false
                                self.showingShareSheet = true
                            }
                        }
                    }) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                            }
                            
                            Text(isExporting ? "Exporting..." : "Export Data")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue)
                        )
                    }
                    .disabled(isExporting)
                    .padding(.horizontal)
                    
                    // Export History
                    if !viewModel.exportHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Exports")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.exportHistory) { export in
                                    ExportHistoryRow(export: export)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Data Export")
            .onAppear {
                viewModel.loadExportPreview(configuration: configuration)
            }
            .onChange(of: configuration) { _, _ in
                viewModel.loadExportPreview(configuration: configuration)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    DataExportShareSheet(items: [url])
                }
            }
        }
    }
}

// MARK: - Data Type Selection Card
struct DataTypeSelectionCard: View {
    let dataType: ExportDataType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: dataType.icon)
                    .foregroundColor(dataType.color)
                    .font(.title3)
                
                Text(dataType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? dataType.color : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? dataType.color.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? dataType.color : .secondary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date Range Picker
struct DateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("End Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            
            // Quick date range buttons
            HStack(spacing: 8) {
                ForEach(quickDateRanges, id: \.title) { range in
                    Button(range.title) {
                        startDate = range.start
                        endDate = range.end
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.secondary.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var quickDateRanges: [(title: String, start: Date, end: Date)] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            ("Last 7 days", calendar.date(byAdding: .day, value: -7, to: now) ?? now, now),
            ("Last 30 days", calendar.date(byAdding: .day, value: -30, to: now) ?? now, now),
            ("Last 3 months", calendar.date(byAdding: .month, value: -3, to: now) ?? now, now),
            ("Last year", calendar.date(byAdding: .year, value: -1, to: now) ?? now, now)
        ]
    }
}

// MARK: - Export Preview Card
struct ExportPreviewCard: View {
    let preview: ExportPreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: preview.dataType.icon)
                    .foregroundColor(preview.dataType.color)
                    .font(.title3)
                
                Text(preview.dataType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("\(preview.recordCount) records")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Size: \(preview.estimatedSize)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Export History Row
struct ExportHistoryRow: View {
    let export: ExportHistory
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .foregroundColor(.blue)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(export.fileName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(export.format.rawValue) • \(export.recordCount) records")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(export.date, formatter: DateFormatter.shortDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(export.fileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Share Sheet
struct DataExportShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Data Models
struct ExportPreview {
    let dataType: ExportDataType
    let recordCount: Int
    let estimatedSize: String
}

struct ExportHistory: Identifiable {
    let id = UUID()
    let fileName: String
    let format: ExportFormat
    let recordCount: Int
    let fileSize: String
    let date: Date
}

// MARK: - Data Export ViewModel
@MainActor
class DataExportViewModel: ObservableObject {
    @Published var exportPreview: [ExportPreview] = []
    @Published var exportHistory: [ExportHistory] = []
    
    func loadExportPreview(configuration: ExportConfiguration) {
        // Generate preview based on configuration
        exportPreview = configuration.dataTypes.map { dataType in
            ExportPreview(
                dataType: dataType,
                recordCount: generateRecordCount(for: dataType),
                estimatedSize: generateEstimatedSize(for: dataType, format: configuration.format)
            )
        }
    }
    
    func exportData(configuration: ExportConfiguration, completion: @escaping @Sendable (URL?) -> Void) {
        // Simulate export process
        DispatchQueue.global(qos: .userInitiated).async {
            // Generate export file
            let fileName = "atlas_export_\(Date().timeIntervalSince1970).\(configuration.format.fileExtension)"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            // Create sample export data
            let exportData = self.generateExportData(configuration: configuration)
            
            do {
                try exportData.write(to: fileURL)
                
                // Add to export history
                DispatchQueue.main.async {
                    self.addToExportHistory(
                        fileName: fileName,
                        format: configuration.format,
                        recordCount: self.getTotalRecordCount(configuration: configuration),
                        fileSize: self.formatFileSize(fileURL),
                        date: Date()
                    )
                }
                
                DispatchQueue.main.async {
                    completion(fileURL)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    private func generateRecordCount(for dataType: ExportDataType) -> Int {
        switch dataType {
        case .tasks: return Int.random(in: 50...200)
        case .notes: return Int.random(in: 30...150)
        case .journal: return Int.random(in: 20...100)
        case .mood: return Int.random(in: 100...365)
        case .analytics: return Int.random(in: 10...50)
        case .all: return Int.random(in: 200...500)
        }
    }
    
    private func generateEstimatedSize(for dataType: ExportDataType, format: ExportFormat) -> String {
        let baseSize = generateRecordCount(for: dataType)
        let multiplier: Double
        
        switch format {
        case .csv: multiplier = 0.5
        case .json: multiplier = 1.0
        case .pdf: multiplier = 2.0
        case .excel: multiplier = 1.5
        }
        
        let sizeInKB = Double(baseSize) * multiplier
        return String(format: "%.1f KB", sizeInKB)
    }
    
    nonisolated private func generateExportData(configuration: ExportConfiguration) -> Data {
        // Generate sample export data based on format
        let sampleData = """
        {
            "export_date": "\(Date().ISO8601Format())",
            "data_types": \(configuration.dataTypes.map { $0.rawValue }),
            "format": "\(configuration.format.rawValue)",
            "date_range": {
                "start": "\(configuration.dateRange.start.ISO8601Format())",
                "end": "\(configuration.dateRange.end.ISO8601Format())"
            },
            "records": []
        }
        """
        
        return sampleData.data(using: .utf8) ?? Data()
    }
    
    private func getTotalRecordCount(configuration: ExportConfiguration) -> Int {
        return configuration.dataTypes.reduce(0) { total, dataType in
            total + generateRecordCount(for: dataType)
        }
    }
    
    private func formatFileSize(_ url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return "Unknown"
    }
    
    private func addToExportHistory(fileName: String, format: ExportFormat, recordCount: Int, fileSize: String, date: Date) {
        let export = ExportHistory(
            fileName: fileName,
            format: format,
            recordCount: recordCount,
            fileSize: fileSize,
            date: date
        )
        exportHistory.insert(export, at: 0)
        
        // Keep only last 10 exports
        if exportHistory.count > 10 {
            exportHistory = Array(exportHistory.prefix(10))
        }
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
struct DataExportView_Previews: PreviewProvider {
    static var previews: some View {
        DataExportView()
    }
}
