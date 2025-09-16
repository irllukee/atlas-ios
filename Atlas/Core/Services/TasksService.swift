import Foundation
import CoreData
import Combine

enum TaskPriority: Int16, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case urgent = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

enum TaskSortOrder: String, CaseIterable {
    case dueDateAscending = "Due Date (Earliest First)"
    case dueDateDescending = "Due Date (Latest First)"
    case priorityDescending = "Priority (High to Low)"
    case priorityAscending = "Priority (Low to High)"
    case createdAtDescending = "Created (Newest First)"
    case titleAscending = "Title (A-Z)"
}

enum TaskFilter: String, CaseIterable {
    case all = "All Tasks"
    case pending = "Pending"
    case completed = "Completed"
    case overdue = "Overdue"
    case dueToday = "Due Today"
    case dueThisWeek = "Due This Week"
    case highPriority = "High Priority"
}

@MainActor
class TasksService: ObservableObject {
    private let taskRepository: TaskRepository
    private let dataManager: DataManager
    
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var sortOrder: TaskSortOrder = .dueDateAscending
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.taskRepository = TaskRepository(context: dataManager.coreDataStack.viewContext)
        
        setupBindings()
        loadTasks()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.filterTasks() }
            .store(in: &cancellables)
        
        $selectedFilter
            .sink { [weak self] _ in self?.filterTasks() }
            .store(in: &cancellables)
        
        $sortOrder
            .sink { [weak self] _ in self?.filterTasks() }
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    
    func createTask(title: String, notes: String = "", priority: TaskPriority = .medium, dueDate: Date? = nil, isRecurring: Bool = false, recurrencePattern: String? = nil) -> Task? {
        let task = taskRepository.createTask(
            title: title,
            notes: notes,
            priority: priority.rawValue,
            dueDate: dueDate,
            isRecurring: isRecurring,
            recurrencePattern: recurrencePattern
        )
        
        if task != nil {
            loadTasks()
        }
        
        return task
    }
    
    func createTaskFromTemplate(_ template: TaskTemplate) -> Task? {
        let task = createTask(
            title: template.title,
            notes: template.notes,
            priority: template.priority,
            dueDate: template.dueDate,
            isRecurring: template.isRecurring,
            recurrencePattern: template.recurrencePattern
        )
        return task
    }
    
    func updateTask(_ task: Task, title: String? = nil, notes: String? = nil, priority: TaskPriority? = nil, dueDate: Date? = nil) -> Bool {
        let success = taskRepository.updateTask(
            task,
            title: title,
            notes: notes,
            priority: priority?.rawValue,
            dueDate: dueDate
        )
        
        if success {
            loadTasks()
        }
        
        return success
    }
    
    func deleteTask(_ task: Task) -> Bool {
        let success = taskRepository.delete(task)
        if success {
            loadTasks()
        }
        return success
    }
    
    func toggleTaskCompletion(_ task: Task) -> Bool {
        let success = taskRepository.toggleCompletion(task)
        if success {
            loadTasks()
        }
        return success
    }
    
    func completeTask(_ task: Task) -> Bool {
        let success = taskRepository.completeTask(task)
        if success {
            loadTasks()
        }
        return success
    }
    
    func uncompleteTask(_ task: Task) -> Bool {
        let success = taskRepository.uncompleteTask(task)
        if success {
            loadTasks()
        }
        return success
    }
    
    // MARK: - Filtering and Sorting
    
    func filterTasks() {
        var tasksToFilter = tasks
        
        // Apply search text filter
        if !searchText.isEmpty {
            tasksToFilter = taskRepository.searchTasks(query: searchText)
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break // No additional filtering
        case .pending:
            tasksToFilter = tasksToFilter.filter { !$0.isCompleted }
        case .completed:
            tasksToFilter = tasksToFilter.filter { $0.isCompleted }
        case .overdue:
            tasksToFilter = taskRepository.fetchOverdue()
        case .dueToday:
            tasksToFilter = taskRepository.fetchDueToday()
        case .dueThisWeek:
            tasksToFilter = taskRepository.fetchDueThisWeek()
        case .highPriority:
            tasksToFilter = tasksToFilter.filter { $0.priority >= 3 && !$0.isCompleted }
        }
        
        // Apply sorting
        switch sortOrder {
        case .dueDateAscending:
            tasksToFilter.sort { 
                guard let dueDate1 = $0.dueDate, let dueDate2 = $1.dueDate else {
                    return $0.dueDate != nil && $1.dueDate == nil
                }
                return dueDate1 < dueDate2
            }
        case .dueDateDescending:
            tasksToFilter.sort { 
                guard let dueDate1 = $0.dueDate, let dueDate2 = $1.dueDate else {
                    return $0.dueDate == nil && $1.dueDate != nil
                }
                return dueDate1 > dueDate2
            }
        case .priorityDescending:
            tasksToFilter.sort { $0.priority > $1.priority }
        case .priorityAscending:
            tasksToFilter.sort { $0.priority < $1.priority }
        case .createdAtDescending:
            tasksToFilter.sort { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        case .titleAscending:
            tasksToFilter.sort { ($0.title ?? "") < ($1.title ?? "") }
        }
        
        filteredTasks = tasksToFilter
    }
    
    // MARK: - Statistics
    
    func getTaskStatistics() -> TaskStatistics {
        return TaskStatistics(
            totalTasks: taskRepository.getTotalCount(),
            completedTasks: taskRepository.getCompletedCount(),
            pendingTasks: taskRepository.getPendingCount(),
            overdueTasks: taskRepository.getOverdueCount(),
            dueTodayTasks: taskRepository.getDueTodayCount(),
            completionRate: taskRepository.getCompletionRate(),
            highPriorityTasks: taskRepository.getHighPriorityCount()
        )
    }
    
    // MARK: - Private Helpers
    
    private func loadTasks() {
        tasks = taskRepository.fetchAll()
        filterTasks()
    }
}

// MARK: - TaskTemplate
struct TaskTemplate: Identifiable {
    let id = UUID()
    let title: String
    let notes: String
    let priority: TaskPriority
    let dueDate: Date?
    let isRecurring: Bool
    let recurrencePattern: String?
}

// MARK: - TaskStatistics
struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let overdueTasks: Int
    let dueTodayTasks: Int
    let completionRate: Double
    let highPriorityTasks: Int
    
    var completionPercentage: Int {
        return Int(completionRate * 100)
    }
    
    var hasOverdueTasks: Bool {
        return overdueTasks > 0
    }
    
    var hasHighPriorityTasks: Bool {
        return highPriorityTasks > 0
    }
}
