import Foundation
import Combine
import CoreData

@MainActor
class TasksViewModel: ObservableObject {
    // MARK: - Properties
    private let tasksService: TasksService
    private var cancellables = Set<AnyCancellable>()
    
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var sortOrder: TaskSortOrder = .dueDateAscending
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingCreateTask: Bool = false
    @Published var showingTemplates: Bool = false
    @Published var showingFilters: Bool = false
    @Published var taskStatistics: TaskStatistics = TaskStatistics(
        totalTasks: 0,
        completedTasks: 0,
        pendingTasks: 0,
        overdueTasks: 0,
        dueTodayTasks: 0,
        completionRate: 0.0,
        highPriorityTasks: 0
    )
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.tasksService = TasksService(dataManager: dataManager)
        
        setupBindings()
    }
    
    private func setupBindings() {
        tasksService.$tasks
            .assign(to: &$tasks)
        
        tasksService.$filteredTasks
            .assign(to: &$filteredTasks)
        
        tasksService.$searchText
            .assign(to: &$searchText)
        
        tasksService.$selectedFilter
            .assign(to: &$selectedFilter)
        
        tasksService.$sortOrder
            .assign(to: &$sortOrder)
        
        tasksService.$isLoading
            .assign(to: &$isLoading)
        
        tasksService.$errorMessage
            .assign(to: &$errorMessage)
        
        // Update statistics when tasks change
        tasksService.$tasks
            .sink { [weak self] _ in
                self?.updateStatistics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load all tasks
    func loadTasks() {
        isLoading = true
        errorMessage = nil
        
        // Tasks are loaded automatically through the service
        isLoading = false
    }
    
    /// Create a new task
    func createTask(title: String, notes: String = "", priority: TaskPriority = .medium, dueDate: Date? = nil, isRecurring: Bool = false, recurrencePattern: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        let task = tasksService.createTask(
            title: title,
            notes: notes,
            priority: priority,
            dueDate: dueDate,
            isRecurring: isRecurring,
            recurrencePattern: recurrencePattern
        )
        
        if task != nil {
            showingCreateTask = false
        } else {
            errorMessage = "Failed to create task"
        }
        isLoading = false
    }
    
    /// Create a task from template
    func createTaskFromTemplate(_ template: TaskTemplate) {
        isLoading = true
        errorMessage = nil
        
        let task = tasksService.createTaskFromTemplate(template)
        
        if task != nil {
            showingTemplates = false
            showingCreateTask = false
        } else {
            errorMessage = "Failed to create task from template"
        }
        isLoading = false
    }
    
    /// Update a task
    func updateTask(_ task: Task, title: String? = nil, notes: String? = nil, priority: TaskPriority? = nil, dueDate: Date? = nil) {
        isLoading = true
        errorMessage = nil
        
        let success = tasksService.updateTask(task, title: title, notes: notes, priority: priority, dueDate: dueDate)
        
        if !success {
            errorMessage = "Failed to update task"
        }
        isLoading = false
    }
    
    /// Delete a task
    func deleteTask(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        let success = tasksService.deleteTask(task)
        
        if !success {
            errorMessage = "Failed to delete task"
        }
        isLoading = false
    }
    
    /// Toggle task completion
    func toggleTaskCompletion(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        let success = tasksService.toggleTaskCompletion(task)
        
        if !success {
            errorMessage = "Failed to update task completion"
        }
        isLoading = false
    }
    
    /// Complete a task
    func completeTask(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        let success = tasksService.completeTask(task)
        
        if !success {
            errorMessage = "Failed to complete task"
        }
        isLoading = false
    }
    
    /// Uncomplete a task
    func uncompleteTask(_ task: Task) {
        isLoading = true
        errorMessage = nil
        
        let success = tasksService.uncompleteTask(task)
        
        if !success {
            errorMessage = "Failed to uncomplete task"
        }
        isLoading = false
    }
    
    /// Search tasks
    func searchTasks(query: String) {
        tasksService.searchText = query
        tasksService.filterTasks()
    }
    
    /// Filter tasks by status
    func filterByStatus(_ filter: TaskFilter) {
        selectedFilter = filter
        tasksService.selectedFilter = filter
        tasksService.filterTasks()
    }
    
    /// Change sort order
    func changeSortOrder(_ order: TaskSortOrder) {
        sortOrder = order
        tasksService.sortOrder = order
        tasksService.filterTasks()
    }
    
    /// Get tasks for a specific date
    func getTasksForDate(_ date: Date) -> [Task] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startOfDay && dueDate < endOfDay
        }
    }
    
    /// Get overdue tasks
    func getOverdueTasks() -> [Task] {
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && !task.isCompleted
        }
    }
    
    /// Get high priority tasks
    func getHighPriorityTasks() -> [Task] {
        return tasks.filter { task in
            return task.priority >= 3 && !task.isCompleted
        }
    }
    
    // MARK: - Private Methods
    
    private func updateStatistics() {
        taskStatistics = tasksService.getTaskStatistics()
    }
}

