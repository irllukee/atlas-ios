import SwiftUI
import CoreData

struct IconColorPicker: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var node: Node

    private let iconOptions = [
        "lightbulb.fill","bolt.fill","star.fill","bookmark.fill","target","flag.fill",
        "chart.bar.fill","list.bullet","hammer.fill","doc.text.fill","clock.fill",
        "link","leaf.fill","paperplane.fill","heart.fill","gear","tag.fill","camera.fill"
    ]
    private let colors = ["#6AAFF0","#9AD1F5","#7EE0D2","#F7D98D","#F2A38C","#E79AE6","#C7C7C7","#FFFFFF"]

    var body: some View {
        NavigationView {
            Form {
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            Button {
                                node.iconName = nil
                                save()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "nosign")
                                        .frame(width: 36, height: 36)
                                    Text("None")
                                        .font(.caption2)
                                }
                                .foregroundColor(node.iconName == nil ? .blue : .primary)
                            }
                            
                            ForEach(iconOptions, id: \.self) { name in
                                Button {
                                    node.iconName = name
                                    save()
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: name)
                                            .frame(width: 36, height: 36)
                                        Text(name.components(separatedBy: ".").first?.capitalized ?? "")
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(node.iconName == name ? .blue : .primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        Button {
                            node.colorHex = nil
                            save()
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(.secondary.opacity(0.3), lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "nosign")
                                }
                                Text("Default")
                                    .font(.caption2)
                            }
                            .foregroundColor(node.colorHex == nil ? .blue : .primary)
                        }

                        ForEach(colors, id: \.self) { hex in
                            Button {
                                node.colorHex = hex
                                save()
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .white)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(node.colorHex == hex ? .blue : .clear, lineWidth: 3)
                                        )
                                        .overlay(
                                            Circle().stroke(.white.opacity(0.6), lineWidth: 1)
                                        )
                                    Text(colorName(for: hex))
                                        .font(.caption2)
                                }
                                .foregroundColor(node.colorHex == hex ? .blue : .primary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func save() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save style changes: \(error)")
        }
    }
    
    private func colorName(for hex: String) -> String {
        switch hex {
        case "#6AAFF0": return "Blue"
        case "#9AD1F5": return "Light Blue"
        case "#7EE0D2": return "Teal"
        case "#F7D98D": return "Yellow"
        case "#F2A38C": return "Orange"
        case "#E79AE6": return "Purple"
        case "#C7C7C7": return "Gray"
        case "#FFFFFF": return "White"
        default: return "Custom"
        }
    }
}
