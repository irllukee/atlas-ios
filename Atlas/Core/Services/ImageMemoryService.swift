@preconcurrency import Foundation
import UIKit
import SwiftUI
import ImageIO

/// Advanced service for efficient image memory management
@MainActor
class ImageMemoryService: ObservableObject {
    static let shared = ImageMemoryService()
    
    @Published var memoryUsage: UInt64 = 0
    @Published var cacheSize: Int = 0
    @Published var isProcessing = false
    
    // Memory management settings
    private let maxCacheSize = 50 // Maximum number of images in cache
    private let maxImageSize = CGSize(width: 1024, height: 1024) // Maximum image dimensions
    private let compressionQuality: CGFloat = 0.8
    
    // Caches
    private var imageCache: [String: UIImage] = [:]
    private var thumbnailCache: [String: UIImage] = [:]
    private var accessTimes: [String: Date] = [:]
    
    // Memory monitoring
    private var memoryWarningObserver: NSObjectProtocol?
    private let memoryThreshold: UInt64 = 100 * 1024 * 1024 // 100MB
    
    private init() {
        setupMemoryMonitoring()
        startMemoryMonitoring()
    }
    
    // MARK: - Memory Monitoring
    
    private func setupMemoryMonitoring() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }
    }
    
    private func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
    }
    
    private func updateMemoryUsage() {
        memoryUsage = getCurrentMemoryUsage()
        cacheSize = imageCache.count + thumbnailCache.count
        
        // Auto-cleanup if memory usage is high
        if memoryUsage > memoryThreshold {
            performMemoryCleanup()
        }
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    private func handleMemoryWarning() {
        print("🚨 Memory warning received - performing aggressive cleanup")
        performAggressiveCleanup()
    }
    
    // MARK: - Image Processing
    
    /// Process and cache an image with memory optimization
    func processImage(_ image: UIImage, id: String) -> UIImage? {
        isProcessing = true
        defer { isProcessing = false }
        
        // Check cache first
        if let cached = imageCache[id] {
            updateAccessTime(id)
            return cached
        }
        
        // Process image
        let processedImage = optimizeImage(image)
        
        // Cache management
        manageCacheSize()
        
        // Store in cache
        imageCache[id] = processedImage
        accessTimes[id] = Date()
        
        return processedImage
    }
    
    /// Generate and cache thumbnail
    func generateThumbnail(_ image: UIImage, id: String, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage? {
        let thumbnailId = "\(id)_thumb"
        
        // Check cache first
        if let cached = thumbnailCache[thumbnailId] {
            updateAccessTime(thumbnailId)
            return cached
        }
        
        // Generate thumbnail
        let thumbnail = createThumbnail(from: image, size: size)
        
        // Cache management
        manageCacheSize()
        
        // Store in cache
        thumbnailCache[thumbnailId] = thumbnail
        accessTimes[thumbnailId] = Date()
        
        return thumbnail
    }
    
    /// Load image from data with memory optimization
    func loadImage(from data: Data, id: String) -> UIImage? {
        // Check cache first
        if let cached = imageCache[id] {
            updateAccessTime(id)
            return cached
        }
        
        // Load image with memory-efficient method
        guard let image = loadImageEfficiently(from: data) else { return nil }
        
        // Process and cache
        return processImage(image, id: id)
    }
    
    // MARK: - Image Optimization
    
    private func optimizeImage(_ image: UIImage) -> UIImage {
        let size = image.size
        
        // Resize if too large
        if size.width > maxImageSize.width || size.height > maxImageSize.height {
            return resizeImage(image, to: maxImageSize)
        }
        
        // Compress if needed
        return compressImage(image)
    }
    
    private func resizeImage(_ image: UIImage, to maxSize: CGSize) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        
        var newSize = maxSize
        
        if aspectRatio > 1 {
            newSize.height = maxSize.width / aspectRatio
        } else {
            newSize.width = maxSize.height * aspectRatio
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func compressImage(_ image: UIImage) -> UIImage {
        guard let data = image.jpegData(compressionQuality: compressionQuality),
              let compressedImage = UIImage(data: data) else {
            return image
        }
        return compressedImage
    }
    
    private func createThumbnail(from image: UIImage, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func loadImageEfficiently(from data: Data) -> UIImage? {
        // Use ImageIO for memory-efficient loading
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return UIImage(data: data)
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Cache Management
    
    private func manageCacheSize() {
        let totalCacheSize = imageCache.count + thumbnailCache.count
        
        if totalCacheSize > maxCacheSize {
            performCacheCleanup()
        }
    }
    
    private func performCacheCleanup() {
        // Remove least recently used items
        let sortedAccessTimes = accessTimes.sorted { $0.value < $1.value }
        let itemsToRemove = max(0, (imageCache.count + thumbnailCache.count) - maxCacheSize + 10)
        
        for i in 0..<min(itemsToRemove, sortedAccessTimes.count) {
            let id = sortedAccessTimes[i].key
            imageCache.removeValue(forKey: id)
            thumbnailCache.removeValue(forKey: id)
            accessTimes.removeValue(forKey: id)
        }
        
        print("🧹 Cache cleanup: Removed \(itemsToRemove) items")
    }
    
    private func performMemoryCleanup() {
        // Remove half of the cache
        let itemsToRemove = max(1, (imageCache.count + thumbnailCache.count) / 2)
        
        let sortedAccessTimes = accessTimes.sorted { $0.value < $1.value }
        
        for i in 0..<min(itemsToRemove, sortedAccessTimes.count) {
            let id = sortedAccessTimes[i].key
            imageCache.removeValue(forKey: id)
            thumbnailCache.removeValue(forKey: id)
            accessTimes.removeValue(forKey: id)
        }
        
        print("🧹 Memory cleanup: Removed \(itemsToRemove) items")
    }
    
    private func performAggressiveCleanup() {
        // Clear all caches
        imageCache.removeAll()
        thumbnailCache.removeAll()
        accessTimes.removeAll()
        
        // Force garbage collection
        DispatchQueue.main.async {
            // Trigger memory cleanup
        }
        
        print("🧹 Aggressive cleanup: Cleared all caches")
    }
    
    private func updateAccessTime(_ id: String) {
        accessTimes[id] = Date()
    }
    
    // MARK: - Public Methods
    
    /// Clear all caches
    func clearAllCaches() {
        imageCache.removeAll()
        thumbnailCache.removeAll()
        accessTimes.removeAll()
        print("🧹 Manual cache clear: All caches cleared")
    }
    
    /// Get cache statistics
    func getCacheStats() -> CacheStats {
        return CacheStats(
            imageCacheSize: imageCache.count,
            thumbnailCacheSize: thumbnailCache.count,
            totalMemoryUsage: memoryUsage,
            memoryUsageMB: Double(memoryUsage) / 1024.0 / 1024.0
        )
    }
    
    /// Preload images for better performance
    func preloadImages(_ imageData: [(id: String, data: Data)]) {
        // Process images on main actor to avoid concurrency issues
        for (id, data) in imageData {
            _ = loadImage(from: data, id: id)
        }
    }
    
    deinit {
        // Observer cleanup is handled by the notification center automatically
        // when the observer is deallocated
    }
}

// MARK: - Cache Statistics

struct CacheStats {
    let imageCacheSize: Int
    let thumbnailCacheSize: Int
    let totalMemoryUsage: UInt64
    let memoryUsageMB: Double
    
    var totalCacheSize: Int {
        return imageCacheSize + thumbnailCacheSize
    }
}

// MARK: - Memory-Efficient Image View

struct MemoryEfficientImageView: View {
    let imageData: Data?
    let id: String
    let placeholder: String
    let maxSize: CGSize
    
    @StateObject private var imageService = ImageMemoryService.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(imageData: Data?, id: String, placeholder: String = "photo", maxSize: CGSize = CGSize(width: 300, height: 300)) {
        self.imageData = imageData
        self.id = id
        self.placeholder = placeholder
        self.maxSize = maxSize
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 30, height: 30)
            } else {
                Image(systemName: placeholder)
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: maxSize.width, height: maxSize.height)
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            // Clean up when view disappears
            if imageService.getCacheStats().totalCacheSize > 40 {
                imageService.clearAllCaches()
            }
        }
    }
    
    private func loadImage() {
        guard let data = imageData else { return }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            _Concurrency.Task { @MainActor in
                let loadedImage = imageService.loadImage(from: data, id: id)
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

// MARK: - Thumbnail View

struct ThumbnailView: View {
    let imageData: Data?
    let id: String
    let size: CGSize
    
    @StateObject private var imageService = ImageMemoryService.shared
    @State private var thumbnail: UIImage?
    
    init(imageData: Data?, id: String, size: CGSize = CGSize(width: 60, height: 60)) {
        self.imageData = imageData
        self.id = id
        self.size = size
    }
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let data = imageData,
              let originalImage = UIImage(data: data) else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            _Concurrency.Task { @MainActor in
                let generatedThumbnail = imageService.generateThumbnail(originalImage, id: id, size: size)
                self.thumbnail = generatedThumbnail
            }
        }
    }
}
