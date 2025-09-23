import SwiftUI
import Combine
import CoreData

// MARK: - Journal View Model
@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var recentMoodEntries: [MoodEntry] = []
    @Published var filteredEntries: [JournalEntry] = []
    @Published var searchText = "" {
        didSet {
            applyFilters()
        }
    }
    @Published var selectedType: JournalEntryType? {
        didSet {
            applyFilters()
        }
    }
    @Published var isLoading = false
    
    private let repository: JournalRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: JournalRepositoryProtocol? = nil) {
        self.repository = repository ?? DependencyContainer.shared.journalRepository
        loadData()
    }
    
    func loadData() {
        _Concurrency.Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            
            do {
                entries = try repository.fetchJournalEntries()
                recentMoodEntries = try repository.fetchMoodEntries(dateRange: nil)
                applyFilters()
            } catch {
                print("Error loading journal data: \(error)")
            }
        }
    }
    
    func createEntry(title: String?, content: String, type: JournalEntryType, isEncrypted: Bool) {
        do {
            let newEntry = try repository.createJournalEntry(
                title: title,
                content: content,
                type: type,
                isEncrypted: isEncrypted
            )
            
            entries.insert(newEntry, at: 0)
            applyFilters()
        } catch {
            print("Error creating entry: \(error)")
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) {
        do {
            try repository.deleteJournalEntry(entry)
            entries.removeAll { $0.id == entry.id }
            applyFilters()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
    
    func logMood(level: Int, scale: MoodScale, emoji: String? = nil, notes: String? = nil) {
        do {
            let moodEntry = try repository.createMoodEntry(
                moodLevel: level,
                scale: scale,
                emoji: emoji,
                notes: notes
            )
            
            recentMoodEntries.insert(moodEntry, at: 0)
        } catch {
            print("Error logging mood: \(error)")
        }
    }
    
    private func applyFilters() {
        var filtered = entries
        
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type.rawValue }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.content?.localizedCaseInsensitiveContains(searchText) == true ||
                (entry.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        filteredEntries = filtered
    }
}

