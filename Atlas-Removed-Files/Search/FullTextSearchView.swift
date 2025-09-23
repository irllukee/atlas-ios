import SwiftUI
import Combine

/// Advanced full-text search view for notes and content
struct FullTextSearchView: View {
    
    // MARK: - Properties
    @StateObject private var searchService = SearchService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedContentType: ContentType? = nil
    @State private var selectedSortOption: SearchSortOption = .relevance
    @State private var showingFilters = false
    @State private var showingSearchHistory = false
    @State private var selectedResult: SearchResult? = nil
    
    @FocusState private var isSearchFocused: Bool
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Header
                    searchHeader
                    
                    // Search Results
                    searchContent
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isSearchFocused = true
        }
        .onChange(of: searchText) { _, newValue in
            searchService.searchQuery = newValue
            if !newValue.isEmpty {
                performSearch()
            } else {
                searchService.searchResults = []
            }
        }
    }
    
    // MARK: - Search Header
    private var searchHeader: some View {
        VStack(spacing: 0) {
            // Top bar with back button and title
            HStack {
                // Back button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                
                Spacer()
                
                Text("Search")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Filter button
                Button(action: {
                    AtlasTheme.Haptics.light()
                    showingFilters.toggle()
                }) {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Search bar
            searchBar
            
            // Filters (if shown)
            if showingFilters {
                filtersView
            }
        }
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            // Search icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            // Search field
            TextField("Search notes, tasks, and more...", text: $searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
            
            // Clear button
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    AtlasTheme.Haptics.light()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Voice search button (placeholder)
            Button(action: {
                AtlasTheme.Haptics.light()
                // TODO: Implement voice search
            }) {
                Image(systemName: "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Filters View
    private var filtersView: some View {
        VStack(spacing: 12) {
            // Content type filter
            HStack {
                Text("Content Type:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Menu {
                    Button("All Types") {
                        selectedContentType = nil
                        performSearch()
                    }
                    
                    ForEach(ContentType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            selectedContentType = type
                            performSearch()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedContentType?.displayName ?? "All Types")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            
            // Sort options
            HStack {
                Text("Sort by:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Menu {
                    ForEach(SearchSortOption.allCases, id: \.self) { option in
                        Button(option.displayName) {
                            selectedSortOption = option
                            performSearch()
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedSortOption.displayName)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Content
    private var searchContent: some View {
        Group {
            if searchText.isEmpty {
                searchSuggestionsView
            } else if searchService.isSearching {
                loadingView
            } else if searchService.searchResults.isEmpty {
                emptyResultsView
            } else {
                searchResultsView
            }
        }
    }
    
    // MARK: - Search Suggestions
    private var searchSuggestionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Recent searches
                if !searchService.recentSearches.isEmpty {
                    recentSearchesSection
                }
                
                // Search suggestions
                if !searchService.searchSuggestions.isEmpty {
                    searchSuggestionsSection
                }
                
                // Quick actions
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Searches")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Clear") {
                    searchService.clearSearchHistory()
                    AtlasTheme.Haptics.light()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AtlasTheme.Colors.accent)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(searchService.recentSearches.prefix(5), id: \.self) { search in
                    Button(action: {
                        searchText = search
                        AtlasTheme.Haptics.light()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 20)
                            
                            Text(search)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                searchService.removeFromSearchHistory(search)
                                AtlasTheme.Haptics.light()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }
    
    private var searchSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggestions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(searchService.searchSuggestions, id: \.id) { suggestion in
                    Button(action: {
                        searchText = suggestion.text
                        AtlasTheme.Haptics.light()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: suggestion.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(suggestion.color)
                                .frame(width: 20)
                            
                            Text(suggestion.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(systemName: "arrow.up.left")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                quickActionCard("All Notes", icon: "note.text", action: {
                    selectedContentType = .note
                    searchText = ""
                    performSearch()
                })
                
                quickActionCard("Recent Notes", icon: "clock", action: {
                    searchText = "today"
                })
                
                quickActionCard("Favorites", icon: "star.fill", action: {
                    searchText = "favorite"
                })
                
                quickActionCard("Tasks", icon: "checklist", action: {
                    selectedContentType = .task
                    searchText = ""
                    performSearch()
                })
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }
    
    private func quickActionCard(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            AtlasTheme.Haptics.light()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AtlasTheme.Colors.accent)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Empty Results View
    private var emptyResultsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Try different keywords or check your spelling")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Search tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Search Tips:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("• Use specific keywords")
                Text("• Try searching for partial words")
                Text("• Use filters to narrow results")
                Text("• Check different content types")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 100)
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Results header
            HStack {
                Text("\(searchService.searchResults.count) results for \"\(searchText)\"")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
            )
            
            // Results list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(searchService.searchResults, id: \.id) { result in
                        SearchResultCard(result: result, searchTerm: searchText) {
                            selectedResult = result
                            // TODO: Navigate to the specific content
                            AtlasTheme.Haptics.light()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        let query = SearchQuery(
            text: searchText,
            contentType: selectedContentType,
            sortBy: selectedSortOption,
            limit: 50
        )
        
        _Concurrency.Task {
            await searchService.search(query)
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let result: SearchResult
    let searchTerm: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with content type and relevance
                HStack {
                    // Content type badge
                    HStack(spacing: 4) {
                        Image(systemName: result.contentType.icon)
                            .font(.system(size: 12, weight: .medium))
                        Text(result.contentType.displayName)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(result.contentType.color.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(result.contentType.color, lineWidth: 1)
                            )
                    )
                    
                    Spacer()
                    
                    // Relevance score
                    if result.relevanceScore > 0 {
                        HStack(spacing: 2) {
                            ForEach(0..<Int(result.relevanceScore * 5), id: \.self) { _ in
                                Circle()
                                    .fill(AtlasTheme.Colors.accent)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
                
                // Title with highlighted search terms
                Text(highlightedText(result.title, searchTerm: searchTerm))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Content preview with highlighted search terms
                if !result.content.isEmpty {
                    Text(highlightedText(String(result.content.prefix(150)), searchTerm: searchTerm))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Metadata
                HStack {
                    // Matched fields
                    if !result.matchedFields.isEmpty {
                        Text("Found in: \(result.matchedFields.joined(separator: ", "))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Date
                    Text(result.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func highlightedText(_ text: String, searchTerm: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        if !searchTerm.isEmpty {
            let range = text.range(of: searchTerm, options: .caseInsensitive)
            if let range = range {
                let nsRange = NSRange(range, in: text)
                if let attributedRange = Range(nsRange, in: attributedString) {
                    attributedString[attributedRange].backgroundColor = AtlasTheme.Colors.accent.opacity(0.3)
                    attributedString[attributedRange].foregroundColor = .white
                }
            }
        }
        
        return attributedString
    }
}

// MARK: - Preview

struct FullTextSearchView_Previews: PreviewProvider {
    static var previews: some View {
        FullTextSearchView()
    }
}

