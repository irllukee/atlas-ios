import SwiftUI
import CoreData

struct TabbedTasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var dataManager: DataManager
    @StateObject private var viewModel: TabbedTasksViewModel
    
    init(dataManager: DataManager) {
        self.dataManager = dataManager
        _viewModel = StateObject(wrappedValue: TabbedTasksViewModel(dataManager: dataManager))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Main Content Area
            VStack(spacing: 0) {
                // Header with search and actions
                VStack(spacing: 12) {
                    // Modern Search Bar
                    ModernSearchBar(
                        searchText: $viewModel.searchText,
                        placeholder: "Search tasks...",
                        onSearch: { query in
                            viewModel.searchTasks(query: query)
                        },
                        onClear: {
                            viewModel.searchTasks(query: "")
                        }
                    )
                    .padding(.horizontal, 16)
                    
                    // Action buttons
                    HStack {
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            viewModel.showingFilters.toggle() 
                        }) {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            viewModel.showingTemplates.toggle() 
                        }) {
                            Label("Templates", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Button(action: { 
                            AtlasTheme.Haptics.light()
                            viewModel.showingCreateTask.toggle() 
                        }) {
                            Label("Add Task", systemImage: "plus.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                // Tasks List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Tasks...")
                        .foregroundColor(.white)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if viewModel.filteredTasks.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        viewModel.selectedTab == nil ? "No Tab Selected" : "No Tasks",
                        systemImage: viewModel.selectedTab == nil ? "folder.badge.plus" : "checklist"
                    )
                    .foregroundColor(.white)
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredTasks) { task in
                            NavigationLink(destination: EditTaskView<TabbedTasksViewModel>(task: task, viewModel: viewModel)) {
                                TaskRow<TabbedTasksViewModel>(task: task, viewModel: viewModel)
                            }
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AtlasTheme.Colors.background)
            
            // Right Side Tab Bar
            VStack(spacing: 0) {
                // Tab header
                HStack {
                    Text("Tabs")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        AtlasTheme.Haptics.light()
                        viewModel.showingCreateTab.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AtlasTheme.Colors.primary.opacity(0.1))
                
                // Tabs list
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(viewModel.tabs, id: \.id) { tab in
                            TabRow(
                                tab: tab,
                                isSelected: viewModel.selectedTab?.id == tab.id,
                                onTap: { viewModel.selectTab(tab) },
                                onRename: { 
                                    viewModel.tabToRename = tab
                                    viewModel.newTabName = tab.displayName
                                    viewModel.showingRenameTab.toggle()
                                },
                                onDelete: { viewModel.deleteTab(tab) }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(AtlasTheme.Colors.background.opacity(0.5))
            }
            .frame(width: 120)
            .background(AtlasTheme.Colors.background.opacity(0.8))
        }
        .navigationTitle(viewModel.selectedTab?.displayName ?? "Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $viewModel.showingCreateTask) {
            CreateTaskView<TabbedTasksViewModel>(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingTemplates) {
            TaskTemplatesView<TabbedTasksViewModel>(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingFilters) {
            TasksFilterView<TabbedTasksViewModel>(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingCreateTab) {
            CreateTabView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingRenameTab) {
            RenameTabView(viewModel: viewModel)
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { viewModel.filteredTasks[$0] }.forEach(viewModel.deleteTask)
        }
    }
}

// MARK: - Tab Row Component
struct TabRow: View {
    let tab: TaskTab
    let isSelected: Bool
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    @State private var showingContextMenu = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Tab content
            Button(action: onTap) {
                VStack(spacing: 4) {
                    // Tab icon
                    Image(systemName: tab.displayIcon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    // Tab name
                    Text(tab.displayName)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .gray)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    // Task count
                    Text("\(tab.taskCount)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .gray.opacity(0.7))
                }
                .frame(width: 100, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AtlasTheme.Colors.primary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? AtlasTheme.Colors.primary : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                Button("Rename", action: onRename)
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
        .padding(.horizontal, 10)
    }
}

// MARK: - Create Tab View
struct CreateTabView: View {
    @ObservedObject var viewModel: TabbedTasksViewModel
    @State private var tabName: String = ""
    @State private var selectedColor: String = "blue"
    @State private var selectedIcon: String = "folder"
    
    private let colors = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "indigo"]
    private let icons = ["folder", "briefcase", "house", "heart", "star", "bolt", "book", "gamecontroller", "camera", "music.note"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tab Details") {
                    TextField("Tab Name", text: $tabName)
                    
                    Picker("Color", selection: $selectedColor) {
                        ForEach(colors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(Color(color))
                                    .frame(width: 20, height: 20)
                                Text(color.capitalized)
                            }
                            .tag(color)
                        }
                    }
                    
                    Picker("Icon", selection: $selectedIcon) {
                        ForEach(icons, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                Text(icon)
                            }
                            .tag(icon)
                        }
                    }
                }
            }
            .navigationTitle("New Tab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingCreateTab = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if !tabName.isEmpty {
                            viewModel.createTab(name: tabName, color: selectedColor, icon: selectedIcon)
                            tabName = ""
                        }
                    }
                    .disabled(tabName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Rename Tab View
struct RenameTabView: View {
    @ObservedObject var viewModel: TabbedTasksViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tab Name") {
                    TextField("Tab Name", text: $viewModel.newTabName)
                }
            }
            .navigationTitle("Rename Tab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showingRenameTab = false
                        viewModel.tabToRename = nil
                        viewModel.newTabName = ""
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let tab = viewModel.tabToRename, !viewModel.newTabName.isEmpty {
                            viewModel.renameTab(tab, newName: viewModel.newTabName)
                        }
                    }
                    .disabled(viewModel.newTabName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview
struct TabbedTasksView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        
        TabbedTasksView(dataManager: dataManager)
    }
}
