# Atlas iOS App Performance Audit - Categorized Action Plan

## 🚨 Category 1: CRITICAL AUTO-SAVE ISSUES
**Priority: IMMEDIATE** | **Impact: HIGH** | **Effort: MEDIUM**

### Problems Found:
- **3 conflicting auto-save systems** running simultaneously
- **Aggressive 2-second intervals** causing excessive database writes
- **16ms debounce** in RadialMindMap overwhelming the system
- **Main thread blocking** during saves

### Files to Fix:
- `Atlas/Core/Services/AutoSaveService.swift` (5-second interval)
- `Atlas/Core/Services/NotesService.swift` (2-second interval)
- `Atlas/Views/Notes/NotesDetailView.swift` (2-second interval)
- `Atlas/Views/MindMapping/RadialMindMap.swift` (16ms debounce)

### Solution:
```swift
// Create single optimized auto-save service
class OptimizedAutoSaveService {
    private let saveInterval: TimeInterval = 3.0  // Increase from 2.0
    private let debounceInterval: TimeInterval = 0.5  // Increase from 16ms
    private var saveTimer: Timer?
    private var debounceTimer: Timer?
    
    func scheduleSave() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.performBackgroundSave()
        }
    }
}
```

---

## 🔧 Category 2: MEMORY LEAKS & TIMER CLEANUP
**Priority: IMMEDIATE** | **Impact: HIGH** | **Effort: LOW**

### Problems Found:
- **4 different timers** not properly cleaned up
- **Potential retain cycles** in timer closures
- **Singleton services** accumulating memory over time

### Files to Fix:
- `Atlas/Core/Security/SecurityManager.swift` (authenticationTimer)
- `Atlas/Core/Services/AutoSaveService.swift` (saveTimer)
- `Atlas/Views/Notes/NotesDetailView.swift` (autoSaveTimer)
- `Atlas/Views/MindMapping/RadialMindMap.swift` (cameraUpdateTimer)

### Solution:
```swift
// Add proper cleanup to all timer-using classes
deinit {
    stopAllTimers()
}

private func stopAllTimers() {
    timer1?.invalidate()
    timer2?.invalidate()
    timer3?.invalidate()
    // Set all timers to nil
}
```

---

## 🎨 Category 3: ANIMATION PERFORMANCE
**Priority: HIGH** | **Impact: MEDIUM** | **Effort: MEDIUM**

### Problems Found:
- **Timer-based camera updates** at 16ms intervals (60fps)
- **Multiple simultaneous animations** without conflict management
- **Excessive transform calculations** on main thread
- **No animation debouncing** for complex operations

### Files to Fix:
- `Atlas/Views/MindMapping/RadialMindMap.swift` (camera animations)
- `Atlas/Views/Journal/CreateJournalEntryView.swift` (mood slider animations)
- All views using `.ultraThinMaterial` and blur effects

### Solution:
```swift
// Replace Timer with CADisplayLink for smooth animations
private var displayLink: CADisplayLink?

private func setupOptimizedCameraUpdates() {
    displayLink = CADisplayLink(target: self, selector: #selector(updateCamera))
    displayLink?.preferredFramesPerSecond = 30  // Reduce from 60fps
    displayLink?.add(to: .main, forMode: .common)
}

deinit {
    displayLink?.invalidate()
}
```

---

## 🗄️ Category 4: CORE DATA OPTIMIZATION
**Priority: HIGH** | **Impact: MEDIUM** | **Effort: HIGH**

### Problems Found:
- **Main thread saves** blocking UI updates
- **No fetch batching** for large datasets
- **Missing fault object management**
- **Potential N+1 query problems**

### Files to Fix:
- `Atlas/Core/Data/CoreDataStack.swift` (save methods)
- `Atlas/Core/Data/DataManager.swift` (fetch operations)
- All repository classes in `Atlas/Core/Data/Repositories/`

### Solution:
```swift
// Always use background context for saves
func saveAsync() {
    guard viewContext.hasChanges else { return }
    
    performBackgroundTask { backgroundContext in
        do {
            try backgroundContext.save()
            DispatchQueue.main.async {
                // Update UI on main thread
            }
        } catch {
            DispatchQueue.main.async {
                self.handleError(error)
            }
        }
    }
}

// Add fetch batching
func fetchWithBatching(limit: Int = 50, offset: Int = 0) -> [Entity] {
    let request = NSFetchRequest<Entity>(entityName: "Entity")
    request.fetchLimit = limit
    request.fetchOffset = offset
    // Execute request
}
```

---

## 📱 Category 5: SWIFTUI STATE MANAGEMENT
**Priority: MEDIUM** | **Impact: MEDIUM** | **Effort: MEDIUM**

### Problems Found:
- **Excessive @Published properties** triggering cascade updates
- **No debouncing** for expensive operations (search, filtering)
- **Immediate state updates** on every keystroke
- **Mixed @StateObject/@ObservedObject** usage

### Files to Fix:
- `Atlas/Views/Journal/JournalViewModel.swift` (6 @Published properties)
- `Atlas/Views/Tasks/TaskViewModel.swift` (search debouncing)
- All views with search functionality

### Solution:
```swift
// Debounce expensive operations
@Published var searchText = "" {
    didSet {
        searchDebounceWorkItem?.cancel()
        searchDebounceWorkItem = DispatchWorkItem {
            self.applyFilters()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: searchDebounceWorkItem!)
    }
}

// Use @StateObject instead of @ObservedObject where appropriate
@StateObject private var viewModel = JournalViewModel()
```

---

## 🖼️ Category 6: RENDERING OPTIMIZATION
**Priority: MEDIUM** | **Impact: LOW** | **Effort: LOW**

### Problems Found:
- **Deep view hierarchy** with nested ZStacks
- **Excessive blur effects** (.ultraThinMaterial)
- **Multiple shadows** without optimization
- **Complex shapes** recalculating paths every frame

### Files to Fix:
- All views using `.ultraThinMaterial`
- Views with multiple shadows
- Complex custom shapes and overlays

### Solution:
```swift
// Optimize blur usage
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(.regularMaterial)  // Use .regular instead of .ultraThin
)

// Cache complex shapes
private let cachedShape = RoundedRectangle(cornerRadius: 12)

// Reduce shadow complexity
.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)  // Single shadow instead of multiple
```

---

## 🔄 Category 7: THREADING & CONCURRENCY
**Priority: MEDIUM** | **Impact: HIGH** | **Effort: HIGH**

### Problems Found:
- **Core Data operations** on main thread
- **File I/O operations** potentially blocking UI
- **Mixed async/sync** patterns
- **No proper error handling** for background operations

### Files to Fix:
- `Atlas/Core/Data/CoreDataStack.swift`
- `Atlas/Core/Services/` (all service classes)
- `Atlas/Views/` (all view models)

### Solution:
```swift
// Standardize async patterns
func performAsyncOperation() async throws -> Result {
    return try await withCheckedThrowingContinuation { continuation in
        performBackgroundTask { context in
            do {
                let result = try self.performOperation(context: context)
                continuation.resume(returning: result)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

---

## 📊 Category 8: PERFORMANCE MONITORING
**Priority: LOW** | **Impact: LOW** | **Effort: LOW**

### Implementation:
Add performance monitoring throughout the app to track improvements and catch regressions.

### Solution:
```swift
class PerformanceMonitor {
    static func measure<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("⏱️ \(operation): \(timeElapsed * 1000)ms")
        return result
    }
}

// Usage in critical paths
let entries = PerformanceMonitor.measure("Journal Entries Fetch") {
    try repository.fetchJournalEntries()
}
```

---

## 🎯 Implementation Priority Order

### Week 1 (Critical Issues):
1. **Category 1**: Fix auto-save conflicts
2. **Category 2**: Fix timer memory leaks

### Week 2 (High Impact):
3. **Category 3**: Optimize animations
4. **Category 4**: Core Data background operations

### Week 3 (Polish):
5. **Category 5**: SwiftUI state management
6. **Category 6**: Rendering optimization

### Week 4 (Architecture):
7. **Category 7**: Threading standardization
8. **Category 8**: Performance monitoring

---

## 📈 Expected Results

After completing all categories:
- **50-70% reduction** in main thread blocking
- **30-50% improvement** in animation smoothness  
- **40-60% reduction** in memory usage
- **20-30% improvement** in battery life
- **Elimination** of thermal throttling issues

## 🧪 Testing Strategy

### After Each Category:
- Run Instruments Time Profiler
- Test on iPhone 8 (older device)
- Monitor memory usage during extended use
- Check for animation frame drops

### Final Validation:
- 30+ minute typing sessions
- 1000+ note operations
- Background/foreground cycling
- Memory pressure simulation
