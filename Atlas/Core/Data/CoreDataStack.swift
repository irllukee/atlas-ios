import Foundation
import CoreData

// MARK: - CoreDataStack
@MainActor
final class CoreDataStack {
    static let shared = CoreDataStack() // Singleton

    let persistentContainer: NSPersistentContainer

    private init() {
        persistentContainer = NSPersistentContainer(name: "Atlas")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error.localizedDescription)")
            }
        }
        // Automatically merge changes from other contexts
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
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
        print("📊 Core Data Database Statistics:")
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
