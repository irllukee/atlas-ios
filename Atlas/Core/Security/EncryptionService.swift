import Foundation
import CryptoKit
import Security

// MARK: - Encryption Service Protocol
protocol EncryptionServiceProtocol {
    func encrypt(_ text: String) throws -> EncryptedData
    func encrypt(_ data: Data) throws -> EncryptedData
    func decrypt(_ encryptedData: EncryptedData) throws -> Data
    func decryptToString(_ encryptedData: EncryptedData) throws -> String
    func generateKey() -> SymmetricKey
    func storeKey(_ key: SymmetricKey, identifier: String) throws
    func retrieveKey(identifier: String) throws -> SymmetricKey
}

// MARK: - Encryption Service Implementation
class EncryptionService: EncryptionServiceProtocol {
    private let keyIdentifier = "atlas.journal.encryption.key"
    
    func encrypt(_ text: String) throws -> EncryptedData {
        let data = text.data(using: .utf8)!
        return try encrypt(data)
    }
    
    func encrypt(_ data: Data) throws -> EncryptedData {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        return EncryptedData(
            data: sealedBox.ciphertext,
            nonce: Data(sealedBox.nonce),
            tag: sealedBox.tag
        )
    }
    
    func decrypt(_ encryptedData: EncryptedData) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: encryptedData.nonce),
            ciphertext: encryptedData.data,
            tag: encryptedData.tag
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func decryptToString(_ encryptedData: EncryptedData) throws -> String {
        let decryptedData = try decrypt(encryptedData)
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidDecryptedData
        }
        
        return decryptedString
    }
    
    func generateKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    func storeKey(_ key: SymmetricKey, identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    func retrieveKey(identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw EncryptionError.keyNotFound
        }
        
        return SymmetricKey(data: keyData)
    }
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        do {
            return try retrieveKey(identifier: keyIdentifier)
        } catch EncryptionError.keyNotFound {
            let newKey = generateKey()
            try storeKey(newKey, identifier: keyIdentifier)
            return newKey
        }
    }
}

// MARK: - Encryption Errors
enum EncryptionError: LocalizedError {
    case invalidDecryptedData
    case keychainError(OSStatus)
    case keyNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidDecryptedData:
            return "Failed to convert decrypted data to string"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .keyNotFound:
            return "Encryption key not found in keychain"
        }
    }
}