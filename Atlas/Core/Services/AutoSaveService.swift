import Foundation
import CoreData
import SwiftUI

/// Service for automatic saving of notes and other content
@MainActor
class AutoSaveService: ObservableObject {
    static let shared = AutoSaveService()
    
    @Published var isAutoSaving = false
    @Published var lastSaveTime: Date?
    @Published var saveStatus: SaveStatus = .idle
    
    private let dataManager = DataManager.shared
    private var saveTimer: Timer?
    private var pendingChanges: [String: Any] = [:]
    private let saveInterval: TimeInterval = 2.0 // Auto-save every 2 seconds
    
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
    
    deinit {
        // Timer cleanup is handled by the timer itself when it's invalidated
        // No need to access saveTimer from deinit due to concurrency safety
    }
    
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
    
    /// Perform automatic save of pending changes
    private func performAutoSave() async {
        guard !pendingChanges.isEmpty else { return }
        
        isAutoSaving = true
        saveStatus = .saving
        
        do {
            try await savePendingChanges()
            saveStatus = .saved
            lastSaveTime = Date()
            pendingChanges.removeAll()
        } catch {
            saveStatus = .error(error.localizedDescription)
            print("Auto-save failed: \(error)")
        }
        
        isAutoSaving = false
    }
    
    /// Save pending changes to Core Data
    private func savePendingChanges() async throws {
        let context = dataManager.coreDataStack.viewContext
        
        for (entityId, changes) in pendingChanges {
            if let noteChanges = changes as? [String: Any] {
                try await saveNoteChanges(entityId: entityId, changes: noteChanges, context: context)
            }
        }
        
        try context.save()
    }
    
    /// Save changes for a specific note
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
    
    // MARK: - Public Methods
    
    /// Register a change for auto-save
    func registerChange<T>(for entityId: String, key: String, value: T) {
        if pendingChanges[entityId] == nil {
            pendingChanges[entityId] = [String: Any]()
        }
        
        if var entityChanges = pendingChanges[entityId] as? [String: Any] {
            entityChanges[key] = value
            pendingChanges[entityId] = entityChanges
        }
    }
    
    /// Register multiple changes for auto-save
    func registerChanges(for entityId: String, changes: [String: Any]) {
        if pendingChanges[entityId] == nil {
            pendingChanges[entityId] = [String: Any]()
        }
        
        if var entityChanges = pendingChanges[entityId] as? [String: Any] {
            for (key, value) in changes {
                entityChanges[key] = value
            }
            pendingChanges[entityId] = entityChanges
        }
    }
    
    /// Force save all pending changes immediately
    func forceSave() async {
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
