import SwiftUI
import CoreData

struct SearchOverlay: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Node.title, ascending: true)],
        animation: .default)
    private var allNodes: FetchedResults<Node>
    
    var onJump: (Node) -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var filtered: [Node] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText.lowercased()
        return allNodes.filter { node in
            (node.title?.lowercased().contains(query) ?? false) || 
            (node.note?.lowercased().contains(query) ?? false)
        }.prefix(25).map { $0 }
    }

    var body: some View {
        VStack(spacing: 12) {
            searchBar
            if !filtered.isEmpty {
                searchResults
            }
        }
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.2), value: filtered.isEmpty)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search ideas & notes", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isSearchFocused)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isSearchFocused = false
                } label: { 
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 1))
        .padding(.horizontal)
    }
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered, id: \.uuid) { node in
                    searchResultRow(for: node)
                }
            }
            .padding(.horizontal)
        }
        .frame(maxHeight: 300)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private func searchResultRow(for node: Node) -> some View {
        Button {
            onJump(node)
            searchText = ""
            isSearchFocused = false
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(node.title ?? "Untitled")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let note = node.note, !note.isEmpty {
                        Text(note)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Show breadcrumb path
                    if let parent = node.parent {
                        Text("in \(parent.title ?? "parent")")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                Spacer()
                
                if let iconName = node.iconName {
                    Image(systemName: iconName)
                        .foregroundColor(Color(hex: node.colorHex ?? "#6AAFF0") ?? AtlasTheme.Colors.primary)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
