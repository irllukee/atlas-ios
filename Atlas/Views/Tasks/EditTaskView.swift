import SwiftUI
import CoreData

struct EditTaskView: View {
    // MARK: - Properties
    @ObservedObject var task: Task
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var isRecurring: Bool = false
    @State private var recurrencePattern: String = "daily"
    @State private var hasChanges = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Task Details") {
                        TextField("Task Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: title) { checkForChanges() }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 150)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .onChange(of: notes) { checkForChanges() }
                        }
                    }
                    
                    Section("Priority") {
                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                HStack {
                                    Circle()
                                        .fill(Color(priority.color))
                                        .frame(width: 12, height: 12)
                                    Text(priority.displayName)
                                }
                                .tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: priority) { checkForChanges() }
                    }
                    
                    Section("Due Date") {
                        Toggle("Set Due Date", isOn: $hasDueDate)
                            .onChange(of: hasDueDate) { checkForChanges() }
                        
                        if hasDueDate {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: dueDate) { checkForChanges() }
                        }
                    }
                    
                    Section("Recurring") {
                        Toggle("Recurring Task", isOn: $isRecurring)
                            .onChange(of: isRecurring) { checkForChanges() }
                        
                        if isRecurring {
                            Picker("Recurrence", selection: $recurrencePattern) {
                                Text("Daily").tag("daily")
                                Text("Weekly").tag("weekly")
                                Text("Monthly").tag("monthly")
                                Text("Yearly").tag("yearly")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: recurrencePattern) { checkForChanges() }
                        }
                    }
                    
                    Section("Task Info") {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(task.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(task.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        if task.isCompleted {
                            HStack {
                                Text("Completed")
                                Spacer()
                                Text(task.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("Edit Task")
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
                    .disabled(!hasChanges || viewModel.isLoading)
                }
            }
            .onAppear {
                loadTaskData()
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView("Saving task...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            HStack(spacing: 12) {
                Button("Delete Task") {
                    deleteTask()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                
                Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                    toggleCompletion()
                }
                .buttonStyle(.bordered)
                .foregroundColor(task.isCompleted ? .orange : .green)
                .frame(maxWidth: .infinity)
                
                Button("Save Changes") {
                    saveTask()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!hasChanges || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    private func loadTaskData() {
        title = task.title ?? ""
        notes = task.notes ?? ""
        priority = TaskPriority(rawValue: task.priority) ?? .medium
        dueDate = task.dueDate ?? Date()
        hasDueDate = task.dueDate != nil
        isRecurring = task.isRecurring
        recurrencePattern = task.recurrencePattern ?? "daily"
    }
    
    private func checkForChanges() {
        hasChanges = title != (task.title ?? "") ||
                    notes != (task.notes ?? "") ||
                    priority.rawValue != task.priority ||
                    (hasDueDate ? dueDate : nil) != task.dueDate ||
                    isRecurring != task.isRecurring ||
                    (isRecurring ? recurrencePattern : nil) != task.recurrencePattern
    }
    
    private func saveTask() {
        guard hasChanges else { return }
        
        viewModel.updateTask(
            task,
            title: title,
            notes: notes,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil
        )
        
        dismiss()
    }
    
    private func deleteTask() {
        viewModel.deleteTask(task)
        dismiss()
    }
    
    private func toggleCompletion() {
        viewModel.toggleTaskCompletion(task)
    }
}

// MARK: - Preview
struct EditTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let viewModel = TasksViewModel(dataManager: dataManager)
        
        // Create a sample task for preview
        let task = createSampleTask()
        
        return EditTaskView(task: task, viewModel: viewModel)
    }
    
    private static func createSampleTask() -> Task {
        let context = PersistenceController.preview.container.viewContext
        let task = Task(context: context)
        task.title = "Sample Task"
        task.notes = "This is a sample task for preview purposes."
        task.createdAt = Date()
        task.updatedAt = Date()
        task.priority = 2
        task.isCompleted = false
        return task
    }
}

