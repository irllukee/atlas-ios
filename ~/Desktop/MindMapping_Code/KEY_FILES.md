# Key Files Reference

## 🎯 Main Entry Points

### MindMappingViewV2.swift
- **Purpose**: Main mind mapping view with navigation
- **Key Features**: NavigationStack, hamburger menu, sheet presentations
- **Recent Changes**: Fixed to show root node directly, removed duplicate menu

### FocusView.swift
- **Purpose**: Individual node view with radial mind map
- **Key Features**: Node display, navigation, operations
- **Recent Changes**: Removed duplicate hamburger menu, simplified navigation

### RadialMindMap.swift
- **Purpose**: Core radial visualization component
- **Key Features**: Node positioning, gesture handling, performance optimization
- **Recent Changes**: Simplified tap gestures, removed double tap, fixed navigation

## 🏗️ Architecture Files

### MindMapStateManager.swift
- **Purpose**: Centralized state management
- **Key Features**: @Published properties, navigation state, error handling
- **Status**: Core state management system

### MindMappingViewModel.swift
- **Purpose**: View model for mind mapping
- **Key Features**: Data management, state coordination
- **Status**: Connects views to state manager

## 🔧 Core Components

### BubbleView.swift
- **Purpose**: Individual node bubble component
- **Key Features**: Node display, styling, interactions
- **Status**: Basic node visualization

### ViewVirtualization.swift
- **Purpose**: Performance optimization
- **Key Features**: LOD (Level of Detail), view virtualization
- **Status**: Performance optimization system

## 📊 Data Management

### MindMapRepository.swift
- **Purpose**: Mind map CRUD operations
- **Key Features**: Create, read, update, delete mind maps
- **Status**: Data persistence layer

### NodeRepository.swift
- **Purpose**: Node CRUD operations
- **Key Features**: Create, read, update, delete nodes
- **Status**: Node data management

## 🚀 Performance Files

### LazyLoadingManager.swift
- **Purpose**: Lazy loading utilities
- **Key Features**: On-demand loading, memory optimization
- **Status**: Performance optimization

### MemoryManagement.swift
- **Purpose**: Memory optimization
- **Key Features**: Memory cleanup, resource management
- **Status**: Memory optimization system

### RenderingOptimization.swift
- **Purpose**: Rendering performance
- **Key Features**: Efficient rendering, animation optimization
- **Status**: Rendering performance system

## 🔍 Debugging Files

### Current Issues
1. **Navigation System** - May still have issues with child node navigation
2. **State Management** - Need to verify state updates trigger UI changes
3. **Performance** - Need to test with large datasets

### Key Areas to Focus On
1. **RadialMindMap.swift** - Core visualization and gesture handling
2. **FocusView.swift** - Node display and navigation
3. **MindMapStateManager.swift** - State management and updates
4. **MindMappingViewV2.swift** - Main navigation system

## 📝 Development Notes

- All files are organized by functionality
- Performance optimizations are in Utils/
- State management is centralized
- Views are separated by concern
- Services handle business logic
- Recent fixes focused on navigation and gesture conflicts
