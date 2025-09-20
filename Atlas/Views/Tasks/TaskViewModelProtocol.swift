import Foundation
import CoreData

@MainActor
protocol TaskViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var selectedFilter: TaskFilter { get }
    var sortOrder: TaskSortOrder { get }
    
    func createTask(title: String, notes: String, priority: TaskPriority, dueDate: Date?, isRecurring: Bool, recurrencePattern: String?)
    func createTaskFromTemplate(_ template: TaskTemplate)
    func updateTask(_ task: Task, title: String?, notes: String?, priority: TaskPriority?, dueDate: Date?)
    func deleteTask(_ task: Task)
    func toggleTaskCompletion(_ task: Task)
    func filterByStatus(_ filter: TaskFilter)
    func changeSortOrder(_ order: TaskSortOrder)
}

extension TasksViewModel: @preconcurrency TaskViewModelProtocol {
    // Already implements the required methods
}

extension TabbedTasksViewModel: @preconcurrency TaskViewModelProtocol {
    // Already implements the required methods
}
