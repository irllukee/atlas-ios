import SwiftUI

struct CreateGalaxyView: View {
    @ObservedObject var galaxyManager: GalaxyManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var galaxyName = ""
    @State private var galaxyDescription = ""
    @State private var selectedTheme: GalaxyTheme = .cosmic
    @State private var selectedNodeTypes: Set<NodeType> = [.note]
    
    private let availableNodeTypes: [NodeType] = [.dream, .note, .task, .journal]
    
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
                        // Galaxy preview
                        GalaxyPreviewSection(
                            name: galaxyName.isEmpty ? "New Galaxy" : galaxyName,
                            description: galaxyDescription.isEmpty ? "Your cosmic space" : galaxyDescription,
                            theme: selectedTheme
                        )
                        
                        // Form sections
                        VStack(spacing: 20) {
                            // Basic info
                            FormSection(title: "Basic Information") {
                                VStack(spacing: 16) {
                                    CustomTextField(
                                        title: "Galaxy Name",
                                        text: $galaxyName,
                                        placeholder: "Enter galaxy name..."
                                    )
                                    
                                    CustomTextField(
                                        title: "Description (Optional)",
                                        text: $galaxyDescription,
                                        placeholder: "Describe your galaxy's purpose..."
                                    )
                                }
                            }
                            
                            // Theme selection
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
                            
                            // Node types
                            FormSection(title: "Node Types") {
                                VStack(spacing: 12) {
                                    ForEach(availableNodeTypes, id: \.self) { nodeType in
                                        NodeTypeOptionView(
                                            nodeType: nodeType,
                                            isSelected: selectedNodeTypes.contains(nodeType),
                                            onToggle: { toggleNodeType(nodeType) }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Create Galaxy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGalaxy()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(galaxyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func toggleNodeType(_ nodeType: NodeType) {
        if selectedNodeTypes.contains(nodeType) {
            selectedNodeTypes.remove(nodeType)
        } else {
            selectedNodeTypes.insert(nodeType)
        }
    }
    
    private func createGalaxy() {
        let trimmedName = galaxyName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = galaxyDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newGalaxy = galaxyManager.createGalaxy(
            name: trimmedName,
            description: trimmedDescription,
            nodeTypes: Array(selectedNodeTypes),
            theme: selectedTheme
        )
        
        galaxyManager.selectGalaxy(newGalaxy)
        dismiss()
    }
}

// MARK: - Galaxy Preview Section
struct GalaxyPreviewSection: View {
    let name: String
    let description: String
    let theme: GalaxyTheme
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Galaxy preview
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: theme.backgroundGradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Sample nodes
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .position(
                                x: CGFloat.random(in: 20...120),
                                y: CGFloat.random(in: 20...80)
                            )
                    }
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Galaxy info
                VStack(spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Form Section
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Theme Option View
struct ThemeOptionView: View {
    let theme: GalaxyTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                // Theme preview
                LinearGradient(
                    gradient: Gradient(colors: theme.backgroundGradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text(theme.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? theme.primaryColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Node Type Option View
struct NodeTypeOptionView: View {
    let nodeType: NodeType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Node type icon
                Group {
                    if nodeType.icon == "galaxy" {
                        GalaxyIcon(
                            size: 24,
                            color: nodeType.color
                        )
                    } else {
                        Image(systemName: nodeType.icon)
                            .font(.title2)
                            .foregroundColor(nodeType.color)
                    }
                }
                .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(nodeType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(nodeType.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? nodeType.color : .white.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? nodeType.color.opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateGalaxyView(galaxyManager: GalaxyManager())
}





