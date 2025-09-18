import Foundation
import CoreData
import Combine
import SwiftUI

// MARK: - Recommendation Models
struct ContentRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: RecommendationType
    let confidence: Double
    let reason: String
    let action: RecommendationAction
    let metadata: [String: String]
    
    init(
        title: String,
        description: String,
        type: RecommendationType,
        confidence: Double,
        reason: String,
        action: RecommendationAction,
        metadata: [String: String] = [:]
    ) {
        self.title = title
        self.description = description
        self.type = type
        self.confidence = confidence
        self.reason = reason
        self.action = action
        self.metadata = metadata
    }
}

enum RecommendationType: String, CaseIterable {
    case productivity = "productivity"
    case habit = "habit"
    case content = "content"
    case insight = "insight"
    case reminder = "reminder"
    
    var icon: String {
        switch self {
        case .productivity: return "chart.line.uptrend.xyaxis"
        case .habit: return "repeat"
        case .content: return "doc.text"
        case .insight: return "lightbulb"
        case .reminder: return "bell"
        }
    }
    
    var color: Color {
        switch self {
        case .productivity: return .green
        case .habit: return .blue
        case .content: return .purple
        case .insight: return .orange
        case .reminder: return .red
        }
    }
}

enum RecommendationAction {
    case createNote(String)
    case createTask(String)
    case createJournalEntry(String)
    case logMood
    case viewAnalytics
    case viewCalendar
    case openSearch(String)
    case custom(String)
}

// MARK: - User Behavior Model
struct UserBehavior {
    let contentType: ContentType
    let action: String
    let timestamp: Date
    let metadata: [String: String]
    
    init(contentType: ContentType, action: String, timestamp: Date = Date(), metadata: [String: Any] = [:]) {
        self.contentType = contentType
        self.action = action
        self.timestamp = timestamp
        self.metadata = metadata.compactMapValues { value in
            if let stringValue = value as? String {
                return stringValue
            } else {
                return String(describing: value)
            }
        }
    }
}

// MARK: - Recommendation Service
@MainActor
class RecommendationService: ObservableObject {
    static let shared = RecommendationService()
    
    @Published var recommendations: [ContentRecommendation] = []
    @Published var isGeneratingRecommendations = false
    
    private let dataManager: DataManager
    private let tagService: TagService
    private var cancellables = Set<AnyCancellable>()
    private var userBehaviors: [UserBehavior] = []
    
    private init() {
        self.dataManager = DataManager.shared
        self.tagService = TagService.shared
        loadUserBehaviors()
        generateRecommendations()
    }
    
    // MARK: - Recommendation Generation
    
    func generateRecommendations() {
        isGeneratingRecommendations = true
        
        _Concurrency.Task {
            let newRecommendations = await analyzeUserBehaviorAndGenerateRecommendations()
            
            await MainActor.run {
                self.recommendations = newRecommendations
                self.isGeneratingRecommendations = false
            }
        }
    }
    
    func refreshRecommendations() {
        generateRecommendations()
    }
    
    // MARK: - User Behavior Tracking
    
    func trackUserBehavior(_ behavior: UserBehavior) {
        userBehaviors.append(behavior)
        saveUserBehaviors()
        
        // Generate new recommendations based on recent behavior
        _Concurrency.Task {
            await generateContextualRecommendations()
        }
    }
    
    func trackContentCreation(_ contentType: ContentType, title: String) {
        let behavior = UserBehavior(
            contentType: contentType,
            action: "create",
            metadata: ["title": title]
        )
        trackUserBehavior(behavior)
    }
    
    func trackContentView(_ contentType: ContentType, title: String) {
        let behavior = UserBehavior(
            contentType: contentType,
            action: "view",
            metadata: ["title": title]
        )
        trackUserBehavior(behavior)
    }
    
    func trackSearch(_ query: String) {
        let behavior = UserBehavior(
            contentType: .note, // Default type for search
            action: "search",
            metadata: ["query": query]
        )
        trackUserBehavior(behavior)
    }
    
    // MARK: - Private Methods
    
    private func analyzeUserBehaviorAndGenerateRecommendations() async -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Analyze recent behavior patterns
        let recentBehaviors = getRecentBehaviors(days: 7)
        
        // Generate productivity recommendations
        let productivityRecs = generateProductivityRecommendations(from: recentBehaviors)
        recommendations.append(contentsOf: productivityRecs)
        
        // Generate habit recommendations
        let habitRecs = generateHabitRecommendations(from: recentBehaviors)
        recommendations.append(contentsOf: habitRecs)
        
        // Generate content recommendations
        let contentRecs = generateContentRecommendations(from: recentBehaviors)
        recommendations.append(contentsOf: contentRecs)
        
        // Generate insights
        let insightRecs = generateInsightRecommendations(from: recentBehaviors)
        recommendations.append(contentsOf: insightRecs)
        
        // Generate reminders
        let reminderRecs = generateReminderRecommendations(from: recentBehaviors)
        recommendations.append(contentsOf: reminderRecs)
        
        // Sort by confidence and return top recommendations
        return recommendations
            .sorted { $0.confidence > $1.confidence }
            .prefix(10)
            .map { $0 }
    }
    
    private func generateContextualRecommendations() async {
        let contextualRecs = await analyzeUserBehaviorAndGenerateRecommendations()
        
        await MainActor.run {
            // Merge with existing recommendations, avoiding duplicates
            let existingTitles = Set(self.recommendations.map { $0.title })
            let newRecs = contextualRecs.filter { !existingTitles.contains($0.title) }
            
            self.recommendations = (self.recommendations + newRecs)
                .sorted { $0.confidence > $1.confidence }
                .prefix(10)
                .map { $0 }
        }
    }
    
    private func generateProductivityRecommendations(from behaviors: [UserBehavior]) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Analyze task completion patterns
        let taskBehaviors = behaviors.filter { $0.contentType == .task }
        let completedTasks = taskBehaviors.filter { $0.action == "complete" }
        let createdTasks = taskBehaviors.filter { $0.action == "create" }
        
        if completedTasks.count > 0 && createdTasks.count > 0 {
            let completionRate = Double(completedTasks.count) / Double(createdTasks.count)
            
            if completionRate < 0.5 {
                recommendations.append(ContentRecommendation(
                    title: "Improve Task Completion",
                    description: "Your task completion rate is \(Int(completionRate * 100))%. Consider breaking down large tasks into smaller ones.",
                    type: .productivity,
                    confidence: 0.8,
                    reason: "Low task completion rate detected",
                    action: .createTask("Break down a large task into smaller subtasks")
                ))
            }
        }
        
        // Analyze time patterns
        let morningBehaviors = behaviors.filter { isMorning($0.timestamp) }
        let eveningBehaviors = behaviors.filter { isEvening($0.timestamp) }
        
        if morningBehaviors.count > eveningBehaviors.count * 2 {
            recommendations.append(ContentRecommendation(
                title: "Morning Productivity",
                description: "You're most productive in the morning. Consider scheduling important tasks for early hours.",
                type: .productivity,
                confidence: 0.7,
                reason: "Higher activity in morning hours",
                action: .createTask("Schedule important task for tomorrow morning")
            ))
        }
        
        return recommendations
    }
    
    private func generateHabitRecommendations(from behaviors: [UserBehavior]) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Analyze journaling patterns
        let journalBehaviors = behaviors.filter { $0.contentType == .journal }
        let journalStreak = calculateStreak(for: journalBehaviors)
        
        if journalStreak > 0 && journalStreak < 7 {
            recommendations.append(ContentRecommendation(
                title: "Journaling Streak",
                description: "You've journaled for \(journalStreak) days in a row. Keep it up!",
                type: .habit,
                confidence: 0.9,
                reason: "Active journaling streak",
                action: .createJournalEntry("Continue your journaling streak")
            ))
        } else if journalStreak == 0 && journalBehaviors.count > 0 {
            recommendations.append(ContentRecommendation(
                title: "Restart Journaling",
                description: "You haven't journaled recently. Consider starting a new entry.",
                type: .habit,
                confidence: 0.6,
                reason: "No recent journal entries",
                action: .createJournalEntry("Start a new journal entry")
            ))
        }
        
        // Analyze mood tracking
        let moodBehaviors = behaviors.filter { $0.contentType == .mood }
        if moodBehaviors.isEmpty {
            recommendations.append(ContentRecommendation(
                title: "Track Your Mood",
                description: "Start tracking your mood to gain insights into your emotional patterns.",
                type: .habit,
                confidence: 0.7,
                reason: "No mood tracking detected",
                action: .logMood
            ))
        }
        
        return recommendations
    }
    
    private func generateContentRecommendations(from behaviors: [UserBehavior]) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Analyze content creation patterns
        let noteBehaviors = behaviors.filter { $0.contentType == .note }
        let taskBehaviors = behaviors.filter { $0.contentType == .task }
        
        if noteBehaviors.count > taskBehaviors.count * 2 {
            recommendations.append(ContentRecommendation(
                title: "Create More Tasks",
                description: "You create many notes but fewer tasks. Consider converting some notes into actionable tasks.",
                type: .content,
                confidence: 0.6,
                reason: "Imbalance between notes and tasks",
                action: .createTask("Convert a note into an actionable task")
            ))
        }
        
        // Analyze search patterns
        let searchBehaviors = behaviors.filter { $0.action == "search" }
        if searchBehaviors.count > 5 {
            let commonQueries = getCommonSearchQueries(from: searchBehaviors)
            if let topQuery = commonQueries.first {
                recommendations.append(ContentRecommendation(
                    title: "Organize Content",
                    description: "You frequently search for '\(topQuery)'. Consider creating a dedicated section or tag for this topic.",
                    type: .content,
                    confidence: 0.7,
                    reason: "Frequent searches for specific topic",
                    action: .createNote("Create a dedicated note for \(topQuery)")
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateInsightRecommendations(from behaviors: [UserBehavior]) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Analyze productivity patterns
        let totalActivities = behaviors.count
        let uniqueDays = Set(behaviors.map { Calendar.current.startOfDay(for: $0.timestamp) }).count
        
        if totalActivities > 0 && uniqueDays > 0 {
            let avgActivitiesPerDay = Double(totalActivities) / Double(uniqueDays)
            
            if avgActivitiesPerDay > 10 {
                recommendations.append(ContentRecommendation(
                    title: "High Activity Level",
                    description: "You're very active with \(Int(avgActivitiesPerDay)) activities per day on average. Great job!",
                    type: .insight,
                    confidence: 0.8,
                    reason: "High daily activity level",
                    action: .viewAnalytics
                ))
            }
        }
        
        // Analyze content type preferences
        let contentTypeCounts = Dictionary(grouping: behaviors, by: { $0.contentType })
            .mapValues { $0.count }
        
        if let mostUsedType = contentTypeCounts.max(by: { $0.value < $1.value }) {
            recommendations.append(ContentRecommendation(
                title: "Content Preference",
                description: "You use \(mostUsedType.key.displayName.lowercased()) most frequently. This might be your preferred way to organize information.",
                type: .insight,
                confidence: 0.6,
                reason: "Most used content type",
                action: .viewAnalytics
            ))
        }
        
        return recommendations
    }
    
    private func generateReminderRecommendations(from behaviors: [UserBehavior]) -> [ContentRecommendation] {
        var recommendations: [ContentRecommendation] = []
        
        // Check for overdue tasks
        let taskBehaviors = behaviors.filter { $0.contentType == .task }
        let recentTaskCreation = taskBehaviors.filter { $0.action == "create" && isRecent($0.timestamp, days: 3) }
        
        if recentTaskCreation.count > 5 {
            recommendations.append(ContentRecommendation(
                title: "Review Recent Tasks",
                description: "You've created \(recentTaskCreation.count) tasks in the last 3 days. Consider reviewing and prioritizing them.",
                type: .reminder,
                confidence: 0.7,
                reason: "Many recent tasks created",
                action: .viewCalendar
            ))
        }
        
        // Check for mood tracking gaps
        let moodBehaviors = behaviors.filter { $0.contentType == .mood }
        let lastMoodEntry = moodBehaviors.max { $0.timestamp < $1.timestamp }
        
        if let lastEntry = lastMoodEntry, !isRecent(lastEntry.timestamp, days: 2) {
            recommendations.append(ContentRecommendation(
                title: "Log Your Mood",
                description: "You haven't logged your mood recently. How are you feeling today?",
                type: .reminder,
                confidence: 0.8,
                reason: "No recent mood entries",
                action: .logMood
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func getRecentBehaviors(days: Int) -> [UserBehavior] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return userBehaviors.filter { $0.timestamp >= cutoffDate }
    }
    
    private func calculateStreak(for behaviors: [UserBehavior]) -> Int {
        let sortedBehaviors = behaviors.sorted { $0.timestamp > $1.timestamp }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        for behavior in sortedBehaviors {
            let behaviorDate = Calendar.current.startOfDay(for: behavior.timestamp)
            if behaviorDate == currentDate {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if behaviorDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    private func getCommonSearchQueries(from behaviors: [UserBehavior]) -> [String] {
        let queries = behaviors.compactMap { behavior -> String? in
            return behavior.metadata["query"]
        }
        let queryCounts = Dictionary(grouping: queries, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return queryCounts.map { $0.key }
    }
    
    private func isMorning(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 6 && hour < 12
    }
    
    private func isEvening(_ date: Date) -> Bool {
        let hour = Calendar.current.component(.hour, from: date)
        return hour >= 18 && hour < 22
    }
    
    private func isRecent(_ date: Date, days: Int) -> Bool {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return date >= cutoffDate
    }
    
    // MARK: - Persistence
    
    private func loadUserBehaviors() {
        if let data = UserDefaults.standard.data(forKey: "AtlasUserBehaviors"),
           let behaviors = try? JSONDecoder().decode([UserBehavior].self, from: data) {
            userBehaviors = behaviors
        }
    }
    
    private func saveUserBehaviors() {
        // Keep only recent behaviors to avoid storage bloat
        let recentBehaviors = getRecentBehaviors(days: 30)
        
        if let data = try? JSONEncoder().encode(recentBehaviors) {
            UserDefaults.standard.set(data, forKey: "AtlasUserBehaviors")
        }
    }
}

// MARK: - User Behavior Extensions
extension UserBehavior: Codable {
    enum CodingKeys: String, CodingKey {
        case contentType, action, timestamp, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let contentTypeString = try container.decode(String.self, forKey: .contentType)
        contentType = ContentType(rawValue: contentTypeString) ?? .note
        
        action = try container.decode(String.self, forKey: .action)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        metadata = try container.decode([String: String].self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(contentType.rawValue, forKey: .contentType)
        try container.encode(action, forKey: .action)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(metadata, forKey: .metadata)
    }
}

// MARK: - Content Type Extensions
extension ContentType: Codable {
}
