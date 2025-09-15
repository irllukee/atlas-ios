import Foundation
import SwiftUI

/// Central security manager coordinating encryption and biometric authentication
@MainActor
final class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    // MARK: - Services
    private let encryptionService = EncryptionService.shared
    private let biometricService = BiometricService.shared
    
    // MARK: - Published Properties
    @Published var isSecurityEnabled = false
    @Published var isAuthenticated = false
    @Published var securityLevel: SecurityLevel = .none
    @Published var lastError: Error?
    
    // MARK: - Security Settings
    @Published var requireBiometricForAppOpen = false
    @Published var requireBiometricForSensitiveData = true
    @Published var autoLockTimeout: TimeInterval = 300 // 5 minutes
    @Published var encryptionEnabled = true
    
    // MARK: - Private Properties
    private var lastAuthenticationTime: Date?
    private var authenticationTimer: Timer?
    
    // MARK: - Initialization
    private init() {
        setupSecurity()
        startAuthenticationTimer()
    }
    
    // MARK: - Setup
    private func setupSecurity() {
        // Check if encryption is available
        if encryptionService.isEncryptionAvailable {
            securityLevel = biometricService.isBiometricAvailable ? .full : .encryptionOnly
            isSecurityEnabled = true
        } else {
            securityLevel = .none
            isSecurityEnabled = false
        }
        
        // Load security preferences
        loadSecurityPreferences()
    }
    
    private func loadSecurityPreferences() {
        let defaults = UserDefaults.standard
        requireBiometricForAppOpen = defaults.bool(forKey: "requireBiometricForAppOpen")
        requireBiometricForSensitiveData = defaults.bool(forKey: "requireBiometricForSensitiveData")
        autoLockTimeout = defaults.double(forKey: "autoLockTimeout") != 0 ? defaults.double(forKey: "autoLockTimeout") : 300
        encryptionEnabled = defaults.object(forKey: "encryptionEnabled") == nil ? true : defaults.bool(forKey: "encryptionEnabled")
    }
    
    private func saveSecurityPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(requireBiometricForAppOpen, forKey: "requireBiometricForAppOpen")
        defaults.set(requireBiometricForSensitiveData, forKey: "requireBiometricForSensitiveData")
        defaults.set(autoLockTimeout, forKey: "autoLockTimeout")
        defaults.set(encryptionEnabled, forKey: "encryptionEnabled")
    }
    
    // MARK: - Authentication Management
    func authenticate(reason: String = "Authenticate to access your data") async throws -> Bool {
        guard isSecurityEnabled else {
            isAuthenticated = true
            return true
        }
        
        // Check if biometric is required
        if requireBiometricForSensitiveData && biometricService.isBiometricAvailable {
            let success = try await biometricService.authenticate(reason: reason)
            if success {
                isAuthenticated = true
                lastAuthenticationTime = Date()
                resetAuthenticationTimer()
            }
            return success
        }
        
        // No biometric required
        isAuthenticated = true
        lastAuthenticationTime = Date()
        resetAuthenticationTimer()
        return true
    }
    
    func authenticateForAppOpen() async throws -> Bool {
        guard requireBiometricForAppOpen && biometricService.isBiometricAvailable else {
            return true
        }
        
        return try await authenticate(reason: "Authenticate to open Atlas")
    }
    
    func logout() {
        isAuthenticated = false
        lastAuthenticationTime = nil
        stopAuthenticationTimer()
    }
    
    // MARK: - Data Encryption
    func encrypt(_ data: Data) throws -> EncryptedData {
        guard encryptionEnabled && isSecurityEnabled else {
            throw SecurityError.encryptionNotAvailable
        }
        
        return try encryptionService.encrypt(data)
    }
    
    func encrypt(_ string: String) throws -> EncryptedData {
        guard encryptionEnabled && isSecurityEnabled else {
            throw SecurityError.encryptionNotAvailable
        }
        
        return try encryptionService.encrypt(string)
    }
    
    func decrypt(_ encryptedData: EncryptedData) throws -> Data {
        guard encryptionEnabled && isSecurityEnabled else {
            throw SecurityError.encryptionNotAvailable
        }
        
        return try encryptionService.decrypt(encryptedData)
    }
    
    func decryptToString(_ encryptedData: EncryptedData) throws -> String {
        guard encryptionEnabled && isSecurityEnabled else {
            throw SecurityError.encryptionNotAvailable
        }
        
        return try encryptionService.decryptToString(encryptedData)
    }
    
    // MARK: - Security Settings Management
    func updateSecuritySettings(
        requireBiometricForAppOpen: Bool? = nil,
        requireBiometricForSensitiveData: Bool? = nil,
        autoLockTimeout: TimeInterval? = nil,
        encryptionEnabled: Bool? = nil
    ) {
        if let value = requireBiometricForAppOpen {
            self.requireBiometricForAppOpen = value
        }
        if let value = requireBiometricForSensitiveData {
            self.requireBiometricForSensitiveData = value
        }
        if let value = autoLockTimeout {
            self.autoLockTimeout = value
        }
        if let value = encryptionEnabled {
            self.encryptionEnabled = value
        }
        
        saveSecurityPreferences()
        updateSecurityLevel()
    }
    
    private func updateSecurityLevel() {
        if encryptionEnabled && encryptionService.isEncryptionAvailable {
            securityLevel = biometricService.isBiometricAvailable ? .full : .encryptionOnly
        } else {
            securityLevel = .none
        }
    }
    
    // MARK: - Auto-Lock Timer
    private func startAuthenticationTimer() {
        stopAuthenticationTimer()
        authenticationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        }
    }
    
    private func stopAuthenticationTimer() {
        authenticationTimer?.invalidate()
        authenticationTimer = nil
    }
    
    private func resetAuthenticationTimer() {
        lastAuthenticationTime = Date()
    }
    
    private func checkAuthenticationTimeout() {
        guard let lastAuth = lastAuthenticationTime else { return }
        
        if Date().timeIntervalSince(lastAuth) > autoLockTimeout {
            logout()
        }
    }
    
    // MARK: - Security Status
    var securityStatusDescription: String {
        switch securityLevel {
        case .none:
            return "No security features enabled"
        case .encryptionOnly:
            return "Data encryption enabled"
        case .full:
            return "Full security with biometric authentication"
        }
    }
    
    var isSecureEnough: Bool {
        return securityLevel != .none
    }
    
    // MARK: - Error Handling
    func handleError(_ error: Error) {
        lastError = error
        print("❌ Security Error: \(error)")
    }
    
    func clearError() {
        lastError = nil
    }
}

// MARK: - Security Level
enum SecurityLevel: Int, CaseIterable {
    case none = 0
    case encryptionOnly = 1
    case full = 2
    
    var name: String {
        switch self {
        case .none:
            return "None"
        case .encryptionOnly:
            return "Encryption Only"
        case .full:
            return "Full Security"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "No security features"
        case .encryptionOnly:
            return "Data encrypted at rest"
        case .full:
            return "Encrypted data + biometric authentication"
        }
    }
}

// MARK: - Security Errors
enum SecurityError: LocalizedError {
    case encryptionNotAvailable
    case authenticationRequired
    case biometricNotAvailable
    case securityNotEnabled
    
    var errorDescription: String? {
        switch self {
        case .encryptionNotAvailable:
            return "Encryption is not available"
        case .authenticationRequired:
            return "Authentication is required to access this data"
        case .biometricNotAvailable:
            return "Biometric authentication is not available"
        case .securityNotEnabled:
            return "Security features are not enabled"
        }
    }
}

