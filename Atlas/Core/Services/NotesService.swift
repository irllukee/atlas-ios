import Foundation
import CoreData
import SwiftUI

/// Service for managing notes, folders, and tags
@MainActor
final class NotesService: ObservableObject {
    static let shared = NotesService()
    
    // MARK: - Published Properties
    @Published var notes: [Note] = []
    @Published var folders: [NoteFolder] = []
    @Published var tags: [NoteTag] = []
    @Published var isLoading = false
    @Published var searchText = "" {
        didSet {
            invalidateFilteredCache()
        }
    }
    @Published var selectedFolder: NoteFolder? {
        didSet {
            invalidateFilteredCache()
        }
    }
    @Published var selectedTag: NoteTag? {
        didSet {
            invalidateFilteredCache()
        }
    }
    
    // MARK: - Core Data
    private let context: NSManagedObjectContext
    private let coreDataStack: CoreDataStack
    
    // MARK: - Caching
    private var _filteredNotes: [Note]?
    private var filteredCacheValid = false
    
    // MARK: - Auto-save (using consolidated service)
    private let autoSaveService = AutoSaveService.shared
    
    // MARK: - Background Processing
    private let backgroundQueue = DispatchQueue(label: "com.atlas.notes.processing", qos: .userInitiated)
    
    // MARK: - Initialization
    private init() {
        self.coreDataStack = CoreDataStack.shared
        self.context = coreDataStack.viewContext
        
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        
        // Load notes with prefetching for relationships
        let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        notesRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)
        ]
        notesRequest.relationshipKeyPathsForPrefetching = ["folder", "tags"]
        
        do {
            notes = try context.fetch(notesRequest)
            // Precompute display properties on background queue
            precomputeDisplayProperties()
        } catch {
            print("❌ Failed to load notes: \(error)")
            handleError(error, context: "loading notes")
        }
        
        // Load folders
        let foldersRequest: NSFetchRequest<NoteFolder> = NoteFolder.fetchRequest()
        foldersRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \NoteFolder.name, ascending: true)
        ]
        
        do {
            folders = try context.fetch(foldersRequest)
        } catch {
            print("❌ Failed to load folders: \(error)")
            handleError(error, context: "loading folders")
        }
        
        // Load tags
        let tagsRequest: NSFetchRequest<NoteTag> = NoteTag.fetchRequest()
        tagsRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \NoteTag.name, ascending: true)
        ]
        
        do {
            tags = try context.fetch(tagsRequest)
        } catch {
            print("❌ Failed to load tags: \(error)")
            handleError(error, context: "loading tags")
        }
        
        invalidateFilteredCache()
        isLoading = false
    }
    
    // MARK: - Note Operations
    func createNote(title: String = "", content: String = "", folder: NoteFolder? = nil) -> Note {
        let note = Note(context: context)
        note.uuid = UUID()
        note.title = title.isEmpty ? "Untitled Note" : title
        note.content = content
        note.createdAt = Date()
        note.updatedAt = Date()
        note.isEncrypted = false
        note.isFavorite = false
        note.lastAccessedAt = Date()
        note.folder = folder
        
        do {
            try context.save()
            // Add to local array instead of reloading all data
            notes.insert(note, at: 0)
            invalidateFilteredCache()
        } catch {
            print("❌ Failed to create note: \(error)")
            handleError(error, context: "creating note")
        }
        
        return note
    }
    
    func updateNote(_ note: Note, title: String? = nil, content: String? = nil) {
        if let title = title {
            note.title = title
        }
        if let content = content {
            note.content = content
        }
        note.updatedAt = Date()
        note.lastAccessedAt = Date()
        
        do {
            try context.save()
            invalidateFilteredCache()
        } catch {
            print("❌ Failed to update note: \(error)")
            handleError(error, context: "updating note")
        }
    }
    
    func deleteNote(_ note: Note) {
        context.delete(note)
        do {
            try context.save()
            // Remove from local array instead of reloading all data
            notes.removeAll { $0.uuid == note.uuid }
            invalidateFilteredCache()
        } catch {
            print("❌ Failed to delete note: \(error)")
            handleError(error, context: "deleting note")
        }
    }
    
    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        note.updatedAt = Date()
        do {
            try context.save()
            invalidateFilteredCache()
        } catch {
            print("❌ Failed to toggle favorite: \(error)")
            handleError(error, context: "toggling favorite")
        }
    }
    
    // MARK: - Folder Operations
    func createFolder(name: String, color: String = "#007AFF") -> NoteFolder {
        let folder = NoteFolder(context: context)
        folder.uuid = UUID()
        folder.name = name
        folder.color = color
        folder.createdAt = Date()
        folder.updatedAt = Date()
        
        do {
            try context.save()
            // Add to local array instead of reloading all data
            folders.append(folder)
            folders.sort { ($0.name ?? "") < ($1.name ?? "") }
        } catch {
            print("❌ Failed to create folder: \(error)")
            handleError(error, context: "creating folder")
        }
        
        return folder
    }
    
    func updateFolder(_ folder: NoteFolder, name: String? = nil, color: String? = nil) {
        if let name = name {
            folder.name = name
        }
        if let color = color {
            folder.color = color
        }
        folder.updatedAt = Date()
        
        do {
            try context.save()
            // Re-sort folders after update
            folders.sort { ($0.name ?? "") < ($1.name ?? "") }
        } catch {
            print("❌ Failed to update folder: \(error)")
            handleError(error, context: "updating folder")
        }
    }
    
    func deleteFolder(_ folder: NoteFolder) {
        // Move notes to no folder
        for note in folder.notes?.allObjects as? [Note] ?? [] {
            note.folder = nil
        }
        
        context.delete(folder)
        do {
            try context.save()
            // Remove from local array instead of reloading all data
            folders.removeAll { $0.uuid == folder.uuid }
        } catch {
            print("❌ Failed to delete folder: \(error)")
            handleError(error, context: "deleting folder")
        }
    }
    
    // MARK: - Tag Operations
    func createTag(name: String, color: String = "#FF9500") -> NoteTag {
        let tag = NoteTag(context: context)
        tag.uuid = UUID()
        tag.name = name
        tag.color = color
        tag.createdAt = Date()
        tag.updatedAt = Date()
        
        do {
            try context.save()
            // Add to local array instead of reloading all data
            tags.append(tag)
            tags.sort { ($0.name ?? "") < ($1.name ?? "") }
        } catch {
            print("❌ Failed to create tag: \(error)")
            handleError(error, context: "creating tag")
        }
        
        return tag
    }
    
    func updateTag(_ tag: NoteTag, name: String? = nil, color: String? = nil) {
        if let name = name {
            tag.name = name
        }
        if let color = color {
            tag.color = color
        }
        tag.updatedAt = Date()
        
        do {
            try context.save()
            // Re-sort tags after update
            tags.sort { ($0.name ?? "") < ($1.name ?? "") }
        } catch {
            print("❌ Failed to update tag: \(error)")
            handleError(error, context: "updating tag")
        }
    }
    
    func deleteTag(_ tag: NoteTag) {
        context.delete(tag)
        do {
            try context.save()
            // Remove from local array instead of reloading all data
            tags.removeAll { $0.uuid == tag.uuid }
        } catch {
            print("❌ Failed to delete tag: \(error)")
            handleError(error, context: "deleting tag")
        }
    }
    
    func addTagToNote(_ note: Note, tag: NoteTag) {
        note.addToTags(tag)
        note.updatedAt = Date()
        do {
            try context.save()
            invalidateFilteredCache()
        } catch {
            print("❌ Failed to add tag to note: \(error)")
            handleError(error, context: "adding tag to note")
        }
    }
    
    func removeTagFromNote(_ note: Note, tag: NoteTag) {
        note.removeFromTags(tag)
        note.updatedAt = Date()
        do {
            try context.save()
            invalidateFilteredCache()
        } catch {
            print("❌ Failed to remove tag from note: \(error)")
            handleError(error, context: "removing tag from note")
        }
    }
    
    // MARK: - Search and Filtering
    var filteredNotes: [Note] {
        if !filteredCacheValid || _filteredNotes == nil {
            _filteredNotes = computeFilteredNotes()
            filteredCacheValid = true
        }
        return _filteredNotes ?? []
    }
    
    private func computeFilteredNotes() -> [Note] {
        var filtered = notes
        
        // Filter by folder
        if let selectedFolder = selectedFolder {
            filtered = filtered.filter { $0.folder == selectedFolder }
        }
        
        // Filter by tag
        if let selectedTag = selectedTag {
            filtered = filtered.filter { note in
                note.tags?.contains(selectedTag) == true
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                (note.title?.localizedCaseInsensitiveContains(searchText) == true) ||
                (note.content?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        
        return filtered
    }
    
    private func invalidateFilteredCache() {
        filteredCacheValid = false
        _filteredNotes = nil
    }
    
    var favoriteNotes: [Note] {
        return notes.filter { $0.isFavorite }
    }
    
    var recentNotes: [Note] {
        return Array(notes.prefix(10))
    }
    
    // MARK: - Auto-save (using consolidated AutoSaveService)
    // Auto-save functionality is now handled by AutoSaveService.shared
    // Use autoSaveService.saveNoteChange() or autoSaveService.registerChange() for auto-save
    
    // MARK: - Context Management
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ Failed to save context: \(error)")
            handleError(error, context: "saving context")
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error, context: String) {
        // Log error for debugging
        print("❌ Error in \(context): \(error)")
        
        // In a production app, you might want to:
        // 1. Show user-facing error messages
        // 2. Report to crash analytics
        // 3. Implement retry logic
        // 4. Rollback changes if needed
    }
    
    // MARK: - Background Processing
    private func precomputeDisplayProperties() {
        // Process notes synchronously on main thread to avoid Sendable issues
        for note in notes {
            // Precompute plain text titles and previews
            if let title = note.title, !title.isEmpty {
                let cleanTitle = stripHTML(from: title)
                if cleanTitle != title {
                    note.title = cleanTitle
                }
            }
            
            // Precompute plain text content for search
            if let content = note.content, !content.isEmpty {
                let plainText = stripHTML(from: content)
                // Store in a computed property or cache if needed
                _ = plainText // Use the value to avoid warning
            }
        }
    }
    
    private func stripHTML(from html: String) -> String {
        // Remove DOCTYPE and HTML tags
        let cleanHTML = html
            .replacingOccurrences(of: "<!DOCTYPE[^>]*>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
        
        return cleanHTML
    }
    
    // MARK: - Statistics
    func getNotesStatistics() -> NotesStatistics {
        return NotesStatistics(
            totalNotes: notes.count,
            favoriteNotes: favoriteNotes.count,
            notesInFolders: notes.filter { $0.folder != nil }.count,
            totalFolders: folders.count,
            totalTags: tags.count,
            notesCreatedToday: notes.filter { Calendar.current.isDateInToday($0.createdAt ?? Date.distantPast) }.count
        )
    }
    
    // MARK: - Cleanup
    // No cleanup needed - AutoSaveService handles its own timer cleanup
}

// MARK: - Notes Statistics
struct NotesStatistics {
    let totalNotes: Int
    let favoriteNotes: Int
    let notesInFolders: Int
    let totalFolders: Int
    let totalTags: Int
    let notesCreatedToday: Int
}
