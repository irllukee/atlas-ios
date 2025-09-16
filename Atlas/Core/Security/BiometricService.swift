import Foundation
@preconcurrency import LocalAuthentication
import SwiftUI

/// Biometric authentication service for Face ID and Touch ID
@MainActor
final class BiometricService: ObservableObject {
    static let shared = BiometricService()
    
    // MARK: - Published Properties
    @Published var isBiometricAvailable = false
    @Published var biometricType: LABiometryType = .none
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    private let context = LAContext()
    
    // MARK: - Initialization
    private init() {
        checkBiometricAvailability()
    }
    
    // MARK: - Biometric Availability
    private func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            biometricType = context.biometryType
        } else {
            isBiometricAvailable = false
            biometricType = .none
            lastError = error
        }
    }
    
    // MARK: - Authentication
    func authenticate(reason: String = "Authenticate to access your data") async throws -> Bool {
        guard isBiometricAvailable else {
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw mapBiometricError(error)
        }
    }
    
    func authenticateWithFallback(reason: String = "Authenticate to access your data") async throws -> Bool {
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            throw BiometricError.notAvailable
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch {
            throw mapBiometricError(error)
        }
    }
    
    // MARK: - Biometric Type Information
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "None"
        @unknown default:
            return "Unknown"
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock"
        @unknown default:
            return "lock"
        }
    }
    
    // MARK: - Error Mapping
    private func mapBiometricError(_ error: Error) -> BiometricError {
        if let laError = error as? LAError {
            switch laError.code {
            case .userCancel:
                return .userCancelled
            case .userFallback:
                return .userFallback
            case .biometryNotAvailable:
                return .notAvailable
            case .biometryNotEnrolled:
                return .notEnrolled
            case .biometryLockout:
                return .lockedOut
            case .systemCancel:
                return .systemCancelled
            case .passcodeNotSet:
                return .passcodeNotSet
            default:
                return .unknown(laError.localizedDescription)
            }
        }
        return .unknown(error.localizedDescription)
    }
    
    // MARK: - Settings Check
    func checkBiometricSettings() -> BiometricSettingsStatus {
        var error: NSError?
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotEnrolled:
                    return .notEnrolled
                case .biometryNotAvailable:
                    return .notAvailable
                case .passcodeNotSet:
                    return .passcodeNotSet
                default:
                    return .unknown
                }
            }
            return .unknown
        }
        
        return .available
    }
}

// MARK: - Biometric Errors
enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case lockedOut
    case userCancelled
    case userFallback
    case systemCancelled
    case passcodeNotSet
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings"
        case .lockedOut:
            return "Biometric authentication is locked out. Please use your passcode"
        case .userCancelled:
            return "Authentication was cancelled by user"
        case .userFallback:
            return "User chose to use passcode instead"
        case .systemCancelled:
            return "Authentication was cancelled by system"
        case .passcodeNotSet:
            return "No passcode is set on this device"
        case .unknown(let message):
            return "Unknown biometric error: \(message)"
        }
    }
}

// MARK: - Biometric Settings Status
enum BiometricSettingsStatus {
    case available
    case notAvailable
    case notEnrolled
    case passcodeNotSet
    case unknown
    
    var description: String {
        switch self {
        case .available:
            return "Biometric authentication is available and ready"
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "Please set up Face ID or Touch ID in Settings"
        case .passcodeNotSet:
            return "Please set up a passcode in Settings"
        case .unknown:
            return "Unable to determine biometric status"
        }
    }
    
    var isActionable: Bool {
        switch self {
        case .notEnrolled, .passcodeNotSet:
            return true
        default:
            return false
        }
    }
}
