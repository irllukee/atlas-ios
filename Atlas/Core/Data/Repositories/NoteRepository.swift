import Foundation
import CoreData

/// Repository for managing Note entities
class NoteRepository: BaseRepository<Note> {
    
    // MARK: - Custom Queries
    func fetchByTitle(_ title: String) -> [Note] {
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", title)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchByContent(_ content: String) -> [Note] {
        let predicate = NSPredicate(format: "content CONTAINS[cd] %@", content)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchEncrypted() -> [Note] {
        let predicate = NSPredicate(format: "isEncrypted == YES")
        let sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchRecent(limit: Int = 10) -> [Note] {
        let request = NSFetchRequest<Note>(entityName: "Note")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch recent notes: \(error)")
            return []
        }
    }
    
    func fetchByDateRange(startDate: Date, endDate: Date) -> [Note] {
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Note.createdAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Create Operations
    func createNote(title: String, content: String, isEncrypted: Bool = false) -> Note? {
        let note = Note.create(context: context, title: title, content: content)
        note.isEncrypted = isEncrypted
        
        if save() {
            return note
        } else {
            context.delete(note)
            return nil
        }
    }
    
    // MARK: - Update Operations
    func updateNote(_ note: Note, title: String? = nil, content: String? = nil, isEncrypted: Bool? = nil) -> Bool {
        note.update(title: title, content: content)
        
        if let isEncrypted = isEncrypted {
            note.isEncrypted = isEncrypted
        }
        
        return save()
    }
    
    // MARK: - Search Operations
    func searchNotes(query: String) -> [Note] {
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let contentPredicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, contentPredicate])
        
        let sortDescriptors = [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Statistics
    func getTotalCount() -> Int {
        return count()
    }
    
    func getEncryptedCount() -> Int {
        let predicate = NSPredicate(format: "isEncrypted == YES")
        return count(predicate: predicate)
    }
    
    func getNotesCreatedToday() -> [Note] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return fetchByDateRange(startDate: today, endDate: tomorrow)
    }
    
    func getNotesCreatedThisWeek() -> [Note] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        return fetchByDateRange(startDate: startOfWeek, endDate: endOfWeek)
    }
}