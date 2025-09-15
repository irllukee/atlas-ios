import SwiftUI

/// View for filtering and sorting notes
struct NotesFilterView: View {
    
    // MARK: - Properties
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var sortOrder: NoteSortOrder = .updatedAtDescending
    @State private var showEncryptedOnly = false
    @State private var showRecentOnly = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                
                Section("Sort Order") {
                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(NoteSortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Additional Filters") {
                    Toggle("Show Encrypted Notes Only", isOn: $showEncryptedOnly)
                    Toggle("Show Recent Notes Only (This Week)", isOn: $showRecentOnly)
                }
                
                Section("Quick Actions") {
                    Button("Clear All Filters") {
                        clearAllFilters()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to Default") {
                        resetToDefault()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
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
        sortOrder = viewModel.sortOrder
    }
    
    private func applyFilters() {
        viewModel.changeSortOrder(sortOrder)
        dismiss()
    }
    
    private func clearAllFilters() {
        sortOrder = .updatedAtDescending
        showEncryptedOnly = false
        showRecentOnly = false
    }
    
    private func resetToDefault() {
        clearAllFilters()
        applyFilters()
    }
}

// MARK: - Preview
struct NotesFilterView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        let viewModel = NotesViewModel(dataManager: dataManager, encryptionService: encryptionService)
        
        NotesFilterView(viewModel: viewModel)
    }
}
