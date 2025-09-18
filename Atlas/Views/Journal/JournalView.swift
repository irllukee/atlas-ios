import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel: JournalViewModel
    @State private var selectedDate: Date = Date() // Local state for DatePicker
    
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self._viewModel = StateObject(wrappedValue: JournalViewModel(dataManager: dataManager, encryptionService: encryptionService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and filters
                    VStack(spacing: 16) {
                        // Search bar
                        ModernSearchBar(
                            searchText: $viewModel.searchText,
                            placeholder: "Search journal entries...",
                            onSearch: { query in
                                // Search functionality handled by viewModel
                            },
                            onClear: {
                                viewModel.searchText = ""
                            }
                        )
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
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Date filter
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                                .onChange(of: selectedDate) { _, newDate in
                                    viewModel.filterByDate(newDate)
                                }
                                .colorScheme(.dark)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // Journal entries list
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading journal entries...")
                            .foregroundColor(.white)
                        Spacer()
                    } else if viewModel.filteredEntries.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("No journal entries found")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if !viewModel.searchText.isEmpty || viewModel.selectedType != nil || viewModel.selectedDate != nil {
                                Text("Try adjusting your filters")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                Text("Start writing your first entry")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(viewModel.filteredEntries, id: \.objectID) { entry in
                                JournalEntryRow(entry: entry, viewModel: viewModel)
                            }
                            .onDelete(perform: deleteEntries)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showingCreateEntry.toggle() }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entryType.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(entryType.color.opacity(0.2))
                    .foregroundColor(entryType.color)
                    .cornerRadius(8)
                
                Spacer()
                
                if let createdAt = entry.createdAt {
                    Text(createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(entry.content ?? "")
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            if let mood = MoodLevel(rawValue: entry.mood) {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundColor(mood.color)
                    Text(mood.description)
                        .font(.caption)
                        .foregroundColor(mood.color)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    JournalView(dataManager: DataManager.shared, encryptionService: EncryptionService.shared)
}