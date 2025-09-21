import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let recipe: Recipe
    @ObservedObject var recipesService: RecipesService
    @StateObject private var shoppingListService: ShoppingListService
    @StateObject private var photoService = PhotoService()
    
    @State private var showEditRecipe = false
    @State private var showAddToShoppingList = false
    @State private var showShareSheet = false
    @State private var showPhotoCapture = false
    @State private var selectedImage: UIImage?
    
    init(recipe: Recipe, recipesService: RecipesService) {
        self.recipe = recipe
        self.recipesService = recipesService
        self._shoppingListService = StateObject(wrappedValue: ShoppingListService(dataManager: DataManager.shared))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Header
                        headerSection
                        
                        // Ingredients
                        ingredientsSection
                        
                        // Instructions
                        instructionsSection
                        
                        // Additional Info
                        additionalInfoSection
                    }
                    .padding(AtlasTheme.Spacing.lg)
                }
            }
            .navigationBarTitle("Recipe Details", displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: AtlasTheme.Spacing.xs) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(AtlasTheme.Typography.body)
                        }
                        .foregroundColor(AtlasTheme.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showEditRecipe = true
                        }) {
                            Label("Edit Recipe", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Recipe", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            showPhotoCapture = true
                        }) {
                            Label("Add Photo", systemImage: "camera")
                        }
                        
                        Button(action: {
                            _ = recipesService.createTemplate(from: recipe)
                        }) {
                            Label("Save as Template", systemImage: "doc.badge.plus")
                        }
                        
                        Button(action: {
                            recipesService.toggleFavorite(recipe)
                        }) {
                            Label(recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                  systemImage: recipe.isFavorite ? "heart.slash" : "heart")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(AtlasTheme.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditRecipe) {
            if let editView = createEditRecipeView() {
                editView
            }
        }
        .sheet(isPresented: $showAddToShoppingList) {
            AddToShoppingListView(recipe: recipe, shoppingListService: shoppingListService)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [recipeShareText])
        }
        .sheet(isPresented: $showPhotoCapture) {
            RecipePhotoCaptureView(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _, image in
            if let image = image {
                _ = photoService.addImageToRecipe(image, recipe: recipe, isCoverImage: true)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            // Recipe Image
            if let coverImage = photoService.getCoverImage(for: recipe) {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(AtlasTheme.CornerRadius.large)
            } else {
                Rectangle()
                    .fill(AtlasTheme.Colors.glassBackground.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(AtlasTheme.CornerRadius.large)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            Text("No Image")
                                .font(AtlasTheme.Typography.body)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                    )
            }
            
            // Recipe Title and Info
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                Text(recipe.title ?? "Untitled Recipe")
                    .font(AtlasTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                if let description = recipe.recipeDescription, !description.isEmpty {
                    Text(description)
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                        .lineLimit(nil)
                }
                
                // Recipe Info Cards
                HStack(spacing: AtlasTheme.Spacing.md) {
                    if recipe.prepTime > 0 {
                        InfoCard(
                            title: "Prep Time",
                            value: formatTime(recipe.prepTime),
                            icon: "clock"
                        )
                    }
                    
                    if recipe.cookingTime > 0 {
                        InfoCard(
                            title: "Cook Time",
                            value: formatTime(recipe.cookingTime),
                            icon: "flame"
                        )
                    }
                    
                    if recipe.servings > 0 {
                        InfoCard(
                            title: "Servings",
                            value: "\(recipe.servings)",
                            icon: "person.2"
                        )
                    }
                }
                
                // Category and Tags
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
                    
                    Button(action: {
                        recipesService.toggleFavorite(recipe)
                    }) {
                        Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(recipe.isFavorite ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                    }
                }
                
                // Source URL
                if let sourceURL = recipe.sourceURL, !sourceURL.isEmpty {
                    HStack {
                        Text("Source:")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Link(sourceURL, destination: URL(string: sourceURL) ?? URL(string: "https://example.com")!)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.primary)
                        
                        Spacer()
                    }
                    .padding(.top, AtlasTheme.Spacing.sm)
                }
            }
        }
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            HStack {
                Text("Ingredients")
                    .font(AtlasTheme.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Spacer()
                
                Button(action: {
                    showAddToShoppingList = true
                }) {
                    Text("Add to Shopping")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.primary)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .padding(.vertical, AtlasTheme.Spacing.sm)
                        .background(AtlasTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AtlasTheme.CornerRadius.small)
                }
            }
            
            if let ingredients = recipe.ingredients, ingredients.count > 0 {
                VStack(spacing: AtlasTheme.Spacing.sm) {
                    ForEach(ingredients.allObjects.compactMap { $0 as? RecipeIngredient }, id: \.uuid) { ingredient in
                        IngredientRowView(ingredient: ingredient)
                    }
                }
            } else {
                VStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    
                    Text("No ingredients listed")
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
                .padding(.vertical, AtlasTheme.Spacing.lg)
            }
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
        .cornerRadius(AtlasTheme.CornerRadius.medium)
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Instructions")
                .font(AtlasTheme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(AtlasTheme.Colors.text)
            
            if let steps = recipe.steps, steps.count > 0 {
                VStack(spacing: AtlasTheme.Spacing.md) {
                    ForEach(steps.allObjects.compactMap { $0 as? RecipeStep }.sorted(by: { $0.order < $1.order }), id: \.uuid) { step in
                        StepRowView(step: step)
                    }
                }
            } else {
                VStack(spacing: AtlasTheme.Spacing.sm) {
                    Image(systemName: "list.number")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    
                    Text("No instructions listed")
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
                .padding(.vertical, AtlasTheme.Spacing.lg)
            }
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
        .cornerRadius(AtlasTheme.CornerRadius.medium)
    }
    
    // MARK: - Additional Info Section
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            if let tags = recipe.tags, tags.count > 0 {
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Tags")
                        .font(AtlasTheme.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AtlasTheme.Spacing.sm) {
                        ForEach(tags.allObjects.compactMap { $0 as? RecipeTag }, id: \.objectID) { tag in
                            Text(tag.name ?? "")
                                .font(AtlasTheme.Typography.caption)
                                .padding(.horizontal, AtlasTheme.Spacing.sm)
                                .padding(.vertical, AtlasTheme.Spacing.xs)
                                .background(AtlasTheme.Colors.primary.opacity(0.1))
                                .foregroundColor(AtlasTheme.Colors.primary)
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                        }
                    }
                }
                .padding(AtlasTheme.Spacing.md)
                .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                .cornerRadius(AtlasTheme.CornerRadius.medium)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ minutes: Int16) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
    
    private func createEditRecipeView() -> AnyView? {
        // Return nil for now - edit functionality can be added later
        return nil
    }
    
    private var recipeShareText: String {
        var text = recipe.title ?? "Recipe"
        
        if let description = recipe.recipeDescription, !description.isEmpty {
            text += "\n\n\(description)"
        }
        
        if let ingredients = recipe.ingredients, ingredients.count > 0 {
            text += "\n\nIngredients:\n"
            for ingredient in ingredients.allObjects.compactMap({ $0 as? RecipeIngredient }) {
                let name = ingredient.name ?? "Unknown"
                let amount = ingredient.amount
                let unit = ingredient.unit ?? ""
                
                if !unit.isEmpty {
                    text += "• \(String(format: "%.1f", amount)) \(unit) \(name)\n"
                } else {
                    text += "• \(String(format: "%.1f", amount)) \(name)\n"
                }
            }
        }
        
        if let steps = recipe.steps, steps.count > 0 {
            text += "\n\nInstructions:\n"
            for (index, step) in steps.allObjects.compactMap({ $0 as? RecipeStep }).sorted(by: { $0.order < $1.order }).enumerated() {
                text += "\(index + 1). \(step.content ?? "")\n"
            }
        }
        
        return text
    }
}

// MARK: - Info Card Component
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AtlasTheme.Colors.primary)
            
            Text(value)
                .font(AtlasTheme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(AtlasTheme.Colors.text)
            
            Text(title)
                .font(AtlasTheme.Typography.caption)
                .foregroundColor(AtlasTheme.Colors.secondaryText)
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
        .cornerRadius(AtlasTheme.CornerRadius.small)
    }
}

// MARK: - Ingredient Row View
struct IngredientRowView: View {
    let ingredient: RecipeIngredient

    var body: some View {
        HStack {
            Text(ingredient.name ?? "Unknown")
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.text)

            Spacer()

            if let unit = ingredient.unit, !unit.isEmpty {
                Text(String(format: "%.1f %@", ingredient.amount, unit))
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            } else {
                Text(String(format: "%.1f", ingredient.amount))
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.sm)
    }
}

// MARK: - Step Row View
struct StepRowView: View {
    let step: RecipeStep
    
    var body: some View {
        HStack(alignment: .top, spacing: AtlasTheme.Spacing.md) {
            Text("\(step.order + 1)")
                .font(AtlasTheme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(AtlasTheme.Colors.primary)
                .frame(width: 30, alignment: .leading)
            
            Text(step.content ?? "")
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.text)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(.vertical, AtlasTheme.Spacing.sm)
    }
}

// MARK: - Add to Shopping List View
struct AddToShoppingListView: View {
    let recipe: Recipe
    let shoppingListService: ShoppingListService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                Text("Add ingredients from '\(recipe.title ?? "Recipe")' to your shopping list?")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.text)
                    .multilineTextAlignment(.center)
                    .padding()
                
                if let ingredients = recipe.ingredients, ingredients.count > 0 {
                    ScrollView {
                        VStack(spacing: AtlasTheme.Spacing.sm) {
                            ForEach(ingredients.allObjects.compactMap { $0 as? RecipeIngredient }, id: \.uuid) { ingredient in
                                HStack {
                                    Text(ingredient.name ?? "Unknown")
                                        .font(AtlasTheme.Typography.body)
                                        .foregroundColor(AtlasTheme.Colors.text)
                                    
                                    Spacer()
                                    
                                    if let unit = ingredient.unit, !unit.isEmpty {
                                        Text(String(format: "%.1f %@", ingredient.amount, unit))
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                                    } else {
                                        Text(String(format: "%.1f", ingredient.amount))
                                            .font(AtlasTheme.Typography.caption)
                                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                                    }
                                }
                                .padding(.vertical, AtlasTheme.Spacing.xs)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                Button(action: {
                    _ = shoppingListService.addIngredientsFromRecipe(recipe)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Add All Ingredients")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AtlasTheme.Colors.primary)
                        .cornerRadius(AtlasTheme.CornerRadius.medium)
                }
                .padding()
            }
            .navigationTitle("Add to Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Recipe Photo Capture View
struct RecipePhotoCaptureView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Photo capture functionality")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Spacer()
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let dataManager = DataManager.shared
    let recipesService = RecipesService(dataManager: dataManager)
    let category = recipesService.fetchCategories().first ?? RecipeCategory()
    
    let recipe = recipesService.createRecipe(
        title: "Sample Recipe",
        recipeDescription: "A delicious sample recipe",
        category: category
    )
    
    RecipeDetailView(recipe: recipe, recipesService: recipesService)
}
