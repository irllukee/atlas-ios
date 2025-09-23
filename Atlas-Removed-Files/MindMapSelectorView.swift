import SwiftUI

/// Mind Map Selector - Choose between Radial and Planetary mind mapping
struct MindMapSelectorView: View {
    @State private var selectedMode: MindMapMode = .radial
    let dataManager: DataManager
    
    enum MindMapMode: String, CaseIterable {
        case radial = "Radial"
        case planetary = "Planetary"
        
        var description: String {
            switch self {
            case .radial:
                return "Organic, free-form mind mapping with natural node distribution"
            case .planetary:
                return "8-directional compass-based mind mapping with structured navigation"
            }
        }
        
        var icon: String {
            switch self {
            case .radial:
                return "circle.grid.3x3"
            case .planetary:
                return "globe"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Mind Mapping")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Choose your preferred mind mapping style")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Mode Selection
                VStack(spacing: 16) {
                    ForEach(MindMapMode.allCases, id: \.self) { mode in
                        MindMapModeCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            onTap: { selectedMode = mode }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Start Button
                NavigationLink(destination: selectedView) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Start Mind Mapping")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(AtlasTheme.Colors.primary)
                            .shadow(color: AtlasTheme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.bottom, 40)
            }
            .background(AtlasTheme.Colors.background.ignoresSafeArea())
            .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    private var selectedView: some View {
        switch selectedMode {
        case .radial:
            MindMappingView(dataManager: dataManager)
        case .planetary:
            PlanetaryMindMapView(dataManager: dataManager)
        }
    }
}

// MARK: - Mind Map Mode Card
private struct MindMapModeCard: View {
    let mode: MindMapSelectorView.MindMapMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? AtlasTheme.Colors.primary : .white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : AtlasTheme.Colors.primary)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.primary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? AtlasTheme.Colors.primary : .white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    MindMapSelectorView(dataManager: DataManager.shared)
        .environment(\.managedObjectContext, DataManager.shared.coreDataStack.viewContext)
}

