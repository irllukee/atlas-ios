import Foundation
import CoreData
import Combine
import SwiftUI

enum JournalEntryType: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case dream = "Dream"
    case gratitude = "Gratitude"
    case reflection = "Reflection"
    
    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .daily: return "book.fill"
        case .dream: return "moon.fill"
        case .gratitude: return "heart.fill"
        case .reflection: return "lightbulb.fill"
        }
    }
}

enum MoodLevel: Int16, CaseIterable, Identifiable {
    case veryLow = 1
    case low = 2
    case neutral = 3
    case good = 4
    case excellent = 5
    
    var id: Int16 { self.rawValue }
    
    var emoji: String {
        switch self {
        case .veryLow: return "😢"
        case .low: return "😔"
        case .neutral: return "😐"
        case .good: return "😊"
        case .excellent: return "😄"
        }
    }
    
    var description: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var color: Color {
        switch self {
        case .veryLow: return .red
        case .low: return .orange
        case .neutral: return .gray
        case .good: return .blue
        case .excellent: return .green
        }
    }
}

@MainActor
class JournalService: ObservableObject {
    private let dataManager: DataManager
    private let encryptionService: EncryptionService
    
    @Published var journalEntries: [JournalEntry] = []
    @Published var filteredEntries: [JournalEntry] = []
    @Published var moodEntries: [MoodEntry] = []
    @Published var searchText: String = ""
    @Published var selectedType: JournalEntryType? = nil
    @Published var selectedDate: Date? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager, encryptionService: EncryptionService) {
        self.dataManager = dataManager
        self.encryptionService = encryptionService
        
        setupBindings()
        loadJournalEntries()
        loadMoodEntries()
    }
    
    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterEntries()
            }
            .store(in: &cancellables)
        
        $selectedType
            .sink { [weak self] _ in
                self?.filterEntries()
            }
            .store(in: &cancellables)
        
        $selectedDate
            .sink { [weak self] _ in
                self?.filterEntries()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Journal Entry Operations
    
    func createJournalEntry(
        content: String,
        type: JournalEntryType,
        mood: MoodLevel? = nil,
        gratitudeEntries: [String] = [],
        prompt: String? = nil,
        isEncrypted: Bool = false
    ) -> JournalEntry? {
        let context = dataManager.coreDataStack.viewContext
        
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.content = content
        entry.isDream = (type == .dream)
        entry.mood = mood?.rawValue ?? MoodLevel.neutral.rawValue
        entry.prompt = prompt
        entry.isEncrypted = isEncrypted
        entry.createdAt = Date()
        entry.updatedAt = Date()
        
        // Handle gratitude entries
        if !gratitudeEntries.isEmpty {
            entry.gratitudeEntries = gratitudeEntries.joined(separator: "|")
        }
        
        // Encrypt content if needed
        if isEncrypted {
            do {
                let encryptedData = try encryptionService.encrypt(content)
                entry.content = encryptedData.data.base64EncodedString()
            } catch {
                print("❌ Failed to encrypt journal entry: \(error)")
                return nil
            }
        }
        
        do {
            try context.save()
            loadJournalEntries()
            filterEntries()
            return entry
        } catch {
            print("❌ Failed to save journal entry: \(error)")
            return nil
        }
    }
    
    func updateJournalEntry(
        _ entry: JournalEntry,
        content: String? = nil,
        mood: MoodLevel? = nil,
        gratitudeEntries: [String]? = nil,
        prompt: String? = nil
    ) -> Bool {
        let context = dataManager.coreDataStack.viewContext
        
        if let content = content {
            if entry.isEncrypted {
                do {
                    let encryptedData = try encryptionService.encrypt(content)
                    entry.content = encryptedData.data.base64EncodedString()
                } catch {
                    print("❌ Failed to encrypt journal entry: \(error)")
                    return false
                }
            } else {
                entry.content = content
            }
        }
        
        if let mood = mood {
            entry.mood = mood.rawValue
        }
        
        if let gratitudeEntries = gratitudeEntries {
            entry.gratitudeEntries = gratitudeEntries.joined(separator: "|")
        }
        
        if let prompt = prompt {
            entry.prompt = prompt
        }
        
        entry.updatedAt = Date()
        
        do {
            try context.save()
            loadJournalEntries()
            filterEntries()
            return true
        } catch {
            print("❌ Failed to update journal entry: \(error)")
            return false
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) -> Bool {
        let context = dataManager.coreDataStack.viewContext
        context.delete(entry)
        
        do {
            try context.save()
            loadJournalEntries()
            filterEntries()
            return true
        } catch {
            print("❌ Failed to delete journal entry: \(error)")
            return false
        }
    }
    
    // MARK: - Mood Entry Operations
    
    func createMoodEntry(
        rating: MoodLevel,
        emoji: String? = nil,
        notes: String? = nil,
        journalEntry: JournalEntry? = nil
    ) -> MoodEntry? {
        let context = dataManager.coreDataStack.viewContext
        
        let moodEntry = MoodEntry(context: context)
        moodEntry.id = UUID()
        moodEntry.rating = rating.rawValue
        moodEntry.emoji = emoji ?? rating.emoji
        moodEntry.notes = notes
        moodEntry.journalEntry = journalEntry
        moodEntry.createdAt = Date()
        moodEntry.updatedAt = Date()
        
        do {
            try context.save()
            loadMoodEntries()
            return moodEntry
        } catch {
            print("❌ Failed to save mood entry: \(error)")
            return nil
        }
    }
    
    func updateMoodEntry(
        _ moodEntry: MoodEntry,
        rating: MoodLevel? = nil,
        emoji: String? = nil,
        notes: String? = nil
    ) -> Bool {
        if let rating = rating {
            moodEntry.rating = rating.rawValue
        }
        
        if let emoji = emoji {
            moodEntry.emoji = emoji
        }
        
        if let notes = notes {
            moodEntry.notes = notes
        }
        
        moodEntry.updatedAt = Date()
        
        do {
            try dataManager.coreDataStack.viewContext.save()
            loadMoodEntries()
            return true
        } catch {
            print("❌ Failed to update mood entry: \(error)")
            return false
        }
    }
    
    func deleteMoodEntry(_ moodEntry: MoodEntry) -> Bool {
        let context = dataManager.coreDataStack.viewContext
        context.delete(moodEntry)
        
        do {
            try context.save()
            loadMoodEntries()
            return true
        } catch {
            print("❌ Failed to delete mood entry: \(error)")
            return false
        }
    }
    
    // MARK: - Data Retrieval
    
    func getJournalEntriesForDate(_ date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return journalEntries.filter { entry in
            guard let createdAt = entry.createdAt else { return false }
            return createdAt >= startOfDay && createdAt < endOfDay
        }
    }
    
    func getMoodEntriesForDate(_ date: Date) -> [MoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return moodEntries.filter { entry in
            guard let createdAt = entry.createdAt else { return false }
            return createdAt >= startOfDay && createdAt < endOfDay
        }
    }
    
    func getAverageMoodForDate(_ date: Date) -> MoodLevel? {
        let moodEntries = getMoodEntriesForDate(date)
        guard !moodEntries.isEmpty else { return nil }
        
        let averageRating = moodEntries.reduce(0) { $0 + $1.rating } / Int16(moodEntries.count)
        return MoodLevel(rawValue: averageRating)
    }
    
    func getGratitudeEntries(_ journalEntry: JournalEntry) -> [String] {
        guard let gratitudeString = journalEntry.gratitudeEntries else { return [] }
        return gratitudeString.components(separatedBy: "|").filter { !$0.isEmpty }
    }
    
    func decryptJournalContent(_ entry: JournalEntry) -> String? {
        guard let encryptedContent = entry.content, entry.isEncrypted else {
            return entry.content
        }
        
        do {
            guard let encryptedData = Data(base64Encoded: encryptedContent) else {
                print("❌ Failed to decode base64 encrypted content")
                return nil
            }
            let decryptedData = try encryptionService.decrypt(EncryptedData(data: encryptedData, timestamp: Date(), version: "1"))
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("❌ Failed to decrypt journal entry: \(error)")
            return nil
        }
    }
    
    // MARK: - Filtering and Search
    
    private func filterEntries() {
        var entriesToFilter = journalEntries
        
        // Apply search text filter
        if !searchText.isEmpty {
            entriesToFilter = entriesToFilter.filter { entry in
                let content = decryptJournalContent(entry) ?? entry.content ?? ""
                return content.localizedCaseInsensitiveContains(searchText) ||
                       (entry.prompt?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply type filter
        if let selectedType = selectedType {
            entriesToFilter = entriesToFilter.filter { entry in
                switch selectedType {
                case .daily:
                    return !entry.isDream && entry.gratitudeEntries?.isEmpty ?? true
                case .dream:
                    return entry.isDream
                case .gratitude:
                    return !(entry.gratitudeEntries?.isEmpty ?? true)
                case .reflection:
                    return !entry.isDream && !(entry.gratitudeEntries?.isEmpty ?? true)
                }
            }
        }
        
        // Apply date filter
        if let selectedDate = selectedDate {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            entriesToFilter = entriesToFilter.filter { entry in
                guard let createdAt = entry.createdAt else { return false }
                return createdAt >= startOfDay && createdAt < endOfDay
            }
        }
        
        // Sort by creation date (newest first)
        entriesToFilter.sort { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        
        filteredEntries = entriesToFilter
    }
    
    // MARK: - Private Helpers
    
    private func loadJournalEntries() {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        
        do {
            journalEntries = try dataManager.coreDataStack.viewContext.fetch(request)
            filterEntries()
        } catch {
            print("❌ Failed to fetch journal entries: \(error)")
            errorMessage = "Failed to load journal entries"
        }
    }
    
    private func loadMoodEntries() {
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.createdAt, ascending: false)]
        
        do {
            moodEntries = try dataManager.coreDataStack.viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch mood entries: \(error)")
            errorMessage = "Failed to load mood entries"
        }
    }
}

// MARK: - Journal Templates
struct JournalTemplate: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let type: JournalEntryType
    let mood: MoodLevel?
    let gratitudeEntries: [String]
    let prompt: String?
    let isEncrypted: Bool
}

// MARK: - Journal Templates
extension JournalTemplate {
    static let templates: [JournalTemplate] = [
        JournalTemplate(
            title: "Daily Reflection",
            content: "## Today's Highlights\n\n### What went well?\n- \n\n### What could be improved?\n- \n\n### Tomorrow's focus:\n- ",
            type: .daily,
            mood: nil,
            gratitudeEntries: [],
            prompt: "Reflect on your day and plan for tomorrow",
            isEncrypted: false
        ),
        JournalTemplate(
            title: "Dream Journal",
            content: "## Dream Entry\n\n### Dream Description\n\n\n### Emotions Felt\n- \n\n### Symbols & Meanings\n- \n\n### Interpretation\n",
            type: .dream,
            mood: nil,
            gratitudeEntries: [],
            prompt: "Record your dreams and explore their meanings",
            isEncrypted: false
        ),
        JournalTemplate(
            title: "Gratitude Practice",
            content: "## Gratitude Journal\n\n### Three things I'm grateful for today:\n1. \n2. \n3. \n\n### Why these matter to me:\n\n\n### How I can show gratitude:\n- ",
            type: .gratitude,
            mood: nil,
            gratitudeEntries: [],
            prompt: "Focus on the positive aspects of your life",
            isEncrypted: false
        ),
        JournalTemplate(
            title: "Private Thoughts",
            content: "## Private Reflection\n\n",
            type: .reflection,
            mood: nil,
            gratitudeEntries: [],
            prompt: "Your private space for personal thoughts",
            isEncrypted: true
        )
    ]
}
