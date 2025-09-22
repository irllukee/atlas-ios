import SwiftUI
import PhotosUI

struct ProfilePictureEditorView: View {
    @StateObject private var profilePictureService = ProfilePictureService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingRemoveAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Current Profile Picture
                VStack(spacing: 16) {
                    Text("Current Profile Picture")
                        .font(AtlasTheme.Typography.headline)
                        .foregroundColor(AtlasTheme.Colors.text)
                    
                    ZStack {
                        Circle()
                            .fill(AtlasTheme.Colors.glassBackground)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(AtlasTheme.Colors.glassBorder, lineWidth: 2)
                            )
                        
                        if let profileImage = profilePictureService.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Choose Photo Button
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Choose Photo")
                        }
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AtlasTheme.Colors.primary)
                        .cornerRadius(AtlasTheme.CornerRadius.medium)
                    }
                    .disabled(profilePictureService.isLoading)
                    
                    // Remove Photo Button
                    if profilePictureService.profileImage != nil {
                        Button(action: {
                            showingRemoveAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Photo")
                            }
                            .font(AtlasTheme.Typography.body)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red)
                            .cornerRadius(AtlasTheme.CornerRadius.medium)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Profile Picture")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedItem) {
            _Concurrency.Task {
                await profilePictureService.loadImage(from: selectedItem)
            }
        }
        .alert("Remove Profile Picture", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                profilePictureService.removeProfileImage()
            }
        } message: {
            Text("Are you sure you want to remove your profile picture?")
        }
    }
}
