import Combine
import CoreData
import Foundation
import SwiftUI

@MainActor
final class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var tabs: [TaskTab] = []
    @Published var selectedTab: TaskTab?
    @Published var filteredTasks: [Task] = []
    @Published var searchText = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var selectedSort: TaskSortOption = .dueDateEarliest
    @Published var isLoading = false
    @Published var showingTaskForm = false
    @Published var showingTabForm = false
    @Published var editingTask: Task?
    @Published var statistics: TaskStatistics?
    
    private let taskRepository: TaskRepositoryProtocol
    private let tabRepository: TaskTabRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var searchDebounceTimer: Timer?
    
    init(taskRepository: TaskRepositoryProtocol, tabRepository: TaskTabRepositoryProtocol) {
        self.taskRepository = taskRepository
        self.tabRepository = tabRepository
        setupSearchDebouncing()
        _Concurrency.Task { @MainActor in
            await self.loadData()
        }
    }
    
    private func setupSearchDebouncing() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3($tasks, $selectedFilter, $selectedSort)
            .sink { [weak self] _ in
                self?.applyFiltersAndSort()
            }
            .store(in: &cancellables)
    }
    
    func loadData() async {
        isLoading = true
        
        do {
            let tasks = try await taskRepository.fetchTasks()
            let tabs = try await tabRepository.fetchTabs()
            
            self.tasks = tasks
            self.tabs = tabs
            if selectedTab == nil, let firstTab = tabs.first {
                selectedTab = firstTab
            }
            updateStatistics()
            applyFiltersAndSort()
            isLoading = false
        } catch {
            print("Error loading data: \(error)")
            isLoading = false
        }
    }
    
    private func applyFiltersAndSort() {
        var filtered = tasks
        
        // Apply tab filter
        if let selectedTab = selectedTab {
            filtered = filtered.filter { $0.tab == selectedTab }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                (task.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (task.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
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
                return !task.isCompleted && dueDate < Date()
            }
        case .dueToday:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }
        case .dueThisWeek:
            filtered = filtered.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
            }
        case .highPriority:
            filtered = filtered.filter { task in
                TaskPriority(rawValue: task.priority ?? "") == .high || TaskPriority(rawValue: task.priority ?? "") == .urgent
            }
        }
        
        // Apply sorting
        switch selectedSort {
        case .dueDateEarliest:
            filtered.sort { task1, task2 in
                guard let date1 = task1.dueDate else { return false }
                guard let date2 = task2.dueDate else { return true }
                return date1 < date2
            }
        case .dueDateLatest:
            filtered.sort { task1, task2 in
                guard let date1 = task1.dueDate else { return true }
                guard let date2 = task2.dueDate else { return false }
                return date1 > date2
            }
        case .priorityHighToLow:
            filtered.sort { task1, task2 in
                let priority1 = TaskPriority(rawValue: task1.priority ?? "")?.sortOrder ?? 0
                let priority2 = TaskPriority(rawValue: task2.priority ?? "")?.sortOrder ?? 0
                return priority1 > priority2
            }
        case .priorityLowToHigh:
            filtered.sort { task1, task2 in
                let priority1 = TaskPriority(rawValue: task1.priority ?? "")?.sortOrder ?? 0
                let priority2 = TaskPriority(rawValue: task2.priority ?? "")?.sortOrder ?? 0
                return priority1 < priority2
            }
        case .createdNewest:
            filtered.sort { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        case .alphabetical:
            filtered.sort { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
        }
        
        filteredTasks = filtered
    }
    
    private func updateStatistics() {
        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count
        let pending = total - completed
        let overdue = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }.count
        let dueToday = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }.count
        let highPriority = tasks.filter { task in
            let priority = TaskPriority(rawValue: task.priority ?? "")
            return priority == .high || priority == .urgent
        }.count
        
        statistics = TaskStatistics(
            totalTasks: total,
            completedTasks: completed,
            pendingTasks: pending,
            overdueTasks: overdue,
            dueTodayTasks: dueToday,
            highPriorityTasks: highPriority
        )
    }
    
    func toggleTaskCompletion(_ task: Task) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        
        taskRepository.updateTask(task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error updating task: \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.updateStatistics()
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteTask(_ task: Task) {
        taskRepository.deleteTask(task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error deleting task: \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    _Concurrency.Task { @MainActor in
                        await self?.loadData()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func duplicateTask(_ task: Task) {
        taskRepository.duplicateTask(task)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error duplicating task: \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    _Concurrency.Task { @MainActor in
                        await self?.loadData()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func createTaskFromTemplate(_ template: TaskTemplate) {
        guard let context = tasks.first?.managedObjectContext else { return }
        
        for templateItem in template.tasks {
            let task = Task(context: context)
            task.title = templateItem.title
            task.notes = templateItem.notes
            task.priority = templateItem.priority.rawValue
            task.category = template.category
            task.tab = selectedTab
            
            taskRepository.createTask(task)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("Error creating task from template: \(error)")
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            _Concurrency.Task { @MainActor in
                await self.loadData()
            }
        }
    }
}
