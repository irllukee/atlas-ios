import SwiftUI

struct WatchlistView: View {
    @StateObject private var watchlistService: WatchlistService
    @StateObject private var tmdbService = TMDBService()
    @State private var showingAddItem = false
    @State private var selectedItem: WatchlistItem?
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var searchResults: [TMDBItem] = []
    @State private var showingSearchResults = false
    @State private var isSearching = false
    
    // Animation states
    @State private var headerOpacity: Double = 0
    @State private var headerOffset: CGFloat = -20
    @State private var itemsOpacity: Double = 0
    @State private var itemsOffset: CGFloat = 30
    @State private var fabScale: CGFloat = 0.8
    @State private var fabOpacity: Double = 0
    
    // MARK: - Initialization
    init(dataManager: DataManager) {
        self._watchlistService = StateObject(wrappedValue: WatchlistService(dataManager: dataManager))
    }
    
    var body: some View {
        ZStack {
            // Background
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Frosted Header Bar
                frostedHeaderBar
                
                // Main Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Statistics Cards
                        statisticsSection
                            .padding(.top, 20)
                        
                        // Filter and Sort Controls
                        filterControlsSection
                            .padding(.horizontal, 20)
                        
                        // Watchlist Items
                        watchlistItemsSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            
        }
        .sheet(isPresented: $showingAddItem) {
            AddWatchlistItemView(watchlistService: watchlistService)
        }
        .sheet(item: $selectedItem) { item in
            WatchlistItemDetailView(item: item, watchlistService: watchlistService)
        }
        .onAppear {
            animateOnAppear()
        }
        .onChange(of: watchlistService.searchText) { _, _ in
            watchlistService.applyFilters()
        }
        .onChange(of: watchlistService.selectedFilter) { _, _ in
            watchlistService.applyFilters()
        }
    }
    
    // MARK: - Frosted Header Bar
    private var frostedHeaderBar: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watchlist")
                        .font(AtlasTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    let stats = watchlistService.getStatistics()
                    Text("\(stats.total) items • \(stats.watched) watched")
                        .font(AtlasTheme.Typography.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(AtlasTheme.Colors.primary)
                                    .overlay(
                                        Circle()
                                            .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                                    )
                            )
                    }
                    
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(AtlasTheme.Colors.glassBackground)
                                    .overlay(
                                        Circle()
                                            .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Search Bar
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search movies and shows...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            showingSearchResults = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .fill(AtlasTheme.Colors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                        )
                )
                
                // Search Results Dropdown
                if showingSearchResults && !searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(searchResults.prefix(5), id: \.id) { result in
                                TMDBSearchResultRow(result: result) {
                                    addMovieFromSearch(result)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 300)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .fill(AtlasTheme.Colors.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                    .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                            )
                    )
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
        .background(
            // Frosted glass effect
            Rectangle()
                .fill(AtlasTheme.Colors.glassBackground)
                .overlay(
                    Rectangle()
                        .fill(AtlasTheme.Colors.glassGradient)
                )
                .overlay(
                    Rectangle()
                        .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                )
        )
        .opacity(headerOpacity)
        .offset(y: headerOffset)
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        let stats = watchlistService.getStatistics()
        let averageRating = watchlistService.getAverageRating()
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Total Items
            WatchlistStatCard(
                title: "Total",
                value: "\(stats.total)",
                icon: "list.bullet",
                color: .blue
            )
            
            // Watched Items
            WatchlistStatCard(
                title: "Watched",
                value: "\(stats.watched)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            // Movies
            WatchlistStatCard(
                title: "Movies",
                value: "\(stats.movies)",
                icon: "tv",
                color: .purple
            )
            
            // TV Shows
            WatchlistStatCard(
                title: "TV Shows",
                value: "\(stats.tvShows)",
                icon: "tv.fill",
                color: .orange
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Filter Controls Section
    private var filterControlsSection: some View {
        VStack(spacing: 12) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(WatchlistService.WatchlistFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.displayName,
                            isSelected: watchlistService.selectedFilter == filter,
                            action: {
                                watchlistService.updateFilter(filter)
                                AtlasTheme.Haptics.light()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Sort Control
            HStack {
                Text("Sort by:")
                    .font(AtlasTheme.Typography.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Menu {
                    ForEach(WatchlistService.WatchlistSortOrder.allCases, id: \.self) { order in
                        Button(order.displayName) {
                            watchlistService.updateSortOrder(order)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(watchlistService.sortOrder.displayName)
                            .font(AtlasTheme.Typography.subheadline)
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.small)
                            .fill(AtlasTheme.Colors.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.small)
                                    .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Watchlist Items Section
    private var watchlistItemsSection: some View {
        LazyVStack(spacing: 12) {
            if watchlistService.filteredItems.isEmpty {
                emptyStateView
            } else {
                ForEach(watchlistService.filteredItems, id: \.uuid) { item in
                    WatchlistItemCard(item: item) {
                        selectedItem = item
                    }
                }
            }
        }
        .opacity(itemsOpacity)
        .offset(y: itemsOffset)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tv")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No items found")
                    .font(AtlasTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Add movies and TV shows to your watchlist")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddItem = true }) {
                Text("Add First Item")
                    .font(AtlasTheme.Typography.button)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .fill(AtlasTheme.Colors.primary)
                    )
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Animation Functions
    private func animateOnAppear() {
        withAnimation(.easeOut(duration: 0.6)) {
            headerOpacity = 1.0
            headerOffset = 0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            itemsOpacity = 1.0
            itemsOffset = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) {
            fabScale = 1.0
            fabOpacity = 1.0
        }
    }
    
    // MARK: - Search Functions
    private func performSearch(query: String) {
        guard !query.isEmpty && query.count >= 2 else {
            searchResults = []
            showingSearchResults = false
            return
        }
        
        isSearching = true
        
        // Search both movies and TV shows using the multi endpoint
        tmdbService.searchAll(query: query) { allResults in
            DispatchQueue.main.async {
                searchResults = Array(allResults.prefix(10)) // Limit to 10 results
                showingSearchResults = !searchResults.isEmpty
                isSearching = false
            }
        }
    }
    
    private func addMovieFromSearch(_ result: TMDBItem) {
        let watchlistItem = watchlistService.createWatchlistItem(
            title: result.displayTitle,
            type: result.mediaType == "movie" ? "Movie" : "TV Show",
            genre: tmdbService.getGenreNames(for: result.genreIds ?? []).joined(separator: ", "),
            posterURL: result.posterURL,
            notes: nil
        )
        
        if watchlistItem != nil {
            // Clear search
            searchText = ""
            searchResults = []
            showingSearchResults = false
            
            // Show success feedback
            AtlasTheme.Haptics.success()
        } else {
            AtlasTheme.Haptics.error()
        }
    }
}

// MARK: - Supporting Views

struct WatchlistStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(AtlasTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(AtlasTheme.Typography.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                .fill(AtlasTheme.Colors.glassBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AtlasTheme.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                        .fill(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                                .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WatchlistItemCard: View {
    let item: WatchlistItem
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Poster/Icon
                AsyncImage(url: URL(string: item.posterURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.small)
                        .fill(AtlasTheme.Colors.glassBackground)
                        .overlay(
                            Image(systemName: item.type?.lowercased() == "movie" ? "tv" : "tv.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                .frame(width: 60, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.small))
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.title ?? "Untitled")
                            .font(AtlasTheme.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button(action: {
                            // Toggle watched status
                        }) {
                            Image(systemName: item.isWatched ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(item.isWatched ? .green : .white.opacity(0.5))
                        }
                    }
                    
                    HStack {
                        Text(item.type?.capitalized ?? "Unknown")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        
                        
                        Spacer()
                    }
                    
                    if let genre = item.genre, !genre.isEmpty {
                        Text(genre)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    if item.isWatched && item.rating > 0 {
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(item.rating / 2) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .fill(AtlasTheme.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - TMDB Search Result Row
struct TMDBSearchResultRow: View {
    let result: TMDBItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: result.posterURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AtlasTheme.Colors.glassBackground)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                .frame(width: 50, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.displayTitle)
                        .font(AtlasTheme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack {
                        Text(result.mediaType?.capitalized ?? "Unknown")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if let year = result.releaseYear {
                            Text("• \(year)")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    if let overview = result.overview, !overview.isEmpty {
                        Text(overview)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(AtlasTheme.Colors.primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AtlasTheme.Colors.glassBackground.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AtlasTheme.Colors.glassBorder.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WatchlistView(dataManager: DataManager.shared)
}
