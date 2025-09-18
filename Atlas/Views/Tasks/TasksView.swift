import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var dataManager: DataManager
    @StateObject private var viewModel: TasksViewModel
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: TasksViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Search Bar
                    ModernSearchBar(
                        searchText: $viewModel.searchText,
                        placeholder: "Search tasks...",
                        onSearch: { query in
                            viewModel.searchTasks(query: query)
                        },
                        onClear: {
                            viewModel.searchTasks(query: "")
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Tasks List
                    if viewModel.isLoading {
                        ProgressView("Loading Tasks...")
                            .foregroundColor(.white)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                    } else if viewModel.filteredTasks.isEmpty {
                        ContentUnavailableView("No Tasks", systemImage: "checklist")
                            .foregroundColor(.white)
                    } else {
                        List {
                            ForEach(viewModel.filteredTasks) { task in
                                NavigationLink(destination: EditTaskView(task: task, viewModel: viewModel)) {
                                    TaskRow(task: task, viewModel: viewModel)
                                }
                            }
                            .onDelete(perform: deleteTasks)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            viewModel.showingFilters.toggle() 
                        }) {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            viewModel.showingTemplates.toggle() 
                        }) {
                            Label("Templates", systemImage: "doc.on.doc")
                        }
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            viewModel.showingCreateTask.toggle() 
                        }) {
                            Label("Add Task", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateTask) {
                CreateTaskView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingTemplates) {
                TaskTemplatesView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingFilters) {
                TasksFilterView(viewModel: viewModel)
            }
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.filteredTasks[$0] }.forEach(viewModel.deleteTask)
        }
    }
}

struct TaskRow: View {
    @ObservedObject var task: Task
    @ObservedObject var viewModel: TasksViewModel
    
    var body: some View {
        HStack {
            // Completion checkbox
            Button(action: {
                viewModel.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    // Priority indicator
                    if task.priority > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark")
                                .font(.caption)
                            Text("\(task.priority)")
                                .font(.caption)
                        }
                        .foregroundColor(priorityColor(task.priority))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(task.priority).opacity(0.2))
                        .cornerRadius(4)
                    }
                    
                    // Due date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(dueDate, formatter: dateFormatter)
                                .font(.caption)
                        }
                        .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func priorityColor(_ priority: Int16) -> Color {
        switch priority {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    private func isOverdue(_ dueDate: Date) -> Bool {
        return dueDate < Date() && !task.isCompleted
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Preview
struct TasksView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        
        TasksView(dataManager: dataManager)
    }
}

