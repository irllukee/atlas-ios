import Foundation
import CoreData
import SwiftUI

/// Service for managing watchlist items (movies and TV shows)
@MainActor
class WatchlistService: ObservableObject {
    
    // MARK: - Properties
    private let dataManager: DataManager
    
    @Published var watchlistItems: [WatchlistItem] = []
    @Published var filteredItems: [WatchlistItem] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: WatchlistFilter = .all
    @Published var sortOrder: WatchlistSortOrder = .dateAddedDescending
    
    // MARK: - Enums
    enum WatchlistFilter: String, CaseIterable {
        case all = "All"
        case movies = "Movies"
        case tvShows = "TV Shows"
        case watched = "Watched"
        case unwatched = "Unwatched"
        
        var displayName: String {
            return rawValue
        }
    }
    
    enum WatchlistSortOrder: String, CaseIterable {
        case dateAddedDescending = "Date Added (Newest)"
        case dateAddedAscending = "Date Added (Oldest)"
        case titleAscending = "Title (A-Z)"
        case titleDescending = "Title (Z-A)"
        case ratingDescending = "Rating (Highest)"
        case ratingAscending = "Rating (Lowest)"
        
        var displayName: String {
            return rawValue
        }
    }
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        loadWatchlistItems()
    }
    
    // MARK: - CRUD Operations
    
    /// Create a new watchlist item
    func createWatchlistItem(
        title: String,
        type: String,
        genre: String? = nil,
        posterURL: String? = nil,
        notes: String? = nil
    ) -> WatchlistItem? {
        
        let context = dataManager.coreDataStack.viewContext
        
        let watchlistItem = WatchlistItem(context: context)
        watchlistItem.uuid = UUID()
        watchlistItem.title = title
        watchlistItem.type = type
        watchlistItem.genre = genre
        watchlistItem.posterURL = posterURL
        watchlistItem.notes = notes
        watchlistItem.isWatched = false
        watchlistItem.rating = 0
        watchlistItem.createdAt = Date()
        watchlistItem.updatedAt = Date()
        
        do {
            try context.save()
            loadWatchlistItems()
            return watchlistItem
        } catch {
            print("Error creating watchlist item: \(error)")
            return nil
        }
    }
    
    /// Update an existing watchlist item
    func updateWatchlistItem(
        _ item: WatchlistItem,
        title: String? = nil,
        type: String? = nil,
        genre: String? = nil,
        posterURL: String? = nil,
        notes: String? = nil,
        rating: Int16? = nil
    ) -> Bool {
        
        let context = dataManager.coreDataStack.viewContext
        
        if let title = title {
            item.title = title
        }
        if let type = type {
            item.type = type
        }
        if let genre = genre {
            item.genre = genre
        }
        if let posterURL = posterURL {
            item.posterURL = posterURL
        }
        if let notes = notes {
            item.notes = notes
        }
        if let rating = rating {
            item.rating = rating
        }
        
        item.updatedAt = Date()
        
        do {
            try context.save()
            loadWatchlistItems()
            return true
        } catch {
            print("Error updating watchlist item: \(error)")
            return false
        }
    }
    
    /// Mark an item as watched/unwatched
    func toggleWatchedStatus(_ item: WatchlistItem) -> Bool {
        let context = dataManager.coreDataStack.viewContext
        
        item.isWatched.toggle()
        if item.isWatched {
            item.watchedAt = Date()
        } else {
            item.watchedAt = nil
            item.rating = 0 // Reset rating when unwatched
        }
        item.updatedAt = Date()
        
        do {
            try context.save()
            loadWatchlistItems()
            return true
        } catch {
            print("Error toggling watched status: \(error)")
            return false
        }
    }
    
    /// Set rating for a watched item
    func setRating(for item: WatchlistItem, rating: Int16) -> Bool {
        guard item.isWatched else { return false }
        
        let context = dataManager.coreDataStack.viewContext
        item.rating = max(0, min(10, rating)) // Clamp between 0-10
        item.updatedAt = Date()
        
        do {
            try context.save()
            loadWatchlistItems()
            return true
        } catch {
            print("Error setting rating: \(error)")
            return false
        }
    }
    
    /// Delete a watchlist item
    func deleteWatchlistItem(_ item: WatchlistItem) -> Bool {
        let context = dataManager.coreDataStack.viewContext
        context.delete(item)
        
        do {
            try context.save()
            loadWatchlistItems()
            return true
        } catch {
            print("Error deleting watchlist item: \(error)")
            return false
        }
    }
    
    // MARK: - Data Loading
    
    /// Load all watchlist items from Core Data
    func loadWatchlistItems() {
        let request: NSFetchRequest<WatchlistItem> = WatchlistItem.fetchRequest()
        
        // Apply sorting
        switch sortOrder {
        case .dateAddedDescending:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.createdAt, ascending: false)]
        case .dateAddedAscending:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.createdAt, ascending: true)]
        case .titleAscending:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: true)]
        case .titleDescending:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.title, ascending: false)]
        case .ratingDescending:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.rating, ascending: false)]
        case .ratingAscending:
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WatchlistItem.rating, ascending: true)]
        }
        
        do {
            watchlistItems = try dataManager.coreDataStack.viewContext.fetch(request)
            applyFilters()
        } catch {
            print("Error loading watchlist items: \(error)")
            watchlistItems = []
            filteredItems = []
        }
    }
    
    /// Apply current filters and search
    func applyFilters() {
        var filtered = watchlistItems
        
        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .movies:
            filtered = filtered.filter { $0.type?.lowercased() == "movie" }
        case .tvShows:
            filtered = filtered.filter { $0.type?.lowercased() == "tv show" || $0.type?.lowercased() == "tv" }
        case .watched:
            filtered = filtered.filter { $0.isWatched }
        case .unwatched:
            filtered = filtered.filter { !$0.isWatched }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title?.localizedCaseInsensitiveContains(searchText) == true ||
                item.genre?.localizedCaseInsensitiveContains(searchText) == true ||
                item.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        filteredItems = filtered
    }
    
    // MARK: - Search and Filtering
    
    /// Update search text and apply filters
    func updateSearchText(_ text: String) {
        searchText = text
        applyFilters()
    }
    
    /// Update filter selection and apply filters
    func updateFilter(_ filter: WatchlistFilter) {
        selectedFilter = filter
        applyFilters()
    }
    
    /// Update sort order and reload data
    func updateSortOrder(_ order: WatchlistSortOrder) {
        sortOrder = order
        loadWatchlistItems()
    }
    
    // MARK: - Statistics
    
    /// Get statistics for the watchlist
    func getStatistics() -> (total: Int, watched: Int, movies: Int, tvShows: Int) {
        let total = watchlistItems.count
        let watched = watchlistItems.filter { $0.isWatched }.count
        let movies = watchlistItems.filter { $0.type?.lowercased() == "movie" }.count
        let tvShows = watchlistItems.filter { $0.type?.lowercased() == "tv show" || $0.type?.lowercased() == "tv" }.count
        
        return (total: total, watched: watched, movies: movies, tvShows: tvShows)
    }
    
    /// Get average rating for watched items
    func getAverageRating() -> Double {
        let watchedItems = watchlistItems.filter { $0.isWatched && $0.rating > 0 }
        guard !watchedItems.isEmpty else { return 0.0 }
        
        let totalRating = watchedItems.reduce(0) { $0 + Int($1.rating) }
        return Double(totalRating) / Double(watchedItems.count)
    }
    
    // MARK: - Utility Functions
    
    /// Format runtime in minutes to hours and minutes
    
    /// Get display type (capitalized)
    func getDisplayType(_ type: String?) -> String {
        guard let type = type else { return "Unknown" }
        return type.capitalized
    }
}
