import Foundation
import SwiftUI

// MARK: - Performance Test for Eat & Do Feature
@MainActor
class EatDoPerformanceTest: ObservableObject {
    private let eatDoService = EatDoService()
    
    func runPerformanceTests() {
        print("🧪 Starting Eat & Do Performance Tests...")
        
        // Test 1: Large Dataset Performance
        testLargeDatasetPerformance()
        
        // Test 2: Save Operation Performance
        testSaveOperationPerformance()
        
        // Test 3: Search Performance
        testSearchPerformance()
        
        // Test 4: Filter Performance
        testFilterPerformance()
        
        print("✅ Performance tests completed!")
    }
    
    // MARK: - Test 1: Large Dataset Performance
    private func testLargeDatasetPerformance() {
        print("\n📊 Testing Large Dataset Performance...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create 1000 restaurants and activities
        for i in 1...1000 {
            let restaurant = Restaurant(
                name: "Restaurant \(i)",
                city: "City \(i % 50)",
                state: "State \(i % 10)",
                rating: Int.random(in: 1...10),
                pros: "Great food \(i)",
                cons: "Long wait \(i)",
                priceRange: Int.random(in: 1...5),
                category: EatDoCategories.restaurantCategories.randomElement() ?? "American"
            )
            
            let activity = Activity(
                name: "Activity \(i)",
                city: "City \(i % 50)",
                state: "State \(i % 10)",
                rating: Int.random(in: 1...10),
                pros: "Fun experience \(i)",
                cons: "Expensive \(i)",
                priceRange: Int.random(in: 1...5),
                category: EatDoCategories.activityCategories.randomElement() ?? "Outdoor"
            )
            
            eatDoService.addRestaurant(restaurant)
            eatDoService.addActivity(activity)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("✅ Created 1000 restaurants and 1000 activities in \(String(format: "%.3f", duration))s")
        print("📈 Average time per entry: \(String(format: "%.3f", duration / 2000))s")
    }
    
    // MARK: - Test 2: Save Operation Performance
    private func testSaveOperationPerformance() {
        print("\n💾 Testing Save Operation Performance...")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test rapid save operations
        for i in 1...100 {
            let restaurant = Restaurant(
                name: "Test Restaurant \(i)",
                city: "Test City",
                state: "Test State",
                rating: 5,
                pros: "Test pros",
                cons: "Test cons",
                priceRange: 3,
                category: "American"
            )
            
            eatDoService.addRestaurant(restaurant)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        print("✅ Added 100 restaurants with debounced saves in \(String(format: "%.3f", duration))s")
        print("📈 Average time per save operation: \(String(format: "%.3f", duration / 100))s")
    }
    
    // MARK: - Test 3: Search Performance
    private func testSearchPerformance() {
        print("\n🔍 Testing Search Performance...")
        
        let searchTerms = ["Restaurant", "City", "Great", "Fun", "Test", "Activity"]
        
        for term in searchTerms {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            var filters = EatDoFilters()
            filters.searchText = term
            
            let restaurants = eatDoService.filteredRestaurants(filters: filters)
            let activities = eatDoService.filteredActivities(filters: filters)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            print("✅ Search for '\(term)': \(restaurants.count) restaurants, \(activities.count) activities in \(String(format: "%.3f", duration))s")
        }
    }
    
    // MARK: - Test 4: Filter Performance
    private func testFilterPerformance() {
        print("\n🎯 Testing Filter Performance...")
        
        let filterTests = [
            ("Category Filter", { () -> EatDoFilters in
                var filters = EatDoFilters()
                filters.selectedCategory = "American"
                return filters
            }),
            ("Price Range Filter", { () -> EatDoFilters in
                var filters = EatDoFilters()
                filters.selectedPriceRange = "$$$"
                return filters
            }),
            ("Rating Filter", { () -> EatDoFilters in
                var filters = EatDoFilters()
                filters.minRating = 7
                filters.maxRating = 10
                return filters
            }),
            ("Combined Filters", { () -> EatDoFilters in
                var filters = EatDoFilters()
                filters.selectedCategory = "Italian"
                filters.selectedPriceRange = "$$"
                filters.minRating = 8
                filters.maxRating = 10
                filters.searchText = "pizza"
                return filters
            })
        ]
        
        for (testName, filterGenerator) in filterTests {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let filters = filterGenerator()
            let restaurants = eatDoService.filteredRestaurants(filters: filters)
            let activities = eatDoService.filteredActivities(filters: filters)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            print("✅ \(testName): \(restaurants.count) restaurants, \(activities.count) activities in \(String(format: "%.3f", duration))s")
        }
    }
}

// MARK: - Performance Test View
struct EatDoPerformanceTestView: View {
    @StateObject private var performanceTest = EatDoPerformanceTest()
    @State private var isRunning = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Eat & Do Performance Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("This test will create a large dataset and measure performance metrics for the Eat & Do feature.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    isRunning = true
                    _Concurrency.Task {
                        performanceTest.runPerformanceTests()
                        isRunning = false
                    }
                }) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isRunning ? "Running Tests..." : "Start Performance Test")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(isRunning ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isRunning)
                
                if isRunning {
                    Text("Tests are running... This may take a few moments.")
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("Performance Test")
        }
    }
}

#Preview {
    EatDoPerformanceTestView()
}
