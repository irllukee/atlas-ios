import SwiftUI

struct RecipesView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var recipesService: RecipesService
    @StateObject private var shoppingListService: ShoppingListService
    @State private var selectedCategory: RecipeCategory?
    @State private var searchText = ""
    @State private var selectedTags: [RecipeTag] = []
    @State private var showFavoritesOnly = false
    @State private var showCreateRecipe = false
    @State private var showShoppingList = false
    @State private var showImportRecipe = false
    @State private var showTemplates = false
    @State private var showTests = false
    @State private var recipes: [Recipe] = []
    
    init() {
        let dataManager = DataManager.shared
        self._recipesService = StateObject(wrappedValue: RecipesService(dataManager: dataManager))
        self._shoppingListService = StateObject(wrappedValue: ShoppingListService(dataManager: dataManager))
    }
    
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search and Filters
                searchAndFiltersView
                
                // Category Tabs
                categoryTabsView
                
                // Recipe Grid
                recipesGridView
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateRecipe) {
            CreateRecipeView(recipesService: recipesService)
        }
        .sheet(isPresented: $showShoppingList) {
            ShoppingListView(shoppingListService: shoppingListService)
        }
        .sheet(isPresented: $showImportRecipe) {
            RecipeImportView(recipesService: recipesService)
        }
        .sheet(isPresented: $showTemplates) {
            TemplateManagementView(recipesService: recipesService)
        }
        #if DEBUG
        .sheet(isPresented: $showTests) {
            RecipeTestView()
        }
        #endif
        .onAppear {
            loadRecipes()
        }
        .onChange(of: selectedCategory) { _ in
            loadRecipes()
        }
        .onChange(of: searchText) { _ in
            loadRecipes()
        }
        .onChange(of: selectedTags) { _ in
            loadRecipes()
        }
        .onChange(of: showFavoritesOnly) { _ in
            loadRecipes()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(AtlasTheme.Colors.text)
            }
            
            Spacer()
            
            Text("Recipes")
                .font(AtlasTheme.Typography.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AtlasTheme.Colors.text)
            
            Spacer()
            
            HStack(spacing: AtlasTheme.Spacing.md) {
                Button(action: {
                    showShoppingList = true
                }) {
                    Image(systemName: "cart")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.text)
                }
                
                Button(action: {
                    showImportRecipe = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.text)
                }
                
                Button(action: {
                    showTemplates = true
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.text)
                }
                
                #if DEBUG
                Button(action: {
                    showTests = true
                }) {
                    Image(systemName: "checkmark.circle")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                #endif
                
                Button(action: {
                    showCreateRecipe = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.primary)
                }
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.top, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Search and Filters View
    private var searchAndFiltersView: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                
                TextField("Search recipes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AtlasTheme.Typography.body)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                }
            }
            .padding(AtlasTheme.Spacing.md)
            .background(AtlasTheme.Colors.glassBackground.opacity(0.5))
            .cornerRadius(AtlasTheme.CornerRadius.medium)
            
            // Filter Toggle
            HStack {
                Button(action: {
                    showFavoritesOnly.toggle()
                }) {
                    HStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(showFavoritesOnly ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                        
                        Text("Favorites")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(showFavoritesOnly ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.md)
                    .padding(.vertical, AtlasTheme.Spacing.sm)
                    .background(showFavoritesOnly ? AtlasTheme.Colors.primary.opacity(0.1) : AtlasTheme.Colors.glassBackground.opacity(0.5))
                    .cornerRadius(AtlasTheme.CornerRadius.small)
                }
                
                Spacer()
                
                Text("\(recipes.count) recipes")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.vertical, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Category Tabs View
    private var categoryTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasTheme.Spacing.sm) {
                // All Categories Tab
                CategoryTab(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil,
                    action: {
                        selectedCategory = nil
                    }
                )
                
                // Category Tabs
                ForEach(recipesService.fetchCategories(), id: \.uuid) { category in
                    CategoryTab(
                        title: category.name ?? "Unknown",
                        icon: category.icon ?? "questionmark",
                        isSelected: selectedCategory?.uuid == category.uuid,
                        action: {
                            selectedCategory = category
                        }
                    )
                }
            }
            .padding(.horizontal, AtlasTheme.Spacing.lg)
        }
    }
    
    // MARK: - Recipes Grid View
    private var recipesGridView: some View {
        ScrollView {
            if recipes.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AtlasTheme.Spacing.md) {
                    ForEach(recipes, id: \.uuid) { recipe in
                        RecipeCard(recipe: recipe, recipesService: recipesService)
                    }
                }
                .padding(.horizontal, AtlasTheme.Spacing.lg)
                .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(AtlasTheme.Colors.primary)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("No Recipes Found")
                    .font(AtlasTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Create your first recipe or adjust your search filters")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showCreateRecipe = true
            }) {
                Text("Create Recipe")
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AtlasTheme.Spacing.xl)
                    .padding(.vertical, AtlasTheme.Spacing.md)
                    .background(AtlasTheme.Colors.primary)
                    .cornerRadius(AtlasTheme.CornerRadius.medium)
            }
            
            Spacer()
        }
        .padding(.horizontal, AtlasTheme.Spacing.xl)
    }
    
    // MARK: - Helper Methods
    private func loadRecipes() {
        recipes = recipesService.fetchRecipes(
            category: selectedCategory,
            searchText: searchText.isEmpty ? nil : searchText,
            tags: selectedTags,
            favoritesOnly: showFavoritesOnly
        )
    }
}

// MARK: - Category Tab Component
struct CategoryTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AtlasTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(AtlasTheme.Typography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
            .padding(.horizontal, AtlasTheme.Spacing.md)
            .padding(.vertical, AtlasTheme.Spacing.sm)
            .background(isSelected ? AtlasTheme.Colors.primary.opacity(0.1) : AtlasTheme.Colors.glassBackground.opacity(0.5))
            .cornerRadius(AtlasTheme.CornerRadius.medium)
        }
    }
}

// MARK: - Recipe Card Component
struct RecipeCard: View {
    let recipe: Recipe
    let recipesService: RecipesService
    @State private var showRecipeDetail = false
    @StateObject private var photoService = PhotoService()
    
    var body: some View {
        Button(action: {
            showRecipeDetail = true
        }) {
            FrostedCard(style: .standard) {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
                    // Recipe Image
                    if let coverImage = photoService.getCoverImage(for: recipe) {
                        Image(uiImage: coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(AtlasTheme.CornerRadius.small)
                    } else {
                        Rectangle()
                            .fill(AtlasTheme.Colors.glassBackground.opacity(0.3))
                            .frame(height: 120)
                            .cornerRadius(AtlasTheme.CornerRadius.small)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.title)
                                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                                    Text("No Image")
                                        .font(AtlasTheme.Typography.caption)
                                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                                }
                            )
                    }
                    
                    // Recipe Info
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        HStack {
                            Text(recipe.title ?? "Untitled Recipe")
                                .font(AtlasTheme.Typography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(AtlasTheme.Colors.text)
                                .lineLimit(2)
                            
                            Spacer()
                            
                            Button(action: {
                                recipesService.toggleFavorite(recipe)
                            }) {
                                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                    .font(.caption)
                                    .foregroundColor(recipe.isFavorite ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                            }
                        }
                        
                        HStack {
                            if let category = recipe.category {
                                HStack(spacing: AtlasTheme.Spacing.xs) {
                                    Image(systemName: category.icon ?? "questionmark")
                                        .font(.caption)
                                    Text(category.name ?? "Unknown")
                                        .font(AtlasTheme.Typography.caption)
                                }
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            if recipe.prepTime > 0 || recipe.cookingTime > 0 {
                                Text(timeText)
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                            }
                        }
                        
                        // Tags
                        if let tags = recipe.tags, tags.count > 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AtlasTheme.Spacing.xs) {
                                    ForEach(Array(tags), id: \.uuid) { tag in
                                        if let recipeTag = tag as? RecipeTag {
                                            Text(recipeTag.name ?? "")
                                                .font(AtlasTheme.Typography.caption2)
                                                .padding(.horizontal, AtlasTheme.Spacing.sm)
                                                .padding(.vertical, AtlasTheme.Spacing.xs)
                                                .background(AtlasTheme.Colors.primary.opacity(0.1))
                                                .foregroundColor(AtlasTheme.Colors.primary)
                                                .cornerRadius(AtlasTheme.CornerRadius.small)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showRecipeDetail) {
            RecipeDetailView(recipe: recipe, recipesService: recipesService)
        }
    }
    
    private var timeText: String {
        let totalMinutes = recipe.prepTime + recipe.cookingTime
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

#Preview {
    RecipesView()
}
