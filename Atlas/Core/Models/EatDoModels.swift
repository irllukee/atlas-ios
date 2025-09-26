import Foundation

// MARK: - Base Place Model
struct Place: Identifiable, Codable {
    var id = UUID()
    var name: String
    var city: String
    var state: String
    var rating: Int // 1-10
    var pros: String
    var cons: String
    var priceRange: Int // 1-5 dollar signs
    var category: String
    var dateAdded: Date
    
    init(name: String, city: String, state: String, rating: Int, pros: String, cons: String, priceRange: Int, category: String) {
        self.id = UUID()
        self.name = name
        self.city = city
        self.state = state
        self.rating = rating
        self.pros = pros
        self.cons = cons
        self.priceRange = priceRange
        self.category = category
        self.dateAdded = Date()
    }
}

// MARK: - Restaurant Model
struct Restaurant: Identifiable, Codable {
    var id = UUID()
    var name: String
    var city: String
    var state: String
    var rating: Int // 1-10
    var pros: String
    var cons: String
    var priceRange: Int // 1-5 dollar signs
    var category: String
    var dateAdded: Date
    
    init(name: String, city: String, state: String, rating: Int, pros: String, cons: String, priceRange: Int, category: String) {
        self.id = UUID()
        self.name = name
        self.city = city
        self.state = state
        self.rating = rating
        self.pros = pros
        self.cons = cons
        self.priceRange = priceRange
        self.category = category
        self.dateAdded = Date()
    }
}

// MARK: - Activity Model
struct Activity: Identifiable, Codable {
    var id = UUID()
    var name: String
    var city: String
    var state: String
    var rating: Int // 1-10
    var pros: String
    var cons: String
    var priceRange: Int // 1-5 dollar signs
    var category: String
    var dateAdded: Date
    
    init(name: String, city: String, state: String, rating: Int, pros: String, cons: String, priceRange: Int, category: String) {
        self.id = UUID()
        self.name = name
        self.city = city
        self.state = state
        self.rating = rating
        self.pros = pros
        self.cons = cons
        self.priceRange = priceRange
        self.category = category
        self.dateAdded = Date()
    }
}

// MARK: - Categories
struct EatDoCategories {
    static let restaurantCategories = [
        "American", "Italian", "Mexican", "Asian", "Mediterranean",
        "Indian", "French", "Seafood", "Fast Food", "Cafe/Coffee",
        "Dessert/Ice Cream", "Other"
    ]
    
    static let activityCategories = [
        "Outdoor", "Entertainment", "Cultural", "Sports", "Shopping",
        "Nightlife", "Family", "Wellness", "Educational", "Social", "Other"
    ]
    
    static let priceRanges = ["$", "$$", "$$$", "$$$$", "$$$$$"]
}

// MARK: - Filter Options
struct EatDoFilters: Equatable {
    var selectedCategory: String = "All"
    var selectedPriceRange: String = "All"
    var minRating: Int = 1
    var maxRating: Int = 10
    var searchText: String = ""
    var sortOption: SortOption = .rating
    
    enum SortOption: String, CaseIterable {
        case rating = "Rating"
        case name = "Name"
        case dateAdded = "Date Added"
    }
}
