import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTab: TabItem = TabItem(title: "Dashboard", icon: "house")
    
    var body: some View {
        ZStack {
            // Background gradient
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Floating Header (Date, Time, Quote)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sep 14")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("September 14, 2025")
                                    .font(.system(size: 16, weight: .light, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Tomorrow is a new day")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.top, 4)
                            }
                            
                            Spacer()
                            
                            // Right-aligned Feature Cards Stack
                            VStack(alignment: .trailing, spacing: 12) {
                                LifeModuleCard(
                                    title: "🌙 Dream Journal",
                                    icon: "moon.stars.fill",
                                    value: "2 entries today",
                                    color: .purple,
                                    progress: 0.6
                                )
                                
                                LifeModuleCard(
                                    title: "📝 Notes / Ideas Bank",
                                    icon: "note.text",
                                    value: "5 notes this week",
                                    color: .blue,
                                    progress: 0.8
                                )
                                
                                LifeModuleCard(
                                    title: "✅ To-Do / Tasks",
                                    icon: "checkmark.circle.fill",
                                    value: "73% complete",
                                    color: .green,
                                    progress: 0.73
                                )
                                
                                LifeModuleCard(
                                    title: "📅 Planner / Calendar",
                                    icon: "calendar",
                                    value: "Next: Meeting 3 PM",
                                    color: .orange,
                                    progress: 0.4
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // Today's Highlights Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Highlights")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("See All") {
                                // Action for See All
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        
                        FrostedCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("12 Entries")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Updated 9:14 AM.")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                HStack {
                                    Text("Notes")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text("Tasks Done")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                    
                                    Text("Habits Logged")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.vertical, 8)
                                
                                // Simple activity graph placeholder
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(height: 60)
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Trends Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Trends")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("See All") {
                                // Action for See All
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 12) {
                            FrostedCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Task Completion Rate")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("→ 73%")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(16)
                            }
                            
                            FrostedCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Habit Streaks")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text("→ 7 days")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .padding(16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Other Feature Modules
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Other Modules")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("See All") {
                                // Action for See All
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            FrostedCard {
                                HStack {
                                    Image(systemName: "fork.knife")
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 20)
                                    
                                    Text("🍳 Recipes")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\"Try One-Pot Mode tonight\"")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                            }
                            
                            FrostedCard {
                                HStack {
                                    Image(systemName: "headphones")
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 20)
                                    
                                    Text("🎧 Media Log")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\"Podcast note: 15 min left\"")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                            }
                            
                            FrostedCard {
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 20)
                                    
                                    Text("💰 Finances")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\"This week's spend: $142\"")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                            }
                            
                            FrostedCard {
                                HStack {
                                    Image(systemName: "airplane")
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 20)
                                    
                                    Text("✈️ Travel / Places")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\"Bucket list: 3 new\"")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                            }
                            
                            FrostedCard {
                                HStack {
                                    Image(systemName: "bed.double.fill")
                                        .foregroundColor(.white.opacity(0.8))
                                        .frame(width: 20)
                                    
                                    Text("💤 Sleep / Relaxation")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Text("\"White noise logged 2 hrs\"")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Space for bottom nav bar
                    }
                }
            }
            
            // Bottom Navigation
            VStack {
                Spacer()
                BottomNavigationBar(selectedTab: $selectedTab) {
                    TabItem(title: "Dashboard", icon: "house")
                    TabItem(title: "Notes", icon: "note.text")
                    TabItem(title: "Planner", icon: "calendar")
                    TabItem(title: "Profile", icon: "person.circle")
                }
            }
        }
    }
}

// MARK: - Life Module Card Component (Floating Text Only)
struct LifeModuleCard: View {
    let title: String
    let icon: String
    let value: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
                
                Spacer()
                
                // Progress indicator
                CircularProgress(progress: progress, color: .white.opacity(0.8), size: 20, lineWidth: 2)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager.shared)
}
