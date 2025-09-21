import Foundation
import CoreData
import SwiftUI

@MainActor
class ShoppingListService: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let dataManager: DataManager
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        self.viewContext = dataManager.coreDataStack.viewContext
    }
    
    // MARK: - Shopping List CRUD Operations
    
    @MainActor
    func addItem(
        name: String,
        amount: Double = 1.0,
        unit: String? = nil,
        notes: String? = nil,
        sourceRecipe: Recipe? = nil
    ) -> ShoppingListItem {
        let item = ShoppingListItem(context: viewContext)
        item.uuid = UUID()
        item.name = name
        item.amount = amount
        item.unit = unit
        item.notes = notes
        item.sourceRecipe = sourceRecipe
        item.isCompleted = false
        item.order = Int16(getMaxOrder() + 1)
        item.createdAt = Date()
        item.updatedAt = Date()
        
        saveContext()
        return item
    }
    
    func addIngredientsFromRecipe(_ recipe: Recipe) -> [ShoppingListItem] {
        var addedItems: [ShoppingListItem] = []
        
        guard let ingredients = recipe.ingredients else { return addedItems }
        
        for ingredient in ingredients {
            if let recipeIngredient = ingredient as? RecipeIngredient {
                let item = addItem(
                    name: recipeIngredient.name ?? "",
                    amount: recipeIngredient.amount,
                    unit: recipeIngredient.unit,
                    notes: recipeIngredient.notes,
                    sourceRecipe: recipe
                )
                addedItems.append(item)
            }
        }
        
        // Auto-merge duplicate items
        mergeDuplicateItems()
        
        return addedItems
    }
    
    @MainActor
    func toggleItemCompletion(_ item: ShoppingListItem) {
        item.isCompleted.toggle()
        item.updatedAt = Date()
        saveContext()
    }
    
    @MainActor
    func updateItem(_ item: ShoppingListItem) {
        item.updatedAt = Date()
        saveContext()
    }
    
    @MainActor
    func deleteItem(_ item: ShoppingListItem) {
        viewContext.delete(item)
        saveContext()
    }
    
    @MainActor
    func clearCompletedItems() {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        
        do {
            let completedItems = try viewContext.fetch(request)
            for item in completedItems {
                viewContext.delete(item)
            }
            saveContext()
        } catch {
            print("Error clearing completed items: \(error)")
        }
    }
    
    // MARK: - Fetching
    
    func fetchItems() -> [ShoppingListItem] {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ShoppingListItem.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.order, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.createdAt, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching shopping list items: \(error)")
            return []
        }
    }
    
    func fetchActiveItems() -> [ShoppingListItem] {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ShoppingListItem.order, ascending: true),
            NSSortDescriptor(keyPath: \ShoppingListItem.createdAt, ascending: true)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching active shopping list items: \(error)")
            return []
        }
    }
    
    func fetchCompletedItems() -> [ShoppingListItem] {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ShoppingListItem.updatedAt, ascending: false)
        ]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching completed shopping list items: \(error)")
            return []
        }
    }
    
    // MARK: - Merge Logic
    
    @MainActor
    func mergeDuplicateItems() {
        let items = fetchActiveItems()
        let groupedItems = Dictionary(grouping: items) { item in
            "\(item.name?.lowercased() ?? "")|\(item.unit ?? "")"
        }
        
        for (_, duplicateItems) in groupedItems {
            if duplicateItems.count > 1 {
                // Merge into the first item
                let primaryItem = duplicateItems.first!
                var totalAmount = primaryItem.amount
                var combinedNotes: [String] = []
                
                if let notes = primaryItem.notes, !notes.isEmpty {
                    combinedNotes.append(notes)
                }
                
                // Add amounts and notes from duplicates
                for item in duplicateItems.dropFirst() {
                    totalAmount += item.amount
                    if let notes = item.notes, !notes.isEmpty {
                        combinedNotes.append(notes)
                    }
                    // Delete the duplicate
                    viewContext.delete(item)
                }
                
                // Update the primary item
                primaryItem.amount = totalAmount
                primaryItem.notes = combinedNotes.isEmpty ? nil : combinedNotes.joined(separator: "; ")
                primaryItem.updatedAt = Date()
            }
        }
        
        saveContext()
    }
    
    @MainActor
    func mergeSpecificItems(_ items: [ShoppingListItem]) -> ShoppingListItem? {
        guard items.count > 1 else { return items.first }
        
        let primaryItem = items.first!
        var totalAmount = primaryItem.amount
        var combinedNotes: [String] = []
        
        if let notes = primaryItem.notes, !notes.isEmpty {
            combinedNotes.append(notes)
        }
        
        // Add amounts and notes from other items
        for item in items.dropFirst() {
            totalAmount += item.amount
            if let notes = item.notes, !notes.isEmpty {
                combinedNotes.append(notes)
            }
            // Delete the item
            viewContext.delete(item)
        }
        
        // Update the primary item
        primaryItem.amount = totalAmount
        primaryItem.notes = combinedNotes.isEmpty ? nil : combinedNotes.joined(separator: "; ")
        primaryItem.updatedAt = Date()
        
        saveContext()
        return primaryItem
    }
    
    // MARK: - Utility Methods
    
    private func getMaxOrder() -> Int16 {
        let request: NSFetchRequest<ShoppingListItem> = ShoppingListItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ShoppingListItem.order, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let lastItem = try viewContext.fetch(request).first
            return lastItem?.order ?? 0
        } catch {
            print("Error getting max order: \(error)")
            return 0
        }
    }
    
    func reorderItems(_ items: [ShoppingListItem]) {
        for (index, item) in items.enumerated() {
            item.order = Int16(index)
            item.updatedAt = Date()
        }
        saveContext()
    }
    
    func getItemCount() -> Int {
        return fetchItems().count
    }
    
    func getCompletedCount() -> Int {
        return fetchCompletedItems().count
    }
    
    func getActiveCount() -> Int {
        return fetchActiveItems().count
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func saveContext() {
        dataManager.save()
    }
}


