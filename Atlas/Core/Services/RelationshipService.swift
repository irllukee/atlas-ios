import Foundation
import CoreData
import Combine
import SwiftUI

// MARK: - Relationship Models
struct ContentRelationship: Identifiable {
    let id = UUID()
    let sourceId: UUID
    let sourceType: ContentType
    let targetId: UUID
    let targetType: ContentType
    let relationshipType: RelationshipType
    let strength: Double
    let createdAt: Date
    let metadata: [String: String]
    
    init(
        sourceId: UUID,
        sourceType: ContentType,
        targetId: UUID,
        targetType: ContentType,
        relationshipType: RelationshipType,
        strength: Double = 1.0,
        metadata: [String: String] = [:]
    ) {
        self.sourceId = sourceId
        self.sourceType = sourceType
        self.targetId = targetId
        self.targetType = targetType
        self.relationshipType = relationshipType
        self.strength = strength
        self.createdAt = Date()
        self.metadata = metadata
    }
}

enum RelationshipType: String, CaseIterable, Codable {
    case related = "related"
    case similar = "similar"
    case dependsOn = "dependsOn"
    case blocks = "blocks"
    case references = "references"
    case follows = "follows"
    case contradicts = "contradicts"
    case enhances = "enhances"
    
    var displayName: String {
        switch self {
        case .related: return "Related"
        case .similar: return "Similar"
        case .dependsOn: return "Depends On"
        case .blocks: return "Blocks"
        case .references: return "References"
        case .follows: return "Follows"
        case .contradicts: return "Contradicts"
        case .enhances: return "Enhances"
        }
    }
    
    var icon: String {
        switch self {
        case .related: return "link"
        case .similar: return "doc.on.doc"
        case .dependsOn: return "arrow.down.circle"
        case .blocks: return "stop.circle"
        case .references: return "quote.bubble"
        case .follows: return "arrow.right.circle"
        case .contradicts: return "exclamationmark.triangle"
        case .enhances: return "plus.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .related: return .blue
        case .similar: return .green
        case .dependsOn: return .orange
        case .blocks: return .red
        case .references: return .purple
        case .follows: return .cyan
        case .contradicts: return .red
        case .enhances: return .green
        }
    }
}

struct RelationshipGraph {
    let nodes: [ContentNode]
    let edges: [RelationshipEdge]
    
    struct ContentNode: Identifiable {
        let id: UUID
        let type: ContentType
        let title: String
        let position: CGPoint
        let importance: Double
    }
    
    struct RelationshipEdge: Identifiable {
        let id = UUID()
        let sourceId: UUID
        let targetId: UUID
        let relationshipType: RelationshipType
        let strength: Double
    }
}

// MARK: - Relationship Service
@MainActor
class RelationshipService: ObservableObject {
    static let shared = RelationshipService()
    
    @Published var relationships: [ContentRelationship] = []
    @Published var relationshipGraph: RelationshipGraph?
    @Published var isAnalyzing = false
    
    private let dataManager: DataManager
    private let tagService: TagService
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.dataManager = DataManager.shared
        self.tagService = TagService.shared
        loadRelationships()
    }
    
    // MARK: - Relationship Management
    
    func createRelationship(
        sourceId: UUID,
        sourceType: ContentType,
        targetId: UUID,
        targetType: ContentType,
        relationshipType: RelationshipType,
        strength: Double = 1.0
    ) {
        let relationship = ContentRelationship(
            sourceId: sourceId,
            sourceType: sourceType,
            targetId: targetId,
            targetType: targetType,
            relationshipType: relationshipType,
            strength: strength
        )
        
        relationships.append(relationship)
        saveRelationships()
    }
    
    func removeRelationship(_ relationship: ContentRelationship) {
        relationships.removeAll { $0.id == relationship.id }
        saveRelationships()
    }
    
    func getRelationships(for contentId: UUID) -> [ContentRelationship] {
        return relationships.filter { $0.sourceId == contentId || $0.targetId == contentId }
    }
    
    func getRelatedContent(for contentId: UUID, limit: Int = 10) -> [ContentRelationship] {
        return getRelationships(for: contentId)
            .sorted { $0.strength > $1.strength }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Automatic Relationship Detection
    
    func analyzeAndCreateRelationships() {
        isAnalyzing = true
        
        _Concurrency.Task {
            await detectContentRelationships()
            await detectTemporalRelationships()
            await detectSemanticRelationships()
            await detectTagRelationships()
            
            await MainActor.run {
                self.isAnalyzing = false
                self.generateRelationshipGraph()
            }
        }
    }
    
    private func detectContentRelationships() async {
        // Detect relationships based on content similarity
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        
        // Analyze notes
        let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let notes = try? context.fetch(notesRequest)
        
        if let notes = notes {
            for i in 0..<notes.count {
                for j in (i+1)..<notes.count {
                    let note1 = notes[i]
                    let note2 = notes[j]
                    
                    if let id1 = note1.uuid, let id2 = note2.uuid,
                       let content1 = note1.content, let content2 = note2.content {
                        
                        let similarity = calculateTextSimilarity(content1, content2)
                        
                        if similarity > 0.7 {
                            createRelationship(
                                sourceId: id1,
                                sourceType: .note,
                                targetId: id2,
                                targetType: .note,
                                relationshipType: .similar,
                                strength: similarity
                            )
                        }
                    }
                }
            }
        }
        
        // Analyze tasks
        let tasksRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let tasks = try? context.fetch(tasksRequest)
        
        if let tasks = tasks {
            for i in 0..<tasks.count {
                for j in (i+1)..<tasks.count {
                    let task1 = tasks[i]
                    let task2 = tasks[j]
                    
                    if let id1 = task1.uuid, let id2 = task2.uuid,
                       let title1 = task1.title, let title2 = task2.title {
                        
                        let similarity = calculateTextSimilarity(title1, title2)
                        
                        if similarity > 0.6 {
                            createRelationship(
                                sourceId: id1,
                                sourceType: .task,
                                targetId: id2,
                                targetType: .task,
                                relationshipType: .related,
                                strength: similarity
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func detectTemporalRelationships() async {
        // Detect relationships based on timing
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        
        // Get all content with timestamps
        let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let tasksRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let journalRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        
        let notes = try? context.fetch(notesRequest)
        let tasks = try? context.fetch(tasksRequest)
        let journalEntries = try? context.fetch(journalRequest)
        
        // Analyze temporal patterns
        var allContent: [(id: UUID, type: ContentType, date: Date)] = []
        
        notes?.forEach { note in
            if let id = note.uuid, let date = note.createdAt {
                allContent.append((id: id, type: .note, date: date))
            }
        }
        
        tasks?.forEach { task in
            if let id = task.uuid, let date = task.createdAt {
                allContent.append((id: id, type: .task, date: date))
            }
        }
        
        journalEntries?.forEach { entry in
            if let id = entry.uuid, let date = entry.createdAt {
                allContent.append((id: id, type: .journal, date: date))
            }
        }
        
        // Sort by date
        allContent.sort { $0.date < $1.date }
        
        // Create temporal relationships
        for i in 0..<(allContent.count - 1) {
            let current = allContent[i]
            let next = allContent[i + 1]
            
            let timeDifference = next.date.timeIntervalSince(current.date)
            
            // If content was created within 1 hour, consider it related
            if timeDifference < 3600 {
                createRelationship(
                    sourceId: current.id,
                    sourceType: current.type,
                    targetId: next.id,
                    targetType: next.type,
                    relationshipType: .follows,
                    strength: 1.0 - (timeDifference / 3600)
                )
            }
        }
    }
    
    private func detectSemanticRelationships() async {
        // Detect relationships based on semantic content analysis
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        
        // Get all content
        let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let tasksRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let journalRequest: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        
        let notes = try? context.fetch(notesRequest)
        let tasks = try? context.fetch(tasksRequest)
        let journalEntries = try? context.fetch(journalRequest)
        
        // Create content items for analysis
        var contentItems: [(id: UUID, type: ContentType, text: String)] = []
        
        notes?.forEach { note in
            if let id = note.uuid, let content = note.content {
                contentItems.append((id: id, type: .note, text: content))
            }
        }
        
        tasks?.forEach { task in
            if let id = task.uuid, let title = task.title {
                let text = title + " " + (task.notes ?? "")
                contentItems.append((id: id, type: .task, text: text))
            }
        }
        
        journalEntries?.forEach { entry in
            if let id = entry.uuid, let content = entry.content {
                contentItems.append((id: id, type: .journal, text: content))
            }
        }
        
        // Analyze semantic relationships
        for i in 0..<contentItems.count {
            for j in (i+1)..<contentItems.count {
                let item1 = contentItems[i]
                let item2 = contentItems[j]
                
                let semanticSimilarity = calculateSemanticSimilarity(item1.text, item2.text)
                
                if semanticSimilarity > 0.6 {
                    createRelationship(
                        sourceId: item1.id,
                        sourceType: item1.type,
                        targetId: item2.id,
                        targetType: item2.type,
                        relationshipType: .related,
                        strength: semanticSimilarity
                    )
                }
            }
        }
    }
    
    private func detectTagRelationships() async {
        // Detect relationships based on shared tags
        // This would require implementing tag relationships in the data model
        // For now, we'll create a placeholder implementation
    }
    
    // MARK: - Relationship Graph Generation
    
    private func generateRelationshipGraph() {
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        
        // Get all content items
        var nodes: [RelationshipGraph.ContentNode] = []
        var edges: [RelationshipGraph.RelationshipEdge] = []
        
        // Create nodes for notes
        let notesRequest: NSFetchRequest<Note> = Note.fetchRequest()
        if let notes = try? context.fetch(notesRequest) {
            for (index, note) in notes.enumerated() {
                if let id = note.uuid, let title = note.title {
                    let node = RelationshipGraph.ContentNode(
                        id: id,
                        type: .note,
                        title: title,
                        position: CGPoint(x: Double(index % 10) * 100, y: Double(index / 10) * 100),
                        importance: 1.0
                    )
                    nodes.append(node)
                }
            }
        }
        
        // Create nodes for tasks
        let tasksRequest: NSFetchRequest<Task> = Task.fetchRequest()
        if let tasks = try? context.fetch(tasksRequest) {
            for (index, task) in tasks.enumerated() {
                if let id = task.uuid, let title = task.title {
                    let node = RelationshipGraph.ContentNode(
                        id: id,
                        type: .task,
                        title: title,
                        position: CGPoint(x: Double(index % 10) * 100, y: Double(index / 10) * 100),
                        importance: 1.0
                    )
                    nodes.append(node)
                }
            }
        }
        
        // Create edges from relationships
        for relationship in relationships {
            let edge = RelationshipGraph.RelationshipEdge(
                sourceId: relationship.sourceId,
                targetId: relationship.targetId,
                relationshipType: relationship.relationshipType,
                strength: relationship.strength
            )
            edges.append(edge)
        }
        
        relationshipGraph = RelationshipGraph(nodes: nodes, edges: edges)
    }
    
    // MARK: - Helper Methods
    
    private func calculateTextSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        if union.isEmpty {
            return 0.0
        }
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func calculateSemanticSimilarity(_ text1: String, _ text2: String) -> Double {
        // Simple semantic similarity based on common words and phrases
        let similarity = calculateTextSimilarity(text1, text2)
        
        // Boost similarity for common phrases
        let phrases1 = extractPhrases(text1)
        let phrases2 = extractPhrases(text2)
        let phraseSimilarity = calculateTextSimilarity(phrases1.joined(separator: " "), phrases2.joined(separator: " "))
        
        return (similarity + phraseSimilarity) / 2.0
    }
    
    private func extractPhrases(_ text: String) -> [String] {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var phrases: [String] = []
        
        for i in 0..<(words.count - 1) {
            let phrase = words[i] + " " + words[i + 1]
            phrases.append(phrase)
        }
        
        return phrases
    }
    
    // MARK: - Persistence
    
    private func loadRelationships() {
        if let data = UserDefaults.standard.data(forKey: "AtlasRelationships"),
           let relationships = try? JSONDecoder().decode([ContentRelationship].self, from: data) {
            self.relationships = relationships
        }
    }
    
    private func saveRelationships() {
        if let data = try? JSONEncoder().encode(relationships) {
            UserDefaults.standard.set(data, forKey: "AtlasRelationships")
        }
    }
}

// MARK: - Content Relationship Extensions
extension ContentRelationship: Codable {
    enum CodingKeys: String, CodingKey {
        case id, sourceId, sourceType, targetId, targetType, relationshipType, strength, createdAt, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sourceId = try container.decode(UUID.self, forKey: .sourceId)
        targetId = try container.decode(UUID.self, forKey: .targetId)
        strength = try container.decode(Double.self, forKey: .strength)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        metadata = try container.decode([String: String].self, forKey: .metadata)
        
        let sourceTypeString = try container.decode(String.self, forKey: .sourceType)
        sourceType = ContentType(rawValue: sourceTypeString) ?? .note
        
        let targetTypeString = try container.decode(String.self, forKey: .targetType)
        targetType = ContentType(rawValue: targetTypeString) ?? .note
        
        let relationshipTypeString = try container.decode(String.self, forKey: .relationshipType)
        relationshipType = RelationshipType(rawValue: relationshipTypeString) ?? .related
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sourceId, forKey: .sourceId)
        try container.encode(targetId, forKey: .targetId)
        try container.encode(strength, forKey: .strength)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(metadata, forKey: .metadata)
        
        try container.encode(sourceType.rawValue, forKey: .sourceType)
        try container.encode(targetType.rawValue, forKey: .targetType)
        try container.encode(relationshipType.rawValue, forKey: .relationshipType)
    }
}
