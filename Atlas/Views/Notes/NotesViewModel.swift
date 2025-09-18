import Foundation
import SwiftUI
import CoreData

/// View model for Notes functionality
@MainActor
class NotesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var notes: [Note] = []
    @Published var filteredNotes: [Note] = []
    @Published var searchText: String = ""
    @Published var sortOrder: NoteSortOrder = .updatedAtDescending
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingCreateNote: Bool = false
    @Published var showingTemplates: Bool = false
    @Published var selectedNote: Note? = nil
    @Published var folders: [NoteFolder] = []
    @Published var favoriteNotes: [Note] = []
    @Published var recentNotes: [Note] = []
    
    // MARK: - Services
    private let notesService: NotesService
    private let dataManager: DataManager
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Initialization
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self.dataManager = dataManager
        self.notesService = NotesService(dataManager: dataManager, encryptionService: encryptionService)
        
        setupBindings()
        loadNotes()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Bind to notes service
        notesService.$notes
            .assign(to: &$notes)
        
        notesService.$filteredNotes
            .assign(to: &$filteredNotes)
        
        notesService.$searchText
            .assign(to: &$searchText)
        
        notesService.$sortOrder
            .assign(to: &$sortOrder)
    }
    
    // MARK: - Public Methods
    
    /// Load all notes
    func loadNotes() {
        isLoading = true
        errorMessage = nil
        
        // Load notes from the service
        notesService.loadNotes()
        
        // Set loading to false after notes are loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
        }
    }
    
    /// Create a new note
    func createNote(title: String, content: String, category: String? = nil, isEncrypted: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        let note = notesService.createNote(
            title: title,
            content: content,
            category: category,
            isEncrypted: isEncrypted
        )
        
        if note != nil {
            showingCreateNote = false
        } else {
            errorHandler.handleAppError(AppError(
                title: "Note Creation Failed",
                message: "Unable to create the note. Please try again.",
                category: .data,
                context: .noteCreation
            ))
        }
        
        isLoading = false
    }
    
    /// Create a note from template
    func createNoteFromTemplate(_ template: NoteTemplate) {
        isLoading = true
        errorMessage = nil
        
        let note = notesService.createNoteFromTemplate(template)
        
        if note != nil {
            showingTemplates = false
            showingCreateNote = false
        } else {
            errorMessage = "Failed to create note from template"
        }
        isLoading = false
    }
    
    /// Update a note
    func updateNote(_ note: Note, title: String? = nil, content: String? = nil, category: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        let success = notesService.updateNote(note, title: title, content: content, category: category)
        
        if !success {
            errorMessage = "Failed to update note"
        }
        isLoading = false
    }
    
    /// Delete a note
    func deleteNote(_ note: Note) {
        isLoading = true
        errorMessage = nil
        
        let success = notesService.deleteNote(note)
        
        if !success {
            errorMessage = "Failed to delete note"
        }
        isLoading = false
    }
    
    /// Search notes
    func searchNotes(query: String) {
        notesService.searchText = query
        notesService.filterNotes()
    }
    
    /// Change sort order
    func changeSortOrder(_ order: NoteSortOrder) {
        notesService.sortOrder = order
        notesService.filterNotes()
    }
    
    /// Clear all filters
    func clearFilters() {
        notesService.clearFilters()
    }
    
    /// Get note templates
    func getNoteTemplates() -> [NoteTemplate] {
        return notesService.getNoteTemplates()
    }
    
    /// Get statistics
    func getStatistics() -> NotesStatistics {
        return NotesStatistics(
            totalNotes: notesService.getTotalNoteCount(),
            encryptedNotes: notesService.getEncryptedNoteCount(),
            notesToday: notesService.getNotesCreatedToday().count,
            notesThisWeek: notesService.getNotesCreatedThisWeek().count
        )
    }
    
    /// Select a note for editing
    func selectNote(_ note: Note) {
        selectedNote = note
    }
    
    /// Clear selected note
    func clearSelectedNote() {
        selectedNote = nil
    }
    
    /// Get all notes (for folder count)
    var allNotes: [Note] {
        return notes
    }
    
    /// Get notes in a specific folder
    func notesInFolder(_ folder: NoteFolder) -> [Note] {
        return notes.filter { $0.folder == folder }
    }
    
    /// Toggle favorite status for a note
    func toggleFavorite(_ note: Note) {
        note.isFavorite.toggle()
        saveContext()
        loadNotes()
    }
    
    /// Create a new folder
    func createFolder(name: String, color: String = "blue") {
        let context = dataManager.coreDataStack.viewContext
        let folder = NoteFolder(context: context)
        folder.uuid = UUID()
        folder.name = name
        folder.color = color
        folder.createdAt = Date()
        folder.updatedAt = Date()
        
        saveContext()
        loadFolders()
    }
    
    /// Load folders from Core Data
    func loadFolders() {
        let request: NSFetchRequest<NoteFolder> = NoteFolder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteFolder.name, ascending: true)]
        
        do {
            folders = try dataManager.coreDataStack.viewContext.fetch(request)
        } catch {
            errorMessage = "Failed to load folders: \(error.localizedDescription)"
        }
    }
    
    /// Update favorite notes list
    func updateFavoriteNotes() {
        favoriteNotes = notes.filter { $0.isFavorite }
    }
    
    /// Update recent notes list (last 10 accessed notes)
    func updateRecentNotes() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.lastAccessedAt, ascending: false)]
        request.fetchLimit = 10
        request.predicate = NSPredicate(format: "lastAccessedAt != nil")
        
        do {
            recentNotes = try dataManager.coreDataStack.viewContext.fetch(request)
        } catch {
            errorMessage = "Failed to load recent notes: \(error.localizedDescription)"
        }
    }
    
    /// Mark a note as accessed (update lastAccessedAt)
    func markNoteAsAccessed(_ note: Note) {
        note.lastAccessedAt = Date()
        saveContext()
        updateRecentNotes()
    }
    
    /// Save Core Data context
    private func saveContext() {
        dataManager.save()
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Supporting Types

struct NotesStatistics {
    let totalNotes: Int
    let encryptedNotes: Int
    let notesToday: Int
    let notesThisWeek: Int
}