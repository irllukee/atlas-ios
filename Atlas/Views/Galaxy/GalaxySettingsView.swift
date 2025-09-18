import SwiftUI

struct GalaxySettingsView: View {
    let galaxy: Galaxy
    @ObservedObject var galaxyManager: GalaxyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var galaxyName: String
    @State private var galaxyDescription: String
    @State private var selectedTheme: GalaxyTheme
    @State private var showingDeleteConfirmation = false
    
    init(galaxy: Galaxy, galaxyManager: GalaxyManager) {
        self.galaxy = galaxy
        self.galaxyManager = galaxyManager
        self._galaxyName = State(initialValue: galaxy.name)
        self._galaxyDescription = State(initialValue: galaxy.description)
        self._selectedTheme = State(initialValue: galaxy.theme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: selectedTheme.backgroundGradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Galaxy info
                        GalaxyInfoSection(galaxy: galaxy)
                        
                        // Settings sections
                        VStack(spacing: 20) {
                            // Basic settings
                            FormSection(title: "Basic Settings") {
                                VStack(spacing: 16) {
                                    CustomTextField(
                                        title: "Galaxy Name",
                                        text: $galaxyName,
                                        placeholder: "Enter galaxy name..."
                                    )
                                    
                                    CustomTextField(
                                        title: "Description",
                                        text: $galaxyDescription,
                                        placeholder: "Describe your galaxy..."
                                    )
                                }
                            }
                            
                            // Theme settings
                            FormSection(title: "Theme") {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(GalaxyTheme.allCases, id: \.self) { theme in
                                        ThemeOptionView(
                                            theme: theme,
                                            isSelected: selectedTheme == theme,
                                            onSelect: { selectedTheme = theme }
                                        )
                                    }
                                }
                            }
                            
                            // Galaxy statistics
                            FormSection(title: "Galaxy Statistics") {
                                VStack(spacing: 12) {
                                    StatRow(title: "Total Nodes", value: "\(galaxy.nodes.count)")
                                    StatRow(title: "Connections", value: "\(galaxy.connections.count)")
                    StatRow(title: "Created", value: DateFormatter.galaxyShortDate.string(from: galaxy.createdAt))
                    StatRow(title: "Last Modified", value: DateFormatter.galaxyShortDate.string(from: galaxy.lastModified))
                                }
                            }
                            
                            // Actions
                            FormSection(title: "Actions") {
                                VStack(spacing: 12) {
                                    GalaxyActionButton(
                                        title: "Duplicate Galaxy",
                                        icon: "doc.on.doc",
                                        color: .blue,
                                        action: duplicateGalaxy
                                    )
                                    
                                    GalaxyActionButton(
                                        title: "Export Galaxy",
                                        icon: "square.and.arrow.up",
                                        color: .green,
                                        action: exportGalaxy
                                    )
                                    
                                    GalaxyActionButton(
                                        title: "Delete Galaxy",
                                        icon: "trash",
                                        color: .red,
                                        action: { showingDeleteConfirmation = true }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Galaxy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Delete Galaxy", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteGalaxy()
            }
        } message: {
            Text("Are you sure you want to delete '\(galaxy.name)'? This action cannot be undone.")
        }
    }
    
    private func saveChanges() {
        var updatedGalaxy = galaxy
        updatedGalaxy.name = galaxyName.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGalaxy.description = galaxyDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedGalaxy.theme = selectedTheme
        
        galaxyManager.updateGalaxy(updatedGalaxy)
        dismiss()
    }
    
    private func duplicateGalaxy() {
        let duplicatedGalaxy = galaxyManager.duplicateGalaxy(galaxy)
        galaxyManager.selectGalaxy(duplicatedGalaxy)
        dismiss()
    }
    
    private func exportGalaxy() {
        // TODO: Implement galaxy export functionality
        print("Exporting galaxy: \(galaxy.name)")
    }
    
    private func deleteGalaxy() {
        galaxyManager.deleteGalaxy(galaxy)
        dismiss()
    }
}

// MARK: - Galaxy Info Section
struct GalaxyInfoSection: View {
    let galaxy: Galaxy
    
    var body: some View {
        VStack(spacing: 16) {
            // Galaxy preview
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: galaxy.theme.backgroundGradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Sample nodes
                ForEach(Array(galaxy.nodes.prefix(8).enumerated()), id: \.element.id) { index, node in
                    Circle()
                        .fill(node.type.color.opacity(0.8))
                        .frame(width: 8, height: 8)
                        .position(
                            x: CGFloat.random(in: 20...120),
                            y: CGFloat.random(in: 20...80)
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
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Galaxy info
            VStack(spacing: 4) {
                Text(galaxy.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(galaxy.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Galaxy Action Button
struct GalaxyActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let galaxyShortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

#Preview {
    GalaxySettingsView(galaxy: GalaxyManager.previewGalaxies[0], galaxyManager: GalaxyManager())
}
