import Foundation
import SwiftUI

/// Comprehensive error handling service for the Atlas app
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var errorHistory: [AppError] = []
    @Published var isShowingError = false
    
    private let maxErrorHistory = 50
    
    private init() {}
    
    // MARK: - Error Handling
    
    /// Handle an error with automatic categorization and user feedback
    func handle(_ error: Error, context: ErrorContext = .general) {
        let appError = AppError(from: error, context: context)
        handleAppError(appError)
    }
    
    /// Handle a custom app error
    func handleAppError(_ error: AppError) {
        currentError = error
        addToHistory(error)
        
        // Show error to user
        isShowingError = true
        
        // Log error
        logError(error)
        
        // Provide haptic feedback
        AtlasTheme.Haptics.error()
        
        // Auto-dismiss after delay for non-critical errors
        if !error.isCritical {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.dismissError()
            }
        }
    }
    
    /// Dismiss the current error
    func dismissError() {
        currentError = nil
        isShowingError = false
    }
    
    /// Clear error history
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    /// Get errors by category
    func getErrors(by category: ErrorCategory) -> [AppError] {
        return errorHistory.filter { $0.category == category }
    }
    
    /// Get recent errors (last 10)
    func getRecentErrors() -> [AppError] {
        return Array(errorHistory.prefix(10))
    }
    
    // MARK: - Private Methods
    
    private func addToHistory(_ error: AppError) {
        errorHistory.insert(error, at: 0)
        
        // Limit history size
        if errorHistory.count > maxErrorHistory {
            errorHistory = Array(errorHistory.prefix(maxErrorHistory))
        }
    }
    
    private func logError(_ error: AppError) {
        print("🚨 Error: \(error.title)")
        print("   Category: \(error.category)")
        print("   Context: \(error.context)")
        print("   Message: \(error.message)")
        if let underlyingError = error.underlyingError {
            print("   Underlying: \(underlyingError)")
        }
    }
}

// MARK: - App Error Model

struct AppError: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let category: ErrorCategory
    let context: ErrorContext
    let timestamp: Date
    let isCritical: Bool
    let underlyingError: Error?
    let recoverySuggestion: String?
    
    init(title: String, message: String, category: ErrorCategory, context: ErrorContext, isCritical: Bool = false, underlyingError: Error? = nil, recoverySuggestion: String? = nil) {
        self.title = title
        self.message = message
        self.category = category
        self.context = context
        self.timestamp = Date()
        self.isCritical = isCritical
        self.underlyingError = underlyingError
        self.recoverySuggestion = recoverySuggestion
    }
    
    init(from error: Error, context: ErrorContext) {
        self.context = context
        self.timestamp = Date()
        self.underlyingError = error
        
        // Categorize and format the error
        let coreDataError = error as NSError
        if coreDataError.domain == "NSCocoaErrorDomain" {
            self.category = .data
            self.title = "Data Error"
            self.message = coreDataError.localizedDescription
            self.isCritical = true
            self.recoverySuggestion = "Try restarting the app or contact support if the problem persists."
        } else if error is URLError {
            self.category = .network
            self.title = "Network Error"
            self.message = "Unable to connect to the network. Please check your internet connection."
            self.isCritical = false
            self.recoverySuggestion = "Check your internet connection and try again."
        } else if error is DecodingError {
            self.category = .data
            self.title = "Data Format Error"
            self.message = "Unable to process the data format."
            self.isCritical = true
            self.recoverySuggestion = "The data may be corrupted. Try restarting the app."
        } else if error is EncodingError {
            self.category = .data
            self.title = "Data Save Error"
            self.message = "Unable to save your data."
            self.isCritical = true
            self.recoverySuggestion = "Try saving again or restart the app."
        } else {
            self.category = .general
            self.title = "Unexpected Error"
            self.message = error.localizedDescription
            self.isCritical = false
            self.recoverySuggestion = "Please try again or contact support if the problem persists."
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Error Categories

enum ErrorCategory: String, CaseIterable {
    case general = "General"
    case data = "Data"
    case network = "Network"
    case authentication = "Authentication"
    case fileSystem = "File System"
    case userInterface = "User Interface"
    case performance = "Performance"
    case security = "Security"
    
    var icon: String {
        switch self {
        case .general: return "exclamationmark.triangle"
        case .data: return "internaldrive"
        case .network: return "wifi.slash"
        case .authentication: return "person.crop.circle.badge.exclamationmark"
        case .fileSystem: return "folder.badge.questionmark"
        case .userInterface: return "rectangle.and.pencil.and.ellipsis"
        case .performance: return "speedometer"
        case .security: return "lock.shield"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .orange
        case .data: return .red
        case .network: return .blue
        case .authentication: return .purple
        case .fileSystem: return .brown
        case .userInterface: return .pink
        case .performance: return .yellow
        case .security: return .green
        }
    }
}

// MARK: - Error Context

enum ErrorContext: String, CaseIterable {
    case general = "General"
    case noteCreation = "Note Creation"
    case noteEditing = "Note Editing"
    case noteDeletion = "Note Deletion"
    case dataSync = "Data Sync"
    case export = "Export"
        case `import` = "Import"
    case authentication = "Authentication"
    case fileAccess = "File Access"
    case networkRequest = "Network Request"
    case userInterface = "User Interface"
    
    var description: String {
        switch self {
        case .general: return "General application error"
        case .noteCreation: return "Error occurred while creating a note"
        case .noteEditing: return "Error occurred while editing a note"
        case .noteDeletion: return "Error occurred while deleting a note"
        case .dataSync: return "Error occurred during data synchronization"
        case .export: return "Error occurred during export operation"
        case .import: return "Error occurred during import operation"
        case .authentication: return "Error occurred during authentication"
        case .fileAccess: return "Error occurred while accessing files"
        case .networkRequest: return "Error occurred during network request"
        case .userInterface: return "Error occurred in user interface"
        }
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    @ObservedObject var errorHandler = ErrorHandler.shared
    @State private var showingDetails = false
    
    var body: some View {
        if let error = errorHandler.currentError {
            VStack(spacing: 16) {
                // Error Icon and Title
                HStack(spacing: 12) {
                    Image(systemName: error.category.icon)
                        .font(.title2)
                        .foregroundColor(error.category.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(error.message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        errorHandler.dismissError()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                
                // Recovery Suggestion
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Details Button
                Button(action: {
                    showingDetails.toggle()
                }) {
                    HStack {
                        Text("Details")
                        Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                // Error Details
                if showingDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(title: "Category", value: error.category.rawValue)
                        DetailRow(title: "Context", value: error.context.description)
                        DetailRow(title: "Time", value: error.timestamp.formatted(date: .omitted, time: .shortened))
                        
                        if let underlyingError = error.underlyingError {
                            DetailRow(title: "Underlying Error", value: underlyingError.localizedDescription)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(error.category.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Error Handling View Modifier

struct ErrorHandlingModifier: ViewModifier {
    @StateObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                if errorHandler.isShowingError {
                    ErrorAlertView()
                        .animation(.easeInOut(duration: 0.3), value: errorHandler.isShowingError)
                }
                
                Spacer()
            }
        }
    }
}

extension View {
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlingModifier())
    }
}
