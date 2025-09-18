import Foundation
import Combine
@preconcurrency import CoreData

/// Time range options for analytics
enum AnalyticsTimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

@MainActor
class AnalyticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var analyticsData = AnalyticsData()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let dataManager: DataManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
    }
    
    // MARK: - Public Methods
    func loadAnalytics(for timeRange: AnalyticsTimeRange) {
        isLoading = true
        errorMessage = nil
        
        let dateRange = getDateRange(for: timeRange)
        
        _Concurrency.Task {
            let analytics = await calculateAnalytics(for: dateRange)
            self.analyticsData = analytics
            self.isLoading = false
        }
    }
    
    func exportAnalyticsSummary() {
        // TODO: Implement analytics summary export
        print("Exporting analytics summary...")
    }
    
    func exportAllData() {
        // TODO: Implement complete data export
        print("Exporting all data...")
    }
    
    // MARK: - Private Methods
    private func getDateRange(for timeRange: AnalyticsTimeRange) -> DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return DateInterval(start: startOfWeek, end: now)
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return DateInterval(start: startOfMonth, end: now)
        case .quarter:
            let quarter = calendar.component(.month, from: now) / 3
            let startOfQuarter = calendar.date(from: DateComponents(
                year: calendar.component(.year, from: now),
                month: quarter * 3 - 2,
                day: 1
            )) ?? now
            return DateInterval(start: startOfQuarter, end: now)
        case .year:
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return DateInterval(start: startOfYear, end: now)
        }
    }
    
    private func calculateAnalytics(for dateRange: DateInterval) async -> AnalyticsData {
        let context = dataManager.coreDataStack.persistentContainer.newBackgroundContext()
        
        return await context.perform { @Sendable in
            var analytics = AnalyticsData()
            
            // Calculate task analytics
            analytics.tasksCompleted = self.calculateTasksCompleted(in: context, dateRange: dateRange)
            analytics.taskCompletionRate = self.calculateTaskCompletionRate(in: context, dateRange: dateRange)
            analytics.averageTasksPerDay = self.calculateAverageTasksPerDay(in: context, dateRange: dateRange)
            analytics.taskCompletionChange = self.calculateTaskCompletionChange(in: context, dateRange: dateRange)
            analytics.taskPriorityData = self.calculateTaskPriorityData(in: context, dateRange: dateRange)
            analytics.productivityData = self.calculateProductivityData(in: context, dateRange: dateRange)
            
            // Calculate notes analytics
            analytics.notesCreated = self.calculateNotesCreated(in: context, dateRange: dateRange)
            analytics.notesChange = self.calculateNotesChange(in: context, dateRange: dateRange)
            analytics.averageNoteLength = self.calculateAverageNoteLength(in: context, dateRange: dateRange)
            analytics.notesData = self.calculateNotesData(in: context, dateRange: dateRange)
            
            // Calculate journal analytics
            analytics.journalEntries = self.calculateJournalEntries(in: context, dateRange: dateRange)
            analytics.journalChange = self.calculateJournalChange(in: context, dateRange: dateRange)
            analytics.journalStreak = self.calculateJournalStreak(in: context)
            analytics.journalTypeData = self.calculateJournalTypeData(in: context, dateRange: dateRange)
            
            // Calculate mood analytics
            analytics.averageMood = self.calculateAverageMood(in: context, dateRange: dateRange)
            analytics.moodChange = self.calculateMoodChange(in: context, dateRange: dateRange)
            analytics.moodData = self.calculateMoodData(in: context, dateRange: dateRange)
            
            return analytics
        }
    }
    
    // MARK: - Task Analytics
    nonisolated private func calculateTasksCompleted(in context: NSManagedObjectContext, dateRange: DateInterval) -> Int {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES AND completionDate >= %@ AND completionDate <= %@", 
                                      dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error calculating tasks completed: \(error)")
            return 0
        }
    }
    
    nonisolated private func calculateTaskCompletionRate(in context: NSManagedObjectContext, dateRange: DateInterval) -> Double {
        let completedRequest: NSFetchRequest<Task> = Task.fetchRequest()
        completedRequest.predicate = NSPredicate(format: "isCompleted == YES AND completionDate >= %@ AND completionDate <= %@", 
                                               dateRange.start as NSDate, dateRange.end as NSDate)
        
        let totalRequest: NSFetchRequest<Task> = Task.fetchRequest()
        totalRequest.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                           dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            let completed = try context.count(for: completedRequest)
            let total = try context.count(for: totalRequest)
            return total > 0 ? Double(completed) / Double(total) : 0.0
        } catch {
            print("Error calculating task completion rate: \(error)")
            return 0.0
        }
    }
    
    nonisolated private func calculateAverageTasksPerDay(in context: NSManagedObjectContext, dateRange: DateInterval) -> Double {
        let days = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
        let tasksCompleted = calculateTasksCompleted(in: context, dateRange: dateRange)
        return Double(tasksCompleted) / Double(max(days, 1))
    }
    
    nonisolated private func calculateTaskCompletionChange(in context: NSManagedObjectContext, dateRange: DateInterval) -> Double {
        let currentPeriod = calculateTasksCompleted(in: context, dateRange: dateRange)
        
        // Calculate previous period
        let duration = dateRange.duration
        let previousStart = dateRange.start.addingTimeInterval(-duration)
        let previousEnd = dateRange.start
        let previousRange = DateInterval(start: previousStart, end: previousEnd)
        let previousPeriod = calculateTasksCompleted(in: context, dateRange: previousRange)
        
        if previousPeriod == 0 {
            return currentPeriod > 0 ? 100.0 : 0.0
        }
        
        return ((Double(currentPeriod) - Double(previousPeriod)) / Double(previousPeriod)) * 100.0
    }
    
    nonisolated private func calculateTaskPriorityData(in context: NSManagedObjectContext, dateRange: DateInterval) -> [TaskPriorityDataPoint] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                      dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            let tasks = try context.fetch(request)
            let priorityCounts = Dictionary(grouping: tasks, by: { task in
                switch task.priority {
                case 0: return "low"
                case 1: return "medium" 
                case 2: return "high"
                default: return "medium"
                }
            })
            
            return [
                TaskPriorityDataPoint(priority: "High", count: priorityCounts["high"]?.count ?? 0),
                TaskPriorityDataPoint(priority: "Medium", count: priorityCounts["medium"]?.count ?? 0),
                TaskPriorityDataPoint(priority: "Low", count: priorityCounts["low"]?.count ?? 0)
            ]
        } catch {
            print("Error calculating task priority data: \(error)")
            return []
        }
    }
    
    nonisolated private func calculateProductivityData(in context: NSManagedObjectContext, dateRange: DateInterval) -> [ProductivityDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [ProductivityDataPoint] = []
        
        var currentDate = dateRange.start
        while currentDate <= dateRange.end {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            
            let dayRange = DateInterval(start: dayStart, end: dayEnd)
            let tasksCompleted = calculateTasksCompleted(in: context, dateRange: dayRange)
            
            dataPoints.append(ProductivityDataPoint(date: dayStart, tasksCompleted: tasksCompleted))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    // MARK: - Notes Analytics
    nonisolated private func calculateNotesCreated(in context: NSManagedObjectContext, dateRange: DateInterval) -> Int {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                      dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error calculating notes created: \(error)")
            return 0
        }
    }
    
    nonisolated private func calculateNotesChange(in context: NSManagedObjectContext, dateRange: DateInterval) -> Double {
        let currentPeriod = calculateNotesCreated(in: context, dateRange: dateRange)
        
        let duration = dateRange.duration
        let previousStart = dateRange.start.addingTimeInterval(-duration)
        let previousEnd = dateRange.start
        let previousRange = DateInterval(start: previousStart, end: previousEnd)
        let previousPeriod = calculateNotesCreated(in: context, dateRange: previousRange)
        
        if previousPeriod == 0 {
            return currentPeriod > 0 ? 100.0 : 0.0
        }
        
        return ((Double(currentPeriod) - Double(previousPeriod)) / Double(previousPeriod)) * 100.0
    }
    
    nonisolated private func calculateAverageNoteLength(in context: NSManagedObjectContext, dateRange: DateInterval) -> Int {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                      dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            let notes = try context.fetch(request)
            let totalLength = notes.compactMap { $0.content }.reduce(0) { $0 + $1.count }
            return notes.isEmpty ? 0 : totalLength / notes.count
        } catch {
            print("Error calculating average note length: \(error)")
            return 0
        }
    }
    
    nonisolated private func calculateNotesData(in context: NSManagedObjectContext, dateRange: DateInterval) -> [NotesDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [NotesDataPoint] = []
        
        var currentDate = dateRange.start
        while currentDate <= dateRange.end {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            
            let dayRange = DateInterval(start: dayStart, end: dayEnd)
            let notesCreated = calculateNotesCreated(in: context, dateRange: dayRange)
            
            dataPoints.append(NotesDataPoint(date: dayStart, notesCreated: notesCreated))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    // MARK: - Journal Analytics
    nonisolated private func calculateJournalEntries(in context: NSManagedObjectContext, dateRange: DateInterval) -> Int {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                      dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error calculating journal entries: \(error)")
            return 0
        }
    }
    
    nonisolated private func calculateJournalChange(in context: NSManagedObjectContext, dateRange: DateInterval) -> Double {
        let currentPeriod = calculateJournalEntries(in: context, dateRange: dateRange)
        
        let duration = dateRange.duration
        let previousStart = dateRange.start.addingTimeInterval(-duration)
        let previousEnd = dateRange.start
        let previousRange = DateInterval(start: previousStart, end: previousEnd)
        let previousPeriod = calculateJournalEntries(in: context, dateRange: previousRange)
        
        if previousPeriod == 0 {
            return currentPeriod > 0 ? 100.0 : 0.0
        }
        
        return ((Double(currentPeriod) - Double(previousPeriod)) / Double(previousPeriod)) * 100.0
    }
    
    nonisolated private func calculateJournalStreak(in context: NSManagedObjectContext) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let dayStart = currentDate
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            let dayRange = DateInterval(start: dayStart, end: dayEnd)
            
            let entries = calculateJournalEntries(in: context, dateRange: dayRange)
            if entries > 0 {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    nonisolated private func calculateJournalTypeData(in context: NSManagedObjectContext, dateRange: DateInterval) -> [JournalTypeDataPoint] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                      dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            let entries = try context.fetch(request)
            let typeCounts = Dictionary(grouping: entries, by: { entry in
                if entry.isDream {
                    return "dream"
                } else if entry.gratitudeEntries != nil && !entry.gratitudeEntries!.isEmpty {
                    return "gratitude"
                } else if entry.prompt != nil && !entry.prompt!.isEmpty {
                    return "reflection"
                } else {
                    return "daily"
                }
            })
            
            return [
                JournalTypeDataPoint(type: "Daily", count: typeCounts["daily"]?.count ?? 0),
                JournalTypeDataPoint(type: "Dream", count: typeCounts["dream"]?.count ?? 0),
                JournalTypeDataPoint(type: "Gratitude", count: typeCounts["gratitude"]?.count ?? 0),
                JournalTypeDataPoint(type: "Reflection", count: typeCounts["reflection"]?.count ?? 0)
            ]
        } catch {
            print("Error calculating journal type data: \(error)")
            return []
        }
    }
    
    // MARK: - Mood Analytics
    nonisolated private func calculateAverageMood(in context: NSManagedObjectContext, dateRange: DateInterval) -> Double {
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", 
                                      dateRange.start as NSDate, dateRange.end as NSDate)
        
        do {
            let moods = try context.fetch(request)
            let totalMood = moods.compactMap { $0.rating }.reduce(0.0) { $0 + Double($1) }
            return moods.isEmpty ? 0.0 : totalMood / Double(moods.count)
        } catch {
            print("Error calculating average mood: \(error)")
            return 0.0
        }
    }
    
    nonisolated private func calculateMoodChange(in context: NSManagedObjectContext, dateRange: DateInterval) -> Double {
        let currentPeriod = calculateAverageMood(in: context, dateRange: dateRange)
        
        let duration = dateRange.duration
        let previousStart = dateRange.start.addingTimeInterval(-duration)
        let previousEnd = dateRange.start
        let previousRange = DateInterval(start: previousStart, end: previousEnd)
        let previousPeriod = calculateAverageMood(in: context, dateRange: previousRange)
        
        if previousPeriod == 0 {
            return currentPeriod > 0 ? 100.0 : 0.0
        }
        
        return ((currentPeriod - previousPeriod) / previousPeriod) * 100.0
    }
    
    nonisolated private func calculateMoodData(in context: NSManagedObjectContext, dateRange: DateInterval) -> [AnalyticsMoodDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [AnalyticsMoodDataPoint] = []
        
        var currentDate = dateRange.start
        while currentDate <= dateRange.end {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            
            let dayRange = DateInterval(start: dayStart, end: dayEnd)
            let averageMood = calculateAverageMood(in: context, dateRange: dayRange)
            
            if averageMood > 0 {
                dataPoints.append(AnalyticsMoodDataPoint(date: dayStart, moodValue: averageMood))
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
}

// MARK: - Data Models
struct AnalyticsData {
    // Task Analytics
    var tasksCompleted: Int = 0
    var taskCompletionRate: Double = 0.0
    var averageTasksPerDay: Double = 0.0
    var taskCompletionChange: Double = 0.0
    var taskPriorityData: [TaskPriorityDataPoint] = []
    var productivityData: [ProductivityDataPoint] = []
    
    // Notes Analytics
    var notesCreated: Int = 0
    var notesChange: Double = 0.0
    var averageNoteLength: Int = 0
    var notesData: [NotesDataPoint] = []
    
    // Journal Analytics
    var journalEntries: Int = 0
    var journalChange: Double = 0.0
    var journalStreak: Int = 0
    var journalTypeData: [JournalTypeDataPoint] = []
    
    // Mood Analytics
    var averageMood: Double = 0.0
    var moodChange: Double = 0.0
    var moodData: [AnalyticsMoodDataPoint] = []
}

// MARK: - Chart Data Points
struct TaskPriorityDataPoint: Identifiable {
    let id = UUID()
    let priority: String
    let count: Int
}

struct ProductivityDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let tasksCompleted: Int
}

struct NotesDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let notesCreated: Int
}

struct JournalTypeDataPoint: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
}

struct AnalyticsMoodDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let moodValue: Double
}
