import SwiftUI

/// Enumeration of different content types in the Atlas app
enum ContentType: String, CaseIterable {
    case note = "note"
    case task = "task"
    case journal = "journal"
    case mood = "mood"
    
    var displayName: String {
        switch self {
        case .note:
            return "Notes"
        case .task:
            return "Tasks"
        case .journal:
            return "Journal"
        case .mood:
            return "Mood"
        }
    }
    
    var icon: String {
        switch self {
        case .note:
            return "note.text"
        case .task:
            return "checklist"
        case .journal:
            return "book.pages"
        case .mood:
            return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .note:
            return .blue
        case .task:
            return .green
        case .journal:
            return .purple
        case .mood:
            return .pink
        }
    }
}

