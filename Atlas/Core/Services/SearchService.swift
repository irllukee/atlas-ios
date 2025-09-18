import Foundation
import CoreData
import Combine
import SwiftUI

// MARK: - Search Models
struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let contentId: UUID
    let title: String
    let content: String
    let contentType: ContentType
    let relevanceScore: Double
    let matchedFields: [String]
    let createdAt: Date
    let updatedAt: Date
    let tags: [Tag]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SearchQuery {
    let text: String
    let contentType: ContentType?
    let tags: [Tag]
    let dateRange: DateInterval?
    let sortBy: SearchSortOption
    let limit: Int
    
    init(
        text: String,
        contentType: ContentType? = nil,
        tags: [Tag] = [],
        dateRange: DateInterval? = nil,
        sortBy: SearchSortOption = .relevance,
        limit: Int = 50
    ) {
        self.text = text
        self.contentType = contentType
        self.tags = tags
        self.dateRange = dateRange
        self.sortBy = sortBy
        self.limit = limit
    }
}

enum SearchSortOption: String, CaseIterable {
    case relevance = "Relevance"
    case dateCreated = "Date Created"
    case dateUpdated = "Date Updated"
    case title = "Title"
    
    var displayName: String {
        return rawValue
    }
}

struct SearchSuggestion: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let type: SuggestionType
    let icon: String
    let color: Color
    
    enum SuggestionType {
        case recent
        case popular
        case tag
        case contentType
        case smart
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Search Service
@MainActor
class SearchService: ObservableObject {
    static let shared = SearchService()
    
    @Published var searchResults: [SearchResult] = []
    @Published var searchSuggestions: [SearchSuggestion] = []
    @Published var recentSearches: [String] = []
    @Published var popularSearches: [String] = []
    @Published var isSearching = false
    @Published var searchQuery = ""
    
    private let dataManager: DataManager
    private let tagService: TagService
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: _Concurrency.Task<Void, Never>?
    
    private init() {
        self.dataManager = DataManager.shared
        self.tagService = TagService.shared
        loadSearchHistory()
        setupSearchDebouncing()
    }
    
    // MARK: - Search Methods
    
    func search(_ query: SearchQuery) async {
        isSearching = true
        searchTask?.cancel()
        
        searchTask = _Concurrency.Task {
            do {
                let results = try await performSearch(query)
                
                if !_Concurrency.Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = results
                        self.isSearching = false
                        self.addToSearchHistory(query.text)
                    }
                }
            } catch {
                if !_Concurrency.Task.isCancelled {
                    await MainActor.run {
                        self.searchResults = []
                        self.isSearching = false
                    }
                }
            }
        }
    }
    
    func quickSearch(_ text: String) async {
        let query = SearchQuery(text: text, limit: 10)
        await search(query)
    }
    
    func searchByTag(_ tag: Tag) async {
        let query = SearchQuery(text: "", tags: [tag])
        await search(query)
    }
    
    func searchByContentType(_ contentType: ContentType) async {
        let query = SearchQuery(text: "", contentType: contentType)
        await search(query)
    }
    
    // MARK: - Search Suggestions
    
    func getSearchSuggestions(for text: String) {
        var suggestions: [SearchSuggestion] = []
        
        // Add recent searches
        let recentMatches = recentSearches
            .filter { $0.localizedCaseInsensitiveContains(text) }
            .prefix(3)
            .map { SearchSuggestion(text: $0, type: SearchSuggestion.SuggestionType.recent, icon: "clock", color: .gray) }
        suggestions.append(contentsOf: recentMatches)
        
        // Add popular searches
        let popularMatches = popularSearches
            .filter { $0.localizedCaseInsensitiveContains(text) }
            .prefix(2)
            .map { SearchSuggestion(text: $0, type: SearchSuggestion.SuggestionType.popular, icon: "star.fill", color: .yellow) }
        suggestions.append(contentsOf: popularMatches)
        
        // Add tag suggestions
        let tagMatches = tagService.searchTags(query: text)
            .prefix(3)
            .map { SearchSuggestion(text: $0.name, type: SearchSuggestion.SuggestionType.tag, icon: "tag.fill", color: $0.displayColor) }
        suggestions.append(contentsOf: tagMatches)
        
        // Add content type suggestions
        let contentTypeMatches = ContentType.allCases
            .filter { $0.displayName.localizedCaseInsensitiveContains(text) }
            .prefix(2)
            .map { SearchSuggestion(text: $0.displayName, type: SearchSuggestion.SuggestionType.contentType, icon: $0.icon, color: $0.color) }
        suggestions.append(contentsOf: contentTypeMatches)
        
        // Add smart suggestions
        let smartSuggestions = generateSmartSuggestions(for: text)
        suggestions.append(contentsOf: smartSuggestions)
        
        searchSuggestions = Array(Set(suggestions)).prefix(10).map { $0 }
    }
    
    // MARK: - Search History
    
    func clearSearchHistory() {
        recentSearches.removeAll()
        saveSearchHistory()
    }
    
    func removeFromSearchHistory(_ search: String) {
        recentSearches.removeAll { $0 == search }
        saveSearchHistory()
    }
    
    // MARK: - Private Methods
    
    private func performSearch(_ query: SearchQuery) async throws -> [SearchResult] {
        var results: [SearchResult] = []
        
        // Search in different content types
        if query.contentType == nil || query.contentType == .note {
            let noteResults = try await searchNotes(query)
            results.append(contentsOf: noteResults)
        }
        
        if query.contentType == nil || query.contentType == .task {
            let taskResults = try await searchTasks(query)
            results.append(contentsOf: taskResults)
        }
        
        if query.contentType == nil || query.contentType == .journal {
            let journalResults = try await searchJournal(query)
            results.append(contentsOf: journalResults)
        }
        
        if query.contentType == nil || query.contentType == .mood {
            let moodResults = try await searchMood(query)
            results.append(contentsOf: moodResults)
        }
        
        // Sort results
        results = sortResults(results, by: query.sortBy)
        
        // Apply limit
        return Array(results.prefix(query.limit))
    }
    
    private func searchNotes(_ query: SearchQuery) async throws -> [SearchResult] {
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Text search
        if !query.text.isEmpty {
            let textPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query.text, query.text)
            predicates.append(textPredicate)
        }
        
        // Date range filter
        if let dateRange = query.dateRange {
            let datePredicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", dateRange.start as NSDate, dateRange.end as NSDate)
            predicates.append(datePredicate)
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        let notes = try context.fetch(request)
        
        return notes.compactMap { note in
            guard let id = note.uuid,
                  let title = note.title,
                  let content = note.content,
                  let createdAt = note.createdAt,
                  let updatedAt = note.updatedAt else { return nil }
            
            let relevanceScore = calculateRelevanceScore(
                searchText: query.text,
                title: title,
                content: content
            )
            
            let matchedFields = getMatchedFields(searchText: query.text, title: title, content: content)
            
            return SearchResult(
                contentId: id,
                title: title,
                content: content,
                contentType: .note,
                relevanceScore: relevanceScore,
                matchedFields: matchedFields,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: [] // Would need to implement tag relationships
            )
        }
    }
    
    private func searchTasks(_ query: SearchQuery) async throws -> [SearchResult] {
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Text search
        if !query.text.isEmpty {
            let textPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", query.text, query.text)
            predicates.append(textPredicate)
        }
        
        // Date range filter
        if let dateRange = query.dateRange {
            let datePredicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", dateRange.start as NSDate, dateRange.end as NSDate)
            predicates.append(datePredicate)
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        let tasks = try context.fetch(request)
        
        return tasks.compactMap { task in
            guard let id = task.uuid,
                  let title = task.title,
                  let createdAt = task.createdAt,
                  let updatedAt = task.updatedAt else { return nil }
            
            let content = task.notes ?? ""
            let relevanceScore = calculateRelevanceScore(
                searchText: query.text,
                title: title,
                content: content
            )
            
            let matchedFields = getMatchedFields(searchText: query.text, title: title, content: content)
            
            return SearchResult(
                contentId: id,
                title: title,
                content: content,
                contentType: .task,
                relevanceScore: relevanceScore,
                matchedFields: matchedFields,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: [] // Would need to implement tag relationships
            )
        }
    }
    
    private func searchJournal(_ query: SearchQuery) async throws -> [SearchResult] {
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Text search
        if !query.text.isEmpty {
            let textPredicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query.text, query.text)
            predicates.append(textPredicate)
        }
        
        // Date range filter
        if let dateRange = query.dateRange {
            let datePredicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", dateRange.start as NSDate, dateRange.end as NSDate)
            predicates.append(datePredicate)
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        let entries = try context.fetch(request)
        
        return entries.compactMap { entry in
            guard let id = entry.uuid,
                  let content = entry.content,
                  let createdAt = entry.createdAt,
                  let updatedAt = entry.updatedAt else { return nil }
            
            let title = String(content.prefix(50)) + (content.count > 50 ? "..." : "")
            
            let relevanceScore = calculateRelevanceScore(
                searchText: query.text,
                title: title,
                content: content
            )
            
            let matchedFields = getMatchedFields(searchText: query.text, title: title, content: content)
            
            return SearchResult(
                contentId: id,
                title: title,
                content: content,
                contentType: .journal,
                relevanceScore: relevanceScore,
                matchedFields: matchedFields,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: [] // Would need to implement tag relationships
            )
        }
    }
    
    private func searchMood(_ query: SearchQuery) async throws -> [SearchResult] {
        let context = dataManager.coreDataStack.persistentContainer.viewContext
        let request: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        // Text search
        if !query.text.isEmpty {
            let textPredicate = NSPredicate(format: "notes CONTAINS[cd] %@", query.text)
            predicates.append(textPredicate)
        }
        
        // Date range filter
        if let dateRange = query.dateRange {
            let datePredicate = NSPredicate(format: "date >= %@ AND date <= %@", dateRange.start as NSDate, dateRange.end as NSDate)
            predicates.append(datePredicate)
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        let entries = try context.fetch(request)
        var results: [SearchResult] = []
        
        for entry in entries {
            guard let id = entry.uuid,
                  let createdAt = entry.createdAt else { continue }
            
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let title = "Mood Entry - \(formatter.string(from: createdAt))"
            let content = entry.notes ?? ""
            let relevanceScore = calculateRelevanceScore(
                searchText: query.text,
                title: title,
                content: content
            )
            
            let matchedFields = getMatchedFields(searchText: query.text, title: title, content: content)
            
            let result = SearchResult(
                contentId: id,
                title: title,
                content: content,
                contentType: .mood,
                relevanceScore: relevanceScore,
                matchedFields: matchedFields,
                createdAt: createdAt,
                updatedAt: createdAt,
                tags: [] // Would need to implement tag relationships
            )
            
            results.append(result)
        }
        
        return results
    }
    
    private func calculateRelevanceScore(searchText: String, title: String, content: String) -> Double {
        if searchText.isEmpty {
            return 0.5
        }
        
        let searchWords = searchText.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let titleWords = title.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let contentWords = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        var score = 0.0
        
        // Title matches are weighted higher
        for word in searchWords {
            if titleWords.contains(word) {
                score += 0.3
            }
            if contentWords.contains(word) {
                score += 0.1
            }
        }
        
        // Exact phrase matches
        if title.lowercased().contains(searchText.lowercased()) {
            score += 0.5
        }
        if content.lowercased().contains(searchText.lowercased()) {
            score += 0.2
        }
        
        return min(score, 1.0)
    }
    
    private func getMatchedFields(searchText: String, title: String, content: String) -> [String] {
        var fields: [String] = []
        
        if title.localizedCaseInsensitiveContains(searchText) {
            fields.append("Title")
        }
        if content.localizedCaseInsensitiveContains(searchText) {
            fields.append("Content")
        }
        
        return fields
    }
    
    private func sortResults(_ results: [SearchResult], by sortOption: SearchSortOption) -> [SearchResult] {
        switch sortOption {
        case .relevance:
            return results.sorted { $0.relevanceScore > $1.relevanceScore }
        case .dateCreated:
            return results.sorted { $0.createdAt > $1.createdAt }
        case .dateUpdated:
            return results.sorted { $0.updatedAt > $1.updatedAt }
        case .title:
            return results.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    private func generateSmartSuggestions(for text: String) -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // Generate smart suggestions based on common patterns
        if text.localizedCaseInsensitiveContains("today") {
            suggestions.append(SearchSuggestion(text: "Today's entries", type: SearchSuggestion.SuggestionType.smart, icon: "calendar", color: .blue))
        }
        
        if text.localizedCaseInsensitiveContains("work") {
            suggestions.append(SearchSuggestion(text: "Work related", type: SearchSuggestion.SuggestionType.smart, icon: "briefcase", color: .orange))
        }
        
        if text.localizedCaseInsensitiveContains("important") {
            suggestions.append(SearchSuggestion(text: "Important items", type: SearchSuggestion.SuggestionType.smart, icon: "exclamationmark", color: .red))
        }
        
        return suggestions
    }
    
    private func setupSearchDebouncing() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.getSearchSuggestions(for: query)
                } else {
                    self?.searchSuggestions = []
                }
            }
            .store(in: &cancellables)
    }
    
    private func addToSearchHistory(_ search: String) {
        if !search.isEmpty && !recentSearches.contains(search) {
            recentSearches.insert(search, at: 0)
            if recentSearches.count > 20 {
                recentSearches = Array(recentSearches.prefix(20))
            }
            saveSearchHistory()
        }
    }
    
    private func loadSearchHistory() {
        if let data = UserDefaults.standard.data(forKey: "AtlasSearchHistory"),
           let searches = try? JSONDecoder().decode([String].self, from: data) {
            recentSearches = searches
        }
        
        // Load popular searches (could be based on analytics)
        popularSearches = ["work", "important", "today", "meeting", "project"]
    }
    
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(recentSearches) {
            UserDefaults.standard.set(data, forKey: "AtlasSearchHistory")
        }
    }
}

