import Foundation
import CoreData
import SwiftUI

/// Optimized service for automatic saving of notes and other content
/// Consolidates all auto-save functionality to prevent conflicts and improve performance
@MainActor
class AutoSaveService: ObservableObject {
    static let shared = AutoSaveService()
    
    @Published var isAutoSaving = false
    @Published var lastSaveTime: Date?
    @Published var saveStatus: SaveStatus = .idle
    
    private let dataManager = DataManager.shared
    private var saveTimer: Timer?
    private var debounceTimer: Timer?
    private var pendingChanges: [String: Any] = [:]
    
    // Optimized timing intervals
    private let saveInterval: TimeInterval = 3.0 // Increased from 5.0 to 3.0 for better UX
    private let debounceInterval: TimeInterval = 0.5 // Increased from immediate to 500ms
    private let maxBatchSize = 15 // Increased batch size for efficiency
    private let maxPendingChanges = 50 // Prevent memory buildup
    
    enum SaveStatus: Equatable {
        case idle
        case saving
        case saved
        case error(String)
        
        static func == (lhs: SaveStatus, rhs: SaveStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.saving, .saving), (.saved, .saved):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    private init() {
        startAutoSaveTimer()
    }
    
    // Note: Timer cleanup is handled by the timers themselves when invalidated
    // No deinit needed due to main actor isolation constraints
    
    // MARK: - Auto-Save Management
    
    /// Start the auto-save timer
    private func startAutoSaveTimer() {
        saveTimer = Timer.scheduledTimer(withTimeInterval: saveInterval, repeats: true) { [weak self] _ in
            _Concurrency.Task {
                await self?.performAutoSave()
            }
        }
    }
    
    /// Stop the auto-save timer
    private func stopAutoSaveTimer() {
        saveTimer?.invalidate()
        saveTimer = nil
    }
    
    /// Stop all timers to prevent memory leaks
    private func stopAllTimers() {
        saveTimer?.invalidate()
        saveTimer = nil
        debounceTimer?.invalidate()
        debounceTimer = nil
    }
    
    /// Perform automatic save of pending changes with background processing
    private func performAutoSave() async {
        guard !pendingChanges.isEmpty else { return }
        
        // Don't start new save if already saving
        guard !isAutoSaving else { return }
        
        isAutoSaving = true
        saveStatus = .saving
        
        do {
            // Use background context for better performance
            try await savePendingChangesInBackground()
            saveStatus = .saved
            lastSaveTime = Date()
            pendingChanges.removeAll()
        } catch {
            saveStatus = .error(error.localizedDescription)
            print("Auto-save failed: \(error)")
        }
        
        isAutoSaving = false
    }
    
    /// Save pending changes to Core Data using background context
    private func savePendingChangesInBackground() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            dataManager.coreDataStack.performBackgroundTask { backgroundContext in
                do {
                    // Limit batch size for better performance
                    let changesToProcess = Array(self.pendingChanges.prefix(self.maxBatchSize))
                    
                    for (entityId, changes) in changesToProcess {
                        if let noteChanges = changes as? [String: Any] {
                            try self.saveNoteChangesSync(entityId: entityId, changes: noteChanges, context: backgroundContext)
                        }
                    }
                    
                    try backgroundContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Save pending changes to Core Data (legacy method for compatibility)
    private func savePendingChanges() async throws {
        let context = dataManager.coreDataStack.viewContext
        
        for (entityId, changes) in pendingChanges {
            if let noteChanges = changes as? [String: Any] {
                try await saveNoteChanges(entityId: entityId, changes: noteChanges, context: context)
            }
        }
        
        try context.save()
    }
    
    /// Save changes for a specific note (async version)
    private func saveNoteChanges(entityId: String, changes: [String: Any], context: NSManagedObjectContext) async throws {
        guard let noteId = UUID(uuidString: entityId) else { return }
        
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", noteId as CVarArg)
        
        let notes = try context.fetch(request)
        guard let note = notes.first else { return }
        
        // Apply changes
        if let title = changes["title"] as? String {
            note.title = title
        }
        if let content = changes["content"] as? String {
            note.content = content
        }
        if let isEncrypted = changes["isEncrypted"] as? Bool {
            note.isEncrypted = isEncrypted
        }
        if let isFavorite = changes["isFavorite"] as? Bool {
            note.isFavorite = isFavorite
        }
        
        note.updatedAt = Date()
    }
    
    /// Save changes for a specific note (sync version for background context)
    private func saveNoteChangesSync(entityId: String, changes: [String: Any], context: NSManagedObjectContext) throws {
        guard let noteId = UUID(uuidString: entityId) else { return }
        
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", noteId as CVarArg)
        
        let notes = try context.fetch(request)
        guard let note = notes.first else { return }
        
        // Apply changes
        if let title = changes["title"] as? String {
            note.title = title
        }
        if let content = changes["content"] as? String {
            note.content = content
        }
        if let isEncrypted = changes["isEncrypted"] as? Bool {
            note.isEncrypted = isEncrypted
        }
        if let isFavorite = changes["isFavorite"] as? Bool {
            note.isFavorite = isFavorite
        }
        
        note.updatedAt = Date()
    }
    
    // MARK: - Public Methods
    
    /// Register a change for auto-save with debouncing
    func registerChange<T>(for entityId: String, key: String, value: T) {
        // Prevent memory buildup by limiting pending changes
        if pendingChanges.count > maxPendingChanges {
            // Remove oldest changes if we exceed the limit
            let keysToRemove = Array(pendingChanges.keys.prefix(pendingChanges.count - maxPendingChanges + 10))
            keysToRemove.forEach { pendingChanges.removeValue(forKey: $0) }
        }
        
        if pendingChanges[entityId] == nil {
            pendingChanges[entityId] = [String: Any]()
        }
        
        if var entityChanges = pendingChanges[entityId] as? [String: Any] {
            entityChanges[key] = value
            pendingChanges[entityId] = entityChanges
            
            // Schedule debounced save
            scheduleDebouncedSave()
        }
    }
    
    /// Schedule a debounced save operation
    private func scheduleDebouncedSave() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            _Concurrency.Task {
                await self?.performAutoSave()
            }
        }
    }
    
    /// Register multiple changes for auto-save with debouncing
    func registerChanges(for entityId: String, changes: [String: Any]) {
        // Prevent memory buildup by limiting pending changes
        if pendingChanges.count > maxPendingChanges {
            // Remove oldest changes if we exceed the limit
            let keysToRemove = Array(pendingChanges.keys.prefix(pendingChanges.count - maxPendingChanges + 10))
            keysToRemove.forEach { pendingChanges.removeValue(forKey: $0) }
        }
        
        if pendingChanges[entityId] == nil {
            pendingChanges[entityId] = [String: Any]()
        }
        
        if var entityChanges = pendingChanges[entityId] as? [String: Any] {
            for (key, value) in changes {
                entityChanges[key] = value
            }
            pendingChanges[entityId] = entityChanges
            
            // Schedule debounced save
            scheduleDebouncedSave()
        }
    }
    
    /// Force save all pending changes immediately
    func forceSave() async {
        // Cancel any pending debounced save
        debounceTimer?.invalidate()
        debounceTimer = nil
        
        await performAutoSave()
    }
    
    /// Clear pending changes for a specific entity
    func clearPendingChanges(for entityId: String) {
        pendingChanges.removeValue(forKey: entityId)
    }
    
    /// Clear all pending changes
    func clearAllPendingChanges() {
        pendingChanges.removeAll()
    }
    
    /// Get the number of pending changes
    var pendingChangesCount: Int {
        return pendingChanges.count
    }
    
    /// Check if there are pending changes for a specific entity
    func hasPendingChanges(for entityId: String) -> Bool {
        return pendingChanges[entityId] != nil
    }
    
    /// Get save status message
    var saveStatusMessage: String {
        switch saveStatus {
        case .idle:
            return "Ready"
        case .saving:
            return "Saving..."
        case .saved:
            if let lastSave = lastSaveTime {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                return "Saved \(formatter.localizedString(for: lastSave, relativeTo: Date()))"
            }
            return "Saved"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    /// Get save status color
    var saveStatusColor: Color {
        switch saveStatus {
        case .idle:
            return .gray
        case .saving:
            return .blue
        case .saved:
            return .green
        case .error:
            return .red
        }
    }
    
    /// Cleanup method to be called when the service is no longer needed
    func cleanup() {
        stopAllTimers()
    }
}

// MARK: - Auto-Save View Modifier

struct AutoSaveModifier: ViewModifier {
    let entityId: String
    @StateObject private var autoSaveService = AutoSaveService.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: autoSaveService.saveStatus) { _, newStatus in
                // Handle save status changes if needed
            }
    }
}

extension View {
    func autoSave(for entityId: String) -> some View {
        self.modifier(AutoSaveModifier(entityId: entityId))
    }
}

// MARK: - Convenience Methods for Common Use Cases

extension AutoSaveService {
    /// Convenience method for saving note changes
    func saveNoteChange(noteId: UUID, title: String? = nil, content: String? = nil, isEncrypted: Bool? = nil, isFavorite: Bool? = nil) {
        let entityId = noteId.uuidString
        var changes: [String: Any] = [:]
        
        if let title = title { changes["title"] = title }
        if let content = content { changes["content"] = content }
        if let isEncrypted = isEncrypted { changes["isEncrypted"] = isEncrypted }
        if let isFavorite = isFavorite { changes["isFavorite"] = isFavorite }
        
        registerChanges(for: entityId, changes: changes)
    }
    
    /// Convenience method for saving journal entry changes
    func saveJournalEntryChange(entryId: UUID, title: String? = nil, content: String? = nil, type: String? = nil, isEncrypted: Bool? = nil) {
        let entityId = entryId.uuidString
        var changes: [String: Any] = [:]
        
        if let title = title { changes["title"] = title }
        if let content = content { changes["content"] = content }
        if let type = type { changes["type"] = type }
        if let isEncrypted = isEncrypted { changes["isEncrypted"] = isEncrypted }
        
        registerChanges(for: entityId, changes: changes)
    }
}
