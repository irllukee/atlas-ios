import SwiftUI

struct FilterView: View {
    @Binding var filters: EatDoFilters
    let categories: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: AtlasTheme.Spacing.lg) {
                // Header
                headerView
                
                // Filter Content
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Category Filter
                        categoryFilterView
                        
                        // Price Range Filter
                        priceRangeFilterView
                        
                        // Rating Filter
                        ratingFilterView
                        
                        // Sort Options
                        sortOptionsView
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                }
                
                // Apply Button
                applyButton
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Filters")
                    .font(AtlasTheme.Typography.largeTitle)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Customize your search")
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
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.top, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Category Filter
    private var categoryFilterView: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Category")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    ForEach(["All"] + categories, id: \.self) { category in
                        Button(action: {
                            AtlasTheme.Haptics.selection()
                            filters.selectedCategory = category
                        }) {
                            Text(category)
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(filters.selectedCategory == category ? AtlasTheme.Colors.text : AtlasTheme.Colors.secondaryText)
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .padding(.vertical, AtlasTheme.Spacing.sm)
                                .glassmorphism(
                                    style: filters.selectedCategory == category ? .medium : .light,
                                    cornerRadius: AtlasTheme.CornerRadius.medium
                                )
                        }
                    }
                }
                .padding(.horizontal, AtlasTheme.Spacing.lg)
            }
        }
    }
    
    // MARK: - Price Range Filter
    private var priceRangeFilterView: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Price Range")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    ForEach(["All", "$", "$$", "$$$", "$$$$", "$$$$$"], id: \.self) { priceRange in
                        Button(action: {
                            AtlasTheme.Haptics.selection()
                            filters.selectedPriceRange = priceRange
                        }) {
                            Text(priceRange)
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(filters.selectedPriceRange == priceRange ? AtlasTheme.Colors.text : AtlasTheme.Colors.secondaryText)
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .padding(.vertical, AtlasTheme.Spacing.sm)
                                .glassmorphism(
                                    style: filters.selectedPriceRange == priceRange ? .medium : .light,
                                    cornerRadius: AtlasTheme.CornerRadius.medium
                                )
                        }
                    }
                }
                .padding(.horizontal, AtlasTheme.Spacing.lg)
            }
        }
    }
    
    // MARK: - Rating Filter
    private var ratingFilterView: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Rating Range")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            FrostedCard(style: .standard) {
                VStack(spacing: AtlasTheme.Spacing.md) {
                    // Min Rating
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        Text("Minimum Rating: \(filters.minRating)")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Slider(value: Binding(
                            get: { Double(filters.minRating) },
                            set: { filters.minRating = Int($0) }
                        ), in: 1...10, step: 1)
                        .accentColor(AtlasTheme.Colors.primary)
                    }
                    
                    // Max Rating
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        Text("Maximum Rating: \(filters.maxRating)")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Slider(value: Binding(
                            get: { Double(filters.maxRating) },
                            set: { filters.maxRating = Int($0) }
                        ), in: 1...10, step: 1)
                        .accentColor(AtlasTheme.Colors.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Sort Options
    private var sortOptionsView: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Sort By")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                ForEach(EatDoFilters.SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        AtlasTheme.Haptics.selection()
                        filters.sortOption = option
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .font(AtlasTheme.Typography.body)
                                .foregroundColor(AtlasTheme.Colors.text)
                            
                            Spacer()
                            
                            if filters.sortOption == option {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(AtlasTheme.Colors.accent)
                            }
                        }
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .padding(.vertical, AtlasTheme.Spacing.sm)
                        .glassmorphism(
                            style: filters.sortOption == option ? .medium : .light,
                            cornerRadius: AtlasTheme.CornerRadius.medium
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Apply Button
    private var applyButton: some View {
        Button(action: {
            AtlasTheme.Haptics.success()
            dismiss()
        }) {
            Text("Apply Filters")
                .font(AtlasTheme.Typography.button)
                .foregroundColor(AtlasTheme.Colors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AtlasTheme.Spacing.md)
                .glassmorphism(style: .medium, cornerRadius: AtlasTheme.CornerRadius.medium)
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.bottom, AtlasTheme.Spacing.md)
    }
}

#Preview {
    FilterView(
        filters: .constant(EatDoFilters()),
        categories: EatDoCategories.restaurantCategories
    )
}