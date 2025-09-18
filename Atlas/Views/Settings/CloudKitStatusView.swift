import SwiftUI
import CloudKit

/// View showing CloudKit sync status and options
struct CloudKitStatusView: View {
    @StateObject private var cloudKitService = CloudKitService.shared
    @State private var showingCloudKitAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            // CloudKit Status Header
            HStack {
                Image(systemName: cloudKitService.syncStatus.icon)
                    .font(.title2)
                    .foregroundColor(cloudKitService.syncStatus.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Sync")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(.white)
                    
                    Text(cloudKitService.syncStatus.displayText)
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(cloudKitService.syncStatus.color)
                }
                
                Spacer()
                
                Button("Refresh") {
                    cloudKitService.refreshSyncStatus()
                }
                .font(AtlasTheme.Typography.caption)
                .foregroundColor(AtlasTheme.Colors.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .fill(AtlasTheme.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                    )
            )
            
            // CloudKit Information
            VStack(alignment: .leading, spacing: 12) {
                Text("About iCloud Sync")
                    .font(AtlasTheme.Typography.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Automatic Sync",
                        description: "Your notes, tasks, and journal entries sync automatically across all your Apple devices"
                    )
                    
                    InfoRow(
                        icon: "lock.shield",
                        title: "Privacy & Security",
                        description: "Your data is encrypted and stored securely in your personal iCloud account"
                    )
                    
                    InfoRow(
                        icon: "icloud.and.arrow.down",
                        title: "Backup & Recovery",
                        description: "Your data is automatically backed up and can be restored if you lose your device"
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                    .fill(AtlasTheme.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                            .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 1)
                    )
            )
            
            // Troubleshooting
            if !cloudKitService.isCloudKitAvailable {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Troubleshooting")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Sign in to iCloud in Settings")
                        Text("• Ensure iCloud Drive is enabled")
                        Text("• Check your internet connection")
                        Text("• Restart the app if sync issues persist")
                    }
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasTheme.CornerRadius.medium)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            Spacer()
        }
        .padding()
        .background(AtlasTheme.Colors.background)
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cloudKitService.refreshSyncStatus()
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AtlasTheme.Colors.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AtlasTheme.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(AtlasTheme.Typography.caption)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationView {
        CloudKitStatusView()
    }
}





