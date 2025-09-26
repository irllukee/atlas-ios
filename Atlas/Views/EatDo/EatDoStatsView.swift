import SwiftUI

struct EatDoStatsView: View {
    @ObservedObject var eatDoService: EatDoService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AtlasTheme.Spacing.lg) {
                    // Header
                    headerView
                    
                    // Overview Stats
                    overviewStatsView
                    
                    // Category Breakdown
                    categoryBreakdownView
                    
                    // Rating Distribution
                    ratingDistributionView
                    
                    // Recent Additions
                    recentAdditionsView
                }
                .padding(.horizontal, AtlasTheme.Spacing.lg)
                .padding(.bottom, AtlasTheme.Spacing.xl)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Eat & Do Stats")
                    .font(AtlasTheme.Typography.largeTitle)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Your place tracking insights")
                    .font(AtlasTheme.Typography.subheadline)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                AtlasTheme.Haptics.light()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .frame(width: 44, height: 44)
                    .glassmorphism(style: .light, cornerRadius: 22)
            }
        }
        .padding(.top, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Overview Stats
    private var overviewStatsView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            Text("Overview")
                .font(AtlasTheme.Typography.title2)
                .foregroundColor(AtlasTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: AtlasTheme.Spacing.md) {
                // Total Places
                FrostedCard(style: .metric) {
                    VStack(spacing: 8) {
                        Text("\(eatDoService.restaurants.count + eatDoService.activities.count)")
                            .font(AtlasTheme.Typography.display)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("Total Places")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                }
                
                // Average Rating
                FrostedCard(style: .metric) {
                    VStack(spacing: 8) {
                        Text(String(format: "%.1f", averageRating))
                            .font(AtlasTheme.Typography.display)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("Avg Rating")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdownView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            Text("Categories")
                .font(AtlasTheme.Typography.title2)
                .foregroundColor(AtlasTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: AtlasTheme.Spacing.md) {
                ForEach(restaurantCategories, id: \.self) { category in
                    categoryCard(category: category, count: restaurantCount(for: category))
                }
                
                ForEach(activityCategories, id: \.self) { category in
                    categoryCard(category: category, count: activityCount(for: category))
                }
            }
        }
    }
    
    // MARK: - Rating Distribution
    private var ratingDistributionView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            Text("Rating Distribution")
                .font(AtlasTheme.Typography.title2)
                .foregroundColor(AtlasTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FrostedCard(style: .standard) {
                VStack(spacing: AtlasTheme.Spacing.sm) {
                    ForEach(1...10, id: \.self) { rating in
                        ratingBar(rating: rating, count: ratingCount(for: rating))
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Additions
    private var recentAdditionsView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            Text("Recent Additions")
                .font(AtlasTheme.Typography.title2)
                .foregroundColor(AtlasTheme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        ForEach(Array(recentPlaces.prefix(5).enumerated()), id: \.offset) { index, place in
                            recentPlaceRow(place: place)
                        }
                    }
        }
    }
    
    // MARK: - Helper Views
    private func categoryCard(category: String, count: Int) -> some View {
        FrostedCard(style: .compact) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(AtlasTheme.Typography.title3)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text(category)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func ratingBar(rating: Int, count: Int) -> some View {
        HStack(spacing: AtlasTheme.Spacing.sm) {
            Text("\(rating)")
                .font(AtlasTheme.Typography.caption)
                .foregroundColor(AtlasTheme.Colors.secondaryText)
                .frame(width: 20)
            
            GeometryReader { geometry in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AtlasTheme.Colors.primary)
                        .frame(width: geometry.size.width * CGFloat(count) / CGFloat(maxRatingCount))
                    
                    Spacer()
                }
            }
            .frame(height: 8)
            
            Text("\(count)")
                .font(AtlasTheme.Typography.caption)
                .foregroundColor(AtlasTheme.Colors.secondaryText)
                .frame(width: 20)
        }
    }
    
    private func recentPlaceRow(place: Any) -> some View {
        HStack {
            Image(systemName: place is Restaurant ? "fork.knife" : "figure.walk")
                .foregroundColor(AtlasTheme.Colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(place is Restaurant ? (place as! Restaurant).name : (place as! Activity).name)
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text(place is Restaurant ? (place as! Restaurant).category : (place as! Activity).category)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                ForEach(0..<(place is Restaurant ? (place as! Restaurant).rating : (place as! Activity).rating), id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AtlasTheme.Colors.warning)
                }
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.xs)
    }
    
    // MARK: - Computed Properties
    private var averageRating: Double {
        let allPlaces: [Any] = eatDoService.restaurants + eatDoService.activities
        guard !allPlaces.isEmpty else { return 0 }
        let totalRating = allPlaces.reduce(0) { sum, place in
            if let restaurant = place as? Restaurant {
                return sum + restaurant.rating
            } else if let activity = place as? Activity {
                return sum + activity.rating
            }
            return sum
        }
        return Double(totalRating) / Double(allPlaces.count)
    }
    
    private var restaurantCategories: [String] {
        Array(Set(eatDoService.restaurants.map { $0.category }))
    }
    
    private var activityCategories: [String] {
        Array(Set(eatDoService.activities.map { $0.category }))
    }
    
    private func restaurantCount(for category: String) -> Int {
        eatDoService.restaurants.filter { $0.category == category }.count
    }
    
    private func activityCount(for category: String) -> Int {
        eatDoService.activities.filter { $0.category == category }.count
    }
    
    private var ratingCount: [Int: Int] {
        let allPlaces: [Any] = eatDoService.restaurants + eatDoService.activities
        var counts: [Int: Int] = [:]
        for place in allPlaces {
            let rating: Int
            if let restaurant = place as? Restaurant {
                rating = restaurant.rating
            } else if let activity = place as? Activity {
                rating = activity.rating
            } else {
                continue
            }
            counts[rating, default: 0] += 1
        }
        return counts
    }
    
    private func ratingCount(for rating: Int) -> Int {
        ratingCount[rating] ?? 0
    }
    
    private var maxRatingCount: Int {
        ratingCount.values.max() ?? 1
    }
    
    private var recentPlaces: [Any] {
        let allPlaces: [Any] = eatDoService.restaurants + eatDoService.activities
        return allPlaces.sorted { place1, place2 in
            let date1: Date
            let date2: Date
            
            if let restaurant1 = place1 as? Restaurant {
                date1 = restaurant1.dateAdded
            } else if let activity1 = place1 as? Activity {
                date1 = activity1.dateAdded
            } else {
                date1 = Date.distantPast
            }
            
            if let restaurant2 = place2 as? Restaurant {
                date2 = restaurant2.dateAdded
            } else if let activity2 = place2 as? Activity {
                date2 = activity2.dateAdded
            } else {
                date2 = Date.distantPast
            }
            
            return date1 > date2
        }
    }
}

#Preview {
    EatDoStatsView(eatDoService: EatDoService())
}
