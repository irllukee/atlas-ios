import SwiftUI

/// Model for content tags
struct Tag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: String
    let icon: String?
    let createdAt: Date
    let usage_count: Int
    
    init(name: String, color: String = "blue", icon: String? = nil, usage_count: Int = 0) {
        self.name = name
        self.color = color
        self.icon = icon
        self.createdAt = Date()
        self.usage_count = usage_count
    }
    
    var displayColor: Color {
        switch color.lowercased() {
        case "red":
            return .red
        case "blue":
            return .blue
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "gray":
            return .gray
        default:
            return .blue
        }
    }
}

