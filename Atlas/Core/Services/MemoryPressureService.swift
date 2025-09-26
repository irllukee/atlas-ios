import Foundation
import UIKit
@preconcurrency import Combine

/// Service for handling memory pressure and optimizing app performance
@MainActor
class MemoryPressureService: ObservableObject {
    static let shared = MemoryPressureService()
    
    @Published var currentMemoryPressure: MemoryPressureLevel = .normal
    @Published var memoryUsage: Double = 0.0
    @Published var isOptimizing = false
    
    private var cancellables = Set<AnyCancellable>()
    private var memoryMonitoringCancellable: AnyCancellable?
    private let performanceService = PerformanceService.shared
    
    enum MemoryPressureLevel: String, CaseIterable {
        case normal = "Normal"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var threshold: Double {
            switch self {
            case .normal: return 0.0
            case .low: return 0.3
            case .medium: return 0.5
            case .high: return 0.7
            case .critical: return 0.85
            }
        }
        
        var color: String {
            switch self {
            case .normal: return "green"
            case .low: return "yellow"
            case .medium: return "orange"
            case .high: return "red"
            case .critical: return "purple"
            }
        }
    }
    
    private init() {
        setupMemoryMonitoring()
        setupMemoryWarningObserver()
    }
    
    // MARK: - Memory Monitoring Setup
    
    private func setupMemoryMonitoring() {
        // Monitor memory usage every 5 seconds
        memoryMonitoringCancellable = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
    }
    
    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleMemoryWarning()
            }
        }
    }
    
    // MARK: - Memory Usage Monitoring
    
    private func updateMemoryUsage() {
        let memoryInfo = getMemoryUsage()
        memoryUsage = memoryInfo.usagePercentage
        
        // Update pressure level based on usage
        let newPressureLevel = determinePressureLevel(from: memoryInfo.usagePercentage)
        if newPressureLevel != currentMemoryPressure {
            currentMemoryPressure = newPressureLevel
            handleMemoryPressure(newPressureLevel)
        }
    }
    
    private func determinePressureLevel(from usagePercentage: Double) -> MemoryPressureLevel {
        switch usagePercentage {
        case 0.0..<0.3:
            return .normal
        case 0.3..<0.5:
            return .low
        case 0.5..<0.7:
            return .medium
        case 0.7..<0.85:
            return .high
        default:
            return .critical
        }
    }
    
    private func getMemoryUsage() -> (used: UInt64, total: UInt64, usagePercentage: Double) {
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
            let used = info.resident_size
            let total = ProcessInfo.processInfo.physicalMemory
            let percentage = Double(used) / Double(total)
            return (used: used, total: total, usagePercentage: percentage)
        }
        
        return (used: 0, total: 0, usagePercentage: 0.0)
    }
    
    // MARK: - Memory Pressure Handling
    
    private func handleMemoryWarning() {
        print("⚠️ Memory warning received - triggering aggressive cleanup")
        handleMemoryPressure(.critical)
    }
    
    private func handleMemoryPressure(_ level: MemoryPressureLevel) {
        guard !isOptimizing else { return }
        
        isOptimizing = true
        
        _Concurrency.Task {
            await performMemoryOptimization(for: level)
            await MainActor.run {
                isOptimizing = false
            }
        }
    }
    
    private func performMemoryOptimization(for level: MemoryPressureLevel) async {
        print("🧹 Performing memory optimization for level: \(level.rawValue)")
        
        switch level {
        case .normal:
            // No action needed
            break
            
        case .low:
            await optimizeForLowPressure()
            
        case .medium:
            await optimizeForMediumPressure()
            
        case .high:
            await optimizeForHighPressure()
            
        case .critical:
            await optimizeForCriticalPressure()
        }
    }
    
    // MARK: - Optimization Strategies
    
    private func optimizeForLowPressure() async {
        // Light optimization - clear old cache entries
        performanceService.handleMemoryPressure(.low)
        print("✅ Low pressure optimization completed")
    }
    
    private func optimizeForMediumPressure() async {
        // Medium optimization - clear more caches and reduce memory usage
        performanceService.handleMemoryPressure(.medium)
        
        // Allow other tasks to run
        await MainActor.run { }
        
        print("✅ Medium pressure optimization completed")
    }
    
    private func optimizeForHighPressure() async {
        // High optimization - aggressive cache clearing
        performanceService.handleMemoryPressure(.high)
        
        // Clear image caches
        await clearImageCaches()
        
        // Allow other tasks to run
        await MainActor.run { }
        
        print("✅ High pressure optimization completed")
    }
    
    private func optimizeForCriticalPressure() async {
        // Critical optimization - maximum cleanup
        performanceService.handleMemoryPressure(.high)
        
        // Clear all caches
        performanceService.clearCaches(aggressive: true)
        
        // Clear image caches
        await clearImageCaches()
        
        // Force save and clear Core Data context
        await saveAndClearContext()
        
        // Allow other tasks to run
        await MainActor.run { }
        
        print("🚨 Critical pressure optimization completed")
    }
    
    // MARK: - Helper Methods
    
    private func clearImageCaches() async {
        // Clear system image cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear any custom image caches
        await MainActor.run {
            // Additional image cache clearing can be added here
        }
    }
    
    private func saveAndClearContext() async {
        await MainActor.run {
            // Save Core Data context
            CoreDataStack.shared.saveAsync()
            
            // Clear any temporary data
            // Additional cleanup can be added here
        }
    }
    
    // MARK: - Public Methods
    
    /// Force memory optimization
    func forceOptimization() async {
        await performMemoryOptimization(for: currentMemoryPressure)
    }
    
    /// Get current memory statistics
    func getMemoryStats() -> (used: UInt64, total: UInt64, percentage: Double, level: MemoryPressureLevel) {
        let memoryInfo = getMemoryUsage()
        return (
            used: memoryInfo.used,
            total: memoryInfo.total,
            percentage: memoryInfo.usagePercentage,
            level: currentMemoryPressure
        )
    }
    
    /// Check if memory pressure is high
    var isHighMemoryPressure: Bool {
        return currentMemoryPressure == .high || currentMemoryPressure == .critical
    }
    
    /// Get memory pressure description
    var pressureDescription: String {
        switch currentMemoryPressure {
        case .normal:
            return "Memory usage is normal"
        case .low:
            return "Memory usage is elevated"
        case .medium:
            return "Memory pressure detected"
        case .high:
            return "High memory pressure"
        case .critical:
            return "Critical memory pressure"
        }
    }
    
    /// Cleanup method for proper resource management
    func cleanup() {
        memoryMonitoringCancellable?.cancel()
        memoryMonitoringCancellable = nil
        
        cancellables.removeAll()
        
        // Remove memory warning observer
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    // Note: Cancellable cleanup is handled automatically when the service is deallocated
    // No deinit needed due to Swift 6 concurrency safety constraints
    
}

// MARK: - Memory Pressure View Modifier (moved to separate SwiftUI file)
// SwiftUI-specific code should be in a separate file for better organization
