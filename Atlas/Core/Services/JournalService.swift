import Foundation
import CoreData
import SwiftUI

// MARK: - Journal Service
@MainActor
class JournalService: ObservableObject {
    static let shared = JournalService()
    
    private let repository: JournalRepositoryProtocol
    private let encryptionService: EncryptionServiceProtocol
    
    @Published var entries: [JournalEntry] = []
    @Published var moodEntries: [MoodEntry] = []
    @Published var templates: [JournalTemplate] = []
    @Published var prompts: [JournalPrompt] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    
    private init() {
        // Initialize with dependencies
        self.encryptionService = EncryptionService()
        self.repository = JournalRepository(
            coreDataStack: CoreDataStack.shared,
            encryptionService: encryptionService
        )
        
        // Load initial data
        _Concurrency.Task {
            await loadAllData()
        }
    }
    
    // MARK: - Data Loading
    func loadAllData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedEntries = try repository.fetchJournalEntries()
            let fetchedMoodEntries = try repository.fetchMoodEntries(dateRange: nil)
            let fetchedTemplates = try repository.fetchTemplates(for: .daily)
            let fetchedPrompts = try repository.fetchPrompts(for: .daily)
            
            entries = fetchedEntries
            moodEntries = fetchedMoodEntries
            templates = fetchedTemplates
            prompts = fetchedPrompts
            
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Journal Entries
    func createEntry(title: String?, content: String, type: JournalEntryType, isEncrypted: Bool = false) async {
        do {
            let newEntry = try repository.createJournalEntry(
                title: title,
                content: content,
                type: type,
                isEncrypted: isEncrypted
            )
            
            entries.insert(newEntry, at: 0)
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    func updateEntry(_ entry: JournalEntry, title: String?, content: String) async {
        do {
            let updatedEntry = try repository.updateJournalEntry(entry, title: title, content: content)
            
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries[index] = updatedEntry
            }
            
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    func deleteEntry(_ entry: JournalEntry) async {
        do {
            try await repository.deleteJournalEntry(entry)
            entries.removeAll { $0.id == entry.id }
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Mood Entries
    func logMood(level: Int, scale: MoodScale, emoji: String? = nil, notes: String? = nil) async {
        do {
            let moodEntry = try repository.createMoodEntry(
                moodLevel: level,
                scale: scale,
                emoji: emoji,
                notes: notes
            )
            
            moodEntries.insert(moodEntry, at: 0)
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    func deleteMoodEntry(_ moodEntry: MoodEntry) async {
        do {
            try await repository.deleteMoodEntry(moodEntry)
            moodEntries.removeAll { $0.id == moodEntry.id }
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Templates
    func loadTemplates(for type: JournalEntryType) async {
        do {
            templates = try repository.fetchTemplates(for: type)
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    func createTemplate(name: String, type: JournalEntryType, content: String) async {
        do {
            let template = try repository.createTemplate(name: name, type: type, content: content, isBuiltIn: false)
            templates.append(template)
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    func deleteTemplate(_ template: JournalTemplate) async {
        do {
            try await repository.deleteTemplate(template)
            templates.removeAll { $0.id == template.id }
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Prompts
    func loadPrompts(for type: JournalEntryType) async {
        do {
            prompts = try repository.fetchPrompts(for: type)
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    func createPrompt(text: String, type: JournalEntryType) async {
        do {
            let prompt = try repository.createPrompt(text: text, type: type, isCustom: true)
            prompts.append(prompt)
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    func deletePrompt(_ prompt: JournalPrompt) async {
        do {
            try await repository.deletePrompt(prompt)
            prompts.removeAll { $0.id == prompt.id }
            clearError()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Analytics
    func getMoodAnalytics(for timeframe: MoodTimeframe) async -> MoodAnalytics? {
        do {
            return try await repository.getMoodAnalytics(for: timeframe)
        } catch {
            handleError(error)
            return nil
        }
    }
    
    // MARK: - Search and Filtering
    func searchEntries(query: String, type: JournalEntryType? = nil) -> [JournalEntry] {
        var filtered = entries
        
        if let type = type {
            filtered = filtered.filter { $0.type == type.rawValue }
        }
        
        if !query.isEmpty {
            filtered = filtered.filter { entry in
                entry.content?.localizedCaseInsensitiveContains(query) == true ||
                (entry.title?.localizedCaseInsensitiveContains(query) ?? false) ||
                (entry.tags?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        
        return filtered
    }
    
    func getRecentMoodEntries(limit: Int = 10) -> [MoodEntry] {
        return Array(moodEntries.prefix(limit))
    }
    
    func getEntriesForDate(_ date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            guard let createdAt = entry.createdAt else { return false }
            return calendar.isDate(createdAt, inSameDayAs: date)
        }
    }
    
    func getMoodEntriesForDate(_ date: Date) -> [MoodEntry] {
        let calendar = Calendar.current
        return moodEntries.filter { entry in
            guard let createdAt = entry.createdAt else { return false }
            return calendar.isDate(createdAt, inSameDayAs: date)
        }
    }
    
    // MARK: - Statistics
    func getJournalStatistics() -> JournalStatistics {
        let totalEntries = entries.count
        let encryptedEntries = entries.filter { $0.isEncrypted }.count
        let entriesToday = getEntriesForDate(Date()).count
        let totalWordCount = entries.reduce(0) { $0 + Int($1.wordCount) }
        let averageWordCount = totalEntries > 0 ? totalWordCount / totalEntries : 0
        
        let moodEntriesCount = moodEntries.count
        let averageMood = moodEntries.isEmpty ? 0.0 : 
            Double(moodEntries.reduce(0) { $0 + Int($1.moodLevel) }) / Double(moodEntries.count)
        
        return JournalStatistics(
            totalEntries: totalEntries,
            encryptedEntries: encryptedEntries,
            entriesToday: entriesToday,
            totalWordCount: totalWordCount,
            averageWordCount: averageWordCount,
            moodEntriesCount: moodEntriesCount,
            averageMood: averageMood
        )
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        lastError = error
        print("❌ JournalService Error: \(error)")
    }
    
    private func clearError() {
        lastError = nil
    }
}

// MARK: - Journal Statistics
struct JournalStatistics {
    let totalEntries: Int
    let encryptedEntries: Int
    let entriesToday: Int
    let totalWordCount: Int
    let averageWordCount: Int
    let moodEntriesCount: Int
    let averageMood: Double
    
    var encryptionPercentage: Double {
        guard totalEntries > 0 else { return 0 }
        return Double(encryptedEntries) / Double(totalEntries) * 100
    }
    
    var hasRecentActivity: Bool {
        return entriesToday > 0
    }
    
    var averageMoodDescription: String {
        switch averageMood {
        case 0..<3: return "Low"
        case 3..<5: return "Below Average"
        case 5..<7: return "Average"
        case 7..<9: return "Good"
        default: return "Excellent"
        }
    }
}
