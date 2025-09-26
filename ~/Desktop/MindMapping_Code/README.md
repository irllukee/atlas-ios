# Atlas Mind Mapping Code

This folder contains only the mind mapping specific code from the Atlas app.

## 📁 Files Included

### 🎯 Main Views
- **MindMappingViewV2.swift** - Main mind mapping view with navigation
- **FocusView.swift** - Individual node view with radial mind map
- **RadialMindMap.swift** - Core radial visualization component
- **BubbleView.swift** - Individual node bubble component

### 🎨 UI Components
- **SpaceBackgroundView.swift** - Space-themed background
- **GlassBackgroundView.swift** - Glass effect backgrounds
- **NoteEditor.swift** - Node note editing interface
- **SearchView.swift** - Node search functionality
- **ConflictResolutionView.swift** - Conflict resolution interface

### 🏗️ Core Architecture
- **MindMapStateManager.swift** - Centralized state management
- **MindMapRepository.swift** - Mind map CRUD operations
- **NodeRepository.swift** - Node CRUD operations
- **MindMappingViewModel.swift** - View model for mind mapping

### 🔧 Services
- **MindMapSearchService.swift** - Search functionality
- **MindMapSyncManager.swift** - Sync operations
- **MindMapConflictResolver.swift** - Conflict resolution

## 🎯 Key Files to Focus On

1. **MindMappingViewV2.swift** - Main navigation system
2. **FocusView.swift** - Node display and navigation
3. **RadialMindMap.swift** - Core visualization and gestures
4. **MindMapStateManager.swift** - State management

## 🔧 Recent Fixes

- ✅ Fixed tap navigation system
- ✅ Removed duplicate hamburger menu
- ✅ Simplified gesture handling
- ✅ Build is successful

## 🚨 Current Issues

- Navigation may still need testing
- State management needs verification
- Performance optimization is in place

This is the core mind mapping system - all the files you need to understand and modify the mind mapping functionality.