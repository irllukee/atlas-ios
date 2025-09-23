import SwiftUI

// MARK: - Template Selection View

struct TaskTemplateSelectionView: View {
    let onTemplateSelected: (TaskTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TaskTemplateService.templates, id: \.id) { template in
                    TaskTemplateRowView(template: template) {
                        onTemplateSelected(template)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Task Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TaskTemplateRowView: View {
    let template: TaskTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(template.tasks.count) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Preview of first few tasks
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(template.tasks.prefix(3)), id: \.title) { task in
                        HStack {
                            Circle()
                                .fill(task.priority.color)
                                .frame(width: 6, height: 6)
                            Text(task.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if template.tasks.count > 3 {
                        Text("+ \(template.tasks.count - 3) more tasks")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                    }
                }
                .padding(.leading, 30)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
