import SwiftUI

struct GalaxySelectionView: View {
    @StateObject private var galaxyManager = GalaxyManager()
    @State private var showingCreateGalaxy = false
    @State private var showingGalaxySettings = false
    @State private var selectedGalaxyForSettings: Galaxy?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Cosmic background
                cosmicBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(galaxyManager.galaxies) { galaxy in
                            GalaxyCardView(
                                galaxy: galaxy,
                                isSelected: galaxyManager.selectedGalaxy?.id == galaxy.id,
                                onSelect: {
                                    galaxyManager.selectGalaxy(galaxy)
                                },
                                onSettings: {
                                    selectedGalaxyForSettings = galaxy
                                    showingGalaxySettings = true
                                }
                            )
                        }
                        
                        // Create new galaxy card
                        CreateGalaxyCardView {
                            showingCreateGalaxy = true
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Brainstorm Galaxies")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        showingCreateGalaxy = true
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingCreateGalaxy) {
            CreateGalaxyView(galaxyManager: galaxyManager)
        }
        .sheet(isPresented: $showingGalaxySettings) {
            if let galaxy = selectedGalaxyForSettings {
                GalaxySettingsView(galaxy: galaxy, galaxyManager: galaxyManager)
            }
        }
        .onAppear {
            if galaxyManager.selectedGalaxy != nil {
                // Navigate to the selected galaxy
                // This will be handled by the parent view
            }
        }
    }
    
    private var cosmicBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.4, green: 0.7, blue: 1.0),
                Color(red: 0.2, green: 0.4, blue: 0.8),
                Color(red: 0.1, green: 0.2, blue: 0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Galaxy Card View
struct GalaxyCardView: View {
    let galaxy: Galaxy
    let isSelected: Bool
    let onSelect: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Galaxy preview
                GalaxyPreviewView(galaxy: galaxy)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Galaxy info
                VStack(alignment: .leading, spacing: 4) {
                    Text(galaxy.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(galaxy.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(galaxy.nodes.count) nodes")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Button(action: onSettings) {
                            Image(systemName: "gearshape.fill")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? galaxy.theme.primaryColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Galaxy Preview View
struct GalaxyPreviewView: View {
    let galaxy: Galaxy
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: galaxy.theme.backgroundGradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Sample nodes for preview
            ForEach(Array(galaxy.nodes.prefix(6).enumerated()), id: \.element.id) { index, node in
                Circle()
                    .fill(node.type.color.opacity(0.8))
                    .frame(width: 8, height: 8)
                    .position(
                        x: CGFloat.random(in: 20...100),
                        y: CGFloat.random(in: 20...100)
                    )
            }
            
            // If no nodes, show placeholder
            if galaxy.nodes.isEmpty {
                VStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Empty Galaxy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Create Galaxy Card View
struct CreateGalaxyCardView: View {
    let onCreate: () -> Void
    
    var body: some View {
        Button(action: onCreate) {
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Create New Galaxy")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Start a new cosmic journey")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.white.opacity(0.3),
                                style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GalaxySelectionView()
}
