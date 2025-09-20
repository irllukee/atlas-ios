import SwiftUI

struct AddWatchlistItemView: View {
    @ObservedObject var watchlistService: WatchlistService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var tmdbService = TMDBService()
    
    @State private var title = ""
    @State private var selectedType = "Movie"
    @State private var genre = ""
    @State private var posterURL = ""
    @State private var notes = ""
    @State private var searchResults: [TMDBItem] = []
    @State private var showingSearchResults = false
    @State private var selectedSearchResult: TMDBItem?
    
    private let types = ["Movie", "TV Show"]
    
    var body: some View {
        ZStack {
            // Background
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
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
                    
                    Spacer()
                    
                    Text("Add to Watchlist")
                        .font(AtlasTheme.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Form Fields
                        VStack(spacing: 20) {
                            // Title
                            AtlasTextField(
                                "Title",
                                placeholder: "Title *",
                                text: $title,
                                icon: "textformat"
                            )
                            
                            // Type Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Type")
                                    .font(AtlasTheme.Typography.headline)
                                    .foregroundColor(.white)
                                
                                Picker("Type", selection: $selectedType) {
                                    ForEach(types, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // Search TMDB Button
                            Button(action: {
                                searchTMDB()
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search TMDB for Movie/TV Details")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AtlasTheme.Colors.primary.opacity(0.2))
                                .foregroundColor(AtlasTheme.Colors.primary)
                                .cornerRadius(12)
                            }
                            .disabled(title.isEmpty || tmdbService.isLoading)
                            
                            // Genre (auto-filled from TMDB or manual)
                            AtlasTextField(
                                "Genre",
                                placeholder: "Genre (e.g., Action, Comedy, Drama)",
                                text: $genre,
                                icon: "tag"
                            )
                            
                            // Poster URL (auto-filled from TMDB or manual)
                            AtlasTextField(
                                "Poster URL",
                                placeholder: "Poster URL (optional)",
                                text: $posterURL,
                                icon: "photo"
                            )
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(AtlasTheme.Typography.headline)
                                    .foregroundColor(.white)
                                
                                TextEditor(text: $notes)
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundColor(.black)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                            .fill(Color.blue.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .frame(minHeight: 100)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Add Button
                            Button(action: addItem) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add to Watchlist")
                                }
                                .font(AtlasTheme.Typography.button)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                        .fill(title.isEmpty ? AtlasTheme.Colors.primary.opacity(0.5) : AtlasTheme.Colors.primary)
                                )
                            }
                            .disabled(title.isEmpty)
                            
                            // Cancel Button
                            Button(action: { dismiss() }) {
                                Text("Cancel")
                                    .font(AtlasTheme.Typography.button)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearchResults) {
            SearchResultsSheet(
                results: searchResults,
                onSelect: selectSearchResult,
                isLoading: tmdbService.isLoading
            )
        }
    }
    
    private func searchTMDB() {
        print("🔍 Starting TMDB search for: '\(title)' (type: \(selectedType))")
        
        if selectedType == "Movie" {
            tmdbService.searchMovies(query: title) { results in
                print("📱 Received \(results.count) movie results in completion handler")
                DispatchQueue.main.async {
                    searchResults = results
                    showingSearchResults = true
                    print("📱 Updated searchResults and showingSearchResults = true")
                }
            }
        } else {
            tmdbService.searchTVShows(query: title) { results in
                print("📱 Received \(results.count) TV show results in completion handler")
                DispatchQueue.main.async {
                    searchResults = results
                    showingSearchResults = true
                    print("📱 Updated searchResults and showingSearchResults = true")
                }
            }
        }
    }
    
    private func selectSearchResult(_ result: TMDBItem) {
        title = result.displayTitle
        posterURL = result.posterURL ?? ""
        genre = tmdbService.getGenreNames(for: result.genreIds ?? []).joined(separator: ", ")
        selectedSearchResult = result
        showingSearchResults = false
    }
    
    private func addItem() {
        guard !title.isEmpty else { return }
        
        let success = watchlistService.createWatchlistItem(
            title: title,
            type: selectedType,
            genre: genre.isEmpty ? nil : genre,
            posterURL: posterURL.isEmpty ? nil : posterURL,
            notes: notes.isEmpty ? nil : notes
        ) != nil
        
        if success {
            AtlasTheme.Haptics.success()
            dismiss()
        } else {
            AtlasTheme.Haptics.error()
        }
    }
}

struct SearchResultsSheet: View {
    let results: [TMDBItem]
    let onSelect: (TMDBItem) -> Void
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(AtlasTheme.Colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("Search Results")
                        .font(AtlasTheme.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 60, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                if isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AtlasTheme.Colors.primary))
                        Text("Searching...")
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.5))
                        Text("No results found")
                            .font(AtlasTheme.Typography.headline)
                            .foregroundColor(.white)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(results, id: \.id) { result in
                                TMDBSearchResultRow(result: result) {
                                    onSelect(result)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}


#Preview {
    AddWatchlistItemView(watchlistService: WatchlistService(dataManager: DataManager.shared))
}
