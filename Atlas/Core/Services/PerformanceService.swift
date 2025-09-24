import Foundation
import SwiftUI
import CoreData

/// Service for managing app performance optimizations
@MainActor
class PerformanceService: ObservableObject {
    static let shared = PerformanceService()
    
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0.0
    
    // Performance settings - adaptive based on device memory
    private let maxVisibleNotes = 50
    private let imageCacheSize: Int
    private let textCacheSize: Int
    private let maxImageCacheSize: Int
    
    // Caches with LRU eviction
    private var imageCache: [String: (UIImage, Date)] = [:]
    private var textCache: [String: (NSAttributedString, Date)] = [:]
    private var notePreviewCache: [String: (String, Date)] = [:]
    private var currentImageCacheSize: Int = 0
    
    // Memory pressure monitoring
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private var lastMemoryWarning: Date = Date.distantPast
    
    private init() {
        // Adaptive cache sizing based on device memory
        let deviceMemory = PerformanceService.getDeviceMemory()
        switch deviceMemory {
        case .low: // < 2GB
            self.imageCacheSize = 20
            self.textCacheSize = 100
            self.maxImageCacheSize = 20 * 1024 * 1024 // 20MB
        case .medium: // 2-4GB
            self.imageCacheSize = 35
            self.textCacheSize = 150
            self.maxImageCacheSize = 35 * 1024 * 1024 // 35MB
        case .high: // > 4GB
            self.imageCacheSize = 50
            self.textCacheSize = 200
            self.maxImageCacheSize = 50 * 1024 * 1024 // 50MB
        }
        
        setupMemoryWarningObserver()
        setupMemoryPressureMonitoring()
    }
    
    // MARK: - Device Memory Detection
    private enum DeviceMemory {
        case low, medium, high
    }
    
    private static func getDeviceMemory() -> DeviceMemory {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let memoryInGB = Double(totalMemory) / (1024 * 1024 * 1024)
        
        if memoryInGB < 2.0 {
            return .low
        } else if memoryInGB < 4.0 {
            return .medium
        } else {
            return .high
        }
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            _Concurrency.Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }
    }
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .main)
        memoryPressureSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.handleMemoryPressure()
        }
        memoryPressureSource?.resume()
    }
    
    private func handleMemoryWarning() {
        lastMemoryWarning = Date()
        clearCaches(aggressive: true)
        print("🚨 Performance: Memory warning received - aggressive cache clearing")
    }
    
    private func handleMemoryPressure() {
        guard Date().timeIntervalSince(lastMemoryWarning) > 5.0 else { return }
        clearCaches(aggressive: false)
        print("⚠️ Performance: Memory pressure detected - moderate cache clearing")
    }
    
    func clearCaches(aggressive: Bool = false) {
        if aggressive {
            // Clear everything
            imageCache.removeAll()
            textCache.removeAll()
            notePreviewCache.removeAll()
            currentImageCacheSize = 0
        } else {
            // Clear oldest entries only
            clearOldestCacheEntries()
        }
        print("🧹 Performance: Caches cleared (aggressive: \(aggressive))")
    }
    
    func handleMemoryPressure(_ level: MemoryPressureService.MemoryPressureLevel) {
        switch level {
        case .normal:
            // No action needed for normal memory pressure
            break
        case .low:
            // Only clear oldest 50% of caches
            clearPartialCaches(percentage: 0.5)
        case .medium:
            // Clear 75% of caches
            clearPartialCaches(percentage: 0.75)
        case .high:
            // Clear all caches aggressively
            clearCaches(aggressive: true)
        case .critical:
            // Clear all caches aggressively
            clearCaches(aggressive: true)
        }
    }
    
    private func clearPartialCaches(percentage: Double) {
        let imageKeysToRemove = Array(imageCache.keys.prefix(Int(Double(imageCache.count) * percentage)))
        let textKeysToRemove = Array(textCache.keys.prefix(Int(Double(textCache.count) * percentage)))
        let noteKeysToRemove = Array(notePreviewCache.keys.prefix(Int(Double(notePreviewCache.count) * percentage)))
        
        for key in imageKeysToRemove {
            if let value = imageCache.removeValue(forKey: key) {
                currentImageCacheSize -= estimateImageSize(value.0)
            }
        }
        
        for key in textKeysToRemove {
            textCache.removeValue(forKey: key)
        }
        
        for key in noteKeysToRemove {
            notePreviewCache.removeValue(forKey: key)
        }
        
        print("🧹 Performance: Cleared \(Int(percentage * 100))% of caches due to memory pressure")
    }
    
    private func clearOldestCacheEntries() {
        let now = Date()
        
        // Clear oldest image cache entries (older than 5 minutes)
        imageCache = imageCache.filter { key, value in
            now.timeIntervalSince(value.1) < 300
        }
        
        // Clear oldest text cache entries (older than 10 minutes)
        textCache = textCache.filter { key, value in
            now.timeIntervalSince(value.1) < 600
        }
        
        // Clear oldest note preview cache entries (older than 5 minutes)
        notePreviewCache = notePreviewCache.filter { key, value in
            now.timeIntervalSince(value.1) < 300
        }
        
        // Recalculate cache size
        currentImageCacheSize = imageCache.values.reduce(0) { total, value in
            total + estimateImageSize(value.0)
        }
    }
    
    // MARK: - Note List Optimization
    
    /// Optimizes note list for smooth scrolling by limiting visible items
    func optimizeNotesList(_ notes: [Note], currentIndex: Int = 0) -> [Note] {
        guard notes.count > maxVisibleNotes else { return notes }
        
        let startIndex = max(0, currentIndex - maxVisibleNotes / 2)
        let endIndex = min(notes.count, startIndex + maxVisibleNotes)
        
        return Array(notes[startIndex..<endIndex])
    }
    
    /// Generates optimized note preview text with LRU cache
    func getOptimizedNotePreview(for note: Note) -> String {
        let noteId = note.uuid?.uuidString ?? ""
        
        if let cached = notePreviewCache[noteId] {
            // Update access time for LRU
            notePreviewCache[noteId] = (cached.0, Date())
            return cached.0
        }
        
        let preview = generateNotePreview(note)
        
        // Cache management with LRU eviction
        if notePreviewCache.count >= textCacheSize {
            evictOldestCacheEntries()
        }
        
        notePreviewCache[noteId] = (preview, Date())
        return preview
    }
    
    private func evictOldestCacheEntries() {
        // Sort by access time and remove oldest 25%
        let sortedEntries = notePreviewCache.sorted { $0.value.1 < $1.value.1 }
        let entriesToRemove = sortedEntries.prefix(textCacheSize / 4)
        
        for (key, _) in entriesToRemove {
            notePreviewCache.removeValue(forKey: key)
        }
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
    
    /// Optimizes image for display with LRU caching
    func getOptimizedImage(from data: Data?, id: String) -> UIImage? {
        guard let data = data else { return nil }
        
        if let cached = imageCache[id] {
            // Update access time for LRU
            imageCache[id] = (cached.0, Date())
            return cached.0
        }
        
        guard let image = UIImage(data: data) else { return nil }
        
        // Resize image if too large
        let optimizedImage = resizeImageIfNeeded(image, maxSize: CGSize(width: 300, height: 300))
        
        // Calculate image size for cache management
        let imageSize = estimateImageSize(optimizedImage)
        
        // Cache management with size limits and LRU eviction
        if currentImageCacheSize + imageSize > maxImageCacheSize || imageCache.count >= imageCacheSize {
            clearOldestImages()
        }
        
        imageCache[id] = (optimizedImage, Date())
        currentImageCacheSize += imageSize
        return optimizedImage
    }
    
    private func estimateImageSize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4 // Rough estimate: width * height * 4 bytes per pixel
    }
    
    private func clearOldestImages() {
        // Sort by access time and remove oldest 25%
        let sortedEntries = imageCache.sorted { $0.value.1 < $1.value.1 }
        let entriesToRemove = sortedEntries.prefix(imageCacheSize / 4)
        
        for (key, value) in entriesToRemove {
            if imageCache.removeValue(forKey: key) != nil {
                currentImageCacheSize -= estimateImageSize(value.0)
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
        
        // Use Core Graphics for better performance
        guard let cgImage = image.cgImage else { return image }
        
        let width = Int(newSize.width)
        let height = Int(newSize.height)
        
        guard let colorSpace = cgImage.colorSpace else { return image }
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return image }
        
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        
        guard let resizedCGImage = context.makeImage() else { return image }
        return UIImage(cgImage: resizedCGImage)
    }
    
    // MARK: - Text Optimization
    
    /// Optimizes attributed text with LRU caching
    func getOptimizedAttributedText(from content: String, id: String) -> NSAttributedString {
        if let cached = textCache[id] {
            // Update access time for LRU
            textCache[id] = (cached.0, Date())
            return cached.0
        }
        
        let attributedString = NSAttributedString(string: content)
        
        // Cache management with LRU eviction
        if textCache.count >= textCacheSize {
            evictOldestTextCacheEntries()
        }
        
        textCache[id] = (attributedString, Date())
        return attributedString
    }
    
    private func evictOldestTextCacheEntries() {
        // Sort by access time and remove oldest 25%
        let sortedEntries = textCache.sorted { $0.value.1 < $1.value.1 }
        let entriesToRemove = sortedEntries.prefix(textCacheSize / 4)
        
        for (key, _) in entriesToRemove {
            textCache.removeValue(forKey: key)
        }
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
