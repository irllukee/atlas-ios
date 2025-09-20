import SwiftUI

struct TasksFilterView<ViewModel: TaskViewModelProtocol>: View {
    // MARK: - Properties
    @ObservedObject var viewModel: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFilter: TaskFilter = .all
    @State private var sortOrder: TaskSortOrder = .dueDateAscending
    @State private var showCompletedTasks = true
    @State private var showOverdueTasks = true
    @State private var showHighPriorityOnly = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section("Filter by Status") {
                    Picker("Status Filter", selection: $selectedFilter) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Sort Order") {
                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(TaskSortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Additional Filters") {
                    Toggle("Show Completed Tasks", isOn: $showCompletedTasks)
                    Toggle("Show Overdue Tasks", isOn: $showOverdueTasks)
                    Toggle("High Priority Only", isOn: $showHighPriorityOnly)
                }
                
                Section("Quick Filters") {
                    VStack(spacing: 12) {
                        HStack {
                            Button("Due Today") {
                                selectedFilter = .dueToday
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            
                            Button("Overdue") {
                                selectedFilter = .overdue
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        }
                        
                        HStack {
                            Button("High Priority") {
                                selectedFilter = .highPriority
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                            
                            Button("Pending") {
                                selectedFilter = .pending
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                
                Section {
                    Button("Apply Filters") {
                        applyFilters()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Clear All Filters") {
                        clearAllFilters()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Filter Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetToDefault()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentFilters()
            }
        }
    }
    
    // MARK: - Actions
    private func loadCurrentFilters() {
        selectedFilter = viewModel.selectedFilter
        sortOrder = viewModel.sortOrder
    }
    
    private func applyFilters() {
        viewModel.filterByStatus(selectedFilter)
        viewModel.changeSortOrder(sortOrder)
        dismiss()
    }
    
    private func clearAllFilters() {
        selectedFilter = .all
        sortOrder = .dueDateAscending
        showCompletedTasks = true
        showOverdueTasks = true
        showHighPriorityOnly = false
    }
    
    private func resetToDefault() {
        clearAllFilters()
        applyFilters()
    }
}

// MARK: - Preview
struct TasksFilterView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let viewModel = TasksViewModel(dataManager: dataManager)
        
        TasksFilterView(viewModel: viewModel)
    }
}

