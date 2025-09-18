import Foundation
import SwiftUI

/// Service for managing loading states and user feedback across the app
@MainActor
class LoadingStatesService: ObservableObject {
    static let shared = LoadingStatesService()
    
    @Published var isLoading = false
    @Published var loadingMessage = ""
    @Published var loadingProgress: Double = 0.0
    @Published var currentOperation: LoadingOperation?
    
    private var loadingOperations: [String: LoadingOperation] = [:]
    
    private init() {}
    
    // MARK: - Loading Operations
    
    func startLoading(_ operation: LoadingOperation) {
        loadingOperations[operation.id] = operation
        currentOperation = operation
        isLoading = true
        loadingMessage = operation.message
        loadingProgress = 0.0
        
        // Auto-complete after timeout if not manually completed
        DispatchQueue.main.asyncAfter(deadline: .now() + operation.timeout) {
            if self.loadingOperations[operation.id] != nil {
                self.completeLoading(operation.id)
            }
        }
    }
    
    func updateProgress(_ operationId: String, progress: Double) {
        guard var operation = loadingOperations[operationId] else { return }
        
        operation.progress = progress
        loadingOperations[operationId] = operation
        loadingProgress = progress
        
        if progress >= 1.0 {
            completeLoading(operationId)
        }
    }
    
    func completeLoading(_ operationId: String) {
        loadingOperations.removeValue(forKey: operationId)
        
        if loadingOperations.isEmpty {
            isLoading = false
            loadingMessage = ""
            loadingProgress = 0.0
            currentOperation = nil
        } else {
            // Switch to next operation
            if let nextOperation = loadingOperations.values.first {
                currentOperation = nextOperation
                loadingMessage = nextOperation.message
                loadingProgress = nextOperation.progress
            }
        }
    }
    
    func cancelLoading(_ operationId: String) {
        loadingOperations.removeValue(forKey: operationId)
        
        if loadingOperations.isEmpty {
            isLoading = false
            loadingMessage = ""
            loadingProgress = 0.0
            currentOperation = nil
        }
    }
    
    // MARK: - Convenience Methods
    
    func startNoteLoading() {
        let operation = LoadingOperation(
            id: "note-loading",
            message: "Loading notes...",
            timeout: 10.0
        )
        startLoading(operation)
    }
    
    func startNoteSaving() {
        let operation = LoadingOperation(
            id: "note-saving",
            message: "Saving note...",
            timeout: 5.0
        )
        startLoading(operation)
    }
    
    func startImageProcessing() {
        let operation = LoadingOperation(
            id: "image-processing",
            message: "Processing image...",
            timeout: 15.0
        )
        startLoading(operation)
    }
    
    func startExportOperation() {
        let operation = LoadingOperation(
            id: "export-operation",
            message: "Exporting content...",
            timeout: 30.0
        )
        startLoading(operation)
    }
    
    func startSearchOperation() {
        let operation = LoadingOperation(
            id: "search-operation",
            message: "Searching...",
            timeout: 10.0
        )
        startLoading(operation)
    }
}

// MARK: - Loading Operation Model

struct LoadingOperation: Identifiable {
    let id: String
    let message: String
    let timeout: TimeInterval
    var progress: Double = 0.0
    let startTime: Date = Date()
    
    init(id: String, message: String, timeout: TimeInterval = 10.0) {
        self.id = id
        self.message = message
        self.timeout = timeout
    }
}

// MARK: - Loading States View Modifier

struct LoadingStatesModifier: ViewModifier {
    @StateObject private var loadingService = LoadingStatesService.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if loadingService.isLoading {
                LoadingOverlay(
                    isVisible: loadingService.isLoading,
                    message: loadingService.loadingMessage
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
}

extension View {
    func withLoadingStates() -> some View {
        self.modifier(LoadingStatesModifier())
    }
}

// MARK: - Loading Overlay
// LoadingOverlay and specific loading views are defined in LoadingStates.swift
