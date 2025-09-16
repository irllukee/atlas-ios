import Foundation
import CoreData

/// Extensions to CoreData models for encryption support
extension Note {
    
    /// Encrypt the note content if security is enabled
    @MainActor
    func encryptContent() throws {
        guard let content = self.content, !content.isEmpty else { return }
        
        let securityManager = SecurityManager.shared
        let encryptedData = try securityManager.encrypt(content)
        
        // Store encrypted data as JSON
        let encoder = JSONEncoder()
        self.content = String(data: try encoder.encode(encryptedData), encoding: .utf8)
        self.isEncrypted = true
        self.updatedAt = Date()
    }
    
    /// Decrypt the note content if it's encrypted
    @MainActor
    func decryptContent() throws -> String {
        guard let content = self.content else { return "" }
        
        if self.isEncrypted {
            let securityManager = SecurityManager.shared
            
            // Parse encrypted data from JSON
            guard let data = content.data(using: .utf8) else {
                throw SecurityError.encryptionNotAvailable
            }
            
            let decoder = JSONDecoder()
            let encryptedData = try decoder.decode(EncryptedData.self, from: data)
            
            return try securityManager.decryptToString(encryptedData)
        }
        
        return content
    }
    
    /// Get decrypted content safely (non-async version for computed properties)
    @MainActor
    var decryptedContent: String {
        get async {
            do {
                return try await decryptContent()
            } catch {
                print("❌ Failed to decrypt note content: \(error)")
                return "Unable to decrypt content"
            }
        }
    }
}

extension JournalEntry {
    
    /// Encrypt the journal content if security is enabled
    @MainActor
    func encryptContent() throws {
        guard let content = self.content, !content.isEmpty else { return }
        
        let securityManager = SecurityManager.shared
        let encryptedData = try securityManager.encrypt(content)
        
        // Store encrypted data as JSON
        let encoder = JSONEncoder()
        self.content = String(data: try encoder.encode(encryptedData), encoding: .utf8)
        self.isEncrypted = true
        self.updatedAt = Date()
    }
    
    /// Decrypt the journal content if it's encrypted
    @MainActor
    func decryptContent() throws -> String {
        guard let content = self.content else { return "" }
        
        if self.isEncrypted {
            let securityManager = SecurityManager.shared
            
            // Parse encrypted data from JSON
            guard let data = content.data(using: .utf8) else {
                throw SecurityError.encryptionNotAvailable
            }
            
            let decoder = JSONDecoder()
            let encryptedData = try decoder.decode(EncryptedData.self, from: data)
            
            return try securityManager.decryptToString(encryptedData)
        }
        
        return content
    }
    
    /// Get decrypted content safely (non-async version for computed properties)
    @MainActor
    var decryptedContent: String {
        get async {
            do {
                return try await decryptContent()
            } catch {
                print("❌ Failed to decrypt journal content: \(error)")
                return "Unable to decrypt content"
            }
        }
    }
}

