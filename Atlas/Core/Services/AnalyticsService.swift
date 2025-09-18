import Foundation
import CoreData
import SwiftUI
import Charts

/// Advanced analytics service for tracking productivity, habits, and insights
@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var productivityMetrics: ProductivityMetrics = ProductivityMetrics()
    @Published var habitData: [HabitData] = []
    @Published var moodTrends: [MoodTrend] = []
    @Published var noteStatistics: NoteStatistics = NoteStatistics()
    @Published var taskAnalytics: TaskAnalytics = TaskAnalytics()
    
    private let dataManager = DataManager.shared
    private let errorHandler = ErrorHandler.shared
    
    private init() {
        loadAnalytics()
    }
    
    // MARK: - Data Models
    
    struct ProductivityMetrics {
        var notesCreatedToday: Int = 0
        var tasksCompletedToday: Int = 0
        var journalEntriesToday: Int = 0
        var totalWordsWritten: Int = 0
        var averageSessionLength: TimeInterval = 0
        var productivityScore: Double = 0.0
        var streakDays: Int = 0
        var lastActiveDate: Date = Date()
    }
    
    struct HabitData: Identifiable {
        let id = UUID()
        let date: Date
        let habitType: HabitType
        let value: Double
        let goal: Double
        
        enum HabitType: String, CaseIterable {
            case notesCreated = "Notes Created"
            case tasksCompleted = "Tasks Completed"
            case journalEntries = "Journal Entries"
            case wordsWritten = "Words Written"
            case moodLogged = "Mood Logged"
        }
    }
    
    struct MoodTrend: Identifiable {
        let id = UUID()
        let date: Date
        let averageMood: Double
        let moodCount: Int
        let dominantEmotion: String
    }
    
    struct NoteStatistics {
        var totalNotes: Int = 0
        var notesThisWeek: Int = 0
        var notesThisMonth: Int = 0
        var averageNoteLength: Double = 0
        var mostProductiveDay: String = ""
        var favoriteNoteCategory: String = ""
        var notesWithImages: Int = 0
        var notesWithTables: Int = 0
    }
    
    struct TaskAnalytics {
        var totalTasks: Int = 0
        var completedTasks: Int = 0
        var completionRate: Double = 0.0
        var averageCompletionTime: TimeInterval = 0
        var mostProductiveCategory: String = ""
        var overdueTasks: Int = 0
        var tasksThisWeek: Int = 0
    }
    
    // MARK: - Analytics Loading
    
    func loadAnalytics() {
        loadProductivityMetrics()
        loadHabitData()
        loadMoodTrends()
        loadNoteStatistics()
        loadTaskAnalytics()
    }
    
    private func loadProductivityMetrics() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Notes created today
        let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        notesRequest.predicate = NSPredicate(format: "createdAt >= %@", today as NSDate)
        let notesToday = (try? dataManager.coreDataStack.viewContext.fetch(notesRequest))?.count ?? 0
        
        // Tasks completed today
        let tasksRequest: NSFetchRequest<Task> = Task.fetchRequest()
        tasksRequest.predicate = NSPredicate(format: "isCompleted == YES AND completedAt >= %@", today as NSDate)
        let tasksToday = (try? dataManager.coreDataStack.viewContext.fetch(tasksRequest))?.count ?? 0
        
        // Journal entries today
        let journalRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        journalRequest.predicate = NSPredicate(format: "createdAt >= %@", today as NSDate)
        let journalToday = (try? dataManager.coreDataStack.viewContext.fetch(journalRequest))?.count ?? 0
        
        // Calculate total words written
        let allNotesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let allNotes = (try? dataManager.coreDataStack.viewContext.fetch(allNotesRequest)) ?? []
        let totalWords = allNotes.reduce(0) { $0 + ($1.content?.components(separatedBy: .whitespacesAndNewlines).count ?? 0) }
        
        // Calculate productivity score (0-100)
        let productivityScore = calculateProductivityScore(
            notes: notesToday,
            tasks: tasksToday,
            journal: journalToday,
            words: totalWords
        )
        
        // Calculate streak
        let streak = calculateStreakDays()
        
        productivityMetrics = ProductivityMetrics(
            notesCreatedToday: notesToday,
            tasksCompletedToday: tasksToday,
            journalEntriesToday: journalToday,
            totalWordsWritten: totalWords,
            averageSessionLength: 0, // TODO: Implement session tracking
            productivityScore: productivityScore,
            streakDays: streak,
            lastActiveDate: Date()
        )
    }
    
    private func loadHabitData() {
        let calendar = Calendar.current
        let endDate = Date()
        _ = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        var habits: [HabitData] = []
        
        // Generate habit data for the last 30 days
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            // Notes created
            let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
            notesRequest.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", dayStart as NSDate, dayEnd as NSDate)
            let notesCount = (try? dataManager.coreDataStack.viewContext.fetch(notesRequest))?.count ?? 0
            
            // Tasks completed
            let tasksRequest: NSFetchRequest<Task> = Task.fetchRequest()
            tasksRequest.predicate = NSPredicate(format: "isCompleted == YES AND completedAt >= %@ AND completedAt < %@", dayStart as NSDate, dayEnd as NSDate)
            let tasksCount = (try? dataManager.coreDataStack.viewContext.fetch(tasksRequest))?.count ?? 0
            
            // Journal entries
            let journalRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
            journalRequest.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", dayStart as NSDate, dayEnd as NSDate)
            let journalCount = (try? dataManager.coreDataStack.viewContext.fetch(journalRequest))?.count ?? 0
            
            habits.append(HabitData(date: date, habitType: .notesCreated, value: Double(notesCount), goal: 3.0))
            habits.append(HabitData(date: date, habitType: .tasksCompleted, value: Double(tasksCount), goal: 5.0))
            habits.append(HabitData(date: date, habitType: .journalEntries, value: Double(journalCount), goal: 1.0))
        }
        
        habitData = habits.reversed() // Most recent first
    }
    
    private func loadMoodTrends() {
        let calendar = Calendar.current
        let endDate = Date()
        
        var trends: [MoodTrend] = []
        
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
            request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", dayStart as NSDate, dayEnd as NSDate)
            
            if let moodEntries = try? dataManager.coreDataStack.viewContext.fetch(request), !moodEntries.isEmpty {
                let averageMood = moodEntries.reduce(0.0) { $0 + Double($1.rating) } / Double(moodEntries.count)
                let dominantEmotion = getDominantEmotion(from: moodEntries)
                
                trends.append(MoodTrend(
                    date: date,
                    averageMood: averageMood,
                    moodCount: moodEntries.count,
                    dominantEmotion: dominantEmotion
                ))
            }
        }
        
        moodTrends = trends.reversed()
    }
    
    private func loadNoteStatistics() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let allNotesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let allNotes = (try? dataManager.coreDataStack.viewContext.fetch(allNotesRequest)) ?? []
        
        let notesThisWeek = allNotes.filter { $0.createdAt ?? Date() >= weekStart }.count
        let notesThisMonth = allNotes.filter { $0.createdAt ?? Date() >= monthStart }.count
        
        let totalLength = allNotes.reduce(0) { $0 + ($1.content?.count ?? 0) }
        let averageLength = allNotes.isEmpty ? 0 : Double(totalLength) / Double(allNotes.count)
        
        // Find most productive day
        let dayCounts = Dictionary(grouping: allNotes) { note in
            calendar.component(.weekday, from: note.createdAt ?? Date())
        }
        let mostProductiveDayNumber = dayCounts.max { $0.value.count < $1.value.count }?.key ?? 1
        let mostProductiveDay = calendar.weekdaySymbols[mostProductiveDayNumber - 1]
        
        // Count notes with special features
        let notesWithImages = allNotes.filter { $0.content?.contains("![") == true }.count
        let notesWithTables = allNotes.filter { $0.content?.contains("|") == true }.count
        
        noteStatistics = NoteStatistics(
            totalNotes: allNotes.count,
            notesThisWeek: notesThisWeek,
            notesThisMonth: notesThisMonth,
            averageNoteLength: averageLength,
            mostProductiveDay: mostProductiveDay,
            favoriteNoteCategory: "General", // TODO: Implement categories
            notesWithImages: notesWithImages,
            notesWithTables: notesWithTables
        )
    }
    
    private func loadTaskAnalytics() {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        let allTasksRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let allTasks = (try? dataManager.coreDataStack.viewContext.fetch(allTasksRequest)) ?? []
        
        let completedTasks = allTasks.filter { $0.isCompleted }.count
        let completionRate = allTasks.isEmpty ? 0 : Double(completedTasks) / Double(allTasks.count) * 100
        
        let tasksThisWeek = allTasks.filter { $0.createdAt ?? Date() >= weekStart }.count
        let overdueTasks = allTasks.filter { 
            guard let dueDate = $0.dueDate else { return false }
            return !$0.isCompleted && dueDate < now
        }.count
        
        // Find most productive category
        let categoryCounts = Dictionary(grouping: allTasks) { $0.category?.name ?? "Uncategorized" }
        let mostProductiveCategory = categoryCounts.max { $0.value.count < $1.value.count }?.key ?? "Uncategorized"
        
        taskAnalytics = TaskAnalytics(
            totalTasks: allTasks.count,
            completedTasks: completedTasks,
            completionRate: completionRate,
            averageCompletionTime: 0, // TODO: Implement completion time tracking
            mostProductiveCategory: mostProductiveCategory,
            overdueTasks: overdueTasks,
            tasksThisWeek: tasksThisWeek
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateProductivityScore(notes: Int, tasks: Int, journal: Int, words: Int) -> Double {
        let notesScore = min(Double(notes) * 10, 30) // Max 30 points
        let tasksScore = min(Double(tasks) * 8, 40) // Max 40 points
        let journalScore = min(Double(journal) * 15, 15) // Max 15 points
        let wordsScore = min(Double(words) * 0.1, 15) // Max 15 points
        
        return notesScore + tasksScore + journalScore + wordsScore
    }
    
    private func calculateStreakDays() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let dayStart = currentDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let request: NSFetchRequest<Note> = Note.fetchRequest()
            request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", dayStart as NSDate, dayEnd as NSDate)
            
            let hasActivity = (try? dataManager.coreDataStack.viewContext.fetch(request))?.isEmpty == false
            
            if hasActivity {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func getDominantEmotion(from moodEntries: [MoodEntry]) -> String {
        // Since MoodEntry doesn't have an emotion property, we'll use rating ranges
        let emotionRanges = moodEntries.map { moodEntry in
            switch moodEntry.rating {
            case 0...2: return "Sad"
            case 3...4: return "Neutral"
            case 5...6: return "Happy"
            case 7...8: return "Excited"
            case 9...10: return "Ecstatic"
            default: return "Neutral"
            }
        }
        let emotionCounts = Dictionary(grouping: emotionRanges) { $0 }
        return emotionCounts.max { $0.value.count < $1.value.count }?.key ?? "Neutral"
    }
    
    // MARK: - Public Methods
    
    func refreshAnalytics() {
        loadAnalytics()
    }
    
    func getProductivityInsights() -> [String] {
        var insights: [String] = []
        
        if productivityMetrics.streakDays > 0 {
            insights.append("🔥 You're on a \(productivityMetrics.streakDays)-day streak!")
        }
        
        if productivityMetrics.notesCreatedToday > 5 {
            insights.append("📝 Great writing day! You've created \(productivityMetrics.notesCreatedToday) notes today.")
        }
        
        if taskAnalytics.completionRate > 80 {
            insights.append("✅ Excellent task completion rate of \(Int(taskAnalytics.completionRate))%!")
        }
        
        if noteStatistics.notesThisWeek > 10 {
            insights.append("📊 You've been very productive this week with \(noteStatistics.notesThisWeek) notes.")
        }
        
        if moodTrends.count > 0 {
            let recentMood = moodTrends.last?.averageMood ?? 0
            if recentMood > 7 {
                insights.append("😊 Your mood has been positive lately!")
            }
        }
        
        return insights
    }
}
