import Foundation
import Combine
import CoreData // Needed for JournalEntry and MoodEntry entities

@MainActor
class JournalViewModel: ObservableObject {
    // MARK: - Properties
    private let journalService: JournalService
    private let encryptionService: EncryptionService
    private var cancellables = Set<AnyCancellable>()
    
    @Published var journalEntries: [JournalEntry] = []
    @Published var filteredEntries: [JournalEntry] = []
    @Published var moodEntries: [MoodEntry] = []
    @Published var searchText: String = ""
    @Published var selectedType: JournalEntryType? = nil
    @Published var selectedDate: Date? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showingCreateJournalEntry: Bool = false
    @Published var showingTemplates: Bool = false
    @Published var showingMoodTracker: Bool = false
    @Published var showingCreateEntry: Bool = false    
    // MARK: - Initialization
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self.encryptionService = encryptionService
        self.journalService = JournalService(dataManager: dataManager, encryptionService: encryptionService)
        
        setupBindings()
    }
    
    private func setupBindings() {
        journalService.$journalEntries
            .assign(to: &$journalEntries)
        
        journalService.$filteredEntries
            .assign(to: &$filteredEntries)
        
        journalService.$moodEntries
            .assign(to: &$moodEntries)
        
        $searchText
            .assign(to: &journalService.$searchText)
        
        $selectedType
            .assign(to: &journalService.$selectedType)
        
        $selectedDate
            .sink { [weak self] date in
                self?.journalService.selectedDate = date
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load all journal entries
    func loadJournalEntries() {
        isLoading = true
        errorMessage = nil
        // Entries are loaded automatically through the service
        isLoading = false
    }
    
    /// Create a new journal entry
    @MainActor
    func createJournalEntry(
        content: String,
        type: JournalEntryType,
        mood: MoodLevel? = nil,
        gratitudeEntries: [String] = [],
        prompt: String? = nil,
        isEncrypted: Bool = false
    ) {
        isLoading = true
        errorMessage = nil
        
        let entry = journalService.createJournalEntry(
            content: content,
            type: type,
            mood: mood,
            gratitudeEntries: gratitudeEntries,
            prompt: prompt,
            isEncrypted: isEncrypted
        )
        
        if entry != nil {
            showingCreateJournalEntry = false
        } else {
            errorMessage = "Failed to create journal entry"
        }
        isLoading = false
    }
    
    /// Create a journal entry from template
    @MainActor
    func createJournalEntryFromTemplate(_ template: JournalTemplate) {
        isLoading = true
        errorMessage = nil
        
        let entry = journalService.createJournalEntry(
            content: template.content,
            type: template.type,
            mood: nil,
            gratitudeEntries: [],
            prompt: template.prompt,
            isEncrypted: template.isEncrypted
        )
        
        if entry != nil {
            showingTemplates = false
            showingCreateJournalEntry = false
        } else {
            errorMessage = "Failed to create journal entry from template"
        }
        isLoading = false
    }
    
    /// Update a journal entry
    @MainActor
    func updateJournalEntry(
        _ entry: JournalEntry,
        content: String? = nil,
        mood: MoodLevel? = nil,
        gratitudeEntries: [String]? = nil,
        prompt: String? = nil
    ) {
        isLoading = true
        errorMessage = nil
        
        let success = journalService.updateJournalEntry(
            entry,
            content: content,
            mood: mood,
            gratitudeEntries: gratitudeEntries,
            prompt: prompt
        )
        
        if !success {
            errorMessage = "Failed to update journal entry"
        }
        isLoading = false
    }
    
    /// Delete a journal entry
    @MainActor
    func deleteJournalEntry(_ entry: JournalEntry) {
        isLoading = true
        errorMessage = nil
        
        let success = journalService.deleteJournalEntry(entry)
        
        if !success {
            errorMessage = "Failed to delete journal entry"
        }
        isLoading = false
    }
    
    /// Create a mood entry
    @MainActor
    func createMoodEntry(
        rating: MoodLevel,
        emoji: String? = nil,
        notes: String? = nil,
        journalEntry: JournalEntry? = nil
    ) {
        isLoading = true
        errorMessage = nil
        
        let moodEntry = journalService.createMoodEntry(
            rating: rating,
            emoji: emoji,
            notes: notes,
            journalEntry: journalEntry
        )
        
        if moodEntry != nil {
            showingMoodTracker = false
        } else {
            errorMessage = "Failed to create mood entry"
        }
        isLoading = false
    }
    
    /// Update a mood entry
    @MainActor
    func updateMoodEntry(
        _ moodEntry: MoodEntry,
        rating: MoodLevel? = nil,
        emoji: String? = nil,
        notes: String? = nil
    ) {
        isLoading = true
        errorMessage = nil
        
        let success = journalService.updateMoodEntry(
            moodEntry,
            rating: rating,
            emoji: emoji,
            notes: notes
        )
        
        if !success {
            errorMessage = "Failed to update mood entry"
        }
        isLoading = false
    }
    
    /// Delete a mood entry
    @MainActor
    func deleteMoodEntry(_ moodEntry: MoodEntry) {
        isLoading = true
        errorMessage = nil
        
        let success = journalService.deleteMoodEntry(moodEntry)
        
        if !success {
            errorMessage = "Failed to delete mood entry"
        }
        isLoading = false
    }
    
    /// Search journal entries
    @MainActor
    func searchJournalEntries(query: String) {
        journalService.searchText = query
    }
    
    /// Filter journal entries by type
    @MainActor
    func filterByType(_ type: JournalEntryType?) {
        selectedType = type
        journalService.selectedType = type
    }
    
    /// Filter by date
    @MainActor
    func filterByDate(_ date: Date?) {
        selectedDate = date
    }
    
    // MARK: - Data Retrieval Helpers
    @MainActor
    func getJournalEntriesForDate(_ date: Date) -> [JournalEntry] {
        return journalService.getJournalEntriesForDate(date)
    }
    
    @MainActor
    func getMoodEntriesForDate(_ date: Date) -> [MoodEntry] {
        return journalService.getMoodEntriesForDate(date)
    }
    
    @MainActor
    func getGratitudeEntries(_ journalEntry: JournalEntry) -> [String] {
        return journalService.getGratitudeEntries(journalEntry)
    }
    
    @MainActor
    func decryptJournalContent(_ entry: JournalEntry) -> String? {
        return journalService.decryptJournalContent(entry)
    }
    
    @MainActor
    func getJournalContent(_ entry: JournalEntry) -> String {
        return decryptJournalContent(entry) ?? entry.content ?? ""
    }
    
    // MARK: - Statistics
    
    func getTotalEntriesCount() -> Int {
        return journalEntries.count
    }
    
    func getEntriesCountForType(_ type: JournalEntryType) -> Int {
        return journalEntries.filter { entry in
            switch type {
            case .daily:
                return !entry.isDream && (entry.gratitudeEntries?.isEmpty ?? true)
            case .dream:
                return entry.isDream
            case .gratitude:
                return !(entry.gratitudeEntries?.isEmpty ?? true)
            case .reflection:
                return !entry.isDream && !(entry.gratitudeEntries?.isEmpty ?? true)
            }
        }.count
    }
    
    func getAverageMood() -> Double {
        let moodValues = journalEntries.compactMap { entry in
            MoodLevel(rawValue: entry.mood)?.rawValue
        }
        
        guard !moodValues.isEmpty else { return 0 }
        return Double(moodValues.reduce(0, +)) / Double(moodValues.count)
    }
    
    @MainActor
    func getMoodTrend(days: Int = 7) -> [MoodLevel?] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        
        var trend: [MoodLevel?] = []
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: i, to: startDate)!
            let averageMood = journalService.getAverageMoodForDate(date)
            trend.append(averageMood)
        }
        
        return trend
    }}