import Foundation
import CoreData

/// Base protocol for all CoreData entities
protocol BaseEntity {
    var uuid: UUID? { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}

/// Extension to provide default implementations
extension BaseEntity {
    /// Generate a new UUID if none exists
    mutating func ensureID() {
        if uuid == nil {
            uuid = UUID()
        }
    }
    
    /// Update the updatedAt timestamp
    mutating func touch() {
        updatedAt = Date()
        if createdAt == nil {
            createdAt = Date()
        }
    }
}

/// CoreData entity extensions - only for entities that have the required properties
extension Note: BaseEntity {}
extension Task: BaseEntity {}
extension JournalEntry: BaseEntity {}

// MARK: - Entity Validation
extension BaseEntity {
    /// Validate that required fields are present
    func isValid() -> Bool {
        return uuid != nil
    }
}

// MARK: - Entity Helpers
extension Note {
    /// Create a new note with default values
    static func create(context: NSManagedObjectContext, title: String, content: String = "") -> Note {
        let note = Note(context: context)
        note.uuid = UUID()
        note.title = title
        note.content = content
        note.createdAt = Date()
        note.updatedAt = Date()
        note.isEncrypted = false
        return note
    }
    
    /// Update note content
    func update(title: String? = nil, content: String? = nil) {
        if let title = title {
            self.title = title
        }
        if let content = content {
            self.content = content
        }
        self.updatedAt = Date()
    }
}

extension Task {
    /// Create a new task with default values
    static func create(context: NSManagedObjectContext, title: String, notes: String = "") -> Task {
        let task = Task(context: context)
        task.uuid = UUID()
        task.title = title
        task.notes = notes
        task.createdAt = Date()
        task.updatedAt = Date()
        task.isCompleted = false
        task.priority = 1
        task.isRecurring = false
        return task
    }
    
    /// Mark task as completed
    func complete() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }
    
    /// Mark task as incomplete
    func uncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
    
    /// Update task details
    func update(title: String? = nil, notes: String? = nil, priority: Int16? = nil, dueDate: Date? = nil) {
        if let title = title {
            self.title = title
        }
        if let notes = notes {
            self.notes = notes
        }
        if let priority = priority {
            self.priority = priority
        }
        if let dueDate = dueDate {
            self.dueDate = dueDate
        }
        self.updatedAt = Date()
    }
}

extension JournalEntry {
    /// Create a new journal entry with default values
    static func create(context: NSManagedObjectContext, content: String, prompt: String? = nil) -> JournalEntry {
        let entry = JournalEntry(context: context)
        entry.uuid = UUID()
        entry.content = content
        entry.prompt = prompt
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.isEncrypted = false
        entry.gratitudeEntries = ""
        return entry
    }
    
    /// Update journal entry content
    func update(content: String? = nil, gratitudeEntries: String? = nil) {
        if let content = content {
            self.content = content
        }
        if let gratitudeEntries = gratitudeEntries {
            self.gratitudeEntries = gratitudeEntries
        }
        self.updatedAt = Date()
    }
}

extension MoodEntry {
    /// Create a new mood entry with default values
    static func create(context: NSManagedObjectContext, rating: Int16, emoji: String? = nil, notes: String? = nil) -> MoodEntry {
        let entry = MoodEntry(context: context)
        entry.uuid = UUID()
        entry.rating = rating
        entry.emoji = emoji
        entry.notes = notes
        entry.createdAt = Date()
        return entry
    }
    
    /// Update mood entry
    func update(rating: Int16? = nil, emoji: String? = nil, notes: String? = nil) {
        if let rating = rating {
            self.rating = rating
        }
        if let emoji = emoji {
            self.emoji = emoji
        }
        if let notes = notes {
            self.notes = notes
        }
    }
}