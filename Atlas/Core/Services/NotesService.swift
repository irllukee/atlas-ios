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
    @Published var searchText = ""
    @Published var selectedFolder: NoteFolder?
    @Published var selectedTag: NoteTag?
    
    // MARK: - Core Data
    private let context: NSManagedObjectContext
    private let coreDataStack: CoreDataStack
    
    // MARK: - Auto-save
    private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 2.0
    
    // MARK: - Initialization
    private init() {
        self.coreDataStack = CoreDataStack.shared
        self.context = coreDataStack.viewContext
        
        setupAutoSave()
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        isLoading = true
        
        // Load notes
        let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        notesRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)
        ]
        
        do {
            notes = try context.fetch(notesRequest)
        } catch {
            print("❌ Failed to load notes: \(error)")
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
        }
        
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
        
        saveContext()
        loadData()
        
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
        
        saveContext()
    }
    
    func deleteNote(_ note: Note) {
        context.delete(note)
        saveContext()
        loadData()
    }
    
    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        note.updatedAt = Date()
        saveContext()
        loadData()
    }
    
    // MARK: - Folder Operations
    func createFolder(name: String, color: String = "#007AFF") -> NoteFolder {
        let folder = NoteFolder(context: context)
        folder.uuid = UUID()
        folder.name = name
        folder.color = color
        folder.createdAt = Date()
        folder.updatedAt = Date()
        
        saveContext()
        loadData()
        
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
        
        saveContext()
        loadData()
    }
    
    func deleteFolder(_ folder: NoteFolder) {
        // Move notes to no folder
        for note in folder.notes?.allObjects as? [Note] ?? [] {
            note.folder = nil
        }
        
        context.delete(folder)
        saveContext()
        loadData()
    }
    
    // MARK: - Tag Operations
    func createTag(name: String, color: String = "#FF9500") -> NoteTag {
        let tag = NoteTag(context: context)
        tag.uuid = UUID()
        tag.name = name
        tag.color = color
        tag.createdAt = Date()
        tag.updatedAt = Date()
        
        saveContext()
        loadData()
        
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
        
        saveContext()
        loadData()
    }
    
    func deleteTag(_ tag: NoteTag) {
        context.delete(tag)
        saveContext()
        loadData()
    }
    
    func addTagToNote(_ note: Note, tag: NoteTag) {
        note.addToTags(tag)
        note.updatedAt = Date()
        saveContext()
        loadData()
    }
    
    func removeTagFromNote(_ note: Note, tag: NoteTag) {
        note.removeFromTags(tag)
        note.updatedAt = Date()
        saveContext()
        loadData()
    }
    
    // MARK: - Search and Filtering
    var filteredNotes: [Note] {
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
    
    var favoriteNotes: [Note] {
        return notes.filter { $0.isFavorite }
    }
    
    var recentNotes: [Note] {
        return Array(notes.prefix(10))
    }
    
    // MARK: - Auto-save
    private func setupAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.performAutoSave()
            }
        }
    }
    
    private func performAutoSave() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("❌ Auto-save failed: \(error)")
        }
    }
    
    // MARK: - Context Management
    func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ Failed to save context: \(error)")
        }
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
    deinit {
        DispatchQueue.main.async { [weak self] in
            self?.autoSaveTimer?.invalidate()
        }
    }
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
