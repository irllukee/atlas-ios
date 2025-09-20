import SwiftUI

struct WatchlistItemDetailView: View {
    @ObservedObject var item: WatchlistItem
    @ObservedObject var watchlistService: WatchlistService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var currentRating: Int16 = 0
    
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
                    
                    Text("Details")
                        .font(AtlasTheme.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil")
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
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Poster
                        VStack(spacing: 16) {
                            // Poster
                            AsyncImage(url: URL(string: item.posterURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                                    .fill(AtlasTheme.Colors.glassBackground)
                                    .overlay(
                                        Image(systemName: item.type?.lowercased() == "movie" ? "tv" : "tv.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white.opacity(0.5))
                                    )
                            }
                            .frame(width: 200, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large))
                            .shadow(color: AtlasTheme.Colors.glassShadow, radius: 20, x: 0, y: 10)
                            
                            // Title and Type
                            VStack(spacing: 8) {
                                Text(item.title ?? "Untitled")
                                    .font(AtlasTheme.Typography.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    Text(item.type?.capitalized ?? "Unknown")
                                        .font(AtlasTheme.Typography.body)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                if let genre = item.genre, !genre.isEmpty {
                                    Text(genre)
                                        .font(AtlasTheme.Typography.subheadline)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        
                        // Watch Status Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Status")
                                    .font(AtlasTheme.Typography.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            Button(action: toggleWatchedStatus) {
                                HStack(spacing: 12) {
                                    Image(systemName: item.isWatched ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(item.isWatched ? .green : .white.opacity(0.7))
                                    
                                    Text(item.isWatched ? "Watched" : "Mark as Watched")
                                        .font(AtlasTheme.Typography.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if item.isWatched {
                                        Text(item.watchedAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
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
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Rating Section (only for watched items)
                            if item.isWatched {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Rating")
                                            .font(AtlasTheme.Typography.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(item.rating)/10")
                                            .font(AtlasTheme.Typography.body)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    HStack(spacing: 8) {
                                        ForEach(1...10, id: \.self) { star in
                                            Button(action: {
                                                setRating(Int16(star))
                                            }) {
                                                Image(systemName: star <= item.rating ? "star.fill" : "star")
                                                    .font(.title3)
                                                    .foregroundColor(star <= item.rating ? .yellow : .white.opacity(0.3))
                                            }
                                        }
                                    }
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
                            }
                        }
                        
                        // Notes Section
                        if let notes = item.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Notes")
                                        .font(AtlasTheme.Typography.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                
                                Text(notes)
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundColor(.black)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                            .fill(Color.blue.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                                    .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Edit Button
                            Button(action: { showingEditSheet = true }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Edit Details")
                                }
                                .font(AtlasTheme.Typography.button)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                        .fill(AtlasTheme.Colors.primary)
                                )
                            }
                            
                            // Delete Button
                            Button(action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Remove from Watchlist")
                                }
                                .font(AtlasTheme.Typography.button)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                        .fill(Color.red.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditWatchlistItemView(item: item, watchlistService: watchlistService)
        }
        .alert("Remove Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("Are you sure you want to remove '\(item.title ?? "this item")' from your watchlist? This action cannot be undone.")
        }
        .onAppear {
            currentRating = item.rating
        }
    }
    
    private func toggleWatchedStatus() {
        let success = watchlistService.toggleWatchedStatus(item)
        if success {
            AtlasTheme.Haptics.light()
        }
    }
    
    private func setRating(_ rating: Int16) {
        let success = watchlistService.setRating(for: item, rating: rating)
        if success {
            AtlasTheme.Haptics.light()
            currentRating = rating
        }
    }
    
    private func deleteItem() {
        let success = watchlistService.deleteWatchlistItem(item)
        if success {
            AtlasTheme.Haptics.success()
            dismiss()
        }
    }
    
}

#Preview {
    let context = DataManager.shared.coreDataStack.viewContext
    let item = WatchlistItem(context: context)
    item.title = "Inception"
    item.type = "Movie"
    item.genre = "Sci-Fi, Action"
    item.isWatched = true
    item.rating = 9
    item.notes = "Mind-bending masterpiece with incredible visuals and storytelling."
    
    return WatchlistItemDetailView(
        item: item,
        watchlistService: WatchlistService(dataManager: DataManager.shared)
    )
}
