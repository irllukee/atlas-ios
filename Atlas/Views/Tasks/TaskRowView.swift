import SwiftUI

// MARK: - Task Row View

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    
    private var priority: TaskPriority {
        TaskPriority(rawValue: task.priority ?? "") ?? .medium
    }
    
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Completion Toggle
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(task.title ?? "Untitled Task")
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                    
                    // Notes (if any)
                    if let notes = task.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Metadata Row
                    HStack(spacing: 8) {
                        // Priority Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(priority.color)
                                .frame(width: 8, height: 8)
                            Text(priority.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Due Date
                        if let dueDate = task.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                Text(formatDueDate(dueDate))
                                    .font(.caption)
                            }
                            .foregroundColor(isOverdue ? .red : .secondary)
                        }
                        
                        // Category
                        if let category = task.category {
                            Text(category)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Actions Menu
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Duplicate", action: onDuplicate)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isOverdue ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
