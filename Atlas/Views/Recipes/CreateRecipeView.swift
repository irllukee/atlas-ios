import SwiftUI

struct CreateRecipeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var recipesService: RecipesService
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: RecipeCategory?
    @State private var prepTime = 0
    @State private var cookingTime = 0
    @State private var servings = 1
    @State private var difficulty = 1
    @State private var sourceURL = ""
    @State private var isTemplate = false
    
    @State private var ingredients: [RecipeIngredient] = []
    @State private var steps: [RecipeStep] = []
    @State private var selectedTags: [RecipeTag] = []
    
    @State private var showingCategoryPicker = false
    @State private var showingTagPicker = false
    @State private var showingAddIngredient = false
    @State private var showingAddStep = false
    
    private let categories: [RecipeCategory]
    
    init(recipesService: RecipesService) {
        self.recipesService = recipesService
        self.categories = recipesService.fetchCategories()
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
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Create Recipe")
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
    
    // MARK: - Helper Methods
    private func saveRecipe() {
        guard let category = selectedCategory else { return }
        
        let recipe = recipesService.createRecipe(
            title: title,
            recipeDescription: description.isEmpty ? nil : description,
            category: category,
            prepTime: Int16(prepTime),
            cookingTime: Int16(cookingTime),
            servings: Int16(servings),
            difficulty: Int16(difficulty),
            sourceURL: sourceURL.isEmpty ? nil : sourceURL,
            isTemplate: isTemplate
        )
        
        // Add ingredients
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
        
        // Add steps
        for step in steps {
            _ = recipesService.addStep(
                to: recipe,
                content: step.content ?? "",
                order: step.order,
                timerMinutes: step.timerMinutes
            )
        }
        
        // Add tags
        for tag in selectedTags {
            recipe.addToTags(tag)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Ingredient Row Component
struct IngredientRow: View {
    let ingredient: RecipeIngredient
    let onDelete: () -> Void
    
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
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.sm)
    }
}

// MARK: - Step Row Component
struct StepRow: View {
    let step: RecipeStep
    let stepNumber: Int
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: AtlasTheme.Spacing.md) {
            Text("\(stepNumber)")
                .font(AtlasTheme.Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(AtlasTheme.Colors.primary)
                .frame(width: 20, height: 20)
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
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, AtlasTheme.Spacing.sm)
    }
}

#Preview {
    CreateRecipeView(recipesService: RecipesService(dataManager: DataManager.shared))
}

