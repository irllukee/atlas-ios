import Foundation
import SwiftUI

// MARK: - Enums

enum TaskPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }
}

enum RecurringType: String, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

enum TaskFilter: String, CaseIterable {
    case all = "All"
    case pending = "Pending"
    case completed = "Completed"
    case overdue = "Overdue"
    case dueToday = "Due Today"
    case dueThisWeek = "Due This Week"
    case highPriority = "High Priority"
}

enum TaskSortOption: String, CaseIterable {
    case dueDateEarliest = "Due Date (Earliest First)"
    case dueDateLatest = "Due Date (Latest First)"
    case priorityHighToLow = "Priority (High to Low)"
    case priorityLowToHigh = "Priority (Low to High)"
    case createdNewest = "Created (Newest First)"
    case alphabetical = "Alphabetical (A-Z)"
}
