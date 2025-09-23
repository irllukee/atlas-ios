import Combine
import CoreData
import Foundation

// MARK: - Task Repository

protocol TaskRepositoryProtocol {
    func getAllTasks() -> AnyPublisher<[Task], Error>
    func getTasksForTab(_ tab: TaskTab) -> AnyPublisher<[Task], Error>
    func createTask(_ task: Task) -> AnyPublisher<Task, Error>
    func updateTask(_ task: Task) -> AnyPublisher<Task, Error>
    func deleteTask(_ task: Task) -> AnyPublisher<Void, Error>
    func duplicateTask(_ task: Task) -> AnyPublisher<Task, Error>
    
    // Async/await methods
    @MainActor func fetchTasks() async throws -> [Task]
    @MainActor func fetchTasksForTab(_ tab: TaskTab) async throws -> [Task]
    @MainActor func createTaskAsync(_ task: Task) async throws -> Task
    @MainActor func updateTaskAsync(_ task: Task) async throws -> Task
    @MainActor func deleteTaskAsync(_ task: Task) async throws
    @MainActor func duplicateTaskAsync(_ task: Task) async throws -> Task
}

class TaskRepository: TaskRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getAllTasks() -> AnyPublisher<[Task], Error> {
        Future { promise in
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)]
            
            do {
                let tasks = try self.context.fetch(request)
                promise(.success(tasks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTasksForTab(_ tab: TaskTab) -> AnyPublisher<[Task], Error> {
        Future { promise in
            let request: NSFetchRequest<Task> = Task.fetchRequest()
            request.predicate = NSPredicate(format: "tab == %@", tab)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)]
            
            do {
                let tasks = try self.context.fetch(request)
                promise(.success(tasks))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createTask(_ task: Task) -> AnyPublisher<Task, Error> {
        Future { promise in
            do {
                try self.context.save()
                promise(.success(task))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateTask(_ task: Task) -> AnyPublisher<Task, Error> {
        Future { promise in
            task.updatedAt = Date()
            do {
                try self.context.save()
                promise(.success(task))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteTask(_ task: Task) -> AnyPublisher<Void, Error> {
        Future { promise in
            self.context.delete(task)
            do {
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func duplicateTask(_ task: Task) -> AnyPublisher<Task, Error> {
        Future { promise in
            let newTask = Task(context: self.context)
            newTask.title = (task.title ?? "Task") + " (Copy)"
            newTask.notes = task.notes
            newTask.priority = task.priority
            newTask.dueDate = task.dueDate
            newTask.recurringType = task.recurringType
            newTask.category = task.category
            newTask.tab = task.tab

            do {
                try self.context.save()
                promise(.success(newTask))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Statistics Methods
    
    func getTotalCount() -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func getCompletedCount() -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func getPendingCount() -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func getOverdueCount() -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO AND dueDate < %@", Date() as NSDate)
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func getDueTodayCount() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO AND dueDate >= %@ AND dueDate < %@", 
                                      startOfDay as NSDate, endOfDay as NSDate)
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func getCompletionRate() -> Double {
        let total = getTotalCount()
        guard total > 0 else { return 0.0 }
        let completed = getCompletedCount()
        return Double(completed) / Double(total) * 100.0
    }
    
    func getHighPriorityCount() -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "priority == %@ OR priority == %@", 
                                      TaskPriority.high.rawValue, TaskPriority.urgent.rawValue)
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    // MARK: - Async/Await Methods
    
    @MainActor func fetchTasks() async throws -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)]
        return try context.fetch(request)
    }
    
    @MainActor func fetchTasksForTab(_ tab: TaskTab) async throws -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "tab == %@", tab)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)]
        return try context.fetch(request)
    }
    
    @MainActor func createTaskAsync(_ task: Task) async throws -> Task {
        try context.save()
        return task
    }
    
    @MainActor func updateTaskAsync(_ task: Task) async throws -> Task {
        try context.save()
        return task
    }
    
    @MainActor func deleteTaskAsync(_ task: Task) async throws {
        context.delete(task)
        try context.save()
    }
    
    @MainActor func duplicateTaskAsync(_ task: Task) async throws -> Task {
        let newTask = Task(context: context)
        newTask.title = (task.title ?? "Task") + " (Copy)"
        newTask.notes = task.notes
        newTask.priority = task.priority
        newTask.dueDate = task.dueDate
        newTask.recurringType = task.recurringType
        newTask.category = task.category
        newTask.tab = task.tab
        
        try context.save()
        return newTask
    }
}

// MARK: - Task Tab Repository

protocol TaskTabRepositoryProtocol {
    func getAllTabs() -> AnyPublisher<[TaskTab], Error>
    func createTab(_ tab: TaskTab) -> AnyPublisher<TaskTab, Error>
    func updateTab(_ tab: TaskTab) -> AnyPublisher<TaskTab, Error>
    func deleteTab(_ tab: TaskTab) -> AnyPublisher<Void, Error>
    
    // Async/await methods
    @MainActor func fetchTabs() async throws -> [TaskTab]
    @MainActor func createTabAsync(_ tab: TaskTab) async throws -> TaskTab
    @MainActor func updateTabAsync(_ tab: TaskTab) async throws -> TaskTab
    @MainActor func deleteTabAsync(_ tab: TaskTab) async throws
}

class TaskTabRepository: TaskTabRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func getAllTabs() -> AnyPublisher<[TaskTab], Error> {
        Future { promise in
            let request: NSFetchRequest<TaskTab> = TaskTab.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskTab.createdAt, ascending: true)]
            
            do {
                let tabs = try self.context.fetch(request)
                promise(.success(tabs))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createTab(_ tab: TaskTab) -> AnyPublisher<TaskTab, Error> {
        Future { promise in
            do {
                try self.context.save()
                promise(.success(tab))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateTab(_ tab: TaskTab) -> AnyPublisher<TaskTab, Error> {
        Future { promise in
            do {
                try self.context.save()
                promise(.success(tab))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteTab(_ tab: TaskTab) -> AnyPublisher<Void, Error> {
        Future { promise in
            self.context.delete(tab)
            do {
                try self.context.save()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - TaskTabRepository Async Methods

extension TaskTabRepository {
    @MainActor func fetchTabs() async throws -> [TaskTab] {
        let request: NSFetchRequest<TaskTab> = TaskTab.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskTab.createdAt, ascending: true)]
        return try context.fetch(request)
    }
    
    @MainActor func createTabAsync(_ tab: TaskTab) async throws -> TaskTab {
        try context.save()
        return tab
    }
    
    @MainActor func updateTabAsync(_ tab: TaskTab) async throws -> TaskTab {
        try context.save()
        return tab
    }
    
    @MainActor func deleteTabAsync(_ tab: TaskTab) async throws {
        context.delete(tab)
        try context.save()
    }
}