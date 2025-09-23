import SwiftUI
import CoreData

// MARK: - Task Tab Form View

struct TaskTabFormView: View {
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    @State private var name = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "folder"
    
    private let colors = ["red", "orange", "yellow", "green", "blue", "indigo", "purple", "pink"]
    private let icons = ["folder", "star", "heart", "house", "person", "briefcase", "book", "gamecontroller", "music.note", "camera"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tab Details") {
                    TextField("Tab Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .shadow(radius: selectedColor == color ? 3 : 1)
                            }
                        }
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : colorFromString(selectedColor))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? colorFromString(selectedColor) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(colorFromString(selectedColor), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                
                Section("Preview") {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundColor(colorFromString(selectedColor))
                            
                            Text(name.isEmpty ? "Tab Name" : name)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text("0")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(colorFromString(selectedColor))
                                .cornerRadius(8)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorFromString(selectedColor).opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(colorFromString(selectedColor), lineWidth: 2)
                                )
                        )
                        Spacer()
                    }
                }
            }
            .navigationTitle("New Tab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTab()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
    
    private func saveTab() {
        let tab = TaskTab(context: context)
        tab.name = name
        tab.colorName = selectedColor
        tab.iconName = selectedIcon
        
        do {
            try context.save()
            onSave()
            dismiss()
        } catch {
            print("Error saving tab: \(error)")
        }
    }
}
