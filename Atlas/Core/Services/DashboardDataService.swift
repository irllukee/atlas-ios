import Foundation
import CoreData
import SwiftUI
@preconcurrency import EventKit

/// Service for providing real-time dashboard statistics and data
@MainActor
class DashboardDataService: ObservableObject {
    
    // MARK: - Properties
    private let dataManager: DataManager
    private let calendarService: CalendarService
    private let tasksService: TasksService
    private let journalService: JournalService
    
    @Published var dashboardStats = DashboardStatistics()
    @Published var isLoading = false
    
    // MARK: - Lazy Initialization
    static var lazy: DashboardDataService {
        return DashboardDataService(
            dataManager: DataManager.shared,
            calendarService: CalendarService(),
            tasksService: TasksService(dataManager: DataManager.shared),
            journalService: JournalService(dataManager: DataManager.shared, encryptionService: EncryptionService.shared)
        )
    }
    
    // MARK: - Initialization
    init(dataManager: DataManager, calendarService: CalendarService, tasksService: TasksService, journalService: JournalService) {
        self.dataManager = dataManager
        self.calendarService = calendarService
        self.tasksService = tasksService
        self.journalService = journalService
        
        loadDashboardData()
    }
    
    // MARK: - Data Loading
    func loadDashboardData() {
        isLoading = true
        
        _Concurrency.Task {
            // Load data in parallel for better performance
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.loadTasksData() }
                group.addTask { await self.loadJournalData() }
                group.addTask { await self.loadCalendarData() }
                
                await group.waitForAll()
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Tasks Data
    private func loadTasksData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Get all tasks
        let allTasks = tasksService.tasks
        
        // Filter tasks for today
        let todayTasks = allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < endOfToday
        }
        
        // Count completed vs total
        let completedToday = todayTasks.filter { $0.isCompleted }.count
        let totalToday = todayTasks.count
        
        dashboardStats.tasksCompletedToday = completedToday
        dashboardStats.tasksTotalToday = totalToday
        dashboardStats.tasksProgress = totalToday > 0 ? Double(completedToday) / Double(totalToday) : 0.0
    }
    
    
    // MARK: - Journal Data
    private func loadJournalData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Get all journal entries
        let allEntries = journalService.journalEntries
        
        // Filter entries for today
        let todayEntries = allEntries.filter { entry in
            guard let createdAt = entry.createdAt else { return false }
            return createdAt >= today && createdAt < endOfToday
        }
        
        dashboardStats.journalEntriesToday = todayEntries.count
        dashboardStats.journalProgress = min(Double(todayEntries.count) / 3.0, 1.0) // Progress based on 3 entries per day
    }
    
    // MARK: - Calendar Data
    private func loadCalendarData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Get events for today
        calendarService.loadEventsForDate(today)
        let todayEvents = calendarService.events.filter { event in
            event.startDate >= today && event.startDate < endOfToday
        }
        
        // Filter remaining events (not yet started)
        let now = Date()
        let remainingEvents = todayEvents.filter { $0.startDate > now }
        
        dashboardStats.eventsRemainingToday = remainingEvents.count
        dashboardStats.calendarProgress = min(Double(remainingEvents.count) / 8.0, 1.0) // Progress based on 8 events per day
    }
    
    // MARK: - Focus Data
    func getTodaysFocusItems() -> [FocusItem] {
        return [
            FocusItem(
                title: "Morning Routine",
                description: "Complete your daily morning routine",
                progress: 0.75,
                color: .blue,
                icon: "sunrise.fill"
            ),
            FocusItem(
                title: "Work Project",
                description: "Finish the quarterly report",
                progress: 0.4,
                color: .green,
                icon: "briefcase.fill"
            ),
            FocusItem(
                title: "Evening Reflection",
                description: "Journal about today's experiences",
                progress: 0.0,
                color: .purple,
                icon: "moon.stars.fill"
            )
        ]
    }
}

// MARK: - Data Models
struct DashboardStatistics {
    var tasksCompletedToday: Int = 0
    var tasksTotalToday: Int = 0
    var tasksProgress: Double = 0.0
    
    
    var journalEntriesToday: Int = 0
    var journalProgress: Double = 0.0
    
    var eventsRemainingToday: Int = 0
    var calendarProgress: Double = 0.0
}

struct FocusItem {
    let title: String
    let description: String
    let progress: Double
    let color: Color
    let icon: String
}
