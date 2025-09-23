import SwiftUI
import CoreData

// MARK: - Task Form View

struct TaskFormView: View {
    let task: Task?
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var title = ""
    @State private var notes = ""
    @State private var selectedPriority: TaskPriority = .medium
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var selectedRecurring: RecurringType = .none
    @State private var category = ""
    @State private var selectedTab: TaskTab?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TaskTab.createdAt, ascending: true)]
    ) private var tabs: FetchedResults<TaskTab>
    
    private var isEditing: Bool { task != nil }
    
    var body: some View {
        NavigationView {
            Form {
                taskDetailsSection
                prioritySection
                dueDateSection
                recurringSection
                organizationSection
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            setupForm()
        }
    }
    
    private var taskDetailsSection: some View {
        Section("Task Details") {
            TextField("Task Title", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Notes (Optional)", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var prioritySection: some View {
        Section("Priority") {
            Picker("Priority", selection: $selectedPriority) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    HStack {
                        Circle()
                            .fill(priority.color)
                            .frame(width: 12, height: 12)
                        Text(priority.rawValue)
                    }
                    .tag(priority)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var dueDateSection: some View {
        Section("Due Date") {
            Toggle("Set Due Date", isOn: $hasDueDate)
            
            if hasDueDate {
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
            }
        }
    }
    
    private var recurringSection: some View {
        Section("Recurring") {
            Picker("Recurring", selection: $selectedRecurring) {
                ForEach(RecurringType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var organizationSection: some View {
        Section("Organization") {
            TextField("Category (Optional)", text: $category)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("Tab", selection: $selectedTab) {
                ForEach(tabs, id: \.id) { tab in
                    HStack {
                        Image(systemName: tab.iconName ?? "folder")
                        Text(tab.name ?? "Unnamed Tab")
                    }
                    .tag(tab as TaskTab?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private func setupForm() {
        if let task = task {
            title = task.title ?? ""
            notes = task.notes ?? ""
            selectedPriority = TaskPriority(rawValue: task.priority ?? "") ?? .medium
            if let dueDate = task.dueDate {
                self.dueDate = dueDate
                hasDueDate = true
            }
            selectedRecurring = RecurringType(rawValue: task.recurringType ?? "") ?? .none
            category = task.category ?? ""
            selectedTab = task.tab
        } else {
            selectedTab = tabs.first
        }
    }
    
    private func saveTask() {
        let taskToSave = task ?? Task(context: context)
        
        taskToSave.title = title
        taskToSave.notes = notes.isEmpty ? nil : notes
        taskToSave.priority = selectedPriority.rawValue
        taskToSave.dueDate = hasDueDate ? dueDate : nil
        taskToSave.recurringType = selectedRecurring == .none ? nil : selectedRecurring.rawValue
        taskToSave.category = category.isEmpty ? nil : category
        taskToSave.tab = selectedTab
        
        do {
            try context.save()
            onSave()
            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}
