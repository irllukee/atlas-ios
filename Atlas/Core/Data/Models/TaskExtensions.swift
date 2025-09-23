import CoreData
import Foundation

// MARK: - Task Extensions

extension Task {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
        isCompleted = false
        priority = TaskPriority.medium.rawValue
    }
}

extension TaskTab {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        colorName = "blue"
        iconName = "folder"
    }
    
    public var tasksArray: [Task] {
        let set = tasks as? Set<Task> ?? []
        return set.sorted { 
            ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
        }
    }
}
