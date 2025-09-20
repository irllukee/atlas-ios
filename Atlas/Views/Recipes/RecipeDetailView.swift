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
        self._shoppingListService = StateObject(wrappedValue: ShoppingListService(dataManager: DependencyContainer.shared.dataManager))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Recipe Header
                        recipeHeaderSection
                        
                        // Recipe Info
                        recipeInfoSection
                        
                        // Ingredients Section
                        ingredientsSection
                        
                        // Instructions Section
                        instructionsSection
                        
                        // Tags Section
                        if let tags = recipe.tags, !tags.isEmpty {
                            tagsSection(tags: tags)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showEditRecipe = true
                        }) {
                            Label("Edit Recipe", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            recipesService.toggleFavorite(recipe)
                        }) {
                            Label(recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                  systemImage: recipe.isFavorite ? "heart.slash" : "heart")
                        }
                        
                        Button(action: {
                            showAddToShoppingList = true
                        }) {
                            Label("Add to Shopping List", systemImage: "cart.badge.plus")
                        }
                        
                        Button(action: {
                            showPhotoCapture = true
                        }) {
                            Label("Add Photo", systemImage: "camera")
                        }
                        
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share Recipe", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            let template = recipesService.createTemplate(from: recipe)
                            showEditRecipe = true
                        }) {
                            Label("Create Template", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AtlasTheme.Colors.text)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditRecipe) {
            EditRecipeView(recipe: recipe, recipesService: recipesService)
        }
        .sheet(isPresented: $showAddToShoppingList) {
            AddToShoppingListView(
                recipe: recipe,
                shoppingListService: shoppingListService
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [recipeShareText])
        }
        .sheet(isPresented: $showPhotoCapture) {
            PhotoCaptureView(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                photoService.addImageToRecipe(image, recipe: recipe, isCoverImage: true)
            }
        }
    }
    
    // MARK: - Recipe Header Section
    private var recipeHeaderSection: some View {
        FrostedCard(style: .floating) {
            VStack(spacing: AtlasTheme.Spacing.lg) {
                // Recipe Image
                if let coverImage = photoService.getCoverImage(for: recipe) {
                    Image(uiImage: coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(AtlasTheme.CornerRadius.medium)
                } else {
                    Rectangle()
                        .fill(AtlasTheme.Colors.cardBackground.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(AtlasTheme.CornerRadius.medium)
                        .overlay(
                            VStack(spacing: AtlasTheme.Spacing.sm) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                                Text("No Image")
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                            }
                        )
                }
                
                // Title and Category
                VStack(spacing: AtlasTheme.Spacing.md) {
                    HStack {
                        Text(recipe.title ?? "Untitled Recipe")
                            .font(AtlasTheme.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AtlasTheme.Colors.text)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            recipesService.toggleFavorite(recipe)
                        }) {
                            Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(recipe.isFavorite ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                        }
                    }
                    
                    if let category = recipe.category {
                        HStack(spacing: AtlasTheme.Spacing.sm) {
                            Image(systemName: category.icon ?? "questionmark")
                                .font(.caption)
                            Text(category.name ?? "Unknown Category")
                                .font(AtlasTheme.Typography.caption)
                        }
                        .foregroundColor(AtlasTheme.Colors.primary)
                        .padding(.horizontal, AtlasTheme.Spacing.md)
                        .padding(.vertical, AtlasTheme.Spacing.sm)
                        .background(AtlasTheme.Colors.primary.opacity(0.1))
                        .cornerRadius(AtlasTheme.CornerRadius.small)
                    }
                    
                    if let description = recipe.recipeDescription, !description.isEmpty {
                        Text(description)
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    // MARK: - Recipe Info Section
    private var recipeInfoSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Recipe Info")
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AtlasTheme.Spacing.md) {
                    if recipe.prepTime > 0 {
                        InfoCard(
                            title: "Prep Time",
                            value: "\(recipe.prepTime)m",
                            icon: "clock"
                        )
                    }
                    
                    if recipe.cookingTime > 0 {
                        InfoCard(
                            title: "Cook Time",
                            value: "\(recipe.cookingTime)m",
                            icon: "timer"
                        )
                    }
                    
                    InfoCard(
                        title: "Servings",
                        value: "\(recipe.servings)",
                        icon: "person.2"
                    )
                    
                    InfoCard(
                        title: "Difficulty",
                        value: difficultyText,
                        icon: "star"
                    )
                }
                
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
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                HStack {
                    SectionHeader(title: "Ingredients")
                    Spacer()
                    Button(action: {
                        showAddToShoppingList = true
                    }) {
                        Text("Add All to Shopping")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.primary)
                            .padding(.horizontal, AtlasTheme.Spacing.md)
                            .padding(.vertical, AtlasTheme.Spacing.sm)
                            .background(AtlasTheme.Colors.primary.opacity(0.1))
                            .cornerRadius(AtlasTheme.CornerRadius.small)
                    }
                }
                
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    ForEach(Array(ingredients), id: \.uuid) { ingredient in
                        if let recipeIngredient = ingredient as? RecipeIngredient {
                            IngredientDetailRow(
                                ingredient: recipeIngredient,
                                onAddToShopping: {
                                    shoppingListService.addItem(
                                        name: recipeIngredient.name ?? "",
                                        amount: recipeIngredient.amount,
                                        unit: recipeIngredient.unit,
                                        notes: recipeIngredient.notes,
                                        sourceRecipe: recipe
                                    )
                                }
                            )
                        }
                    }
                } else {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Text("No ingredients listed")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, AtlasTheme.Spacing.lg)
                }
            }
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Instructions")
                
                if let steps = recipe.steps, !steps.isEmpty {
                    ForEach(Array(steps).sorted(by: { ($0 as? RecipeStep)?.order ?? 0 < ($1 as? RecipeStep)?.order ?? 0 }), id: \.uuid) { step in
                        if let recipeStep = step as? RecipeStep {
                            StepDetailRow(step: recipeStep)
                        }
                    }
                } else {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "list.number")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Text("No instructions provided")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, AtlasTheme.Spacing.lg)
                }
            }
        }
    }
    
    // MARK: - Tags Section
    private func tagsSection(tags: NSSet) -> some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Tags")
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AtlasTheme.Spacing.sm) {
                    ForEach(Array(tags), id: \.uuid) { tag in
                        if let recipeTag = tag as? RecipeTag {
                            Text(recipeTag.name ?? "")
                                .font(AtlasTheme.Typography.caption)
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .padding(.vertical, AtlasTheme.Spacing.sm)
                                .background(AtlasTheme.Colors.primary.opacity(0.1))
                                .foregroundColor(AtlasTheme.Colors.primary)
                                .cornerRadius(AtlasTheme.CornerRadius.small)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var difficultyText: String {
        switch recipe.difficulty {
        case 1: return "Easy"
        case 2: return "Easy+"
        case 3: return "Medium"
        case 4: return "Hard"
        case 5: return "Expert"
        default: return "Unknown"
        }
    }
    
    private var recipeShareText: String {
        var text = "\(recipe.title ?? "Recipe")\n\n"
        
        if let description = recipe.recipeDescription {
            text += "\(description)\n\n"
        }
        
        if let category = recipe.category {
            text += "Category: \(category.name ?? "")\n"
        }
        
        if recipe.prepTime > 0 {
            text += "Prep Time: \(recipe.prepTime) minutes\n"
        }
        
        if recipe.cookingTime > 0 {
            text += "Cooking Time: \(recipe.cookingTime) minutes\n"
        }
        
        text += "Servings: \(recipe.servings)\n\n"
        
        if let ingredients = recipe.ingredients {
            text += "Ingredients:\n"
            for ingredient in ingredients {
                if let recipeIngredient = ingredient as? RecipeIngredient {
                    let amount = recipeIngredient.amount
                    let unit = recipeIngredient.unit ?? ""
                    let name = recipeIngredient.name ?? ""
                    text += "• \(amount) \(unit) \(name)\n"
                }
            }
            text += "\n"
        }
        
        if let steps = recipe.steps {
            text += "Instructions:\n"
            for (index, step) in Array(steps).enumerated() {
                if let recipeStep = step as? RecipeStep {
                    text += "\(index + 1). \(recipeStep.content ?? "")\n"
                }
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
                .fontWeight(.bold)
                .foregroundColor(AtlasTheme.Colors.text)
            
            Text(title)
                .font(AtlasTheme.Typography.caption)
                .foregroundColor(AtlasTheme.Colors.secondaryText)
        }
        .padding(AtlasTheme.Spacing.md)
        .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
        .cornerRadius(AtlasTheme.CornerRadius.small)
    }
}

// MARK: - Ingredient Detail Row Component
struct IngredientDetailRow: View {
    let ingredient: RecipeIngredient
    let onAddToShopping: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                Text(ingredient.name ?? "Unknown")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                if let unit = ingredient.unit, !unit.isEmpty {
                    Text("\(ingredient.amount, specifier: "%.1f") \(unit)")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                } else {
                    Text("\(ingredient.amount, specifier: "%.1f")")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
                
                if let notes = ingredient.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AtlasTheme.Typography.caption2)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                        .italic()
                }
            }
            
            Spacer()
            
            Button(action: onAddToShopping) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(AtlasTheme.Colors.primary)
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.sm)
    }
}

// MARK: - Step Detail Row Component
struct StepDetailRow: View {
    let step: RecipeStep
    
    var body: some View {
        HStack(alignment: .top, spacing: AtlasTheme.Spacing.md) {
            Text("\((step.order) + 1)")
                .font(AtlasTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(AtlasTheme.Colors.primary)
                .frame(width: 24, height: 24)
                .background(AtlasTheme.Colors.primary.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                Text(step.content ?? "No content")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                if step.timerMinutes > 0 {
                    HStack(spacing: AtlasTheme.Spacing.xs) {
                        Image(systemName: "timer")
                            .font(.caption)
                        Text("\(step.timerMinutes) minutes")
                            .font(AtlasTheme.Typography.caption)
                    }
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .padding(.horizontal, AtlasTheme.Spacing.sm)
                    .padding(.vertical, AtlasTheme.Spacing.xs)
                    .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                    .cornerRadius(AtlasTheme.CornerRadius.small)
                }
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.sm)
    }
}

// MARK: - Add to Shopping List View
struct AddToShoppingListView: View {
    @Environment(\.presentationMode) var presentationMode
    let recipe: Recipe
    @ObservedObject var shoppingListService: ShoppingListService
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: AtlasTheme.Spacing.lg) {
                    Text("Add ingredients from '\(recipe.title ?? "Recipe")' to your shopping list?")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AtlasTheme.Spacing.lg)
                    
                    if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: AtlasTheme.Spacing.sm) {
                                ForEach(Array(ingredients), id: \.uuid) { ingredient in
                                    if let recipeIngredient = ingredient as? RecipeIngredient {
                                        HStack {
                                            Text(recipeIngredient.name ?? "Unknown")
                                                .font(AtlasTheme.Typography.body)
                                                .foregroundColor(AtlasTheme.Colors.text)
                                            
                                            Spacer()
                                            
                                            if let unit = recipeIngredient.unit, !unit.isEmpty {
                                                Text("\(recipeIngredient.amount, specifier: "%.1f") \(unit)")
                                                    .font(AtlasTheme.Typography.caption)
                                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                                            } else {
                                                Text("\(recipeIngredient.amount, specifier: "%.1f")")
                                                    .font(AtlasTheme.Typography.caption)
                                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                                            }
                                        }
                                        .padding(AtlasTheme.Spacing.md)
                                        .background(AtlasTheme.Colors.cardBackground.opacity(0.3))
                                        .cornerRadius(AtlasTheme.CornerRadius.small)
                                    }
                                }
                            }
                            .padding(.horizontal, AtlasTheme.Spacing.lg)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, AtlasTheme.Spacing.lg)
            }
            .navigationTitle("Add to Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add All") {
                        shoppingListService.addIngredientsFromRecipe(recipe)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
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
