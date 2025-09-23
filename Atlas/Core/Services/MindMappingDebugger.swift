import Foundation
import SwiftUI
import CoreData

/// Debugger specifically designed to identify mind mapping freeze issues
@MainActor
class MindMappingDebugger: ObservableObject {
    static let shared = MindMappingDebugger()
    
    @Published var isEnabled = false
    @Published var debugLog: [DebugEntry] = []
    @Published var performanceMetrics: PerformanceSnapshot = PerformanceSnapshot()
    
    private var freezeDetectionTimer: Timer?
    private var lastInteractionTime: Date = Date()
    private let freezeThreshold: TimeInterval = 2.0 // 2 seconds without interaction = potential freeze
    
    private init() {}
    
    // MARK: - Debug Control
    
    func enable() {
        isEnabled = true
        debugLog.removeAll()
        startFreezeDetection()
        log("🧠 Mind Mapping Debugger ENABLED")
    }
    
    func disable() {
        isEnabled = false
        freezeDetectionTimer?.invalidate()
        freezeDetectionTimer = nil
        log("🧠 Mind Mapping Debugger DISABLED")
    }
    
    // MARK: - Logging
    
    func log(_ message: String, category: DebugCategory = .general, metadata: [String: Any] = [:]) {
        // Always print to console for immediate debugging
        print("🧠 [\(category.rawValue.uppercased())] \(message)")
        if !metadata.isEmpty {
            print("   Metadata: \(metadata)")
        }
        
        // Only store in debugLog if enabled
        guard isEnabled else { return }
        
        let entry = DebugEntry(
            timestamp: Date(),
            message: message,
            category: category,
            metadata: metadata
        )
        
        debugLog.append(entry)
        
        // Keep only last 100 entries to prevent memory issues
        if debugLog.count > 100 {
            debugLog.removeFirst()
        }
    }
    
    // MARK: - Freeze Detection
    
    private func startFreezeDetection() {
        freezeDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            DispatchQueue.main.async {
                let timeSinceLastInteraction = Date().timeIntervalSince(self.lastInteractionTime)
                
                if timeSinceLastInteraction > self.freezeThreshold {
                    self.log("⚠️ POTENTIAL FREEZE DETECTED", 
                            category: .freeze, 
                            metadata: [
                                "timeSinceLastInteraction": timeSinceLastInteraction,
                                "threshold": self.freezeThreshold
                            ])
                }
            }
        }
    }
    
    func recordInteraction(_ interaction: String, metadata: [String: Any] = [:]) {
        lastInteractionTime = Date()
        // Always log interactions to console immediately
        print("🧠 [INTERACTION] 👆 User Interaction: \(interaction)")
        if !metadata.isEmpty {
            print("   Metadata: \(metadata)")
        }
        log("👆 User Interaction: \(interaction)", category: .interaction, metadata: metadata)
    }
    
    // MARK: - Performance Monitoring
    
    func capturePerformanceSnapshot() {
        let snapshot = PerformanceSnapshot(
            memoryUsage: getMemoryUsage(),
            nodeCount: getNodeCount(),
            gestureCount: getActiveGestureCount(),
            animationCount: getActiveAnimationCount(),
            timestamp: Date()
        )
        
        performanceMetrics = snapshot
        
        log("📊 Performance Snapshot Captured", 
            category: .performance, 
            metadata: [
                "memoryUsage": snapshot.memoryUsage,
                "nodeCount": snapshot.nodeCount,
                "gestureCount": snapshot.gestureCount,
                "animationCount": snapshot.animationCount
            ])
    }
    
    // MARK: - Mind Mapping Specific Debugging
    
    func debugGestureConflict(_ gesture1: String, _ gesture2: String, location: String) {
        log("⚔️ GESTURE CONFLICT DETECTED", 
            category: .gesture, 
            metadata: [
                "gesture1": gesture1,
                "gesture2": gesture2,
                "location": location,
                "timestamp": Date().timeIntervalSince1970
            ])
    }
    
    func debugAnimationIssue(_ animation: String, reason: String, metadata: [String: Any] = [:]) {
        log("🎬 ANIMATION ISSUE", 
            category: .animation, 
            metadata: [
                "animation": animation,
                "reason": reason,
                "timestamp": Date().timeIntervalSince1970
            ].merging(metadata) { _, new in new })
    }
    
    func debugCoreDataIssue(_ operation: String, error: Error?, metadata: [String: Any] = [:]) {
        log("💾 CORE DATA ISSUE", 
            category: .coreData, 
            metadata: [
                "operation": operation,
                "error": error?.localizedDescription ?? "No error",
                "timestamp": Date().timeIntervalSince1970
            ].merging(metadata) { _, new in new })
    }
    
    func debugNavigationIssue(_ from: String, to: String, reason: String) {
        log("🧭 NAVIGATION ISSUE", 
            category: .navigation, 
            metadata: [
                "from": from,
                "to": to,
                "reason": reason,
                "timestamp": Date().timeIntervalSince1970
            ])
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Double {
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
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        return 0.0
    }
    
    private func getNodeCount() -> Int {
        // This would need to be connected to your actual node data
        return 0
    }
    
    private func getActiveGestureCount() -> Int {
        // This would need to be connected to your gesture tracking
        return 0
    }
    
    private func getActiveAnimationCount() -> Int {
        // This would need to be connected to your animation tracking
        return 0
    }
    
    // MARK: - Export Debug Info
    
    func exportDebugLog() -> String {
        var output = "🧠 Mind Mapping Debug Log\n"
        output += "========================\n\n"
        
        for entry in debugLog {
            output += "[\(entry.timestamp.formatted(date: .omitted, time: .standard))] "
            output += "[\(entry.category.rawValue.uppercased())] "
            output += "\(entry.message)\n"
            
            if !entry.metadata.isEmpty {
                for (key, value) in entry.metadata {
                    output += "  \(key): \(value)\n"
                }
            }
            output += "\n"
        }
        
        return output
    }
}

// MARK: - Supporting Types

enum DebugCategory: String, CaseIterable {
    case general = "general"
    case freeze = "freeze"
    case interaction = "interaction"
    case performance = "performance"
    case gesture = "gesture"
    case animation = "animation"
    case coreData = "coredata"
    case navigation = "navigation"
}

struct DebugEntry {
    let timestamp: Date
    let message: String
    let category: DebugCategory
    let metadata: [String: Any]
}

struct PerformanceSnapshot {
    let memoryUsage: Double // MB
    let nodeCount: Int
    let gestureCount: Int
    let animationCount: Int
    let timestamp: Date
    
    init(memoryUsage: Double = 0, nodeCount: Int = 0, gestureCount: Int = 0, animationCount: Int = 0, timestamp: Date = Date()) {
        self.memoryUsage = memoryUsage
        self.nodeCount = nodeCount
        self.gestureCount = gestureCount
        self.animationCount = animationCount
        self.timestamp = timestamp
    }
}
