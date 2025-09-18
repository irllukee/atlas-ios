import Foundation
import SwiftUI
import PhotosUI

/// Service for managing user profile pictures
@MainActor
final class ProfilePictureService: ObservableObject {
    static let shared = ProfilePictureService()
    
    @Published var profileImage: UIImage?
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let profileImageKey = "user_profile_image"
    
    private init() {
        loadStoredProfileImage()
    }
    
    // MARK: - Public Methods
    
    /// Load profile image from photo picker
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await setProfileImage(image)
            }
        } catch {
            print("Failed to load image: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Set profile image directly
    func setProfileImage(_ image: UIImage) async {
        profileImage = image
        saveProfileImage(image)
    }
    
    /// Remove current profile image
    func removeProfileImage() {
        profileImage = nil
        userDefaults.removeObject(forKey: profileImageKey)
    }
    
    // MARK: - Private Methods
    
    private func loadStoredProfileImage() {
        guard let data = userDefaults.data(forKey: profileImageKey),
              let image = UIImage(data: data) else {
            return
        }
        profileImage = image
    }
    
    private func saveProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        userDefaults.set(data, forKey: profileImageKey)
    }
}

