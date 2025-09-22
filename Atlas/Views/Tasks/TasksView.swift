import SwiftUI
import CoreData

// Use the Core Data Task entity directly
// Note: Task is the Core Data entity name, not Swift's Task type
// TaskEntity typealias is defined in TasksService.swift

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var dataManager: DataManager
    @StateObject private var viewModel: TasksViewModel
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: TasksViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        TabbedTasksView(dataManager: dataManager)
    }
    
}

struct TaskRow<ViewModel: TaskViewModelProtocol>: View {
    @ObservedObject var task: TaskEntity
    @ObservedObject var viewModel: ViewModel
    
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

