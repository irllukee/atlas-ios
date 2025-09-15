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
    
    // MARK: - Services
    private let notesService: NotesService
    private let dataManager: DataManager
    
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
        
        // Notes are loaded automatically through the service
        isLoading = false
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
            errorMessage = "Failed to create note"
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