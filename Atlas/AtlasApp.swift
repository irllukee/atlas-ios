import SwiftUI
import CoreData
import UIKit

@main
struct AtlasApp: App {
    // MARK: - Core Services
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var securityManager = SecurityManager.shared
    @StateObject private var biometricService = BiometricService.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var notesService = NotesService.shared
    @StateObject private var dependencyContainer = DependencyContainer.shared
    
    // MARK: - App State
    @State private var isAppReady = false
    
    init() {
        // Configure UIKit to prevent white backgrounds
        configureUIKitAppearance()
    }
    
    private func configureUIKitAppearance() {
        // Set window background to clear to prevent white flash
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.backgroundColor = UIColor.clear
            }
        }
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Solid base layer that fills the entire screen
                AtlasTheme.Colors.background
                    .ignoresSafeArea(.all)
                
                if isAppReady {
                    // Check if onboarding is complete
                    if permissionManager.isOnboardingComplete {
                        // Show main app
                        ContentView()
                            .environmentObject(dataManager)
                            .environmentObject(securityManager)
                            .environmentObject(biometricService)
                            .environmentObject(permissionManager)
                            .environmentObject(notesService)
                            .environmentObject(dependencyContainer)
                            .environment(\.managedObjectContext, dataManager.coreDataStack.persistentContainer.viewContext)
                    } else {
                        // Show permission onboarding
                        PermissionOnboardingView()
                            .environmentObject(permissionManager)
                    }
                } else {
                    SplashView()
                        .onAppear {
                            initializeApp()
                        }
                }
            }
        }
    }
    
    // MARK: - App Initialization
    private func initializeApp() {
        // Fast initialization for better performance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAppReady = true
            }
            
            // Removed performance metrics logging
        }
        
        // Initialize Journal data in background
        _Concurrency.Task {
            await JournalInitializationService.shared.initializeJournalData()
        }
    }
    
}

// MARK: - Splash View
struct SplashView: View {
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AtlasTheme.Colors.primary)
                
                Text("Atlas")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Personal Knowledge System")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AtlasTheme.Colors.primary))
                    .scaleEffect(1.5)
                    .padding(.top, 20)
            }
        }
    }
}

// MARK: - Preview
struct AtlasApp_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
