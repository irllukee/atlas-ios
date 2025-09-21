import Foundation
import CoreData
import SwiftUI

@MainActor
class RecipesService: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.viewContext = dataManager.coreDataStack.viewContext
        setupDefaultCategories()
    }
    
    // MARK: - Recipe CRUD Operations
    
    func createRecipe(
        title: String,
        recipeDescription: String? = nil,
        category: RecipeCategory,
        prepTime: Int16 = 0,
        cookingTime: Int16 = 0,
        servings: Int16 = 1,
        difficulty: Int16 = 1,
        sourceURL: String? = nil,
        isTemplate: Bool = false
    ) -> Recipe {
        let recipe = Recipe(context: viewContext)
        recipe.uuid = UUID()
        recipe.title = title
        recipe.recipeDescription = recipeDescription
        recipe.category = category
        recipe.prepTime = prepTime
        recipe.cookingTime = cookingTime
        recipe.servings = servings
        recipe.difficulty = difficulty
        recipe.sourceURL = sourceURL
        recipe.isTemplate = isTemplate
        recipe.isFavorite = false
        recipe.createdAt = Date()
        recipe.updatedAt = Date()
        
        saveContext()
        return recipe
    }
    
    func updateRecipe(_ recipe: Recipe) {
        recipe.updatedAt = Date()
        saveContext()
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        viewContext.delete(recipe)
        saveContext()
    }
    
    func toggleFavorite(_ recipe: Recipe) {
        recipe.isFavorite.toggle()
        recipe.updatedAt = Date()
        saveContext()
    }
    
    // MARK: - Recipe Fetching
    
    func fetchRecipes(
        category: RecipeCategory? = nil,
        searchText: String? = nil,
        tags: [RecipeTag] = [],
        favoritesOnly: Bool = false,
        templatesOnly: Bool = false
    ) -> [Recipe] {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        var predicates: [NSPredicate] = []
        
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category))
        }
        
        if let searchText = searchText, !searchText.isEmpty {
            let titlePredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchText)
            let descriptionPredicate = NSPredicate(format: "description CONTAINS[cd] %@", searchText)
            let ingredientPredicate = NSPredicate(format: "ANY ingredients.name CONTAINS[cd] %@", searchText)
            let stepPredicate = NSPredicate(format: "ANY steps.content CONTAINS[cd] %@", searchText)
            
            let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                titlePredicate, descriptionPredicate, ingredientPredicate, stepPredicate
            ])
            predicates.append(searchPredicate)
        }
        
        if !tags.isEmpty {
            predicates.append(NSPredicate(format: "ANY tags IN %@", tags))
        }
        
        if favoritesOnly {
            predicates.append(NSPredicate(format: "isFavorite == YES"))
        }
        
        if templatesOnly {
            predicates.append(NSPredicate(format: "isTemplate == YES"))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Recipe.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \Recipe.title, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching recipes: \(error)")
            return []
        }
    }
    
    func fetchRecipe(by uuid: UUID) -> Recipe? {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuid as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching recipe: \(error)")
            return nil
        }
    }
    
    // MARK: - Categories
    
    func fetchCategories() -> [RecipeCategory] {
        let request: NSFetchRequest<RecipeCategory> = RecipeCategory.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \RecipeCategory.order, ascending: true),
            NSSortDescriptor(keyPath: \RecipeCategory.name, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    func createCategory(name: String, icon: String, color: String) -> RecipeCategory {
        let category = RecipeCategory(context: viewContext)
        category.uuid = UUID()
        category.name = name
        category.icon = icon
        category.color = color
        category.isSystemCategory = false
        category.order = Int16(fetchCategories().count)
        category.createdAt = Date()
        category.updatedAt = Date()
        
        saveContext()
        return category
    }
    
    private func setupDefaultCategories() {
        let existingCategories = fetchCategories()
        if !existingCategories.isEmpty { return }
        
        let defaultCategories = [
            ("Breakfast", "sun.max.fill", "#FF9500"),
            ("Lunch", "sun.max", "#FFCC00"),
            ("Dinner", "moon.stars.fill", "#8E44AD"),
            ("Snack", "hand.raised.fill", "#E67E22"),
            ("Dessert", "birthday.cake.fill", "#E91E63"),
            ("Drink", "drop.fill", "#3498DB")
        ]
        
        for (index, (name, icon, color)) in defaultCategories.enumerated() {
            let category = RecipeCategory(context: viewContext)
            category.uuid = UUID()
            category.name = name
            category.icon = icon
            category.color = color
            category.isSystemCategory = true
            category.order = Int16(index)
            category.createdAt = Date()
            category.updatedAt = Date()
        }
        
        saveContext()
    }
    
    // MARK: - Tags
    
    func fetchTags() -> [RecipeTag] {
        let request: NSFetchRequest<RecipeTag> = RecipeTag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RecipeTag.name, ascending: true)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tags: \(error)")
            return []
        }
    }
    
    func createTag(name: String, color: String = "#007AFF") -> RecipeTag {
        let tag = RecipeTag(context: viewContext)
        tag.uuid = UUID()
        tag.name = name
        tag.color = color
        tag.createdAt = Date()
        tag.updatedAt = Date()
        
        saveContext()
        return tag
    }
    
    func deleteTag(_ tag: RecipeTag) {
        viewContext.delete(tag)
        saveContext()
    }
    
    // MARK: - Ingredients
    
    func addIngredient(
        to recipe: Recipe,
        name: String,
        amount: Double,
        unit: String? = nil,
        notes: String? = nil,
        order: Int16 = 0
    ) -> RecipeIngredient {
        let ingredient = RecipeIngredient(context: viewContext)
        ingredient.uuid = UUID()
        ingredient.name = name
        ingredient.amount = amount
        ingredient.unit = unit
        ingredient.notes = notes
        ingredient.order = order
        ingredient.recipe = recipe
        ingredient.createdAt = Date()
        ingredient.updatedAt = Date()
        
        saveContext()
        return ingredient
    }
    
    func updateIngredient(_ ingredient: RecipeIngredient) {
        ingredient.updatedAt = Date()
        saveContext()
    }
    
    func deleteIngredient(_ ingredient: RecipeIngredient) {
        viewContext.delete(ingredient)
        saveContext()
    }
    
    // MARK: - Steps
    
    func addStep(
        to recipe: Recipe,
        content: String,
        order: Int16 = 0,
        timerMinutes: Int16 = 0
    ) -> RecipeStep {
        let step = RecipeStep(context: viewContext)
        step.uuid = UUID()
        step.content = content
        step.order = order
        step.timerMinutes = timerMinutes
        step.recipe = recipe
        step.createdAt = Date()
        step.updatedAt = Date()
        
        saveContext()
        return step
    }
    
    func updateStep(_ step: RecipeStep) {
        step.updatedAt = Date()
        saveContext()
    }
    
    func deleteStep(_ step: RecipeStep) {
        viewContext.delete(step)
        saveContext()
    }
    
    // MARK: - Templates
    
    func createTemplate(from recipe: Recipe) -> Recipe {
        let template = Recipe(context: viewContext)
        template.uuid = UUID()
        template.title = "\(recipe.title ?? "Untitled") Template"
        template.recipeDescription = recipe.recipeDescription
        template.category = recipe.category
        template.prepTime = recipe.prepTime
        template.cookingTime = recipe.cookingTime
        template.servings = recipe.servings
        template.difficulty = recipe.difficulty
        template.isTemplate = true
        template.isFavorite = false
        template.createdAt = Date()
        template.updatedAt = Date()
        
        // Copy ingredients
        if let ingredients = recipe.ingredients {
            for ingredient in ingredients {
                if let originalIngredient = ingredient as? RecipeIngredient {
                    _ = addIngredient(
                        to: template,
                        name: originalIngredient.name ?? "",
                        amount: originalIngredient.amount,
                        unit: originalIngredient.unit,
                        notes: originalIngredient.notes,
                        order: originalIngredient.order
                    )
                }
            }
        }
        
        // Copy steps
        if let steps = recipe.steps {
            for step in steps {
                if let originalStep = step as? RecipeStep {
                    _ = addStep(
                        to: template,
                        content: originalStep.content ?? "",
                        order: originalStep.order,
                        timerMinutes: originalStep.timerMinutes
                    )
                }
            }
        }
        
        // Copy tags
        if let tags = recipe.tags {
            for tag in tags {
                if let recipeTag = tag as? RecipeTag {
                    template.addToTags(recipeTag)
                }
            }
        }
        
        saveContext()
        return template
    }
    
    func createRecipeFromTemplate(_ template: Recipe, title: String) -> Recipe {
        let recipe = Recipe(context: viewContext)
        recipe.uuid = UUID()
        recipe.title = title
        recipe.recipeDescription = template.recipeDescription
        recipe.category = template.category
        recipe.prepTime = template.prepTime
        recipe.cookingTime = template.cookingTime
        recipe.servings = template.servings
        recipe.difficulty = template.difficulty
        recipe.isTemplate = false
        recipe.isFavorite = false
        recipe.createdAt = Date()
        recipe.updatedAt = Date()
        
        // Copy ingredients
        if let ingredients = template.ingredients {
            for ingredient in ingredients {
                if let originalIngredient = ingredient as? RecipeIngredient {
                    _ = addIngredient(
                        to: recipe,
                        name: originalIngredient.name ?? "",
                        amount: originalIngredient.amount,
                        unit: originalIngredient.unit,
                        notes: originalIngredient.notes,
                        order: originalIngredient.order
                    )
                }
            }
        }
        
        // Copy steps
        if let steps = template.steps {
            for step in steps {
                if let originalStep = step as? RecipeStep {
                    _ = addStep(
                        to: recipe,
                        content: originalStep.content ?? "",
                        order: originalStep.order,
                        timerMinutes: originalStep.timerMinutes
                    )
                }
            }
        }
        
        // Copy tags
        if let tags = template.tags {
            for tag in tags {
                if let recipeTag = tag as? RecipeTag {
                    recipe.addToTags(recipeTag)
                }
            }
        }
        
        saveContext()
        return recipe
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func saveContext() {
        dataManager.save()
    }
}

