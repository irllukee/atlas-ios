import SwiftUI

// Type alias to avoid naming conflict with Core Data Task entity
typealias AsyncTask = _Concurrency.Task

/// User profile view showing authenticated user information
struct UserProfileView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingSignOutAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile Header
            VStack(spacing: 16) {
                // Profile Image
                AsyncImage(url: URL(string: authService.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(AtlasTheme.Colors.primary.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(AtlasTheme.Colors.primary)
                        )
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(AtlasTheme.Colors.primary, lineWidth: 3)
                )
                
                // User Info
                VStack(spacing: 8) {
                    Text(authService.currentUser?.name ?? "User")
                        .font(AtlasTheme.Typography.title2)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    Text(authService.currentUser?.email ?? "")
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    
                    // Provider Badge
                    HStack(spacing: 6) {
                        Image(systemName: providerIcon)
                            .font(.system(size: 12))
                            .foregroundColor(providerColor)
                        
                        Text(providerName)
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(providerColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(providerColor.opacity(0.1))
                    )
                }
            }
            
            // Account Actions
            VStack(spacing: 12) {
                // Sign Out Button
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Sign Out")
                            .font(AtlasTheme.Typography.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
                
                // Privacy Settings
                Button(action: {
                    // Handle privacy settings
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Privacy Settings")
                            .font(AtlasTheme.Typography.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .stroke(AtlasTheme.Colors.primary, lineWidth: 1)
                    )
                }
            }
            
            Spacer()
        }
        .padding(24)
        .background(AtlasTheme.Colors.background)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                AsyncTask {
                    await authService.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Computed Properties
    private var providerIcon: String {
        switch authService.currentUser?.provider {
        case .apple:
            return "applelogo"
        case .none:
            return "person"
        }
    }
    
    private var providerName: String {
        switch authService.currentUser?.provider {
        case .apple:
            return "Apple"
        case .none:
            return "Guest"
        }
    }
    
    private var providerColor: Color {
        switch authService.currentUser?.provider {
        case .apple:
            return .black
        case .none:
            return AtlasTheme.Colors.secondaryText
        }
    }
}

// MARK: - Preview
#Preview {
    UserProfileView()
        .environmentObject(AuthenticationService.shared)
}
