import SwiftUI
import Charts
import CoreData

// MARK: - Main Journal View
struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    JournalTabBar(selectedTab: $selectedTab)
                        .padding(.top, AtlasTheme.Spacing.md)
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        JournalEntriesView(viewModel: viewModel)
                            .tag(0)
                        
                        MoodTrackingView(viewModel: viewModel)
                            .tag(1)
                        
                        MoodAnalyticsView(viewModel: viewModel)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Custom Tab Bar with Book-style Tabs
struct JournalTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        ("Entries", "book.pages", 0),
        ("Mood", "heart.circle", 1),
        ("Analytics", "chart.line.uptrend.xyaxis", 2)
    ]
    
    var body: some View {
        HStack {
            Spacer()
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                ForEach(tabs, id: \.2) { tab in
                    JournalTabButton(
                        title: tab.0,
                        icon: tab.1,
                        isSelected: selectedTab == tab.2,
                        action: { 
                            AtlasTheme.Haptics.selection()
                            selectedTab = tab.2 
                        }
                    )
                }
            }
            .padding(.trailing, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.md)
        }
        .glassmorphism(style: .floating, cornerRadius: AtlasTheme.CornerRadius.large)
        .padding(.horizontal, AtlasTheme.Spacing.md)
    }
}

struct JournalTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(AtlasTheme.Typography.label)
                
                if isSelected {
                    Text(title)
                        .font(AtlasTheme.Typography.caption)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .foregroundColor(isSelected ? AtlasTheme.Colors.textOnPrimary : AtlasTheme.Colors.secondaryText)
            .padding(.horizontal, isSelected ? AtlasTheme.Spacing.md : AtlasTheme.Spacing.sm)
            .padding(.vertical, AtlasTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .fill(isSelected ? AtlasTheme.Colors.accent : Color.clear)
                    .shadow(
                        color: isSelected ? AtlasTheme.Colors.accent.opacity(0.3) : .clear, 
                        radius: 8, x: 0, y: 4
                    )
            )
        }
        .animation(AtlasTheme.Animations.spring, value: isSelected)
        .buttonStyle(.plain)
    }
}

// MARK: - Journal Entries View
struct JournalEntriesView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var showingCreateEntry = false
    @State private var searchText = ""
    @State private var selectedType: JournalEntryType?
    
    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            // Search and Filter Bar
            VStack(spacing: AtlasTheme.Spacing.md) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                        .font(AtlasTheme.Typography.body)
                    
                    TextField("Search entries...", text: $searchText)
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.text)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            AtlasTheme.Haptics.light()
                            searchText = ""
                        }
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                }
                .padding(AtlasTheme.Spacing.md)
                .glassmorphism(style: .card, cornerRadius: AtlasTheme.CornerRadius.medium)
                
                // Filter Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasTheme.Spacing.sm) {
                        FilterButton(
                            title: "All",
                            isSelected: selectedType == nil,
                            action: { 
                                AtlasTheme.Haptics.selection()
                                selectedType = nil 
                            }
                        )
                        
                        ForEach(JournalEntryType.allCases, id: \.self) { type in
                            FilterButton(
                                title: "\(type.emoji) \(type.displayName)",
                                isSelected: selectedType == type,
                                action: { 
                                    AtlasTheme.Haptics.selection()
                                    selectedType = type 
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.md)
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.md)
            
            // Entries List
            if viewModel.filteredEntries.isEmpty {
                EmptyStateView(
                    icon: "book.pages",
                    title: "No entries yet",
                    subtitle: "Start your journaling journey",
                    buttonTitle: "Create Entry",
                    action: { 
                        AtlasTheme.Haptics.medium()
                        showingCreateEntry = true 
                    }
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AtlasTheme.Spacing.md) {
                        ForEach(viewModel.filteredEntries) { entry in
                            JournalEntryCard(entry: entry, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.md)
                }
            }
            
            Spacer()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
        .onChange(of: selectedType) { _, newValue in
            viewModel.selectedType = newValue
        }
        .sheet(isPresented: $showingCreateEntry) {
            CreateJournalEntryView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateEntry = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AtlasTheme.Typography.caption)
                .foregroundColor(isSelected ? AtlasTheme.Colors.textOnPrimary : AtlasTheme.Colors.text)
                .padding(.horizontal, AtlasTheme.Spacing.md)
                .padding(.vertical, AtlasTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? AtlasTheme.Colors.accent : AtlasTheme.Colors.glassBackgroundLight)
                )
        }
        .animation(AtlasTheme.Animations.smooth, value: isSelected)
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @State private var showingDetail = false
    
    private var entryType: JournalEntryType {
        JournalEntryType(rawValue: entry.type ?? "daily") ?? .daily
    }
    
    private var previewText: String {
        let content = entry.isEncrypted ? "🔒 Encrypted Entry" : (entry.content ?? "")
        return String(content.prefix(120)) + (content.count > 120 ? "..." : "")
    }
    
    var body: some View {
        Button {
            AtlasTheme.Haptics.light()
            showingDetail = true
        } label: {
            FrostedCard(style: .standard) {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                    // Header
                    HStack {
                        HStack(spacing: AtlasTheme.Spacing.sm) {
                            Text(entryType.emoji)
                                .font(AtlasTheme.Typography.title2)
                            
                            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                                if let title = entry.title, !title.isEmpty {
                                    Text(title)
                                        .font(AtlasTheme.Typography.headline)
                                        .foregroundColor(AtlasTheme.Colors.text)
                                        .lineLimit(1)
                                }
                                
                                Text(entryType.displayName)
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: AtlasTheme.Spacing.xs) {
                            Text((entry.createdAt ?? Date()).formatted(date: .abbreviated, time: .omitted))
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            if entry.wordCount > 0 {
                                Text("\(entry.wordCount) words")
                                    .font(AtlasTheme.Typography.caption2)
                                    .foregroundColor(AtlasTheme.Colors.tertiaryText)
                            }
                        }
                    }
                    
                    // Preview Content
                    Text(previewText)
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.text)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                    
                    // Metadata Footer
                    HStack {
                        if entry.isEncrypted {
                            Label("Encrypted", systemImage: "lock.fill")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        if entry.readingTime > 0 {
                            Text("\(entry.readingTime) min read")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            JournalEntryDetailView(entry: entry, viewModel: viewModel)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(AtlasTheme.Colors.secondaryText)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text(title)
                    .font(AtlasTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text(subtitle)
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                AtlasTheme.Haptics.medium()
                action()
            }) {
                Text(buttonTitle)
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(AtlasTheme.Colors.textOnPrimary)
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.vertical, AtlasTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .fill(AtlasTheme.Colors.accent)
                    )
            }
        }
        .padding(AtlasTheme.Spacing.xxl)
    }
}

// MARK: - Preview
#Preview {
    JournalView()
        .environmentObject(DependencyContainer.shared)
}
