import Foundation
import CoreData

/// Repository for managing Task entities
class TaskRepository: BaseRepository<Task> {
    
    // MARK: - Custom Queries
    func fetchCompleted() -> [Task] {
        let predicate = NSPredicate(format: "isCompleted == YES")
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.completedAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchPending() -> [Task] {
        let predicate = NSPredicate(format: "isCompleted == NO")
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.priority, ascending: false), NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchByPriority(_ priority: Int16) -> [Task] {
        let predicate = NSPredicate(format: "priority == %d", priority)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchOverdue() -> [Task] {
        let predicate = NSPredicate(format: "dueDate < %@ AND isCompleted == NO", Date() as NSDate)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchDueToday() -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == NO", startOfDay as NSDate, endOfDay as NSDate)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.priority, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchDueThisWeek() -> [Task] {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == NO", startOfWeek as NSDate, endOfWeek as NSDate)
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    func fetchRecurring() -> [Task] {
        let predicate = NSPredicate(format: "isRecurring == YES")
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.updatedAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Create Operations
    func createTask(title: String, notes: String = "", priority: Int16 = 1, dueDate: Date? = nil, isRecurring: Bool = false, recurrencePattern: String? = nil) -> Task? {
        let task = Task.create(context: context, title: title, notes: notes)
        task.priority = priority
        task.dueDate = dueDate
        task.isRecurring = isRecurring
        task.recurrencePattern = recurrencePattern
        
        if save() {
            return task
        } else {
            context.delete(task)
            return nil
        }
    }
    
    // MARK: - Update Operations
    func updateTask(_ task: Task, title: String? = nil, notes: String? = nil, priority: Int16? = nil, dueDate: Date? = nil) -> Bool {
        task.update(title: title, notes: notes, priority: priority, dueDate: dueDate)
        return save()
    }
    
    func completeTask(_ task: Task) -> Bool {
        task.complete()
        return save()
    }
    
    func uncompleteTask(_ task: Task) -> Bool {
        task.uncomplete()
        return save()
    }
    
    func toggleCompletion(_ task: Task) -> Bool {
        if task.isCompleted {
            return uncompleteTask(task)
        } else {
            return completeTask(task)
        }
    }
    
    // MARK: - Search Operations
    func searchTasks(query: String) -> [Task] {
        let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", query)
        let notesPredicate = NSPredicate(format: "notes CONTAINS[cd] %@", query)
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, notesPredicate])
        
        let sortDescriptors = [NSSortDescriptor(keyPath: \Task.priority, ascending: false), NSSortDescriptor(keyPath: \Task.updatedAt, ascending: false)]
        return fetch(predicate: predicate, sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Statistics
    func getTotalCount() -> Int {
        return count()
    }
    
    func getCompletedCount() -> Int {
        let predicate = NSPredicate(format: "isCompleted == YES")
        return count(predicate: predicate)
    }
    
    func getPendingCount() -> Int {
        let predicate = NSPredicate(format: "isCompleted == NO")
        return count(predicate: predicate)
    }
    
    func getOverdueCount() -> Int {
        let predicate = NSPredicate(format: "dueDate < %@ AND isCompleted == NO", Date() as NSDate)
        return count(predicate: predicate)
    }
    
    func getDueTodayCount() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND isCompleted == NO", startOfDay as NSDate, endOfDay as NSDate)
        return count(predicate: predicate)
    }
    
    func getCompletionRate() -> Double {
        let total = getTotalCount()
        guard total > 0 else { return 0.0 }
        
        let completed = getCompletedCount()
        return Double(completed) / Double(total)
    }
    
    func getHighPriorityCount() -> Int {
        let predicate = NSPredicate(format: "priority >= 3 AND isCompleted == NO")
        return count(predicate: predicate)
    }
}