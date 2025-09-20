import Foundation
import UIKit
import SwiftUI

class PhotoService: ObservableObject {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        documentsDirectory = paths[0]
        
        // Create photos directory if it doesn't exist
        let photosDirectory = documentsDirectory.appendingPathComponent("RecipePhotos")
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Photo Management
    
    func saveImage(_ image: UIImage, for recipe: Recipe, isCoverImage: Bool = false) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let filename = "\(recipe.uuid?.uuidString ?? UUID().uuidString)_\(Date().timeIntervalSince1970).jpg"
        let fileURL = documentsDirectory.appendingPathComponent("RecipePhotos").appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(filename: String) -> UIImage? {
        let fileURL = documentsDirectory.appendingPathComponent("RecipePhotos").appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func deleteImage(filename: String) {
        let fileURL = documentsDirectory.appendingPathComponent("RecipePhotos").appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Recipe Image Management
    
    func addImageToRecipe(_ image: UIImage, recipe: Recipe, isCoverImage: Bool = false, order: Int16 = 0) -> RecipeImage? {
        guard let filename = saveImage(image, for: recipe, isCoverImage: isCoverImage) else { return nil }
        
        // If this is a cover image, remove cover status from other images
        if isCoverImage {
            if let existingImages = recipe.images {
                for existingImage in existingImages {
                    if let recipeImage = existingImage as? RecipeImage {
                        recipeImage.isCoverImage = false
                    }
                }
            }
        }
        
        let recipeImage = RecipeImage(context: recipe.managedObjectContext!)
        recipeImage.uuid = UUID()
        recipeImage.imageData = image.jpegData(compressionQuality: 0.8)
        recipeImage.isCoverImage = isCoverImage
        recipeImage.order = order
        recipeImage.recipe = recipe
        recipeImage.createdAt = Date()
        recipeImage.updatedAt = Date()
        
        try? recipe.managedObjectContext?.save()
        return recipeImage
    }
    
    func addImageToStep(_ image: UIImage, step: RecipeStep, order: Int16 = 0) -> RecipeImage? {
        guard let recipe = step.recipe else { return nil }
        guard let filename = saveImage(image, for: recipe) else { return nil }
        
        let recipeImage = RecipeImage(context: step.managedObjectContext!)
        recipeImage.uuid = UUID()
        recipeImage.imageData = image.jpegData(compressionQuality: 0.8)
        recipeImage.isCoverImage = false
        recipeImage.order = order
        recipeImage.step = step
        recipeImage.recipe = recipe
        recipeImage.createdAt = Date()
        recipeImage.updatedAt = Date()
        
        try? step.managedObjectContext?.save()
        return recipeImage
    }
    
    func deleteRecipeImage(_ recipeImage: RecipeImage) {
        // Delete the image file if it exists
        if let imageData = recipeImage.imageData,
           let filename = filenameForImageData(imageData) {
            deleteImage(filename: filename)
        }
        
        recipeImage.managedObjectContext?.delete(recipeImage)
        try? recipeImage.managedObjectContext?.save()
    }
    
    func setCoverImage(_ recipeImage: RecipeImage, for recipe: Recipe) {
        // Remove cover status from all other images
        if let existingImages = recipe.images {
            for existingImage in existingImages {
                if let existingRecipeImage = existingImage as? RecipeImage {
                    existingRecipeImage.isCoverImage = false
                }
            }
        }
        
        // Set this image as cover
        recipeImage.isCoverImage = true
        recipeImage.updatedAt = Date()
        
        try? recipe.managedObjectContext?.save()
    }
    
    // MARK: - Helper Methods
    
    private func filenameForImageData(_ imageData: Data) -> String? {
        // This is a simplified approach - in a real app you might want to store filenames
        // in the Core Data model or use a different approach
        return nil
    }
    
    func getCoverImage(for recipe: Recipe) -> UIImage? {
        if let images = recipe.images {
            for image in images {
                if let recipeImage = image as? RecipeImage,
                   recipeImage.isCoverImage,
                   let imageData = recipeImage.imageData {
                    return UIImage(data: imageData)
                }
            }
        }
        return nil
    }
    
    func getAllImages(for recipe: Recipe) -> [RecipeImage] {
        guard let images = recipe.images else { return [] }
        return Array(images).compactMap { $0 as? RecipeImage }
            .sorted { $0.order < $1.order }
    }
    
    func getStepImages(for step: RecipeStep) -> [RecipeImage] {
        guard let images = step.images else { return [] }
        return Array(images).compactMap { $0 as? RecipeImage }
            .sorted { $0.order < $1.order }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Photo Capture View
struct PhotoCaptureView: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
    var body: some View {
        VStack(spacing: AtlasTheme.Spacing.md) {
            Text("Add Photo")
                .font(AtlasTheme.Typography.headline)
                .foregroundColor(AtlasTheme.Colors.text)
            
            Text("Choose how you'd like to add a photo")
                .font(AtlasTheme.Typography.body)
                .foregroundColor(AtlasTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            HStack(spacing: AtlasTheme.Spacing.lg) {
                // Camera Button
                Button(action: {
                    showingCamera = true
                }) {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text("Camera")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                    .background(AtlasTheme.Colors.primary)
                    .cornerRadius(AtlasTheme.CornerRadius.medium)
                }
                
                // Photo Library Button
                Button(action: {
                    showingImagePicker = true
                }) {
                    VStack(spacing: AtlasTheme.Spacing.sm) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                        
                        Text("Library")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                    .background(AtlasTheme.Colors.secondary)
                    .cornerRadius(AtlasTheme.CornerRadius.medium)
                }
            }
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AtlasTheme.Colors.secondaryText)
                
                Spacer()
            }
        }
        .padding(AtlasTheme.Spacing.lg)
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
    }
}


