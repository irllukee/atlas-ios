import Foundation
import SwiftUI
import CoreData

/// Service for managing app performance optimizations
@MainActor
class PerformanceService: ObservableObject {
    static let shared = PerformanceService()
    
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0.0
    
    // Performance settings
    private let maxVisibleNotes = 50
    private let imageCacheSize = 50 // Reduced from 100 for better memory management
    private let textCacheSize = 200
    private let maxImageCacheSize = 50 * 1024 * 1024 // 50MB limit
    
    // Caches
    private var imageCache: [String: UIImage] = [:]
    private var textCache: [String: NSAttributedString] = [:]
    private var notePreviewCache: [String: String] = [:]
    private var currentImageCacheSize: Int = 0
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.clearCaches()
            }
        }
    }
    
    func clearCaches() {
        imageCache.removeAll()
        textCache.removeAll()
        notePreviewCache.removeAll()
        currentImageCacheSize = 0
        print("🧹 Performance: Caches cleared due to memory pressure")
    }
    
    // MARK: - Note List Optimization
    
    /// Optimizes note list for smooth scrolling by limiting visible items
    func optimizeNotesList(_ notes: [Note], currentIndex: Int = 0) -> [Note] {
        guard notes.count > maxVisibleNotes else { return notes }
        
        let startIndex = max(0, currentIndex - maxVisibleNotes / 2)
        let endIndex = min(notes.count, startIndex + maxVisibleNotes)
        
        return Array(notes[startIndex..<endIndex])
    }
    
    /// Generates optimized note preview text
    func getOptimizedNotePreview(for note: Note) -> String {
        let noteId = note.uuid?.uuidString ?? ""
        
        if let cached = notePreviewCache[noteId] {
            return cached
        }
        
        let preview = generateNotePreview(note)
        
        // Cache management
        if notePreviewCache.count >= textCacheSize {
            let keysToRemove = Array(notePreviewCache.keys.prefix(textCacheSize / 4))
            keysToRemove.forEach { notePreviewCache.removeValue(forKey: $0) }
        }
        
        notePreviewCache[noteId] = preview
        return preview
    }
    
    private func generateNotePreview(_ note: Note) -> String {
        guard let content = note.content, !content.isEmpty else {
            return "No content"
        }
        
        // Remove markdown and formatting for preview
        let cleanContent = content
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "`", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return String(cleanContent.prefix(150))
    }
    
    // MARK: - Image Optimization
    
    /// Optimizes image for display with caching
    func getOptimizedImage(from data: Data?, id: String) -> UIImage? {
        guard let data = data else { return nil }
        
        if let cached = imageCache[id] {
            return cached
        }
        
        guard let image = UIImage(data: data) else { return nil }
        
        // Resize image if too large
        let optimizedImage = resizeImageIfNeeded(image, maxSize: CGSize(width: 300, height: 300))
        
        // Calculate image size for cache management
        let imageSize = estimateImageSize(optimizedImage)
        
        // Cache management with size limits
        if currentImageCacheSize + imageSize > maxImageCacheSize || imageCache.count >= imageCacheSize {
            clearOldestImages()
        }
        
        imageCache[id] = optimizedImage
        currentImageCacheSize += imageSize
        return optimizedImage
    }
    
    private func estimateImageSize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4 // Rough estimate: width * height * 4 bytes per pixel
    }
    
    private func clearOldestImages() {
        let keysToRemove = Array(imageCache.keys.prefix(imageCacheSize / 4))
        keysToRemove.forEach { key in
            if let image = imageCache.removeValue(forKey: key) {
                currentImageCacheSize -= estimateImageSize(image)
            }
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage, maxSize: CGSize) -> UIImage {
        let size = image.size
        
        if size.width <= maxSize.width && size.height <= maxSize.height {
            return image
        }
        
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
    
    // MARK: - Text Optimization
    
    /// Optimizes attributed text with caching
    func getOptimizedAttributedText(from content: String, id: String) -> NSAttributedString {
        if let cached = textCache[id] {
            return cached
        }
        
        let attributedString = NSAttributedString(string: content)
        
        // Cache management
        if textCache.count >= textCacheSize {
            let keysToRemove = Array(textCache.keys.prefix(textCacheSize / 4))
            keysToRemove.forEach { textCache.removeValue(forKey: $0) }
        }
        
        textCache[id] = attributedString
        return attributedString
    }
    
    // MARK: - Performance Monitoring
    
    /// Monitors and reports performance metrics
    func getPerformanceMetrics() -> PerformanceMetrics {
        return PerformanceMetrics(
            imageCacheSize: imageCache.count,
            textCacheSize: textCache.count,
            notePreviewCacheSize: notePreviewCache.count,
            memoryUsage: getMemoryUsage(),
            imageCacheMemoryUsage: currentImageCacheSize
        )
    }
    
    private func getMemoryUsage() -> UInt64 {
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
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
    let imageCacheSize: Int
    let textCacheSize: Int
    let notePreviewCacheSize: Int
    let memoryUsage: UInt64
    let imageCacheMemoryUsage: Int
    
    var memoryUsageMB: Double {
        return Double(memoryUsage) / 1024.0 / 1024.0
    }
    
    var imageCacheMemoryUsageMB: Double {
        return Double(imageCacheMemoryUsage) / 1024.0 / 1024.0
    }
    
    var totalCacheSize: Int {
        return imageCacheSize + textCacheSize + notePreviewCacheSize
    }
}

// MARK: - Performance View Modifier

struct PerformanceOptimizedModifier: ViewModifier {
    @StateObject private var performanceService = PerformanceService.shared
    let noteId: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Preload optimizations when view appears
                // Note: Performance optimization disabled to avoid Core Data issues
                // _ = performanceService.getOptimizedNotePreview(for: Note())
            }
            .onDisappear {
                // Clean up when view disappears
                if performanceService.getPerformanceMetrics().totalCacheSize > 150 {
                    performanceService.clearCaches()
                }
            }
    }
}

extension View {
    func performanceOptimized(for noteId: String) -> some View {
        self.modifier(PerformanceOptimizedModifier(noteId: noteId))
    }
}
