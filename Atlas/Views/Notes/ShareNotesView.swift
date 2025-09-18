import SwiftUI

/// View for sharing notes to various platforms and apps
struct ShareNotesView: View {
    
    // MARK: - Properties
    let notes: [Note]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sharingService = SharingService.shared
    
    @State private var selectedDestination: SharingService.SharingDestination?
    @State private var isSharing = false
    @State private var shareSuccess = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Share info
                            shareInfoView
                            
                            // Sharing options
                            sharingOptionsView
                            
                            // Quick actions
                            quickActionsView
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Share Successful", isPresented: $shareSuccess) {
            Button("OK") {
                shareSuccess = false
            }
        } message: {
            Text("Your notes have been shared successfully!")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back Button
            Button(action: {
                AtlasTheme.Haptics.light()
                dismiss()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Title
            Text("Share Notes")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Activity button (show native share sheet)
            Button(action: {
                AtlasTheme.Haptics.light()
                sharingService.shareNotes(notes)
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Share Info View
    private var shareInfoView: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "square.and.arrow.up.on.square.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(AtlasTheme.Colors.accent)
            
            // Title and description
            VStack(spacing: 8) {
                Text("Share \(notes.count) \(notes.count == 1 ? "Note" : "Notes")")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Choose how you'd like to share your notes")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Sharing Options View
    private var sharingOptionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Share to Apps")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(SharingService.SharingDestination.allCases.filter { $0.isAvailable }, id: \.rawValue) { destination in
                    sharingOptionCard(destination)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }
    
    private func sharingOptionCard(_ destination: SharingService.SharingDestination) -> some View {
        Button(action: {
            selectedDestination = destination
            performShare(to: destination)
        }) {
            VStack(spacing: 12) {
                // App icon
                Image(systemName: destination.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(destination.color)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(destination.color.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(destination.color.opacity(0.3), lineWidth: 1)
                            )
                    )
                
                // App name
                Text(destination.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(selectedDestination == destination && isSharing ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedDestination)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isSharing)
    }
    
    // MARK: - Quick Actions View
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Copy to clipboard
                quickActionButton(
                    title: "Copy to Clipboard",
                    subtitle: "Copy all notes as formatted text",
                    icon: "doc.on.clipboard.fill",
                    color: .gray
                ) {
                    performShare(to: .copy)
                }
                
                // Export and share
                quickActionButton(
                    title: "Export & Share",
                    subtitle: "Export to PDF and share",
                    icon: "square.and.arrow.up.on.square",
                    color: AtlasTheme.Colors.accent
                ) {
                    // TODO: Integrate with export service
                    performShare(to: .activityView)
                }
                
                // Email as attachment
                if SharingService.SharingDestination.mail.isAvailable {
                    quickActionButton(
                        title: "Email as Attachment",
                        subtitle: "Send notes via email",
                        icon: "envelope.fill",
                        color: .blue
                    ) {
                        performShare(to: .mail)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        )
    }
    
    private func quickActionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            AtlasTheme.Haptics.light()
            action()
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(color.opacity(0.1))
                    )
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func performShare(to destination: SharingService.SharingDestination) {
        isSharing = true
        
        // Add slight delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sharingService.shareNotes(notes, destination: destination)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSharing = false
                selectedDestination = nil
                
                // Show success for clipboard copy
                if destination == .copy {
                    shareSuccess = true
                }
            }
        }
    }
}

// MARK: - Preview

struct ShareNotesView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        let context = dataManager.coreDataStack.viewContext
        
        // Create sample notes
        let note1 = Note(context: context)
        note1.title = "Sample Note 1"
        note1.content = "This is a sample note for testing sharing functionality."
        
        let note2 = Note(context: context)
        note2.title = "Sample Note 2"
        note2.content = "Another sample note with different content."
        
        return ShareNotesView(notes: [note1, note2])
    }
}

