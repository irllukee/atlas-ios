import Foundation
import CoreData

// MARK: - CoreDataStack
@MainActor
final class CoreDataStack {
    static let shared = CoreDataStack() // Singleton

    let persistentContainer: NSPersistentContainer

    private init() {
        print("📋 CoreDataStack: Initializing...")
        // Use regular NSPersistentContainer for local storage only
        persistentContainer = NSPersistentContainer(name: "Atlas")

        // Configure store for local storage only
        guard let description = persistentContainer.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Enable automatic migration
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Enable history tracking to prevent read-only mode issues
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data Error: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
                
                // Try to delete the store and recreate it
                if let storeURL = description.url {
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        print("✅ Deleted corrupted store, will recreate on next launch")
                    } catch {
                        print("❌ Failed to delete store: \(error)")
                    }
                }
                
                fatalError("Failed to load Core Data stack: \(error.localizedDescription)")
            } else {
                print("✅ Core Data stack loaded successfully")
            }
        }
        
        // Automatically merge changes from other contexts
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }

    func newDerivedContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Data Validation & Cleanup
    func validateContext() -> Bool {
        return viewContext.persistentStoreCoordinator != nil
    }

    func deleteAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                do {
                    try viewContext.execute(batchDeleteRequest)
                } catch {
                    print("Error deleting all data for entity \(entityName): \(error)")
                }
            }
        }
        save()
    }

    func logDatabaseStats() {
        let entities = persistentContainer.managedObjectModel.entities
        // Core Data Database Statistics
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                do {
                    let count = try viewContext.count(for: fetchRequest)
                    print("  - \(entityName): \(count) records")
                } catch {
                    print("  - Error fetching count for \(entityName): \(error)")
                }
            }
        }
    }
}
