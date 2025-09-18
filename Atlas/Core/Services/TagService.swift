import Foundation
import SwiftUI

/// Service for managing tags
@MainActor
class TagService: ObservableObject {
    static let shared = TagService()
    
    @Published var tags: [Tag] = []
    
    private init() {
        loadTags()
    }
    
    func searchTags(query: String) -> [Tag] {
        if query.isEmpty {
            return tags
        }
        
        return tags.filter { tag in
            tag.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    func addTag(name: String, color: String = "blue") {
        let tag = Tag(name: name, color: color)
        tags.append(tag)
        saveTags()
    }
    
    func removeTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        saveTags()
    }
    
    private func loadTags() {
        // For now, load some default tags
        tags = [
            Tag(name: "Work", color: "blue", icon: "briefcase", usage_count: 15),
            Tag(name: "Personal", color: "green", icon: "person", usage_count: 12),
            Tag(name: "Important", color: "red", icon: "exclamationmark", usage_count: 8),
            Tag(name: "Ideas", color: "yellow", icon: "lightbulb", usage_count: 6),
            Tag(name: "Meeting", color: "purple", icon: "person.3", usage_count: 10),
            Tag(name: "Project", color: "orange", icon: "folder", usage_count: 7)
        ]
    }
    
    private func saveTags() {
        // TODO: Implement Core Data persistence for tags
    }
}