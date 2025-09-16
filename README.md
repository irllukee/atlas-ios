# Atlas - Personal Life OS iOS App

A beautiful, modern iOS app built with SwiftUI that serves as your personal life operating system. Features a stunning glassmorphism design with sky blue aesthetics and comprehensive life tracking capabilities.

## 🌟 Features

### ✅ Completed (Tasks #1-3)
- **Beautiful UI**: Glassmorphism design with frosted glass effects and sky blue theme
- **CoreData Integration**: Robust local storage with repository pattern
- **Life Modules**: Notes, Tasks, Journal, Mood tracking, and more
- **Modern Design**: Floating headers, right-aligned feature cards, bottom navigation
- **Offline-First**: Pure CoreData implementation with no external dependencies

### 🚧 In Progress
- **Encryption & Security**: AES-GCM encryption for sensitive data
- **Calendar Integration**: EventKit integration for seamless scheduling
- **Notification System**: Smart local notifications and reminders

### 📋 Planned Features
- **Analytics Dashboard**: Insights and trends visualization
- **Cross-Linking**: Smart relationships between notes, tasks, and journal entries
- **Performance Optimization**: Background processing and caching
- **App Store Preparation**: Final polish and submission

## 🏗️ Architecture

- **MVVM Pattern**: Clean separation of concerns
- **Repository Pattern**: Abstracted data access layer
- **Dependency Injection**: Modular and testable architecture
- **CoreData Stack**: Robust local storage with background processing

## 🎨 Design System

- **Glassmorphism**: Frosted glass effects with transparency
- **Sky Blue Theme**: Airy, modern color palette
- **Typography**: Clean, modern sans-serif fonts
- **Animations**: Smooth transitions and micro-interactions

## 🚀 Getting Started

1. **Prerequisites**
   - Xcode 16.0+
   - iOS 18.5+
   - macOS 14.0+

2. **Installation**
   ```bash
   git clone https://github.com/yourusername/atlas-ios.git
   cd atlas-ios
   open Atlas.xcodeproj
   ```

3. **Build & Run**
   - Select iPhone 16 simulator or physical device
   - Build and run (⌘+R)

## 📱 Screenshots

*Coming soon - beautiful UI screenshots will be added*

## 🛠️ Development

### Project Structure
```
Atlas/
├── Core/
│   ├── Data/           # CoreData models, repositories, stack
│   ├── Theme/          # Design system and colors
│   └── Utils/          # Utilities and dependency injection
├── Common/
│   └── Components/     # Reusable UI components
├── Features/           # Feature-specific modules (planned)
└── Resources/          # Assets, localization, etc.
```

### Key Components
- **ContentView**: Main app interface with glassmorphism design
- **DataManager**: Centralized data coordination
- **CoreDataStack**: Robust CoreData implementation
- **Repository Pattern**: Clean data access abstraction

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you have any questions or need help, please open an issue on GitHub.

---

**Built with ❤️ using SwiftUI and CoreData**
