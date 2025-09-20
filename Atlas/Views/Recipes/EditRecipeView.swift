import SwiftUI

struct EditRecipeView: View {
    @Environment(\.presentationMode) var presentationMode
    let recipe: Recipe
    @ObservedObject var recipesService: RecipesService
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: RecipeCategory?
    @State private var prepTime: Int
    @State private var cookingTime: Int
    @State private var servings: Int
    @State private var difficulty: Int
    @State private var sourceURL: String
    @State private var isTemplate: Bool
    
    @State private var ingredients: [RecipeIngredient] = []
    @State private var steps: [RecipeStep] = []
    @State private var selectedTags: [RecipeTag] = []
    
    @State private var showingCategoryPicker = false
    @State private var showingTagPicker = false
    @State private var showingAddIngredient = false
    @State private var showingAddStep = false
    @State private var showingDeleteConfirmation = false
    
    private let categories: [RecipeCategory]
    
    init(recipe: Recipe, recipesService: RecipesService) {
        self.recipe = recipe
        self.recipesService = recipesService
        self.categories = recipesService.fetchCategories()
        
        // Initialize state with recipe values
        self._title = State(initialValue: recipe.title ?? "")
        self._description = State(initialValue: recipe.recipeDescription ?? "")
        self._selectedCategory = State(initialValue: recipe.category)
        self._prepTime = State(initialValue: Int(recipe.prepTime))
        self._cookingTime = State(initialValue: Int(recipe.cookingTime))
        self._servings = State(initialValue: Int(recipe.servings))
        self._difficulty = State(initialValue: Int(recipe.difficulty))
        self._sourceURL = State(initialValue: recipe.sourceURL ?? "")
        self._isTemplate = State(initialValue: recipe.isTemplate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Basic Info Section
                        basicInfoSection
                        
                        // Category and Tags Section
                        categoryAndTagsSection
                        
                        // Time and Difficulty Section
                        timeAndDifficultySection
                        
                        // Ingredients Section
                        ingredientsSection
                        
                        // Steps Section
                        stepsSection
                        
                        // Template Toggle
                        templateSection
                        
                        // Delete Button
                        deleteSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Edit Recipe")
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
                    Button("Save") {
                        saveRecipe()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                    .disabled(title.isEmpty || selectedCategory == nil)
                }
            }
        }
        .onAppear {
            loadRecipeData()
        }
        .sheet(isPresented: $showingCategoryPicker) {
            CategoryPickerView(
                categories: categories,
                selectedCategory: $selectedCategory,
                recipesService: recipesService
            )
        }
        .sheet(isPresented: $showingTagPicker) {
            TagPickerView(
                selectedTags: $selectedTags,
                recipesService: recipesService
            )
        }
        .sheet(isPresented: $showingAddIngredient) {
            AddIngredientView(
                ingredients: $ingredients,
                recipesService: recipesService
            )
        }
        .sheet(isPresented: $showingAddStep) {
            AddStepView(
                steps: $steps,
                recipesService: recipesService
            )
        }
        .alert("Delete Recipe?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("This action cannot be undone. The recipe and all its data will be permanently deleted.")
        }
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Basic Information")
                
                VStack(spacing: AtlasTheme.Spacing.md) {
                    AtlasTextField(
                        "Recipe Title",
                        placeholder: "Enter recipe title",
                        text: $title
                    )
                    
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        Text("Description")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 80)
                            .padding(AtlasTheme.Spacing.sm)
                            .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                            .cornerRadius(AtlasTheme.CornerRadius.small)
                    }
                    
                    AtlasTextField(
                        "Source URL (Optional)",
                        placeholder: "https://example.com/recipe",
                        text: $sourceURL
                    )
                }
            }
        }
    }
    
    // MARK: - Category and Tags Section
    private var categoryAndTagsSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Category & Tags")
                
                VStack(spacing: AtlasTheme.Spacing.md) {
                    // Category Picker
                    Button(action: {
                        showingCategoryPicker = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                                Text("Category")
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                                
                                Text(selectedCategory?.name ?? "Select Category")
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundColor(selectedCategory != nil ? AtlasTheme.Colors.text : AtlasTheme.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                        .padding(AtlasTheme.Spacing.md)
                        .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                        .cornerRadius(AtlasTheme.CornerRadius.small)
                    }
                    
                    // Tags Picker
                    Button(action: {
                        showingTagPicker = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                                Text("Tags")
                                    .font(AtlasTheme.Typography.caption)
                                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                                
                                Text(selectedTags.isEmpty ? "Add Tags (Optional)" : "\(selectedTags.count) tags selected")
                                    .font(AtlasTheme.Typography.body)
                                    .foregroundColor(AtlasTheme.Colors.text)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                        .padding(AtlasTheme.Spacing.md)
                        .background(AtlasTheme.Colors.glassBackground.opacity(0.3))
                        .cornerRadius(AtlasTheme.CornerRadius.small)
                    }
                }
            }
        }
    }
    
    // MARK: - Time and Difficulty Section
    private var timeAndDifficultySection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Time & Difficulty")
                
                VStack(spacing: AtlasTheme.Spacing.md) {
                    HStack(spacing: AtlasTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Prep Time (minutes)")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            Stepper("\(prepTime)", value: $prepTime, in: 0...300, step: 5)
                                .font(AtlasTheme.Typography.body)
                        }
                        
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Cooking Time (minutes)")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            Stepper("\(cookingTime)", value: $cookingTime, in: 0...300, step: 5)
                                .font(AtlasTheme.Typography.body)
                        }
                    }
                    
                    HStack(spacing: AtlasTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Servings")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            Stepper("\(servings)", value: $servings, in: 1...20)
                                .font(AtlasTheme.Typography.body)
                        }
                        
                        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                            Text("Difficulty")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                            
                            Stepper("\(difficulty)", value: $difficulty, in: 1...5)
                                .font(AtlasTheme.Typography.body)
                        }
                    }
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
                        showingAddIngredient = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.primary)
                    }
                }
                
                if ingredients.isEmpty {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Text("No ingredients added yet")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Text("Tap the + button to add ingredients")
                            .font(AtlasTheme.Typography.caption2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, AtlasTheme.Spacing.lg)
                } else {
                    ForEach(ingredients.indices, id: \.self) { index in
                        IngredientRow(
                            ingredient: ingredients[index],
                            onDelete: {
                                ingredients.remove(at: index)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Steps Section
    private var stepsSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                HStack {
                    SectionHeader(title: "Instructions")
                    Spacer()
                    Button(action: {
                        showingAddStep = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.primary)
                    }
                }
                
                if steps.isEmpty {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "list.number")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Text("No steps added yet")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Text("Tap the + button to add cooking steps")
                            .font(AtlasTheme.Typography.caption2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, AtlasTheme.Spacing.lg)
                } else {
                    ForEach(steps.indices, id: \.self) { index in
                        StepRow(
                            step: steps[index],
                            stepNumber: index + 1,
                            onDelete: {
                                steps.remove(at: index)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Template Section
    private var templateSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Template")
                
                HStack {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                        Text("Save as Template")
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("Templates can be used to quickly create similar recipes")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isTemplate)
                        .toggleStyle(SwitchToggleStyle(tint: AtlasTheme.Colors.primary))
                }
            }
        }
    }
    
    // MARK: - Delete Section
    private var deleteSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Danger Zone")
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                        
                        Text("Delete Recipe")
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(AtlasTheme.Spacing.md)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(AtlasTheme.CornerRadius.small)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadRecipeData() {
        // Load ingredients
        if let recipeIngredients = recipe.ingredients {
            ingredients = Array(recipeIngredients).compactMap { $0 as? RecipeIngredient }
        }
        
        // Load steps
        if let recipeSteps = recipe.steps {
            steps = Array(recipeSteps).compactMap { $0 as? RecipeStep }
        }
        
        // Load tags
        if let recipeTags = recipe.tags {
            selectedTags = Array(recipeTags).compactMap { $0 as? RecipeTag }
        }
    }
    
    private func saveRecipe() {
        recipe.title = title
        recipe.recipeDescription = description.isEmpty ? nil : description
        recipe.category = selectedCategory
        recipe.prepTime = Int16(prepTime)
        recipe.cookingTime = Int16(cookingTime)
        recipe.servings = Int16(servings)
        recipe.difficulty = Int16(difficulty)
        recipe.sourceURL = sourceURL.isEmpty ? nil : sourceURL
        recipe.isTemplate = isTemplate
        
        // Update ingredients
        if let existingIngredients = recipe.ingredients {
            for ingredient in existingIngredients {
                recipesService.deleteIngredient(ingredient as! RecipeIngredient)
            }
        }
        
        for ingredient in ingredients {
            _ = recipesService.addIngredient(
                to: recipe,
                name: ingredient.name ?? "",
                amount: ingredient.amount,
                unit: ingredient.unit,
                notes: ingredient.notes,
                order: ingredient.order
            )
        }
        
        // Update steps
        if let existingSteps = recipe.steps {
            for step in existingSteps {
                recipesService.deleteStep(step as! RecipeStep)
            }
        }
        
        for step in steps {
            _ = recipesService.addStep(
                to: recipe,
                content: step.content ?? "",
                order: step.order,
                timerMinutes: step.timerMinutes
            )
        }
        
        // Update tags
        recipe.tags = NSSet(array: selectedTags)
        
        recipesService.updateRecipe(recipe)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteRecipe() {
        recipesService.deleteRecipe(recipe)
        presentationMode.wrappedValue.dismiss()
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
    
    EditRecipeView(recipe: recipe, recipesService: recipesService)
}

