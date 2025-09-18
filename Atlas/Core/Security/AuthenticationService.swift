import Foundation
import SwiftUI
import AuthenticationServices

/// Authentication service for Apple Sign-In
@MainActor
final class AuthenticationService: NSObject, ObservableObject {
    static let shared = AuthenticationService()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false  // Start as not authenticated
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var lastError: Error?
    
    // MARK: - User Model
    struct User: Identifiable, Codable {
        let id: String
        let email: String
        let name: String
        let profileImageURL: String?
        let provider: AuthProvider
        
        enum AuthProvider: String, Codable {
            case apple = "apple"
        }
    }
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let userKey = "authenticated_user"
    
    // MARK: - Initialization
    private override init() {
        super.init()
        // Check if user is already logged in from previous session
        loadStoredUser()
    }
    
    
    // MARK: - Apple Sign-In (Simulated for Testing)
    func signInWithApple() async throws {
        isLoading = true
        lastError = nil
        
        // Simulate Apple Sign-In for testing without Apple Developer account
        print("🍎 Simulating Apple Sign-In for testing...")
        
        // Simulate network delay
        try await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Create a simulated user
        let simulatedUser = User(
            id: "simulated-apple-user-\(UUID().uuidString)",
            email: "user@icloud.com",
            name: "Test User",
            profileImageURL: nil,
            provider: .apple
        )
        
        await handleSuccessfulSignIn(user: simulatedUser)
        print("✅ Simulated Apple Sign-In successful!")
    }
    
    // MARK: - Sign Out
    func signOut() async {
        isLoading = true
        
        // Clear stored user data
        userDefaults.removeObject(forKey: userKey)
        
        // Reset state
        currentUser = nil
        isAuthenticated = false
        isLoading = false
    }
    
    // MARK: - Private Methods
    private func handleSuccessfulSignIn(user: User) async {
        currentUser = user
        isAuthenticated = true
        isLoading = false
        
        // Store user data
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
        }
    }
    
    private func loadStoredUser() {
        guard let userData = userDefaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return
        }
        
        currentUser = user
        isAuthenticated = true
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    // MARK: - Apple Sign-In Continuation
    private var appleSignInContinuation: CheckedContinuation<ASAuthorization, Error>?
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        appleSignInContinuation?.resume(returning: authorization)
        appleSignInContinuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for Apple Sign-In")
        }
        return window
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case noViewController
    case appleSignInFailed
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "No view controller available for authentication"
        case .appleSignInFailed:
            return "Apple Sign-In failed"
        case .userCancelled:
            return "Sign-in was cancelled"
        }
    }
}
