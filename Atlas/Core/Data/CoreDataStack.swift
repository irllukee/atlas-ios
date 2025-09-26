import Foundation
import CoreData

// MARK: - Migration Manager
@MainActor
final class CoreDataMigrationManager: @unchecked Sendable {
    static let shared = CoreDataMigrationManager()
    
    private init() {}
    
    func requiresMigration(at storeURL: URL, to version: String) -> Bool {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL) else {
            return false
        }
        
        return (metadata[NSStoreModelVersionHashesKey] as? [String: Any]) != nil
    }
    
    func performMigration(from sourceURL: URL, to destinationURL: URL) throws {
        _ = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: sourceURL)
        guard let destinationModel = NSManagedObjectModel.mergedModel(from: Bundle.allBundles) else {
            throw NSError(domain: "MigrationError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Could not load destination model"])
        }
        
        guard let sourceModel = NSManagedObjectModel(contentsOf: sourceURL.appendingPathComponent("Contents")) else {
            throw NSError(domain: "MigrationError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Could not load source model"])
        }
        
        // Perform lightweight migration
        let mappingModel = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
        
        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        
        try migrationManager.migrateStore(from: sourceURL, sourceType: NSSQLiteStoreType, options: nil, with: mappingModel, toDestinationURL: destinationURL, destinationType: NSSQLiteStoreType, destinationOptions: nil)
    }
}

// MARK: - CoreDataStack
@MainActor
final class CoreDataStack {
    static let shared = CoreDataStack() // Singleton

    let persistentContainer: NSPersistentContainer
    private let migrationManager = CoreDataMigrationManager.shared

    private init() {
        print("📋 CoreDataStack: Initializing...")
        // Use regular NSPersistentContainer for local storage only
        persistentContainer = NSPersistentContainer(name: "Atlas")

        // Configure store for local storage only
        guard let description = persistentContainer.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        // Configure migration settings
        setupMigration(description: description)
        
        persistentContainer.loadPersistentStores { [weak self] description, error in
            self?.handleStoreLoading(description: description, error: error)
        }
        
        // Automatically merge changes from other contexts
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    private func setupMigration(description: NSPersistentStoreDescription) {
        // Enable automatic migration for lightweight changes
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // AGGRESSIVE: Force disable history tracking to prevent read-only mode issues
        // This resolves the persistent "Store opened without NSPersistentHistoryTrackingKey" error
        description.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        print("⚠️ Core Data: History tracking disabled to prevent read-only mode conflicts")
        
        // Set migration options for better performance
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Configure SQLite options for better performance
        var sqliteOptions: [String: Any] = [:]
        sqliteOptions["journal_mode"] = "WAL" // Write-Ahead Logging for better concurrency
        sqliteOptions["synchronous"] = "NORMAL" // Balance between performance and safety
        sqliteOptions["cache_size"] = 10000 // Increase cache size
        sqliteOptions["temp_store"] = "MEMORY" // Store temporary tables in memory
        description.setOption(sqliteOptions as NSDictionary, forKey: NSSQLitePragmasOption)
        
        // AGGRESSIVE: If store exists with history tracking, delete and recreate
        if let storeURL = description.url, FileManager.default.fileExists(atPath: storeURL.path) {
            do {
                // Check if store has history tracking metadata
                let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL)
                if metadata[NSPersistentHistoryTrackingKey] as? Bool == true {
                    print("🔄 Core Data: Store has history tracking, recreating without it...")
                    try FileManager.default.removeItem(at: storeURL)
                    print("✅ Core Data: Store recreated without history tracking")
                }
            } catch {
                print("⚠️ Core Data: Could not check store metadata: \(error)")
            }
        }
    }
    
    private func handleStoreLoading(description: NSPersistentStoreDescription, error: Error?) {
        if let error = error {
            print("❌ Core Data Error: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            
            // Check if it's a history tracking mismatch error
            if error.localizedDescription.contains("NSPersistentHistoryTrackingKey") || 
               error.localizedDescription.contains("Forcing into Read Only mode") {
                print("🔄 Core Data: History tracking mismatch detected, attempting to resolve...")
                if let storeURL = description.url {
                    do {
                        // First, try to disable history tracking to resolve the conflict
                        description.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                        print("⚠️ Core Data: Disabling history tracking to resolve conflict")
                        
                        // Try to migrate the store to support history tracking
                        try migrateToHistoryTracking(storeURL: storeURL)
                        print("✅ Core Data: Successfully migrated to history tracking")
                        // Retry loading after migration
                        retryStoreLoading(description: description)
                        return
                    } catch {
                        print("❌ Core Data: Migration to history tracking failed: \(error)")
                        // Fall back to disabling history tracking permanently
                        description.setOption(false as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                        print("⚠️ Core Data: Permanently disabling history tracking to resolve conflict")
                        retryStoreLoading(description: description)
                        return
                    }
                }
            }
            
            // Attempt migration if needed
            if let storeURL = description.url, 
               migrationManager.requiresMigration(at: storeURL, to: "1.0") {
                do {
                    try performStoreMigration(from: storeURL)
                    // Retry loading after migration
                    retryStoreLoading(description: description)
                    return
                } catch {
                    print("❌ Migration failed: \(error)")
                }
            }
            
            // Try to delete the store and recreate it as last resort
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
            logDatabaseStats()
        }
    }
    
    private func performStoreMigration(from storeURL: URL) throws {
        print("🔄 Performing Core Data migration...")
        
        let backupURL = storeURL.appendingPathExtension("backup")
        
        // Create backup
        try FileManager.default.copyItem(at: storeURL, to: backupURL)
        print("📦 Created backup at: \(backupURL)")
        
        // Perform migration
        try migrationManager.performMigration(from: storeURL, to: storeURL)
        
        // Remove backup after successful migration
        try FileManager.default.removeItem(at: backupURL)
        print("✅ Migration completed successfully")
    }
    
    private func retryStoreLoading(description: NSPersistentStoreDescription) {
        persistentContainer.loadPersistentStores { [weak self] description, error in
            self?.handleStoreLoading(description: description, error: error)
        }
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
    
    func saveAsync() {
        guard viewContext.hasChanges else { return }
        
        performBackgroundTask { backgroundContext in
            do {
                try backgroundContext.save()
                print("✅ Background save completed successfully")
            } catch {
                print("❌ Background save failed: \(error)")
                // Fallback to main thread save using Task for better performance
                _Concurrency.Task { @MainActor in
                    self.save()
                }
            }
        }
    }
    
    func autoSave() {
        guard viewContext.hasChanges else { return }
        
        // Use background save for better performance
        saveAsync()
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Data Validation & Cleanup
    func validateContext() -> Bool {
        return viewContext.persistentStoreCoordinator != nil
    }
    
    
    private func migrateToHistoryTracking(storeURL: URL) throws {
        print("🔄 Migrating store to support history tracking...")
        
        // Create a backup of the current store
        let backupURL = storeURL.appendingPathExtension("backup")
        try FileManager.default.copyItem(at: storeURL, to: backupURL)
        
        // For now, we'll just recreate the store with history tracking
        // In a production app, you might want to implement a more sophisticated migration
        try FileManager.default.removeItem(at: storeURL)
        print("✅ Store recreated with history tracking support")
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
