import SwiftUI
import CoreData

struct TasksView: View {
    @StateObject private var viewModel: TaskViewModel
    
    init() {
        let taskRepo = TaskRepository(context: CoreDataStack.shared.viewContext)
        let tabRepo = TaskTabRepository(context: CoreDataStack.shared.viewContext)
        _viewModel = StateObject(wrappedValue: TaskViewModel(taskRepository: taskRepo, tabRepository: tabRepo))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with glassmorphism
                VStack {
                    HStack {
                        Text("Tasks")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: { viewModel.showingTaskForm = true }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Statistics Bar
                    if let stats = viewModel.statistics {
                        TaskStatisticsView(statistics: stats)
                            .padding(.horizontal)
                    }
                    
                    // Search Bar
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal)
                    
                    // Filter and Sort Controls
                    FilterSortBar(
                        selectedFilter: $viewModel.selectedFilter,
                        selectedSort: $viewModel.selectedSort
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // Tab Navigation
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.tabs, id: \.id) { tab in
                            TaskTabView(
                                tab: tab,
                                isSelected: viewModel.selectedTab?.id == tab.id,
                                onTap: { viewModel.selectedTab = tab }
                            )
                        }
                        
                        // Add Tab Button
                        Button(action: { viewModel.showingTabForm = true }) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("Add Tab")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 80, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Tasks List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                       } else if viewModel.filteredTasks.isEmpty {
                           TaskEmptyStateView()
                               .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredTasks, id: \.id) { task in
                            TaskRowView(
                                task: task,
                                onToggle: { viewModel.toggleTaskCompletion(task) },
                                onEdit: { viewModel.editingTask = task },
                                onDuplicate: { viewModel.duplicateTask(task) }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteTask)
                    }
                    .listStyle(PlainListStyle())
                           .refreshable {
                               await viewModel.loadData()
                           }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingTaskForm) {
            TaskFormView(task: nil) {
                _Concurrency.Task {
                    await viewModel.loadData()
                    // Clear the form state after loading
                    await MainActor.run {
                        viewModel.showingTaskForm = false
                    }
                }
            }
        }
        .sheet(item: $viewModel.editingTask) { task in
            TaskFormView(task: task) {
                _Concurrency.Task {
                    await viewModel.loadData()
                    // Clear the editing state after loading
                    await MainActor.run {
                        viewModel.editingTask = nil
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingTabForm) {
            TaskTabFormView {
                _Concurrency.Task {
                    await viewModel.loadData()
                    // Clear the form state after loading
                    await MainActor.run {
                        viewModel.showingTabForm = false
                    }
                }
            }
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let task = viewModel.filteredTasks[index]
            viewModel.deleteTask(task)
        }
    }
}

// MARK: - Task Statistics View

struct TaskStatisticsView: View {
    let statistics: TaskStatistics
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                TaskStatCard(title: "Total", value: "\(statistics.totalTasks)", color: .blue)
                TaskStatCard(title: "Completed", value: "\(statistics.completedTasks)", color: .green)
                TaskStatCard(title: "Pending", value: "\(statistics.pendingTasks)", color: .orange)
                TaskStatCard(title: "Overdue", value: "\(statistics.overdueTasks)", color: .red)
                TaskStatCard(title: "Due Today", value: "\(statistics.dueTodayTasks)", color: .purple)
                TaskStatCard(title: "Completion", value: String(format: "%.0f%%", statistics.completionRate), color: .indigo)
            }
            .padding(.horizontal)
        }
    }
}

struct TaskStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tasks...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Filter Sort Bar

struct FilterSortBar: View {
    @Binding var selectedFilter: TaskFilter
    @Binding var selectedSort: TaskSortOption
    
    var body: some View {
        HStack {
            // Filter Menu
            Menu {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) {
                        selectedFilter = filter
                    }
                }
            } label: {
                HStack {
                    Text("Filter: \(selectedFilter.rawValue)")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Sort Menu
            Menu {
                ForEach(TaskSortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        selectedSort = option
                    }
                }
            } label: {
                HStack {
                    Text("Sort")
                        .font(.caption)
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Task Tab View

struct TaskTabView: View {
    let tab: TaskTab
    let isSelected: Bool
    let onTap: () -> Void
    
    private var tabColor: Color {
        switch tab.colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName ?? "folder")
                    .font(.title2)
                    .foregroundColor(isSelected ? tabColor : .secondary)
                
                Text(tab.name ?? "Unnamed Tab")
                    .font(.caption)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                
                // Task count badge
                Text("\(tab.tasksArray.count)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tabColor)
                    .cornerRadius(8)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tabColor.opacity(0.1) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? tabColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View

struct TaskEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Create your first task to get started with organizing your life.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
