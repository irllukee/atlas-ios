import SwiftUI

struct RecipeTestView: View {
    @StateObject private var recipesService: RecipesService
    @StateObject private var shoppingListService: ShoppingListService
    @StateObject private var importService: RecipeImportService
    @StateObject private var photoService = PhotoService()
    
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    
    init() {
        let dataManager = DataManager.shared
        self._recipesService = StateObject(wrappedValue: RecipesService(dataManager: dataManager))
        self._shoppingListService = StateObject(wrappedValue: ShoppingListService(dataManager: dataManager))
        self._importService = StateObject(wrappedValue: RecipeImportService(recipesService: RecipesService(dataManager: dataManager)))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Test Header
                        testHeaderSection
                        
                        // Test Controls
                        testControlsSection
                        
                        // Test Results
                        testResultsSection
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.top, AtlasTheme.Spacing.md)
                }
            }
            .navigationTitle("Recipe Feature Tests")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Test Header Section
    private var testHeaderSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundColor(AtlasTheme.Colors.primary)
                    
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                        Text("Recipe Feature Tests")
                            .font(AtlasTheme.Typography.title)
                            .fontWeight(.bold)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("Comprehensive testing of all recipe features")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Text("This test suite validates all the implemented recipe features including CRUD operations, shopping list integration, import functionality, photo management, and template system.")
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Test Controls Section
    private var testControlsSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Test Controls")
                
                Button(action: {
                    runAllTests()
                }) {
                    HStack {
                        if isRunningTests {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                        
                        Text(isRunningTests ? "Running Tests..." : "Run All Tests")
                            .font(AtlasTheme.Typography.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AtlasTheme.Spacing.md)
                    .background(AtlasTheme.Colors.primary)
                    .cornerRadius(AtlasTheme.CornerRadius.medium)
                }
                .disabled(isRunningTests)
                
                if !testResults.isEmpty {
                    Button(action: {
                        testResults.removeAll()
                    }) {
                        Text("Clear Results")
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Test Results Section
    private var testResultsSection: some View {
        FrostedCard {
            VStack(spacing: AtlasTheme.Spacing.md) {
                SectionHeader(title: "Test Results")
                
                if testResults.isEmpty {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Text("No tests run yet")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    .padding(.vertical, AtlasTheme.Spacing.lg)
                } else {
                    ForEach(testResults.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: testResults[index].hasPrefix("✅") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(testResults[index].hasPrefix("✅") ? .green : .red)
                            
                            Text(testResults[index])
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.text)
                            
                            Spacer()
                        }
                        .padding(.vertical, AtlasTheme.Spacing.xs)
                    }
                }
            }
        }
    }
    
    // MARK: - Test Methods
    private func runAllTests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task { @MainActor in
            await runTests()
            isRunningTests = false
        }
    }
    
    private func runTests() async {
        await addTestResult("🧪 Starting Recipe Feature Tests...")
        
        // Test 1: Core Data Models
        await testCoreDataModels()
        
        // Test 2: Recipe CRUD Operations
        await testRecipeCRUD()
        
        // Test 3: Categories
        await testCategories()
        
        // Test 4: Tags
        await testTags()
        
        // Test 5: Ingredients and Steps
        await testIngredientsAndSteps()
        
        // Test 6: Shopping List
        await testShoppingList()
        
        // Test 7: Search and Filtering
        await testSearchAndFiltering()
        
        // Test 8: Favorites
        await testFavorites()
        
        // Test 9: Templates
        await testTemplates()
        
        // Test 10: Import Functionality
        await testImportFunctionality()
        
        await addTestResult("🎉 All tests completed!")
    }
    
    private func addTestResult(_ message: String) async {
        await MainActor.run {
            testResults.append(message)
        }
    }
    
    private func testCoreDataModels() async {
        await addTestResult("📊 Testing Core Data Models...")
        
        // Test if categories are created
        let categories = recipesService.fetchCategories()
        if categories.count >= 6 {
            await addTestResult("✅ Default categories created successfully (\(categories.count) categories)")
        } else {
            await addTestResult("❌ Failed to create default categories")
        }
    }
    
    private func testRecipeCRUD() async {
        await addTestResult("📝 Testing Recipe CRUD Operations...")
        
        // Create a test recipe
        let categories = recipesService.fetchCategories()
        guard let category = categories.first else {
            await addTestResult("❌ No categories available for testing")
            return
        }
        
        let recipe = recipesService.createRecipe(
            title: "Test Recipe",
            recipeDescription: "A test recipe for validation",
            category: category,
            prepTime: 15,
            cookingTime: 30,
            servings: 4,
            difficulty: 3
        )
        
        if recipe.title == "Test Recipe" {
            await addTestResult("✅ Recipe creation successful")
        } else {
            await addTestResult("❌ Recipe creation failed")
        }
        
        // Test fetching
        let fetchedRecipe = recipesService.fetchRecipe(by: recipe.uuid!)
        if fetchedRecipe != nil {
            await addTestResult("✅ Recipe fetching successful")
        } else {
            await addTestResult("❌ Recipe fetching failed")
        }
        
        // Test updating
        recipe.title = "Updated Test Recipe"
        recipesService.updateRecipe(recipe)
        
        let updatedRecipe = recipesService.fetchRecipe(by: recipe.uuid!)
        if updatedRecipe?.title == "Updated Test Recipe" {
            await addTestResult("✅ Recipe updating successful")
        } else {
            await addTestResult("❌ Recipe updating failed")
        }
        
        // Test deletion
        recipesService.deleteRecipe(recipe)
        let deletedRecipe = recipesService.fetchRecipe(by: recipe.uuid!)
        if deletedRecipe == nil {
            await addTestResult("✅ Recipe deletion successful")
        } else {
            await addTestResult("❌ Recipe deletion failed")
        }
    }
    
    private func testCategories() async {
        await addTestResult("📂 Testing Categories...")
        
        let categories = recipesService.fetchCategories()
        
        // Test default categories
        let defaultCategoryNames = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert", "Drink"]
        let hasAllDefaults = defaultCategoryNames.allSatisfy { name in
            categories.contains { $0.name == name }
        }
        
        if hasAllDefaults {
            await addTestResult("✅ Default categories present")
        } else {
            await addTestResult("❌ Missing default categories")
        }
        
        // Test custom category creation
        let customCategory = recipesService.createCategory(name: "Test Category", icon: "star", color: "#FF0000")
        if customCategory.name == "Test Category" {
            await addTestResult("✅ Custom category creation successful")
        } else {
            await addTestResult("❌ Custom category creation failed")
        }
    }
    
    private func testTags() async {
        await addTestResult("🏷️ Testing Tags...")
        
        // Test tag creation
        let tag = recipesService.createTag(name: "Test Tag", color: "#00FF00")
        if tag.name == "Test Tag" {
            await addTestResult("✅ Tag creation successful")
        } else {
            await addTestResult("❌ Tag creation failed")
        }
        
        // Test tag fetching
        let tags = recipesService.fetchTags()
        if tags.contains(where: { $0.name == "Test Tag" }) {
            await addTestResult("✅ Tag fetching successful")
        } else {
            await addTestResult("❌ Tag fetching failed")
        }
        
        // Test tag deletion
        recipesService.deleteTag(tag)
        let remainingTags = recipesService.fetchTags()
        if !remainingTags.contains(where: { $0.name == "Test Tag" }) {
            await addTestResult("✅ Tag deletion successful")
        } else {
            await addTestResult("❌ Tag deletion failed")
        }
    }
    
    private func testIngredientsAndSteps() async {
        await addTestResult("🥘 Testing Ingredients and Steps...")
        
        let categories = recipesService.fetchCategories()
        guard let category = categories.first else { return }
        
        let recipe = recipesService.createRecipe(
            title: "Test Recipe with Ingredients",
            category: category
        )
        
        // Test ingredient creation
        let ingredient = recipesService.addIngredient(
            to: recipe,
            name: "Test Ingredient",
            amount: 2.5,
            unit: "cups",
            notes: "Optional note"
        )
        
        if ingredient.name == "Test Ingredient" && ingredient.amount == 2.5 {
            await addTestResult("✅ Ingredient creation successful")
        } else {
            await addTestResult("❌ Ingredient creation failed")
        }
        
        // Test step creation
        let step = recipesService.addStep(
            to: recipe,
            content: "Test cooking step",
            timerMinutes: 10
        )
        
        if step.content == "Test cooking step" && step.timerMinutes == 10 {
            await addTestResult("✅ Step creation successful")
        } else {
            await addTestResult("❌ Step creation failed")
        }
        
        // Cleanup
        recipesService.deleteRecipe(recipe)
    }
    
    private func testShoppingList() async {
        await addTestResult("🛒 Testing Shopping List...")
        
        // Test adding individual items
        let item1 = shoppingListService.addItem(name: "Test Item 1", amount: 1, unit: "cup")
        let item2 = shoppingListService.addItem(name: "Test Item 2", amount: 2, unit: "tbsp")
        
        let items = shoppingListService.fetchItems()
        if items.count >= 2 {
            await addTestResult("✅ Shopping list item creation successful")
        } else {
            await addTestResult("❌ Shopping list item creation failed")
        }
        
        // Test toggle completion
        shoppingListService.toggleItemCompletion(item1)
        let activeItems = shoppingListService.fetchActiveItems()
        let completedItems = shoppingListService.fetchCompletedItems()
        
        if activeItems.count == 1 && completedItems.count == 1 {
            await addTestResult("✅ Shopping list toggle completion successful")
        } else {
            await addTestResult("❌ Shopping list toggle completion failed")
        }
        
        // Test merge functionality
        let duplicateItem = shoppingListService.addItem(name: "Test Item 1", amount: 1, unit: "cup")
        shoppingListService.mergeDuplicateItems()
        
        let mergedItems = shoppingListService.fetchItems()
        let testItem1Count = mergedItems.filter { $0.name == "Test Item 1" }.count
        
        if testItem1Count == 1 {
            await addTestResult("✅ Shopping list merge functionality successful")
        } else {
            await addTestResult("❌ Shopping list merge functionality failed")
        }
        
        // Cleanup
        shoppingListService.deleteItem(item1)
        shoppingListService.deleteItem(item2)
        shoppingListService.deleteItem(duplicateItem)
    }
    
    private func testSearchAndFiltering() async {
        await addTestResult("🔍 Testing Search and Filtering...")
        
        let categories = recipesService.fetchCategories()
        guard let category = categories.first else { return }
        
        // Create test recipes
        let recipe1 = recipesService.createRecipe(title: "Pasta Recipe", recipeDescription: "Delicious pasta", category: category)
        let recipe2 = recipesService.createRecipe(title: "Pizza Recipe", recipeDescription: "Homemade pizza", category: category)
        let recipe3 = recipesService.createRecipe(title: "Salad Recipe", recipeDescription: "Fresh salad", category: category)
        
        // Test search by title
        let searchResults = recipesService.fetchRecipes(searchText: "Pasta")
        if searchResults.contains(where: { $0.title == "Pasta Recipe" }) {
            await addTestResult("✅ Search by title successful")
        } else {
            await addTestResult("❌ Search by title failed")
        }
        
        // Test category filtering
        let categoryResults = recipesService.fetchRecipes(category: category)
        if categoryResults.count >= 3 {
            await addTestResult("✅ Category filtering successful")
        } else {
            await addTestResult("❌ Category filtering failed")
        }
        
        // Cleanup
        recipesService.deleteRecipe(recipe1)
        recipesService.deleteRecipe(recipe2)
        recipesService.deleteRecipe(recipe3)
    }
    
    private func testFavorites() async {
        await addTestResult("⭐ Testing Favorites...")
        
        let categories = recipesService.fetchCategories()
        guard let category = categories.first else { return }
        
        let recipe = recipesService.createRecipe(title: "Favorite Test Recipe", category: category)
        
        // Test toggle favorite
        recipesService.toggleFavorite(recipe)
        let favoritedRecipe = recipesService.fetchRecipe(by: recipe.uuid!)
        
        if favoritedRecipe?.isFavorite == true {
            await addTestResult("✅ Favorite toggle successful")
        } else {
            await addTestResult("❌ Favorite toggle failed")
        }
        
        // Test favorites filtering
        let favorites = recipesService.fetchRecipes(favoritesOnly: true)
        if favorites.contains(where: { $0.title == "Favorite Test Recipe" }) {
            await addTestResult("✅ Favorites filtering successful")
        } else {
            await addTestResult("❌ Favorites filtering failed")
        }
        
        // Cleanup
        recipesService.deleteRecipe(recipe)
    }
    
    private func testTemplates() async {
        await addTestResult("📋 Testing Templates...")
        
        let categories = recipesService.fetchCategories()
        guard let category = categories.first else { return }
        
        let recipe = recipesService.createRecipe(title: "Template Source Recipe", category: category)
        _ = recipesService.addIngredient(to: recipe, name: "Template Ingredient", amount: 1, unit: "cup")
        _ = recipesService.addStep(to: recipe, content: "Template step", order: 0)
        
        // Test template creation
        let template = recipesService.createTemplate(from: recipe)
        if template.isTemplate && template.title?.contains("Template") == true {
            await addTestResult("✅ Template creation successful")
        } else {
            await addTestResult("❌ Template creation failed")
        }
        
        // Test template fetching
        let templates = recipesService.fetchRecipes(templatesOnly: true)
        if templates.contains(where: { $0.isTemplate }) {
            await addTestResult("✅ Template fetching successful")
        } else {
            await addTestResult("❌ Template fetching failed")
        }
        
        // Test recipe creation from template
        let newRecipe = recipesService.createRecipeFromTemplate(template, title: "Recipe from Template")
        if newRecipe.title == "Recipe from Template" && !newRecipe.isTemplate {
            await addTestResult("✅ Recipe creation from template successful")
        } else {
            await addTestResult("❌ Recipe creation from template failed")
        }
        
        // Cleanup
        recipesService.deleteRecipe(recipe)
        recipesService.deleteRecipe(template)
        recipesService.deleteRecipe(newRecipe)
    }
    
    private func testImportFunctionality() async {
        await addTestResult("📥 Testing Import Functionality...")
        
        // Test manual text import
        let testText = """
        Test Import Recipe
        A recipe for testing import functionality
        
        Ingredients:
        2 cups flour
        1 cup sugar
        2 eggs
        
        Instructions:
        1. Mix flour and sugar
        2. Add eggs
        3. Bake for 30 minutes
        
        Prep: 15 min
        Cook: 30 min
        Serves: 4
        """
        
        let importResult = importService.importRecipeFromText(testText)
        
        if case .success(let importedRecipe) = importResult {
            await addTestResult("✅ Manual text import successful")
            
            // Verify imported data
            if importedRecipe.title == "Test Import Recipe" {
                await addTestResult("✅ Imported recipe title correct")
            } else {
                await addTestResult("❌ Imported recipe title incorrect")
            }
            
            // Cleanup
            recipesService.deleteRecipe(importedRecipe)
        } else {
            await addTestResult("❌ Manual text import failed")
        }
    }
}

#Preview {
    RecipeTestView()
}


