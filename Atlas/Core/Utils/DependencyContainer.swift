import Foundation
import SwiftUI

// MARK: - Dependency Container
@MainActor
final class DependencyContainer: ObservableObject {
    static let shared = DependencyContainer()
    
    private var dependencies: [String: Any] = [:]
    
    // Core Data Stack
    let coreDataStack: CoreDataStack
    
    private init() {
        self.coreDataStack = CoreDataStack.shared
        setupDependencies()
    }
    
    private func setupDependencies() {
        // Register Core Data Stack
        register(CoreDataStack.self, instance: coreDataStack)
        
        // Register Encryption Service
        register(EncryptionServiceProtocol.self, instance: EncryptionService())
        
        // Register Journal Repository
        register(JournalRepositoryProtocol.self) {
            JournalRepository(
                coreDataStack: self.coreDataStack,
                encryptionService: self.resolve(EncryptionServiceProtocol.self)!
            )
        }
    }
    
    // MARK: - Registration
    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        dependencies[key] = instance
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        dependencies[key] = factory
    }
    
    // MARK: - Resolution
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        if let instance = dependencies[key] as? T {
            return instance
        }
        
        if let factory = dependencies[key] as? () -> T {
            return factory()
        }
        
        return nil
    }
    
    func resolve<T>(_ type: T.Type) throws -> T {
        guard let instance = resolve(type) else {
            throw DependencyError.notRegistered
        }
        return instance
    }
    
    // MARK: - Convenience Properties
    var journalRepository: JournalRepositoryProtocol {
        return resolve(JournalRepositoryProtocol.self)!
    }
}

// MARK: - Dependency Error
enum DependencyError: Error {
    case notRegistered
    case circularDependency
    case invalidType
}

// MARK: - Environment Key
struct DependenciesKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func inject(_ dependencies: DependencyContainer) -> some View {
        self.environment(\.dependencies, dependencies)
    }
}