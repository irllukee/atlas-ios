import SwiftUI
import AuthenticationServices

/// Main authentication view with Google and Apple Sign-In options
struct AuthenticationView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            // Background
            AtlasTheme.Colors.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AtlasTheme.Colors.primary)
                        .shadow(color: AtlasTheme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Atlas")
                        .font(AtlasTheme.Typography.largeTitle)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    Text("Your Personal Life OS")
                        .font(AtlasTheme.Typography.title3)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                    // Authentication Options
                    VStack(spacing: 16) {
                        // Apple Sign-In Button (Simulated)
                    Button(action: {
                        _Concurrency.Task {
                            do {
                                try await authService.signInWithApple()
                            } catch {
                                showingError = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18, weight: .medium))
                            Text("Sign in with Apple (Demo)")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .cornerRadius(AtlasTheme.CornerRadius.medium)
                    }
                    .disabled(authService.isLoading)
                    
                    // Demo notice
                    Text("Demo Mode: Simulated Apple Sign-In")
                        .font(.system(size: 12))
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Privacy Notice
                VStack(spacing: 8) {
                    Text("By signing in, you agree to our")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Handle terms of service
                        }
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.primary)
                        
                        Text("and")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                        
                        Button("Privacy Policy") {
                            // Handle privacy policy
                        }
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.primary)
                    }
                }
                .padding(.bottom, 32)
            }
            
            // Loading Overlay
            if authService.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(AtlasTheme.Colors.primary)
                        
                        Text("Signing in...")
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(AtlasTheme.Colors.text)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.large)
                            .fill(AtlasTheme.Colors.glassBackground)
                            .shadow(color: AtlasTheme.Colors.glassShadow, radius: 20, x: 0, y: 10)
                    )
                }
            }
        }
        .alert("Sign-In Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(authService.lastError?.localizedDescription ?? "An unknown error occurred")
        }
    }
}


// MARK: - Preview
#Preview {
    AuthenticationView()
}
