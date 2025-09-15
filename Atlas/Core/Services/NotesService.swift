import Foundation
import CoreData
import SwiftUI

/// Comprehensive Notes service providing CRUD operations, search, and templates
@MainActor
class NotesService: ObservableObject {
    
    // MARK: - Properties
    private let noteRepository: NoteRepository
    private let encryptionService: EncryptionService
    private let dataManager: DataManager
    
    @Published var notes: [Note] = []
    @Published var filteredNotes: [Note] = []
    @Published var searchText: String = ""
    @Published var sortOrder: NoteSortOrder = .updatedAtDescending
    
    // MARK: - Initialization
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self.dataManager = dataManager
        self.encryptionService = encryptionService
        self.noteRepository = NoteRepository(context: dataManager.coreDataStack.viewContext)
        
        loadNotes()
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new note
    func createNote(title: String, content: String, category: String? = nil, isEncrypted: Bool = false) -> Note? {
        let note = noteRepository.createNote(
            title: title,
            content: content,
            isEncrypted: isEncrypted
        )
        
        loadNotes()
        return note
    }
    
    /// Update an existing note
    func updateNote(_ note: Note, title: String? = nil, content: String? = nil, category: String? = nil, isEncrypted: Bool? = nil) -> Bool {
        let success = noteRepository.updateNote(
            note,
            title: title,
            content: content,
            isEncrypted: isEncrypted
        )
        
        if success {
            loadNotes()
        }
        
        return success
    }
    
    /// Delete a note
    func deleteNote(_ note: Note) -> Bool {
        let success = noteRepository.delete(note)
        if success {
            loadNotes()
        }
        return success
    }
    
    /// Get a note by ID
    func getNote(by id: UUID) -> Note? {
        return noteRepository.fetch(by: id)
    }
    
    // MARK: - Rich Text Operations
    
    /// Create a note with rich text formatting
    func createRichTextNote(title: String, content: NSAttributedString, category: String? = nil, isEncrypted: Bool = false) -> Note? {
        let htmlContent = attributedStringToHTML(content)
        return createNote(title: title, content: htmlContent, category: category, isEncrypted: isEncrypted)
    }
    
    /// Update a note with rich text formatting
    func updateRichTextNote(_ note: Note, title: String? = nil, content: NSAttributedString? = nil, category: String? = nil) -> Bool {
        let htmlContent = content != nil ? attributedStringToHTML(content!) : nil
        return updateNote(note, title: title, content: htmlContent, category: category)
    }
    
    /// Convert NSAttributedString to HTML
    private func attributedStringToHTML(_ attributedString: NSAttributedString) -> String {
        let options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        do {
            let htmlData = try attributedString.data(from: NSRange(location: 0, length: attributedString.length), documentAttributes: options)
            return String(data: htmlData, encoding: .utf8) ?? ""
        } catch {
            print("❌ Failed to convert attributed string to HTML: \(error)")
            return attributedString.string
        }
    }
    
    /// Convert HTML to NSAttributedString
    func htmlToAttributedString(_ html: String) -> NSAttributedString {
        guard let data = html.data(using: .utf8) else {
            return NSAttributedString(string: html)
        }
        
        do {
            return try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            )
        } catch {
            print("❌ Failed to convert HTML to attributed string: \(error)")
            return NSAttributedString(string: html)
        }
    }
    
    // MARK: - Search & Filtering
    
    /// Search notes by query
    func searchNotes(query: String) -> [Note] {
        return noteRepository.searchNotes(query: query)
    }
    
    /// Filter notes based on current criteria
    func filterNotes() {
        var filtered = notes
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.title?.localizedCaseInsensitiveContains(searchText) == true ||
                note.content?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply sorting
        filtered.sort { note1, note2 in
            switch sortOrder {
            case .titleAscending:
                return (note1.title ?? "") < (note2.title ?? "")
            case .titleDescending:
                return (note1.title ?? "") > (note2.title ?? "")
            case .createdAtAscending:
                return (note1.createdAt ?? Date.distantPast) < (note2.createdAt ?? Date.distantPast)
            case .createdAtDescending:
                return (note1.createdAt ?? Date.distantPast) > (note2.createdAt ?? Date.distantPast)
            case .updatedAtAscending:
                return (note1.updatedAt ?? Date.distantPast) < (note2.updatedAt ?? Date.distantPast)
            case .updatedAtDescending:
                return (note1.updatedAt ?? Date.distantPast) > (note2.updatedAt ?? Date.distantPast)
            }
        }
        
        filteredNotes = filtered
    }
    
    /// Clear all filters
    func clearFilters() {
        searchText = ""
        sortOrder = .updatedAtDescending
        filterNotes()
    }
    
    // MARK: - Templates
    
    /// Create a note from template
    func createNoteFromTemplate(_ template: NoteTemplate) -> Note? {
        return createNote(
            title: template.title,
            content: template.content,
            category: template.category,
            isEncrypted: template.isEncrypted
        )
    }
    
    /// Get available note templates
    func getNoteTemplates() -> [NoteTemplate] {
        return NoteTemplate.allTemplates
    }
    
    // MARK: - Statistics & Analytics
    
    /// Get total note count
    func getTotalNoteCount() -> Int {
        return noteRepository.getTotalCount()
    }
    
    /// Get encrypted note count
    func getEncryptedNoteCount() -> Int {
        return noteRepository.getEncryptedCount()
    }
    
    /// Get notes created today
    func getNotesCreatedToday() -> [Note] {
        return noteRepository.getNotesCreatedToday()
    }
    
    /// Get notes created this week
    func getNotesCreatedThisWeek() -> [Note] {
        return noteRepository.getNotesCreatedThisWeek()
    }
    
    /// Get recent notes
    func getRecentNotes(limit: Int = 10) -> [Note] {
        return noteRepository.fetchRecent(limit: limit)
    }
    
    // MARK: - Encryption Support
    
    /// Encrypt a note's content
    func encryptNote(_ note: Note) -> Bool {
        guard let content = note.content else { return false }
        
        do {
            let encryptedData = try encryptionService.encrypt(content)
            // Store the encrypted data as base64 string in the content field
            note.content = encryptedData.data.base64EncodedString()
            note.isEncrypted = true
            return noteRepository.save()
        } catch {
            print("❌ Failed to encrypt note: \(error)")
            return false
        }
    }
    
    /// Decrypt a note's content
    func decryptNote(_ note: Note) -> String? {
        guard let encryptedContentString = note.content, note.isEncrypted else {
            return note.content
        }
        
        do {
            // Convert base64 string back to data
            guard let encryptedData = Data(base64Encoded: encryptedContentString) else {
                print("❌ Failed to decode base64 encrypted content")
                return nil
            }
            
            // Create EncryptedData object
            let encryptedDataObj = EncryptedData(
                data: encryptedData,
                timestamp: Date(),
                version: "1.0"
            )
            
            return try encryptionService.decryptToString(encryptedDataObj)
        } catch {
            print("❌ Failed to decrypt note: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadNotes() {
        notes = noteRepository.fetchAll()
        filterNotes()
    }
}

// MARK: - Supporting Types

enum NoteSortOrder: String, CaseIterable {
    case titleAscending = "Title (A-Z)"
    case titleDescending = "Title (Z-A)"
    case createdAtAscending = "Created (Oldest First)"
    case createdAtDescending = "Created (Newest First)"
    case updatedAtAscending = "Updated (Oldest First)"
    case updatedAtDescending = "Updated (Newest First)"
}

struct NoteTemplate {
    let title: String
    let content: String
    let category: String?
    let isEncrypted: Bool
    
    static let allTemplates: [NoteTemplate] = [
        NoteTemplate(
            title: "Meeting Notes",
            content: "## Meeting: [Topic]\n\n**Date:** [Date]\n**Attendees:** [List]\n\n### Agenda\n- [ ] Item 1\n- [ ] Item 2\n- [ ] Item 3\n\n### Action Items\n- [ ] [Action 1] - [Assignee]\n- [ ] [Action 2] - [Assignee]\n\n### Notes\n[Meeting notes here]",
            category: "Work",
            isEncrypted: false
        ),
        NoteTemplate(
            title: "Daily Journal",
            content: "## Daily Journal - [Date]\n\n### What went well today?\n[Write your thoughts]\n\n### What could be improved?\n[Write your thoughts]\n\n### Gratitude\n- [Gratitude item 1]\n- [Gratitude item 2]\n- [Gratitude item 3]\n\n### Tomorrow's Focus\n[What you want to focus on tomorrow]",
            category: "Personal",
            isEncrypted: false
        ),
        NoteTemplate(
            title: "Project Planning",
            content: "## Project: [Project Name]\n\n**Goal:** [Project goal]\n**Timeline:** [Start date] - [End date]\n\n### Tasks\n- [ ] [Task 1]\n- [ ] [Task 2]\n- [ ] [Task 3]\n\n### Resources\n- [Resource 1]\n- [Resource 2]\n\n### Notes\n[Additional notes]",
            category: "Projects",
            isEncrypted: false
        ),
        NoteTemplate(
            title: "Book Notes",
            content: "## [Book Title] - [Author]\n\n**Rating:** [X]/5\n**Date Read:** [Date]\n\n### Key Takeaways\n- [Takeaway 1]\n- [Takeaway 2]\n- [Takeaway 3]\n\n### Favorite Quotes\n> \"[Quote 1]\"\n\n> \"[Quote 2]\"\n\n### Summary\n[Book summary]\n\n### Action Items\n- [ ] [Action from book]",
            category: "Learning",
            isEncrypted: false
        ),
        NoteTemplate(
            title: "Private Note",
            content: "[Your private thoughts here]",
            category: "Private",
            isEncrypted: true
        )
    ]
}