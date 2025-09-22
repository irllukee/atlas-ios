import Foundation
import CoreData
import SwiftUI

/// Central data manager coordinating all repositories and CoreData operations
@MainActor
final class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - Core Data Stack
    let coreDataStack: CoreDataStack
    
    // MARK: - Repositories
    let taskRepository: TaskRepository
    
    // MARK: - Published Properties for SwiftUI
    @Published var isLoading = false
    @Published var lastError: Error?
    @Published var isDataValid = true
    
    // MARK: - Initialization
    private init() {
        self.coreDataStack = CoreDataStack.shared
        self.taskRepository = TaskRepository(context: coreDataStack.viewContext)
        
        // Validate data integrity on startup
        validateDataIntegrity()
    }
    
    // MARK: - Data Operations
    func save() {
        coreDataStack.save()
        clearError()
    }
    
    func refresh() {
        // Force refresh of all data
        objectWillChange.send()
    }
    
    // MARK: - Error Handling
    func clearError() {
        lastError = nil
    }
    
    func handleError(_ error: Error) {
        lastError = error
        print("❌ DataManager Error: \(error)")
    }
    
    // MARK: - Data Validation
    private func validateDataIntegrity() {
        guard coreDataStack.validateContext() else {
            isDataValid = false
            handleError(DataError.invalidContext)
            return
        }
        
        isDataValid = true
        print("✅ Data integrity validated")
    }
    
    // MARK: - Statistics
    func getAppStatistics() -> AppStatistics {
        let notesService = NotesService.shared
        let notesStats = notesService.getNotesStatistics()
        
        return AppStatistics(
            totalNotes: notesStats.totalNotes,
            encryptedNotes: 0, // TODO: Implement encrypted notes count
            notesToday: notesStats.notesCreatedToday,
            totalTasks: taskRepository.getTotalCount(),
            completedTasks: taskRepository.getCompletedCount(),
            pendingTasks: taskRepository.getPendingCount(),
            overdueTasks: taskRepository.getOverdueCount(),
            tasksDueToday: taskRepository.getDueTodayCount(),
            completionRate: taskRepository.getCompletionRate(),
            highPriorityTasks: taskRepository.getHighPriorityCount()
        )
    }
    
    // MARK: - Cleanup Operations
    func deleteAllData() {
        isLoading = true
        
        coreDataStack.persistentContainer.performBackgroundTask { context in
            self.coreDataStack.deleteAllData()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.refresh()
            }
        }
    }
    
    func logDatabaseStats() {
        coreDataStack.logDatabaseStats()
    }
    
    // MARK: - Performance Monitoring
    func logPerformanceMetrics() {
        let stats = getAppStatistics()
        let performanceMetrics = PerformanceService.shared.getPerformanceMetrics()
        
        print("📊 Atlas Performance Metrics:")
        print("  📝 Notes: \(stats.totalNotes) total, \(stats.notesToday) today")
        print("  ✅ Tasks: \(stats.totalTasks) total, \(stats.completedTasks) completed")
        print("  💾 Memory: \(String(format: "%.1f", performanceMetrics.memoryUsageMB))MB")
        print("  🖼️ Image Cache: \(performanceMetrics.imageCacheSize) items (\(String(format: "%.1f", performanceMetrics.imageCacheMemoryUsageMB))MB)")
        print("  📄 Text Cache: \(performanceMetrics.textCacheSize) items")
        print("  🔍 Preview Cache: \(performanceMetrics.notePreviewCacheSize) items")
    }
}

// MARK: - App Statistics Model
struct AppStatistics {
    let totalNotes: Int
    let encryptedNotes: Int
    let notesToday: Int
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let overdueTasks: Int
    let tasksDueToday: Int
    let completionRate: Double
    let highPriorityTasks: Int
    
    var completionPercentage: Int {
        return Int(completionRate * 100)
    }
    
    var hasOverdueTasks: Bool {
        return overdueTasks > 0
    }
    
    var hasHighPriorityTasks: Bool {
        return highPriorityTasks > 0
    }
}

// MARK: - Data Errors
enum DataError: LocalizedError {
    case invalidContext
    case saveFailed
    case fetchFailed
    case deleteFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidContext:
            return "Database context is invalid"
        case .saveFailed:
            return "Failed to save data"
        case .fetchFailed:
            return "Failed to fetch data"
        case .deleteFailed:
            return "Failed to delete data"
        case .validationFailed:
            return "Data validation failed"
        }
    }
}

// MARK: - Environment Key
struct DataManagerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: DataManager = DataManager.shared
}

extension EnvironmentValues {
    var dataManager: DataManager {
        get { self[DataManagerKey.self] }
        set { self[DataManagerKey.self] = newValue }
    }
}
