import Foundation
import Combine
import CoreData

@MainActor
class TabbedTasksViewModel: ObservableObject {
    // MARK: - Properties
    private let dataManager: DataManager
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var tabs: [TaskTab] = []
    @Published var selectedTab: TaskTab?
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
    @Published var showingCreateTab: Bool = false
    @Published var showingRenameTab: Bool = false
    @Published var tabToRename: TaskTab?
    @Published var newTabName: String = ""
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        loadTabs()
    }
    
    // MARK: - Tab Management
    
    func loadTabs() {
        print("📋 TabbedTasksViewModel: Loading tabs...")
        let request: NSFetchRequest<TaskTab> = TaskTab.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskTab.order, ascending: true)]
        
        do {
            tabs = try dataManager.coreDataStack.viewContext.fetch(request)
            print("📋 TabbedTasksViewModel: Loaded \(tabs.count) tabs")
            
            // Create default tab if none exist
            if tabs.isEmpty {
                print("📋 TabbedTasksViewModel: No tabs found, creating default tab...")
                createDefaultTab()
            } else {
                if selectedTab == nil {
                    selectedTab = tabs.first
                    print("📋 TabbedTasksViewModel: Selected first tab: \(selectedTab?.name ?? "Unknown")")
                }
                loadTasksForSelectedTab()
            }
        } catch {
            print("❌ TabbedTasksViewModel: Failed to load tabs: \(error.localizedDescription)")
            errorMessage = "Failed to load tabs: \(error.localizedDescription)"
        }
    }
    
    private func createDefaultTab() {
        print("📋 TabbedTasksViewModel: Creating default tab...")
        let defaultTab = TaskTab(context: dataManager.coreDataStack.viewContext)
        defaultTab.id = UUID()
        defaultTab.name = "My Tasks"
        defaultTab.color = "blue"
        defaultTab.icon = "checklist"
        defaultTab.order = 0
        defaultTab.createdAt = Date()
        defaultTab.updatedAt = Date()
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            print("📋 TabbedTasksViewModel: Default tab created successfully")
            loadTabs() // Reload tabs after creating default
        } catch {
            print("❌ TabbedTasksViewModel: Failed to create default tab: \(error.localizedDescription)")
            errorMessage = "Failed to create default tab: \(error.localizedDescription)"
        }
    }
    
    func createTab(name: String, color: String = "blue", icon: String = "folder") {
        let newTab = TaskTab(context: dataManager.coreDataStack.viewContext)
        newTab.id = UUID()
        newTab.name = name
        newTab.color = color
        newTab.icon = icon
        newTab.order = Int16(tabs.count)
        newTab.createdAt = Date()
        newTab.updatedAt = Date()
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTabs()
            selectedTab = newTab
            showingCreateTab = false
        } catch {
            errorMessage = "Failed to create tab: \(error.localizedDescription)"
        }
    }
    
    func renameTab(_ tab: TaskTab, newName: String) {
        tab.name = newName
        tab.updatedAt = Date()
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTabs()
            showingRenameTab = false
            tabToRename = nil
            newTabName = ""
        } catch {
            errorMessage = "Failed to rename tab: \(error.localizedDescription)"
        }
    }
    
    func deleteTab(_ tab: TaskTab) {
        // Don't allow deleting the last tab
        if tabs.count <= 1 {
            errorMessage = "Cannot delete the last tab"
            return
        }
        
        // If deleting the selected tab, switch to another tab
        if selectedTab == tab {
            if let index = tabs.firstIndex(of: tab) {
                selectedTab = index > 0 ? tabs[index - 1] : tabs[index + 1]
            }
        }
        
        dataManager.coreDataStack.viewContext.delete(tab)
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTabs()
        } catch {
            errorMessage = "Failed to delete tab: \(error.localizedDescription)"
        }
    }
    
    func selectTab(_ tab: TaskTab) {
        selectedTab = tab
        loadTasksForSelectedTab()
    }
    
    func moveTab(from source: IndexSet, to destination: Int) {
        var updatedTabs = tabs
        updatedTabs.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, tab) in updatedTabs.enumerated() {
            tab.order = Int16(index)
        }
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTabs()
        } catch {
            errorMessage = "Failed to reorder tabs: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Task Management
    
    func loadTasksForSelectedTab() {
        print("📋 TabbedTasksViewModel: Loading tasks for selected tab...")
        guard let selectedTab = selectedTab else {
            print("📋 TabbedTasksViewModel: No tab selected")
            tasks = []
            filteredTasks = []
            return
        }
        
        tasks = selectedTab.tasksArray
        print("📋 TabbedTasksViewModel: Loaded \(tasks.count) tasks for tab: \(selectedTab.name ?? "Unknown")")
        filterTasks()
    }
    
    func createTask(title: String, notes: String = "", priority: TaskPriority = .medium, dueDate: Date? = nil, isRecurring: Bool = false, recurrencePattern: String? = nil) {
        guard let selectedTab = selectedTab else {
            errorMessage = "No tab selected"
            return
        }
        
        let newTask = Task(context: dataManager.coreDataStack.viewContext)
        newTask.uuid = UUID()
        newTask.title = title
        newTask.notes = notes
        newTask.priority = priority.rawValue
        newTask.dueDate = dueDate
        newTask.isRecurring = isRecurring
        newTask.recurrencePattern = recurrencePattern
        newTask.isCompleted = false
        newTask.createdAt = Date()
        newTask.updatedAt = Date()
        newTask.tab = selectedTab
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTasksForSelectedTab()
            
            // Schedule notification if task has a due date
            if let dueDate = dueDate {
                notificationService.scheduleTaskReminder(
                    taskId: newTask.uuid?.uuidString ?? "",
                    title: title,
                    dueDate: dueDate
                )
            }
            
            showingCreateTask = false
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
        }
    }
    
    func createTaskFromTemplate(_ template: TaskTemplate) {
        createTask(
            title: template.title,
            notes: template.notes,
            priority: template.priority,
            dueDate: template.dueDate,
            isRecurring: template.isRecurring,
            recurrencePattern: template.recurrencePattern
        )
    }
    
    func updateTask(_ task: Task, title: String? = nil, notes: String? = nil, priority: TaskPriority? = nil, dueDate: Date? = nil) {
        if let title = title { task.title = title }
        if let notes = notes { task.notes = notes }
        if let priority = priority { task.priority = priority.rawValue }
        if let dueDate = dueDate { task.dueDate = dueDate }
        task.updatedAt = Date()
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTasksForSelectedTab()
            
            // Update notifications if due date changed
            if let taskId = task.uuid?.uuidString {
                notificationService.removeTaskReminders(taskId: taskId)
                
                if let dueDate = dueDate ?? task.dueDate {
                    notificationService.scheduleTaskReminder(
                        taskId: taskId,
                        title: title ?? task.title ?? "Task",
                        dueDate: dueDate
                    )
                }
            }
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }
    
    func deleteTask(_ task: Task) {
        // Remove notifications before deleting task
        if let taskId = task.uuid?.uuidString {
            notificationService.removeTaskReminders(taskId: taskId)
        }
        
        dataManager.coreDataStack.viewContext.delete(task)
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTasksForSelectedTab()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        task.updatedAt = Date()
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadTasksForSelectedTab()
        } catch {
            errorMessage = "Failed to update task completion: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Filtering and Sorting
    
    func searchTasks(query: String) {
        searchText = query
        filterTasks()
    }
    
    func filterByStatus(_ filter: TaskFilter) {
        selectedFilter = filter
        filterTasks()
    }
    
    func changeSortOrder(_ order: TaskSortOrder) {
        sortOrder = order
        filterTasks()
    }
    
    private func filterTasks() {
        var filtered = tasks
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title?.localizedCaseInsensitiveContains(searchText) == true ||
                task.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .pending:
            filtered = filtered.filter { !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        case .overdue:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < Date() && !task.isCompleted
            }
        case .dueToday:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate >= today && dueDate < tomorrow && !task.isCompleted
            }
        case .dueThisWeek:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!
            
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate >= today && dueDate < endOfWeek && !task.isCompleted
            }
        case .highPriority:
            filtered = filtered.filter { $0.priority >= 3 && !$0.isCompleted }
        }
        
        // Apply sorting
        switch sortOrder {
        case .dueDateAscending:
            filtered = filtered.sorted { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 < date2
            }
        case .dueDateDescending:
            filtered = filtered.sorted { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 > date2
            }
        case .priorityAscending:
            filtered = filtered.sorted { $0.priority < $1.priority }
        case .priorityDescending:
            filtered = filtered.sorted { $0.priority > $1.priority }
        case .createdAtDescending:
            filtered = filtered.sorted { task1, task2 in
                guard let date1 = task1.createdAt else { return false }
                guard let date2 = task2.createdAt else { return true }
                return date1 > date2
            }
        case .titleAscending:
            filtered = filtered.sorted { task1, task2 in
                (task1.title ?? "") < (task2.title ?? "")
            }
        }
        
        filteredTasks = filtered
    }
    
    // MARK: - Statistics
    
    func getTaskStatistics() -> TaskStatistics {
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        let pendingTasks = totalTasks - completedTasks
        let overdueTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && !task.isCompleted
        }.count
        let dueTodayTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            let calendar = Calendar.current
            return calendar.isDateInToday(dueDate) && !task.isCompleted
        }.count
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        let highPriorityTasks = tasks.filter { $0.priority >= 3 && !$0.isCompleted }.count
        
        return TaskStatistics(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            pendingTasks: pendingTasks,
            overdueTasks: overdueTasks,
            dueTodayTasks: dueTodayTasks,
            completionRate: completionRate,
            highPriorityTasks: highPriorityTasks
        )
    }
}

// MARK: - Supporting Types
// All supporting types are defined in TasksService.swift
