import Foundation
import CoreData
import SwiftUI
@preconcurrency import EventKit

/// Service for providing real-time dashboard statistics and data
@MainActor
class DashboardDataService: ObservableObject {
    
    // MARK: - Properties
    private let dataManager: DataManager
    
    @Published var dashboardStats = DashboardStatistics()
    @Published var isLoading = false
    
    // MARK: - Lazy Initialization
    static var lazy: DashboardDataService {
        return DashboardDataService(dataManager: DataManager.shared)
    }
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        
        loadDashboardData()
    }
    
    // MARK: - Data Loading
    func loadDashboardData() {
        isLoading = true
        
        _Concurrency.Task {
            // Load data in parallel for better performance
            await withTaskGroup(of: Void.self) { group in
                // Only load notes data since other features were removed
                group.addTask { await self.loadNotesData() }
                
                await group.waitForAll()
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Notes Data
    private func loadNotesData() async {
        // Load notes statistics from DataManager
        let stats = dataManager.getAppStatistics()
        
        await MainActor.run {
            // Update dashboard stats with notes data
            dashboardStats.notesToday = stats.notesToday
        }
    }
    
}

// MARK: - Data Models
struct DashboardStatistics {
    var notesToday: Int = 0
}

