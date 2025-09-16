import Foundation
import CryptoKit
import Security

/// High-level encryption service using AES-GCM for secure data protection
@MainActor
final class EncryptionService: ObservableObject {
    static let shared = EncryptionService()
    
    // MARK: - Private Properties
    private var encryptionKey: SymmetricKey?
    private let keychain = KeychainService.shared
    
    // MARK: - Published Properties
    @Published var isEncryptionAvailable = false
    @Published var lastError: Error?
    
    // MARK: - Initialization
    private init() {
        setupEncryption()
    }
    
    // MARK: - Setup
    private func setupEncryption() {
        do {
            encryptionKey = try getOrCreateEncryptionKey()
            isEncryptionAvailable = true
        } catch {
            lastError = error
            isEncryptionAvailable = false
            print("❌ Encryption setup failed: \(error)")
        }
    }
    
    // MARK: - Key Management
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to retrieve existing key from keychain
        if let existingKey = try keychain.getEncryptionKey() {
            return existingKey
        }
        
        // Generate new key if none exists
        let newKey = SymmetricKey(size: .bits256)
        try keychain.storeEncryptionKey(newKey)
        return newKey
    }
    
    // MARK: - Encryption Operations
    func encrypt(_ data: Data) throws -> EncryptedData {
        guard let key = encryptionKey else {
            throw EncryptionError.noEncryptionKey
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return EncryptedData(
            data: encryptedData,
            timestamp: Date(),
            version: "1.0"
        )
    }
    
    func encrypt(_ string: String) throws -> EncryptedData {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.stringConversionFailed
        }
        return try encrypt(data)
    }
    
    func decrypt(_ encryptedData: EncryptedData) throws -> Data {
        guard let key = encryptionKey else {
            throw EncryptionError.noEncryptionKey
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData.data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
    
    func decryptToString(_ encryptedData: EncryptedData) throws -> String {
        let data = try decrypt(encryptedData)
        guard let string = String(data: data, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        return string
    }
    
    // MARK: - Utility Methods
    func isDataEncrypted(_ data: Data) -> Bool {
        // Check if data has the expected AES-GCM structure
        return data.count >= 12 // Minimum size for AES-GCM (nonce + tag)
    }
    
    func rekey() throws {
        // Generate new encryption key and re-encrypt all data
        let newKey = SymmetricKey(size: .bits256)
        try keychain.storeEncryptionKey(newKey)
        encryptionKey = newKey
        print("✅ Encryption key successfully rekeyed")
    }
    
    func clearEncryptionKey() throws {
        try keychain.deleteEncryptionKey()
        encryptionKey = nil
        isEncryptionAvailable = false
        print("🗑️ Encryption key cleared")
    }
}

// MARK: - EncryptedData Model
struct EncryptedData: Codable {
    let data: Data
    let timestamp: Date
    let version: String
    
    var isValid: Bool {
        return !data.isEmpty && version == "1.0"
    }
}

// MARK: - Encryption Errors
enum EncryptionError: LocalizedError {
    case noEncryptionKey
    case encryptionFailed
    case decryptionFailed
    case stringConversionFailed
    case keychainError(String)
    
    var errorDescription: String? {
        switch self {
        case .noEncryptionKey:
            return "No encryption key available"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .stringConversionFailed:
            return "Failed to convert string to data"
        case .keychainError(let message):
            return "Keychain error: \(message)"
        }
    }
}

// MARK: - Keychain Service
@MainActor
final class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.lucas.Atlas.Encryption"
    private let keyTag = "AtlasEncryptionKey"
    
    private init() {}
    
    func storeEncryptionKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError("Failed to store encryption key: \(status)")
        }
    }
    
    func getEncryptionKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw EncryptionError.keychainError("Failed to retrieve encryption key: \(status)")
        }
        
        guard let keyData = result as? Data else {
            throw EncryptionError.keychainError("Invalid key data format")
        }
        
        return SymmetricKey(data: keyData)
    }
    
    func deleteEncryptionKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: keyTag
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw EncryptionError.keychainError("Failed to delete encryption key: \(status)")
        }
    }
}
