import SwiftUI
import CoreData

/// Main Notes view with list, search, and filtering capabilities
struct NotesView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: NotesViewModel
    @State private var showingCreateNote = false
    @State private var showingFilters = false
    
    // MARK: - Initialization
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self._viewModel = StateObject(wrappedValue: NotesViewModel(dataManager: dataManager, encryptionService: encryptionService))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Statistics Bar
                statisticsBar
                
                // Notes List
                notesList
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("New Note") {
                            showingCreateNote = true
                        }
                        
                        Button("From Template") {
                            viewModel.showingTemplates = true
                        }
                        
                        Button("Filter & Sort") {
                            showingFilters = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateNote) {
                CreateNoteView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingTemplates) {
                NoteTemplatesView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingFilters) {
                NotesFilterView(viewModel: viewModel)
            }
            .sheet(item: $viewModel.selectedNote) { note in
                EditNoteView(note: note, viewModel: viewModel)
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search notes...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: viewModel.searchText) { newValue in
                    viewModel.searchNotes(query: newValue)
                }
            
            if !viewModel.searchText.isEmpty {
                Button("Clear") {
                    viewModel.searchText = ""
                    viewModel.searchNotes(query: "")
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    // MARK: - Statistics Bar
    private var statisticsBar: some View {
        let stats = viewModel.getStatistics()
        
        return HStack(spacing: 20) {
            StatisticItem(title: "Total", value: "\(stats.totalNotes)")
            StatisticItem(title: "Today", value: "\(stats.notesToday)")
            StatisticItem(title: "This Week", value: "\(stats.notesThisWeek)")
            StatisticItem(title: "Encrypted", value: "\(stats.encryptedNotes)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Notes List
    private var notesList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading notes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredNotes.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(viewModel.filteredNotes, id: \.id) { note in
                        NoteRowView(note: note) {
                            viewModel.selectNote(note)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                viewModel.deleteNote(note)
                            }
                            
                            Button("Edit") {
                                viewModel.selectNote(note)
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Notes Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if viewModel.searchText.isEmpty {
                Text("Create your first note to get started")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Create Note") {
                    showingCreateNote = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Try adjusting your search")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Clear Search") {
                    viewModel.clearFilters()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Supporting Views

struct StatisticItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NoteRowView: View {
    let note: Note
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(note.title ?? "Untitled")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if note.isEncrypted {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
                
                if let content = note.content, !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Spacer()
                    
                    Text(note.updatedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let encryptionService = EncryptionService.shared
        
        NotesView(dataManager: dataManager, encryptionService: encryptionService)
    }
}