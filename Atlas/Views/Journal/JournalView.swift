import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel: JournalViewModel
    @State private var selectedDate: Date = Date() // Local state for DatePicker
    
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self._viewModel = StateObject(wrappedValue: JournalViewModel(dataManager: dataManager, encryptionService: encryptionService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filters
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search journal entries...", text: $viewModel.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Filter controls
                    HStack {
                        // Type filter
                        Picker("Type", selection: $viewModel.selectedType) {
                            Text("All Types").tag(nil as JournalEntryType?)
                            ForEach(JournalEntryType.allCases) { type in
                                Text(type.rawValue).tag(type as JournalEntryType?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Spacer()
                        
                        // Date filter
                        DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                            .onChange(of: selectedDate) { _, newDate in
                                viewModel.filterByDate(newDate)
                            }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                // Journal entries list
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading journal entries...")
                    Spacer()
                } else if viewModel.filteredEntries.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No journal entries found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if !viewModel.searchText.isEmpty || viewModel.selectedType != nil || viewModel.selectedDate != nil {
                            Text("Try adjusting your filters")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Start writing your first entry")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredEntries, id: \.id) { entry in
                            JournalEntryRow(entry: entry, viewModel: viewModel)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingCreateEntry.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateEntry) {
                CreateJournalEntryView(viewModel: viewModel)
            }
        }
    }
    
    private func deleteEntries(offsets: IndexSet) {
        for index in offsets {
            let entry = viewModel.filteredEntries[index]
            viewModel.deleteJournalEntry(entry)
        }
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry
    let viewModel: JournalViewModel
    
    private var entryType: JournalEntryType {
        if entry.isDream {
            return .dream
        } else if !(entry.gratitudeEntries?.isEmpty ?? true) {
            return .gratitude
        } else {
            return .daily
        }
    }
    
    private var moodLevel: MoodLevel? {
        return MoodLevel(rawValue: entry.mood)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entryType.icon)
                    .foregroundColor(.accentColor)
                
                Text(entryType.rawValue)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                if let mood = moodLevel {
                    Text(mood.emoji)
                        .font(.title2)
                }
                
                if entry.isEncrypted {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Text(viewModel.getJournalContent(entry))
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            if let prompt = entry.prompt, !prompt.isEmpty {
                Text("Prompt: \(prompt)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            HStack {
                if let createdAt = entry.createdAt {
                    Text(createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let updatedAt = entry.updatedAt, updatedAt != entry.createdAt {
                    Text("Edited")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalView(dataManager: DataManager.shared, encryptionService: EncryptionService.shared)
}
