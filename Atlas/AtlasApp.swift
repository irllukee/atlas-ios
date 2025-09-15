import SwiftUI
import CoreData

@main
struct AtlasApp: App {
    // MARK: - Core Services
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var securityManager = SecurityManager.shared
    @StateObject private var biometricService = BiometricService.shared
    
    // MARK: - App State
    @State private var isAppReady = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isAppReady {
                    ContentView()
                        .environmentObject(dataManager)
                        .environmentObject(securityManager)
                        .environmentObject(biometricService)
                        .environment(\.managedObjectContext, dataManager.coreDataStack.persistentContainer.viewContext)
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
        // Simple synchronous initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAppReady = true
            }
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
