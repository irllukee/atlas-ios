import Foundation
import CoreData

// MARK: - Convenience Properties
extension TaskTab {
    var displayName: String {
        return name ?? "Untitled Tab"
    }
    
    var displayColor: String {
        return color ?? "blue"
    }
    
    var displayIcon: String {
        return icon ?? "folder"
    }
    
    var tasksArray: [Task] {
        let set = tasks as? Set<Task> ?? []
        return set.sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
    }
    
    var taskCount: Int {
        return tasksArray.count
    }
    
    var completedTaskCount: Int {
        return tasksArray.filter { $0.isCompleted }.count
    }
    
    var pendingTaskCount: Int {
        return taskCount - completedTaskCount
    }
}
