import SwiftUI
import Foundation

// MARK: - Node Type
enum NodeType: String, CaseIterable, Codable {
    case dream = "dream"
    case note = "note"
    case task = "task"
    case journal = "journal"
    
    var displayName: String {
        switch self {
        case .dream: return "Dream"
        case .note: return "Note"
        case .task: return "Task"
        case .journal: return "Journal"
        }
    }
    
    var description: String {
        switch self {
        case .dream: return "Dream symbols and patterns"
        case .note: return "Ideas and thoughts"
        case .task: return "Tasks and goals"
        case .journal: return "Journal entries"
        }
    }
    
    var icon: String {
        switch self {
        case .dream: return "moon.stars.fill"
        case .note: return "galaxy" // Custom galaxy icon
        case .task: return "checkmark.circle"
        case .journal: return "book.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .dream: return Color(red: 0.6, green: 0.3, blue: 0.8) // Purple/indigo
        case .note: return Color(red: 1.0, green: 0.8, blue: 0.2) // Yellow/amber
        case .task: return Color(red: 0.2, green: 0.7, blue: 1.0) // Blue/cyan
        case .journal: return Color(red: 0.9, green: 0.9, blue: 0.9) // White
        }
    }
}

// MARK: - Node Size
enum NodeSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var diameter: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }
}

// MARK: - Task Status
enum TaskStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "inProgress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return Color.orange
        case .inProgress: return Color.blue
        case .completed: return Color.green
        case .cancelled: return Color.red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "play.circle"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        }
    }
}

// MARK: - Galaxy Node Model
struct GalaxyNode: Identifiable, Codable {
    let id: UUID
    var title: String
    let type: NodeType
    var position: CGPoint
    let size: NodeSize
    
    // Optional link to existing data
    var linkedNoteId: UUID?
    var linkedTaskId: UUID?
    var linkedJournalId: UUID?
    var linkedDreamId: UUID?
    
    // Task-specific properties
    var taskStatus: TaskStatus?
    var isGoalNode: Bool = false
    var orbitalRadius: CGFloat = 0.0
    var orbitalSpeed: CGFloat = 1.0
    var parentGoalId: UUID?
    
    // Visual indicators
    var isLinked: Bool {
        return linkedNoteId != nil || linkedTaskId != nil || linkedJournalId != nil || linkedDreamId != nil
    }
    
    var isTaskCompleted: Bool {
        return taskStatus == .completed
    }
    
    init(id: UUID = UUID(), title: String, type: NodeType, position: CGPoint, size: NodeSize, linkedNoteId: UUID? = nil, linkedTaskId: UUID? = nil, linkedJournalId: UUID? = nil, linkedDreamId: UUID? = nil, taskStatus: TaskStatus? = nil, isGoalNode: Bool = false, orbitalRadius: CGFloat = 0.0, orbitalSpeed: CGFloat = 1.0, parentGoalId: UUID? = nil) {
        self.id = id
        self.title = title
        self.type = type
        self.position = position
        self.size = size
        self.linkedNoteId = linkedNoteId
        self.linkedTaskId = linkedTaskId
        self.linkedJournalId = linkedJournalId
        self.linkedDreamId = linkedDreamId
        self.taskStatus = taskStatus
        self.isGoalNode = isGoalNode
        self.orbitalRadius = orbitalRadius
        self.orbitalSpeed = orbitalSpeed
        self.parentGoalId = parentGoalId
    }
}

// MARK: - Galaxy Connection Model
struct GalaxyConnection: Identifiable, Codable {
    let id: UUID
    let fromNode: GalaxyNode
    let toNode: GalaxyNode
    let isTemporary: Bool
    
    init(id: UUID = UUID(), fromNode: GalaxyNode, toNode: GalaxyNode, isTemporary: Bool = false) {
        self.id = id
        self.fromNode = fromNode
        self.toNode = toNode
        self.isTemporary = isTemporary
    }
}

// MARK: - Galaxy Theme
enum GalaxyTheme: String, CaseIterable, Codable {
    case cosmic = "cosmic"
    case dreamy = "dreamy"
    case creative = "creative"
    case analytical = "analytical"
    case mystical = "mystical"
    
    var displayName: String {
        switch self {
        case .cosmic: return "Cosmic"
        case .dreamy: return "Dreamy"
        case .creative: return "Creative"
        case .analytical: return "Analytical"
        case .mystical: return "Mystical"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .cosmic: return Color(red: 0.4, green: 0.7, blue: 1.0)
        case .dreamy: return Color(red: 0.8, green: 0.4, blue: 0.9)
        case .creative: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .analytical: return Color(red: 0.2, green: 0.8, blue: 0.6)
        case .mystical: return Color(red: 0.6, green: 0.2, blue: 0.8)
        }
    }
    
    var backgroundGradient: [Color] {
        switch self {
        case .cosmic:
            return [
                Color(red: 0.4, green: 0.7, blue: 1.0),
                Color(red: 0.2, green: 0.4, blue: 0.8),
                Color(red: 0.1, green: 0.2, blue: 0.5)
            ]
        case .dreamy:
            return [
                Color(red: 0.8, green: 0.4, blue: 0.9),
                Color(red: 0.6, green: 0.2, blue: 0.7),
                Color(red: 0.4, green: 0.1, blue: 0.5)
            ]
        case .creative:
            return [
                Color(red: 1.0, green: 0.6, blue: 0.2),
                Color(red: 0.8, green: 0.4, blue: 0.1),
                Color(red: 0.6, green: 0.2, blue: 0.05)
            ]
        case .analytical:
            return [
                Color(red: 0.2, green: 0.8, blue: 0.6),
                Color(red: 0.1, green: 0.6, blue: 0.4),
                Color(red: 0.05, green: 0.4, blue: 0.2)
            ]
        case .mystical:
            return [
                Color(red: 0.6, green: 0.2, blue: 0.8),
                Color(red: 0.4, green: 0.1, blue: 0.6),
                Color(red: 0.2, green: 0.05, blue: 0.4)
            ]
        }
    }
}

// MARK: - Galaxy Model
struct Galaxy: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var nodeTypes: [NodeType]
    var nodes: [GalaxyNode]
    var connections: [GalaxyConnection]
    var theme: GalaxyTheme
    let createdAt: Date
    var lastModified: Date
    
    init(name: String, description: String = "", nodeTypes: [NodeType] = [.note], theme: GalaxyTheme = .cosmic) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.nodeTypes = nodeTypes
        self.nodes = []
        self.connections = []
        self.theme = theme
        self.createdAt = Date()
        self.lastModified = Date()
    }
}
