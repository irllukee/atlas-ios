import SwiftUI

// MARK: - Quick Action Models
struct QuickAction: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: QuickActionType
    let category: QuickActionCategory
    let isEnabled: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color,
        action: QuickActionType,
        category: QuickActionCategory,
        isEnabled: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
        self.category = category
        self.isEnabled = isEnabled
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: QuickAction, rhs: QuickAction) -> Bool {
        return lhs.id == rhs.id
    }
}

enum QuickActionType {
    case createNote
    case createTask
    case createJournalEntry
    case logMood
    case search
    case viewAnalytics
    case viewCalendar
    case exportData
    case settings
    case custom(String)
}

enum QuickActionCategory: String, CaseIterable {
    case create = "Create"
    case navigate = "Navigate"
    case tools = "Tools"
    case shortcuts = "Shortcuts"
    
    var icon: String {
        switch self {
        case .create: return "plus.circle.fill"
        case .navigate: return "arrow.right.circle.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .shortcuts: return "bolt.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .create: return .green
        case .navigate: return .blue
        case .tools: return .orange
        case .shortcuts: return .purple
        }
    }
}

// MARK: - Quick Actions View
struct QuickActionsView: View {
    @StateObject private var viewModel = QuickActionsViewModel()
    @State private var selectedCategory: QuickActionCategory = .create
    @State private var showingCustomActionSheet = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Selector
                categorySelector
                
                // Quick Actions Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.getActions(for: selectedCategory)) { action in
                            QuickActionCard(action: action) {
                                viewModel.performAction(action)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCustomActionSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCustomActionSheet) {
                CustomActionSheet { customAction in
                    viewModel.addCustomAction(customAction)
                }
            }
        }
    }
    
    // MARK: - Category Selector
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(QuickActionCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: QuickActionCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : .clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: action.icon)
                    .font(.system(size: 32))
                    .foregroundColor(action.color)
                
                VStack(spacing: 4) {
                    Text(action.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if let subtitle = action.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(action.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!action.isEnabled)
        .opacity(action.isEnabled ? 1.0 : 0.6)
    }
}

// MARK: - Custom Action Sheet
struct CustomActionSheet: View {
    let onSave: (QuickAction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var subtitle = ""
    @State private var icon = "star.fill"
    @State private var color: Color = .blue
    @State private var category: QuickActionCategory = .shortcuts
    
    private let availableIcons = [
        "star.fill", "heart.fill", "bookmark.fill", "flag.fill",
        "bell.fill", "gear.fill", "house.fill", "person.fill",
        "envelope.fill", "phone.fill", "camera.fill", "music.note"
    ]
    
    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .gray
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Action Details") {
                    TextField("Title", text: $title)
                    TextField("Subtitle (optional)", text: $subtitle)
                }
                
                Section("Appearance") {
                    Picker("Icon", selection: $icon) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            HStack {
                                Image(systemName: iconName)
                                Text(iconName)
                            }
                            .tag(iconName)
                        }
                    }
                    
                    Picker("Color", selection: $color) {
                        ForEach(availableColors, id: \.self) { colorOption in
                            HStack {
                                Circle()
                                    .fill(colorOption)
                                    .frame(width: 20, height: 20)
                                Text(colorOption.description)
                            }
                            .tag(colorOption)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(QuickActionCategory.allCases, id: \.self) { categoryOption in
                            Text(categoryOption.rawValue).tag(categoryOption)
                        }
                    }
                }
            }
            .navigationTitle("Custom Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAction()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveAction() {
        let customAction = QuickAction(
            title: title,
            subtitle: subtitle.isEmpty ? nil : subtitle,
            icon: icon,
            color: color,
            action: .custom(title),
            category: category
        )
        
        onSave(customAction)
        dismiss()
    }
}

// MARK: - Quick Actions ViewModel
@MainActor
class QuickActionsViewModel: ObservableObject {
    @Published var actions: [QuickAction] = []
    @Published var customActions: [QuickAction] = []
    
    init() {
        loadDefaultActions()
        loadCustomActions()
    }
    
    func getActions(for category: QuickActionCategory) -> [QuickAction] {
        let allActions = actions + customActions
        return allActions.filter { $0.category == category }
    }
    
    func performAction(_ action: QuickAction) {
        // Handle the action based on type
        switch action.action {
        case .createNote:
            // Navigate to create note
            print("Create note")
        case .createTask:
            // Navigate to create task
            print("Create task")
        case .createJournalEntry:
            // Navigate to create journal entry
            print("Create journal entry")
        case .logMood:
            // Navigate to mood logging
            print("Log mood")
        case .search:
            // Navigate to search
            print("Open search")
        case .viewAnalytics:
            // Navigate to analytics
            print("View analytics")
        case .viewCalendar:
            // Navigate to calendar
            print("View calendar")
        case .exportData:
            // Navigate to export
            print("Export data")
        case .settings:
            // Navigate to settings
            print("Open settings")
        case .custom(let title):
            // Handle custom action
            print("Custom action: \(title)")
        }
    }
    
    func addCustomAction(_ action: QuickAction) {
        customActions.append(action)
        saveCustomActions()
    }
    
    func removeCustomAction(_ action: QuickAction) {
        customActions.removeAll { $0.id == action.id }
        saveCustomActions()
    }
    
    private func loadDefaultActions() {
        actions = [
            // Create Actions
            QuickAction(
                title: "New Note",
                subtitle: "Quick note",
                icon: "note.text",
                color: .blue,
                action: .createNote,
                category: .create
            ),
            QuickAction(
                title: "New Task",
                subtitle: "Add task",
                icon: "checkmark.circle",
                color: .green,
                action: .createTask,
                category: .create
            ),
            QuickAction(
                title: "Journal Entry",
                subtitle: "Write thoughts",
                icon: "book.fill",
                color: .purple,
                action: .createJournalEntry,
                category: .create
            ),
            QuickAction(
                title: "Log Mood",
                subtitle: "How are you?",
                icon: "face.smiling",
                color: .orange,
                action: .logMood,
                category: .create
            ),
            
            // Navigate Actions
            QuickAction(
                title: "Search",
                subtitle: "Find content",
                icon: "magnifyingglass",
                color: .blue,
                action: .search,
                category: .navigate
            ),
            QuickAction(
                title: "Analytics",
                subtitle: "View insights",
                icon: "chart.bar.fill",
                color: .green,
                action: .viewAnalytics,
                category: .navigate
            ),
            QuickAction(
                title: "Calendar",
                subtitle: "View schedule",
                icon: "calendar",
                color: .orange,
                action: .viewCalendar,
                category: .navigate
            ),
            
            // Tools Actions
            QuickAction(
                title: "Export Data",
                subtitle: "Backup content",
                icon: "square.and.arrow.up",
                color: .purple,
                action: .exportData,
                category: .tools
            ),
            QuickAction(
                title: "Settings",
                subtitle: "App preferences",
                icon: "gear",
                color: .gray,
                action: .settings,
                category: .tools
            )
        ]
    }
    
    private func loadCustomActions() {
        if let data = UserDefaults.standard.data(forKey: "AtlasCustomActions"),
           let actions = try? JSONDecoder().decode([QuickAction].self, from: data) {
            customActions = actions
        }
    }
    
    private func saveCustomActions() {
        if let data = try? JSONEncoder().encode(customActions) {
            UserDefaults.standard.set(data, forKey: "AtlasCustomActions")
        }
    }
}

// MARK: - Quick Action Extensions
extension QuickAction: Codable {
    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, icon, color, action, category, isEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode basic properties
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        icon = try container.decode(String.self, forKey: .icon)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        
        // Decode color
        let colorData = try container.decode(Data.self, forKey: .color)
        if #available(iOS 12.0, *) {
            color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)?.asSwiftUIColor ?? .blue
        } else {
            color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? Color ?? .blue
        }
        
        // Decode action
        let actionString = try container.decode(String.self, forKey: .action)
        if actionString.hasPrefix("custom:") {
            action = .custom(String(actionString.dropFirst(7)))
        } else {
            // Handle other action types
            action = .custom(actionString)
        }
        
        // Decode category
        let categoryString = try container.decode(String.self, forKey: .category)
        category = QuickActionCategory(rawValue: categoryString) ?? .shortcuts
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encode(icon, forKey: .icon)
        try container.encode(isEnabled, forKey: .isEnabled)
        
        // Encode color
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
        
        // Encode action
        let actionString: String
        switch action {
        case .custom(let title):
            actionString = "custom:\(title)"
        default:
            actionString = "unknown"
        }
        try container.encode(actionString, forKey: .action)
        
        try container.encode(category.rawValue, forKey: .category)
    }
}

// MARK: - Extensions
extension UIColor {
    var asSwiftUIColor: Color {
        return Color(self)
    }
}

// MARK: - Preview
struct QuickActionsView_Previews: PreviewProvider {
    static var previews: some View {
        QuickActionsView()
    }
}
