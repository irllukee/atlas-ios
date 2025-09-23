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
extension Task: BaseEntity {
    var uuid: UUID? {
        get { id }
        set { if let newValue = newValue { id = newValue } }
    }
}
extension JournalEntry: BaseEntity {}
extension Node: BaseEntity {}

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
        task.priority = TaskPriority.medium.rawValue
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
            self.priority = String(priority)
        }
        if let dueDate = dueDate {
            self.dueDate = dueDate
        }
        self.updatedAt = Date()
    }
}

extension JournalEntry {
    /// Create a new journal entry with default values
    static func create(context: NSManagedObjectContext, content: String, title: String? = nil, type: String = "daily") -> JournalEntry {
        let entry = JournalEntry(context: context)
        entry.uuid = UUID()
        entry.content = content
        entry.title = title
        entry.type = type
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.isEncrypted = false
        entry.wordCount = Int32(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        entry.readingTime = Int32(max(1, entry.wordCount / 200)) // Assume 200 words per minute
        return entry
    }
    
    /// Update journal entry content
    func update(content: String? = nil, title: String? = nil) {
        if let content = content {
            self.content = content
            self.wordCount = Int32(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
            self.readingTime = Int32(max(1, self.wordCount / 200))
        }
        if let title = title {
            self.title = title
        }
        self.updatedAt = Date()
    }
}

extension MoodEntry {
    /// Create a new mood entry with default values
    static func create(context: NSManagedObjectContext, moodLevel: Int16, scale: String = "5-point", emoji: String? = nil, notes: String? = nil) -> MoodEntry {
        let entry = MoodEntry(context: context)
        entry.uuid = UUID()
        entry.moodLevel = moodLevel
        entry.scale = scale
        entry.emoji = emoji
        entry.notes = notes
        entry.createdAt = Date()
        entry.updatedAt = Date()
        return entry
    }
    
    /// Update mood entry
    func update(moodLevel: Int16? = nil, scale: String? = nil, emoji: String? = nil, notes: String? = nil) {
        if let moodLevel = moodLevel {
            self.moodLevel = moodLevel
        }
        if let scale = scale {
            self.scale = scale
        }
        if let emoji = emoji {
            self.emoji = emoji
        }
        if let notes = notes {
            self.notes = notes
        }
        self.updatedAt = Date()
    }
}

extension Node {
    /// Create a new node with default values
    static func create(context: NSManagedObjectContext, title: String, parent: Node? = nil, direction: String? = nil, level: Int16 = 0) -> Node {
        let node = Node(context: context)
        node.uuid = UUID()
        node.title = title
        node.createdAt = Date()
        node.updatedAt = Date()
        node.parent = parent
        node.direction = direction
        node.level = level
        return node
    }
    
    /// Update node details
    func update(title: String? = nil, note: String? = nil, direction: String? = nil, level: Int16? = nil) {
        if let title = title {
            self.title = title
        }
        if let note = note {
            self.note = note
        }
        if let direction = direction {
            self.direction = direction
        }
        if let level = level {
            self.level = level
        }
        self.updatedAt = Date()
    }
    
    /// Get all children as an array
    var childrenArray: [Node] {
        return Array(children as? Set<Node> ?? [])
    }
    
    /// Check if node has children in a specific direction
    func hasChildInDirection(_ direction: String) -> Bool {
        return childrenArray.contains { $0.direction == direction }
    }
    
    /// Get child in specific direction
    func childInDirection(_ direction: String) -> Node? {
        return childrenArray.first { $0.direction == direction }
    }
}