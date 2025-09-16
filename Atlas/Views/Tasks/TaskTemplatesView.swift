import SwiftUI

struct TaskTemplatesView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    
    let templates: [TaskTemplate] = [
        TaskTemplate(
            title: "Daily Standup",
            notes: "## Daily Standup\n\n### What did I accomplish yesterday?\n- \n\n### What will I work on today?\n- \n\n### Any blockers or impediments?\n- ",
            priority: .medium,
            dueDate: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()),
            isRecurring: true,
            recurrencePattern: "daily"
        ),
        TaskTemplate(
            title: "Weekly Review",
            notes: "## Weekly Review\n\n### What went well this week?\n- \n\n### What could be improved?\n- \n\n### Goals for next week:\n- ",
            priority: .high,
            dueDate: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()),
            isRecurring: true,
            recurrencePattern: "weekly"
        ),
        TaskTemplate(
            title: "Project Planning",
            notes: "## Project Planning\n\n**Project:** \n**Deadline:** \n\n### Tasks to Complete\n- [ ] \n- [ ] \n- [ ] \n\n### Resources Needed\n- \n\n### Risks & Mitigation\n- ",
            priority: .high,
            dueDate: nil,
            isRecurring: false,
            recurrencePattern: nil
        ),
        TaskTemplate(
            title: "Meeting Preparation",
            notes: "## Meeting Preparation\n\n**Meeting:** \n**Date & Time:** \n**Attendees:** \n\n### Agenda Items\n- \n\n### Questions to Ask\n- \n\n### Materials to Review\n- ",
            priority: .medium,
            dueDate: nil,
            isRecurring: false,
            recurrencePattern: nil
        ),
        TaskTemplate(
            title: "Learning & Development",
            notes: "## Learning & Development\n\n**Topic:** \n**Resource:** \n**Goal:** \n\n### Key Points\n- \n\n### Action Items\n- [ ] \n\n### Next Steps\n- ",
            priority: .medium,
            dueDate: nil,
            isRecurring: false,
            recurrencePattern: nil
        ),
        TaskTemplate(
            title: "Health & Wellness",
            notes: "## Health & Wellness\n\n### Exercise\n- [ ] \n\n### Nutrition\n- [ ] \n\n### Mental Health\n- [ ] \n\n### Sleep\n- [ ] ",
            priority: .high,
            dueDate: nil,
            isRecurring: true,
            recurrencePattern: "daily"
        ),
        TaskTemplate(
            title: "Financial Review",
            notes: "## Financial Review\n\n### Income\n- \n\n### Expenses\n- \n\n### Savings Goals\n- \n\n### Investment Review\n- ",
            priority: .medium,
            dueDate: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()),
            isRecurring: true,
            recurrencePattern: "monthly"
        ),
        TaskTemplate(
            title: "Home Maintenance",
            notes: "## Home Maintenance\n\n### Cleaning Tasks\n- [ ] \n- [ ] \n\n### Repairs Needed\n- [ ] \n- [ ] \n\n### Seasonal Tasks\n- [ ] ",
            priority: .low,
            dueDate: nil,
            isRecurring: false,
            recurrencePattern: nil
        )
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            List {
                ForEach(templates) { template in
                    Button(action: {
                        viewModel.createTaskFromTemplate(template)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(template.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Priority indicator
                                Circle()
                                    .fill(Color(template.priority.color))
                                    .frame(width: 12, height: 12)
                            }
                            
                            Text(template.notes.prefix(100) + "...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            HStack {
                                if let dueDate = template.dueDate {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                        Text(dueDate, formatter: dateFormatter)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                if template.isRecurring {
                                    HStack(spacing: 4) {
                                        Image(systemName: "repeat")
                                            .font(.caption)
                                        Text(template.recurrencePattern?.capitalized ?? "Recurring")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Task Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
struct TaskTemplatesView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let viewModel = TasksViewModel(dataManager: dataManager)
        
        TaskTemplatesView(viewModel: viewModel)
    }
}
