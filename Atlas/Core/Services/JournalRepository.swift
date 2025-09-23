import Foundation
import CoreData

// MARK: - Journal Repository Protocol
@MainActor
protocol JournalRepositoryProtocol {
    func fetchJournalEntries() throws -> [JournalEntry]
    func createJournalEntry(title: String?, content: String, type: JournalEntryType, isEncrypted: Bool) throws -> JournalEntry
    func updateJournalEntry(_ entry: JournalEntry, title: String?, content: String) throws -> JournalEntry
    func deleteJournalEntry(_ entry: JournalEntry) throws
    
    func fetchMoodEntries(dateRange: ClosedRange<Date>?) throws -> [MoodEntry]
    func createMoodEntry(moodLevel: Int, scale: MoodScale, emoji: String?, notes: String?) throws -> MoodEntry
    
    func fetchTemplates(for type: JournalEntryType?) throws -> [JournalTemplate]
    func createTemplate(name: String, type: JournalEntryType, content: String, isBuiltIn: Bool) throws -> JournalTemplate
    func updateTemplate(_ template: JournalTemplate, name: String, content: String) throws -> JournalTemplate
    func deleteTemplate(_ template: JournalTemplate) throws
    
    func fetchPrompts(for type: JournalEntryType?) throws -> [JournalPrompt]
    func createPrompt(text: String, type: JournalEntryType, isCustom: Bool) throws -> JournalPrompt
    func deletePrompt(_ prompt: JournalPrompt) throws
    
    func deleteMoodEntry(_ moodEntry: MoodEntry) throws
    
    func getMoodAnalytics(for timeframe: MoodTimeframe) throws -> MoodAnalytics
}

// MARK: - Journal Repository Implementation
@MainActor
class JournalRepository: JournalRepositoryProtocol {
    private let coreDataStack: CoreDataStack
    private let encryptionService: EncryptionServiceProtocol
    
    init(coreDataStack: CoreDataStack, encryptionService: EncryptionServiceProtocol) {
        self.coreDataStack = coreDataStack
        self.encryptionService = encryptionService
    }
    
    // MARK: - Journal Entries
    func fetchJournalEntries() throws -> [JournalEntry] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        return try context.fetch(request)
    }
    
    func createJournalEntry(title: String?, content: String, type: JournalEntryType, isEncrypted: Bool) throws -> JournalEntry {
        let context = coreDataStack.viewContext
        let entry = JournalEntry(context: context)
        entry.uuid = UUID()
        entry.title = title
        entry.content = content
        entry.type = type.rawValue
        entry.isEncrypted = isEncrypted
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.wordCount = Int32(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        entry.readingTime = Int32(max(1, entry.wordCount / 200))
        
        if isEncrypted {
            let encryptedData = try encryptionService.encrypt(content)
            entry.encryptedContent = try JSONEncoder().encode(encryptedData)
            entry.content = nil
        }
        
        try context.save()
        return entry
    }
    
    func updateJournalEntry(_ entry: JournalEntry, title: String?, content: String) throws -> JournalEntry {
        let context = coreDataStack.viewContext
        entry.title = title
        entry.content = content
        entry.updatedAt = Date()
        entry.wordCount = Int32(content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count)
        entry.readingTime = Int32(max(1, entry.wordCount / 200))
        
        if entry.isEncrypted {
            let encryptedData = try encryptionService.encrypt(content)
            entry.encryptedContent = try JSONEncoder().encode(encryptedData)
            entry.content = nil
        }
        
        try context.save()
        return entry
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) throws {
        let context = coreDataStack.viewContext
        context.delete(entry)
        try context.save()
    }
    
    // MARK: - Mood Entries
    func fetchMoodEntries(dateRange: ClosedRange<Date>?) throws -> [MoodEntry] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.createdAt, ascending: false)]
        
        if let dateRange = dateRange {
            request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                          dateRange.lowerBound as NSDate, 
                                          dateRange.upperBound as NSDate)
        }
        
        return try context.fetch(request)
    }
    
    func createMoodEntry(moodLevel: Int, scale: MoodScale, emoji: String?, notes: String?) throws -> MoodEntry {
        let context = coreDataStack.viewContext
        let moodEntry = MoodEntry(context: context)
        moodEntry.uuid = UUID()
        moodEntry.moodLevel = Int16(moodLevel)
        moodEntry.scale = scale.rawValue
        moodEntry.emoji = emoji
        moodEntry.notes = notes
        moodEntry.createdAt = Date()
        moodEntry.updatedAt = Date()
        
        try context.save()
        return moodEntry
    }
    
    // MARK: - Templates
    func fetchTemplates(for type: JournalEntryType?) throws -> [JournalTemplate] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<JournalTemplate> = JournalTemplate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalTemplate.name, ascending: true)]
        
        if let type = type {
            request.predicate = NSPredicate(format: "type == %@", type.rawValue)
        }
        
        return try context.fetch(request)
    }
    
    func createTemplate(name: String, type: JournalEntryType, content: String, isBuiltIn: Bool) throws -> JournalTemplate {
        let context = coreDataStack.viewContext
        let template = JournalTemplate(context: context)
        template.uuid = UUID()
        template.name = name
        template.type = type.rawValue
        template.content = content
        template.isBuiltIn = isBuiltIn
        template.createdAt = Date()
        template.updatedAt = Date()
        template.usageCount = 0
        
        try context.save()
        return template
    }
    
    func updateTemplate(_ template: JournalTemplate, name: String, content: String) throws -> JournalTemplate {
        let context = coreDataStack.viewContext
        template.name = name
        template.content = content
        template.updatedAt = Date()
        
        try context.save()
        return template
    }
    
    func deleteTemplate(_ template: JournalTemplate) throws {
        let context = coreDataStack.viewContext
        context.delete(template)
        try context.save()
    }
    
    // MARK: - Prompts
    func fetchPrompts(for type: JournalEntryType?) throws -> [JournalPrompt] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<JournalPrompt> = JournalPrompt.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalPrompt.text, ascending: true)]
        
        if let type = type {
            request.predicate = NSPredicate(format: "type == %@", type.rawValue)
        }
        
        return try context.fetch(request)
    }
    
    func createPrompt(text: String, type: JournalEntryType, isCustom: Bool) throws -> JournalPrompt {
        let context = coreDataStack.viewContext
        let prompt = JournalPrompt(context: context)
        prompt.uuid = UUID()
        prompt.text = text
        prompt.type = type.rawValue
        prompt.isCustom = isCustom
        prompt.createdAt = Date()
        prompt.updatedAt = Date()
        prompt.usageCount = 0
        
        try context.save()
        return prompt
    }
    
    func deleteMoodEntry(_ moodEntry: MoodEntry) throws {
        let context = coreDataStack.viewContext
        context.delete(moodEntry)
        try context.save()
    }
    
    func deletePrompt(_ prompt: JournalPrompt) throws {
        let context = coreDataStack.viewContext
        context.delete(prompt)
        try context.save()
    }
    
    // MARK: - Analytics
    func getMoodAnalytics(for timeframe: MoodTimeframe) throws -> MoodAnalytics {
        let context = coreDataStack.viewContext
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.createdAt, ascending: true)]
        
        let moodEntries = try context.fetch(request)
        
        guard !moodEntries.isEmpty else {
            return MoodAnalytics(
                averageMood: 0,
                totalEntries: 0,
                bestMood: 0,
                consistencyScore: 0,
                moodTrend: [],
                bestDay: nil
            )
        }
        
        let moods = moodEntries.map { Int($0.moodLevel) }
        let averageMood = moods.reduce(0, +) / moods.count
        let bestMood = moods.max() ?? 0
        let totalEntries = moodEntries.count
        
        // Calculate consistency (simplified)
        let consistencyScore = min(100, max(0, 100 - ((moods.max() ?? 0) - (moods.min() ?? 0))))
        
        // Create mood trend data
        let moodTrend: [MoodDataPoint] = moodEntries
            .filter { $0.createdAt != nil }
            .map { entry in
                MoodDataPoint(
                    date: entry.createdAt!,
                    moodValue: Double(entry.moodLevel),
                    emoji: entry.emoji ?? "😐"
                )
            }
        
        // Find best day (simplified - just the day with highest mood)
        let bestDay = moodEntries.max { $0.moodLevel < $1.moodLevel }?.createdAt
        
        return MoodAnalytics(
            averageMood: averageMood,
            totalEntries: totalEntries,
            bestMood: bestMood,
            consistencyScore: consistencyScore,
            moodTrend: moodTrend,
            bestDay: bestDay
        )
    }
}

// MARK: - Analytics Models
struct MoodAnalytics {
    let averageMood: Int
    let totalEntries: Int
    let bestMood: Int
    let consistencyScore: Int
    let moodTrend: [MoodDataPoint]
    let bestDay: Date?
}

// MARK: - Journal Errors
enum JournalError: LocalizedError {
    case entryNotFound
    case encryptionFailed(Error)
    case decryptionFailed(Error)
    case templateNotFound
    case promptNotFound
    
    var errorDescription: String? {
        switch self {
        case .entryNotFound:
            return "Journal entry not found"
        case .encryptionFailed(let error):
            return "Encryption failed: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "Decryption failed: \(error.localizedDescription)"
        case .templateNotFound:
            return "Template not found"
        case .promptNotFound:
            return "Prompt not found"
        }
    }
}