import SwiftUI

struct ActivityListView: View {
    @ObservedObject var eatDoService: EatDoService
    @Binding var showingAddActivity: Bool
    @State private var filters = EatDoFilters()
    @State private var showingFilters = false
    
    // Performance optimization: Debounce search
    @State private var searchText = ""
    @State private var searchTask: _Concurrency.Task<Void, Never>?
    
    private var filteredActivities: [Activity] {
        eatDoService.filteredActivities(filters: filters)
    }
    
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterView
                
                // Content
                if filteredActivities.isEmpty {
                    emptyStateView
                } else {
                    activityListView
                }
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            AddEditActivityView(eatDoService: eatDoService)
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(filters: $filters, categories: EatDoCategories.activityCategories)
        }
    }
    
    // MARK: - Search and Filter View
    private var searchAndFilterView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            // Search Bar
            HStack(spacing: AtlasTheme.Spacing.md) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    
                    TextField("Search activities...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.text)
                        .onChange(of: searchText) { _, newValue in
                            // Debounce search input
                            searchTask?.cancel()
                            searchTask = _Concurrency.Task { @MainActor in
                                try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                                guard !_Concurrency.Task.isCancelled else { return }
                                filters.searchText = newValue
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            filters.searchText = ""
                        }
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.accent)
                    }
                }
                .padding(.horizontal, AtlasTheme.Spacing.md)
                .padding(.vertical, AtlasTheme.Spacing.sm)
                .glassmorphism(style: .light, cornerRadius: AtlasTheme.CornerRadius.medium)
                
                // Filter Button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingFilters = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.accent)
                        .frame(width: 44, height: 44)
                        .glassmorphism(style: .light, cornerRadius: 22)
                }
            }
            
            // Active Filters
            if hasActiveFilters {
                activeFiltersView
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.bottom, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Active Filters
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasTheme.Spacing.sm) {
                if filters.selectedCategory != "All" {
                    filterChip(title: "Category: \(filters.selectedCategory)") {
                        filters.selectedCategory = "All"
                    }
                }
                
                if filters.selectedPriceRange != "All" {
                    filterChip(title: "Price: \(filters.selectedPriceRange)") {
                        filters.selectedPriceRange = "All"
                    }
                }
                
                if filters.minRating > 1 || filters.maxRating < 10 {
                    filterChip(title: "Rating: \(filters.minRating)-\(filters.maxRating)") {
                        filters.minRating = 1
                        filters.maxRating = 10
                    }
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.lg)
        }
    }
    
    private func filterChip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            AtlasTheme.Haptics.light()
            action()
        }) {
            HStack(spacing: AtlasTheme.Spacing.xs) {
                Text(title)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            }
            .padding(.horizontal, AtlasTheme.Spacing.sm)
            .padding(.vertical, AtlasTheme.Spacing.xs)
            .glassmorphism(style: .light, cornerRadius: AtlasTheme.CornerRadius.small)
        }
    }
    
    // MARK: - Activity List
    private var activityListView: some View {
        ScrollView {
            LazyVStack(spacing: AtlasTheme.Spacing.md) {
                ForEach(filteredActivities) { activity in
                    ActivityCard(
                        activity: activity,
                        onEdit: { editActivity(activity) },
                        onDelete: { deleteActivity(activity) }
                    )
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.lg)
            .padding(.bottom, AtlasTheme.Spacing.xl)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 80))
                .foregroundColor(AtlasTheme.Colors.secondaryText)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("No Activities Yet")
                    .font(AtlasTheme.Typography.title2)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Start building your activity collection by adding your favorite things to do.")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                AtlasTheme.Haptics.medium()
                showingAddActivity = true
            }) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "plus")
                        .font(.title3)
                    
                    Text("Add Activity")
                        .font(AtlasTheme.Typography.button)
                }
                .foregroundColor(AtlasTheme.Colors.text)
                .padding(.horizontal, AtlasTheme.Spacing.lg)
                .padding(.vertical, AtlasTheme.Spacing.md)
                .glassmorphism(style: .medium, cornerRadius: AtlasTheme.CornerRadius.medium)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.xl)
        .padding(.top, AtlasTheme.Spacing.xxl)
    }
    
    // MARK: - Helper Properties
    private var hasActiveFilters: Bool {
        filters.selectedCategory != "All" ||
        filters.selectedPriceRange != "All" ||
        filters.minRating > 1 ||
        filters.maxRating < 10
    }
    
    // MARK: - Actions
    private func editActivity(_ activity: Activity) {
        // TODO: Implement edit functionality - will need to pass activity to edit form
        // For now, this is a placeholder
    }
    
    private func deleteActivity(_ activity: Activity) {
        AtlasTheme.Haptics.warning()
        eatDoService.deleteActivity(activity)
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: Activity
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        FrostedCard(style: .standard) {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.name)
                            .font(AtlasTheme.Typography.title3)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("\(activity.city), \(activity.state)")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Rating
                    HStack(spacing: 2) {
                        ForEach(0..<activity.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(AtlasTheme.Colors.warning)
                        }
                    }
                }
                
                // Category and Price
                HStack {
                    Text(activity.category)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.accent)
                        .padding(.horizontal, AtlasTheme.Spacing.sm)
                        .padding(.vertical, AtlasTheme.Spacing.xs)
                        .glassmorphism(style: .light, cornerRadius: AtlasTheme.CornerRadius.small)
                    
                    Spacer()
                    
                    Text(String(repeating: "$", count: activity.priceRange))
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
                
                // Pros and Cons
                if !activity.pros.isEmpty || !activity.cons.isEmpty {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        if !activity.pros.isEmpty {
                            HStack(alignment: .top, spacing: AtlasTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AtlasTheme.Colors.success)
                                    .font(.caption)
                                
                                Text(activity.pros)
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundColor(AtlasTheme.Colors.text)
                            }
                        }
                        
                        if !activity.cons.isEmpty {
                            HStack(alignment: .top, spacing: AtlasTheme.Spacing.sm) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AtlasTheme.Colors.error)
                                    .font(.caption)
                                
                                Text(activity.cons)
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundColor(AtlasTheme.Colors.text)
                            }
                        }
                    }
                }
                
                // Actions
                HStack {
                    Spacer()
                    
                    Button(action: {
                        AtlasTheme.Haptics.light()
                        onEdit()
                    }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(AtlasTheme.Colors.accent)
                    }
                    
                    Button(action: {
                        AtlasTheme.Haptics.warning()
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(AtlasTheme.Colors.error)
                    }
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AtlasTheme.Animations.spring, value: isPressed)
        .onTapGesture {
            withAnimation(AtlasTheme.Animations.snappy) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AtlasTheme.Animations.snappy) {
                    isPressed = false
                }
            }
        }
    }
}

#Preview {
    ActivityListView(
        eatDoService: EatDoService(),
        showingAddActivity: .constant(false)
    )
}