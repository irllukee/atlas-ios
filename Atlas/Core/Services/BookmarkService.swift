import Foundation
import CoreData
import SwiftUI

/// Service for managing bookmarks within notes
@MainActor
class BookmarkService: ObservableObject {
    static let shared = BookmarkService()
    
    @Published var bookmarks: [NoteBookmark] = []
    
    private let dataManager = DataManager.shared
    
    private init() {}
    
    // MARK: - Bookmark Management
    
    /// Create a new bookmark at the specified position in a note
    func createBookmark(in note: Note, name: String, position: Int32) {
        let context = dataManager.coreDataStack.viewContext
        
        let bookmark = NoteBookmark(context: context)
        bookmark.uuid = UUID()
        bookmark.name = name
        bookmark.position = position
        bookmark.createdAt = Date()
        bookmark.updatedAt = Date()
        bookmark.note = note
        
        do {
            try context.save()
            loadBookmarks(for: note)
            AtlasTheme.Haptics.success()
        } catch {
            print("Failed to create bookmark: \(error)")
            AtlasTheme.Haptics.error()
        }
    }
    
    /// Update an existing bookmark
    func updateBookmark(_ bookmark: NoteBookmark, name: String? = nil, position: Int32? = nil) {
        let context = dataManager.coreDataStack.viewContext
        
        if let name = name {
            bookmark.name = name
        }
        if let position = position {
            bookmark.position = position
        }
        bookmark.updatedAt = Date()
        
        do {
            try context.save()
            AtlasTheme.Haptics.success()
        } catch {
            print("Failed to update bookmark: \(error)")
            AtlasTheme.Haptics.error()
        }
    }
    
    /// Delete a bookmark
    func deleteBookmark(_ bookmark: NoteBookmark) {
        let context = dataManager.coreDataStack.viewContext
        context.delete(bookmark)
        
        do {
            try context.save()
            if let note = bookmark.note {
                loadBookmarks(for: note)
            }
            AtlasTheme.Haptics.success()
        } catch {
            print("Failed to delete bookmark: \(error)")
            AtlasTheme.Haptics.error()
        }
    }
    
    /// Load bookmarks for a specific note
    func loadBookmarks(for note: Note) {
        let context = dataManager.coreDataStack.viewContext
        let request: NSFetchRequest<NoteBookmark> = NoteBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "note == %@", note)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NoteBookmark.position, ascending: true)]
        
        do {
            bookmarks = try context.fetch(request)
        } catch {
            print("Failed to load bookmarks: \(error)")
            bookmarks = []
        }
    }
    
    /// Get bookmark at a specific position
    func getBookmark(at position: Int32, in note: Note) -> NoteBookmark? {
        return bookmarks.first { $0.position == position && $0.note == note }
    }
    
    /// Move to a bookmark position in the note content
    func jumpToBookmark(_ bookmark: NoteBookmark) {
        // This will be handled by the CreateNoteView to scroll to the position
        AtlasTheme.Haptics.light()
    }
    
    /// Get all bookmarks for a note sorted by position
    func getBookmarks(for note: Note) -> [NoteBookmark] {
        return bookmarks.filter { $0.note == note }.sorted { $0.position < $1.position }
    }
    
    /// Check if a position already has a bookmark
    func hasBookmark(at position: Int32, in note: Note) -> Bool {
        return bookmarks.contains { $0.position == position && $0.note == note }
    }
    
    /// Get the next bookmark after a given position
    func getNextBookmark(after position: Int32, in note: Note) -> NoteBookmark? {
        let noteBookmarks = getBookmarks(for: note)
        return noteBookmarks.first { $0.position > position }
    }
    
    /// Get the previous bookmark before a given position
    func getPreviousBookmark(before position: Int32, in note: Note) -> NoteBookmark? {
        let noteBookmarks = getBookmarks(for: note)
        return noteBookmarks.last { $0.position < position }
    }
}
