import SwiftUI

struct CreateTaskView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var priority: TaskPriority = .medium
    @State private var dueDate: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var isRecurring: Bool = false
    @State private var recurrencePattern: String = "daily"
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Task Details") {
                        TextField("Task Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
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
                    }
                    
                    Section("Due Date") {
                        Toggle("Set Due Date", isOn: $hasDueDate)
                        
                        if hasDueDate {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                    
                    Section("Recurring") {
                        Toggle("Recurring Task", isOn: $isRecurring)
                        
                        if isRecurring {
                            Picker("Recurrence", selection: $recurrencePattern) {
                                Text("Daily").tag("daily")
                                Text("Weekly").tag("weekly")
                                Text("Monthly").tag("monthly")
                                Text("Yearly").tag("yearly")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("New Task")
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
                    .disabled(title.isEmpty || viewModel.isLoading)
                }
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    private func saveTask() {
        guard !title.isEmpty else { return }
        
        viewModel.createTask(
            title: title,
            notes: notes,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            isRecurring: isRecurring,
            recurrencePattern: isRecurring ? recurrencePattern : nil
        )
    }
}

// MARK: - Preview
struct CreateTaskView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let viewModel = TasksViewModel(dataManager: dataManager)
        
        CreateTaskView(viewModel: viewModel)
    }
}

