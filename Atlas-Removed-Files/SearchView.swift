import SwiftUI

// MARK: - Search View
struct SearchView: View {
    @StateObject private var searchService = SearchService.shared
    @StateObject private var tagService = TagService.shared
    @State private var searchText = ""
    @State private var selectedContentType: ContentType?
    @State private var selectedTags: Set<Tag> = []
    @State private var sortBy: SearchSortOption = .relevance
    @State private var showingFilters = false
    @State private var showingSuggestions = false
    
    // Date formatter
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Filters (when showing)
                if showingFilters {
                    filtersSection
                }
                
                // Search Results
                if searchService.isSearching {
                    loadingView
                } else if searchService.searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else if searchService.searchResults.isEmpty {
                    emptyStateView
                } else {
                    searchResultsView
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(showingFilters ? .blue : .primary)
                    }
                }
            }
            .onAppear {
                searchText = searchService.searchQuery
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        VStack(spacing: 0) {
            HStack {
                ModernSearchBar(
                    searchText: $searchText,
                    placeholder: "Search notes, tasks, journal...",
                    onSearch: { query in
                        searchService.searchQuery = query
                        if !query.isEmpty {
                            showingSuggestions = true
                            searchService.getSearchSuggestions(for: query)
                        } else {
                            showingSuggestions = false
                        }
                    },
                    onClear: {
                        clearSearch()
                    }
                )
                
                if !searchText.isEmpty {
                    Button("Search") {
                        performSearch()
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AtlasTheme.Colors.primary)
                    )
                    .foregroundColor(.white)
                }
            }
            .padding()
            
            // Search Suggestions
            if showingSuggestions && !searchService.searchSuggestions.isEmpty {
                searchSuggestionsView
            }
        }
    }
    
    // MARK: - Search Suggestions
    private var searchSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(searchService.searchSuggestions) { suggestion in
                Button(action: {
                    selectSuggestion(suggestion)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: suggestion.icon)
                            .foregroundColor(suggestion.color)
                            .frame(width: 20)
                        
                        Text(suggestion.text)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(suggestion.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if suggestion.id != searchService.searchSuggestions.last?.id {
                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(spacing: 16) {
            // Content Type Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Content Type")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedContentType == nil,
                            action: { selectedContentType = nil }
                        )
                        
                        ForEach(ContentType.allCases, id: \.self) { contentType in
                            FilterChip(
                                title: contentType.displayName,
                                isSelected: selectedContentType == contentType,
                                action: { selectedContentType = contentType }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Tags Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tagService.tags) { tag in
                            TagChip(
                                tag: tag,
                                isSelected: selectedTags.contains(tag),
                                action: { toggleTag(tag) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Sort Options
            VStack(alignment: .leading, spacing: 8) {
                Text("Sort By")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Sort By", selection: $sortBy) {
                    ForEach(SearchSortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Search Results
    private var searchResultsView: some View {
        List {
            ForEach(searchService.searchResults) { result in
                SearchResultRow(result: result)
                    .onTapGesture {
                        // Navigate to the specific content
                        navigateToContent(result)
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty Results View
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Try adjusting your search terms or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                clearFilters()
            }
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Search Your Content")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Find notes, tasks, journal entries, and more")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Recent Searches
            if !searchService.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Searches")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(searchService.recentSearches.prefix(5), id: \.self) { search in
                        Button(action: {
                            searchText = search
                            performSearch()
                        }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.secondary)
                                
                                Text(search)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        showingSuggestions = false
        
        let query = SearchQuery(
            text: searchText,
            contentType: selectedContentType,
            tags: Array(selectedTags),
            sortBy: sortBy
        )
        
        _Concurrency.Task {
            await searchService.search(query)
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchService.searchQuery = ""
        showingSuggestions = false
        searchService.searchResults = []
    }
    
    private func selectSuggestion(_ suggestion: SearchSuggestion) {
        searchText = suggestion.text
        showingSuggestions = false
        performSearch()
    }
    
    private func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func clearFilters() {
        selectedContentType = nil
        selectedTags.removeAll()
        sortBy = .relevance
    }
    
    private func navigateToContent(_ result: SearchResult) {
        // This would navigate to the specific content based on type
        // Implementation would depend on your navigation structure
        print("Navigate to \(result.contentType.rawValue) with ID: \(result.contentId)")
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.contentType.icon)
                    .foregroundColor(result.contentType.color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(result.contentType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(result.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if result.relevanceScore > 0 {
                        Text("\(Int(result.relevanceScore * 100))%")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if !result.content.isEmpty {
                Text(result.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            if !result.matchedFields.isEmpty {
                HStack {
                    Text("Matched in:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ForEach(result.matchedFields, id: \.self) { field in
                        Text(field)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? .blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(tag.displayColor)
                    .frame(width: 8, height: 8)
                
                Text(tag.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? tag.displayColor : Color(.systemGray5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Suggestion Extension
extension SearchSuggestion.SuggestionType {
    var rawValue: String {
        switch self {
        case .recent: return "recent"
        case .popular: return "popular"
        case .tag: return "tag"
        case .contentType: return "contentType"
        case .smart: return "smart"
        }
    }
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
