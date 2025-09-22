import SwiftUI

struct ProfileView: View {
    @State private var showingNotificationSettings = false
    @StateObject private var profilePictureService = ProfilePictureService.shared
    
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // User Profile Section
                VStack(spacing: 16) {
                    ZStack {
                        if let profileImage = profilePictureService.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(AtlasTheme.Colors.primary.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(AtlasTheme.Colors.primary)
                                )
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("Atlas User")
                            .font(AtlasTheme.Typography.title2)
                            .foregroundColor(AtlasTheme.Colors.text)
                        
                        Text("Welcome to your personal space")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                }
                .padding(.top, 40)
                
                // Settings Section
                VStack(spacing: 16) {
                    Button(action: { showingNotificationSettings = true }) {
                        ProfileRow(title: "Notifications", icon: "bell")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ProfileRow(title: "Settings", icon: "gear")
                    ProfileRow(title: "Preferences", icon: "slider.horizontal.3")
                    ProfileRow(title: "About", icon: "info.circle")
                    ProfileRow(title: "Help & Support", icon: "questionmark.circle")
                }
                .padding(.top, 40)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }
}

// MARK: - Profile Row Component
struct ProfileRow: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AtlasTheme.Colors.primary)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.text)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AtlasTheme.Colors.secondaryText)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AtlasTheme.Colors.glassBackground)
        .cornerRadius(AtlasTheme.CornerRadius.medium)
    }
}
