import Foundation
import SwiftUI

@MainActor
class EatDoService: ObservableObject {
    @Published var restaurants: [Restaurant] = []
    @Published var activities: [Activity] = []
    
    private let restaurantsKey = "EatDoRestaurants"
    private let activitiesKey = "EatDoActivities"
    
    // Performance optimization: Debounce save operations
    private var saveTask: _Concurrency.Task<Void, Never>?
    private let saveDelay: TimeInterval = 0.5 // 500ms debounce
    
    // Performance optimization: Cache filtered results
    private var cachedRestaurants: [Restaurant]?
    private var cachedActivities: [Activity]?
    private var lastFilters: EatDoFilters?
    
    init() {
        loadData()
    }
    
    // MARK: - Data Persistence
    private func loadData() {
        loadRestaurants()
        loadActivities()
    }
    
    private func loadRestaurants() {
        if let data = UserDefaults.standard.data(forKey: restaurantsKey),
           let decoded = try? JSONDecoder().decode([Restaurant].self, from: data) {
            restaurants = decoded
        }
    }
    
    private func loadActivities() {
        if let data = UserDefaults.standard.data(forKey: activitiesKey),
           let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
            activities = decoded
        }
    }
    
    private func saveRestaurants() {
        // Cancel previous save task
        saveTask?.cancel()
        
        // Debounce save operation
        saveTask = _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(saveDelay * 1_000_000_000))
            
            guard !_Concurrency.Task.isCancelled else { return }
            
            if let encoded = try? JSONEncoder().encode(restaurants) {
                UserDefaults.standard.set(encoded, forKey: restaurantsKey)
            }
        }
    }
    
    private func saveActivities() {
        // Cancel previous save task
        saveTask?.cancel()
        
        // Debounce save operation
        saveTask = _Concurrency.Task { @MainActor in
            try? await _Concurrency.Task.sleep(nanoseconds: UInt64(saveDelay * 1_000_000_000))
            
            guard !_Concurrency.Task.isCancelled else { return }
            
            if let encoded = try? JSONEncoder().encode(activities) {
                UserDefaults.standard.set(encoded, forKey: activitiesKey)
            }
        }
    }
    
    // MARK: - Restaurant Management
    func addRestaurant(_ restaurant: Restaurant) {
        restaurants.append(restaurant)
        invalidateCache()
        saveRestaurants()
    }
    
    func updateRestaurant(_ restaurant: Restaurant) {
        if let index = restaurants.firstIndex(where: { $0.id == restaurant.id }) {
            restaurants[index] = restaurant
            invalidateCache()
            saveRestaurants()
        }
    }
    
    func deleteRestaurant(_ restaurant: Restaurant) {
        restaurants.removeAll { $0.id == restaurant.id }
        invalidateCache()
        saveRestaurants()
    }
    
    // MARK: - Activity Management
    func addActivity(_ activity: Activity) {
        activities.append(activity)
        invalidateCache()
        saveActivities()
    }
    
    func updateActivity(_ activity: Activity) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
            invalidateCache()
            saveActivities()
        }
    }
    
    func deleteActivity(_ activity: Activity) {
        activities.removeAll { $0.id == activity.id }
        invalidateCache()
        saveActivities()
    }
    
    // MARK: - Cache Management
    private func invalidateCache() {
        cachedRestaurants = nil
        cachedActivities = nil
        lastFilters = nil
    }
    
    // MARK: - Filtering and Sorting
    func filteredRestaurants(filters: EatDoFilters) -> [Restaurant] {
        // Check cache first
        if let cached = cachedRestaurants,
           let lastFilters = lastFilters,
           lastFilters == filters {
            return cached
        }
        
        var filtered = restaurants
        
        // Search filter
        if !filters.searchText.isEmpty {
            filtered = filtered.filter { restaurant in
                restaurant.name.localizedCaseInsensitiveContains(filters.searchText) ||
                restaurant.city.localizedCaseInsensitiveContains(filters.searchText) ||
                restaurant.state.localizedCaseInsensitiveContains(filters.searchText) ||
                restaurant.pros.localizedCaseInsensitiveContains(filters.searchText) ||
                restaurant.cons.localizedCaseInsensitiveContains(filters.searchText)
            }
        }
        
        // Category filter
        if filters.selectedCategory != "All" {
            filtered = filtered.filter { $0.category == filters.selectedCategory }
        }
        
        // Price range filter
        if filters.selectedPriceRange != "All" {
            let priceIndex = EatDoCategories.priceRanges.firstIndex(of: filters.selectedPriceRange) ?? 0
            filtered = filtered.filter { $0.priceRange == priceIndex + 1 }
        }
        
        // Rating filter
        filtered = filtered.filter { restaurant in
            restaurant.rating >= filters.minRating && restaurant.rating <= filters.maxRating
        }
        
        // Sorting
        switch filters.sortOption {
        case .rating:
            filtered.sort { $0.rating > $1.rating }
        case .name:
            filtered.sort { $0.name < $1.name }
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        }
        
        // Cache results
        cachedRestaurants = filtered
        lastFilters = filters
        
        return filtered
    }
    
    func filteredActivities(filters: EatDoFilters) -> [Activity] {
        // Check cache first
        if let cached = cachedActivities,
           let lastFilters = lastFilters,
           lastFilters == filters {
            return cached
        }
        
        var filtered = activities
        
        // Search filter
        if !filters.searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.name.localizedCaseInsensitiveContains(filters.searchText) ||
                activity.city.localizedCaseInsensitiveContains(filters.searchText) ||
                activity.state.localizedCaseInsensitiveContains(filters.searchText) ||
                activity.pros.localizedCaseInsensitiveContains(filters.searchText) ||
                activity.cons.localizedCaseInsensitiveContains(filters.searchText)
            }
        }
        
        // Category filter
        if filters.selectedCategory != "All" {
            filtered = filtered.filter { $0.category == filters.selectedCategory }
        }
        
        // Price range filter
        if filters.selectedPriceRange != "All" {
            let priceIndex = EatDoCategories.priceRanges.firstIndex(of: filters.selectedPriceRange) ?? 0
            filtered = filtered.filter { $0.priceRange == priceIndex + 1 }
        }
        
        // Rating filter
        filtered = filtered.filter { activity in
            activity.rating >= filters.minRating && activity.rating <= filters.maxRating
        }
        
        // Sorting
        switch filters.sortOption {
        case .rating:
            filtered.sort { $0.rating > $1.rating }
        case .name:
            filtered.sort { $0.name < $1.name }
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        }
        
        // Cache results
        cachedActivities = filtered
        lastFilters = filters
        
        return filtered
    }
}
