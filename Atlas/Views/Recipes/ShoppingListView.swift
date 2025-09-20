import SwiftUI

struct ShoppingListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var shoppingListService: ShoppingListService
    
    @State private var items: [ShoppingListItem] = []
    @State private var newItemName = ""
    @State private var newItemAmount = 1.0
    @State private var newItemUnit = ""
    @State private var showingAddItem = false
    @State private var showingClearCompleted = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AtlasTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Quick Add Section
                    quickAddSection
                    
                    // Items List
                    itemsListSection
                }
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AtlasTheme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingClearCompleted = true
                        }) {
                            Label("Clear Completed", systemImage: "checkmark.circle")
                        }
                        .disabled(items.filter { $0.isCompleted }.isEmpty)
                        
                        Button(action: {
                            shoppingListService.clearCompletedItems()
                            loadItems()
                        }) {
                            Label("Clear All", systemImage: "trash")
                        }
                        .disabled(items.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AtlasTheme.Colors.text)
                    }
                }
            }
        }
        .onAppear {
            loadItems()
        }
        .alert("Clear Completed Items?", isPresented: $showingClearCompleted) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                shoppingListService.clearCompletedItems()
                loadItems()
            }
        } message: {
            Text("This will remove all checked items from your shopping list.")
        }
    }
    
    // MARK: - Quick Add Section
    private var quickAddSection: some View {
        FrostedCard(style: .compact) {
            HStack(spacing: AtlasTheme.Spacing.md) {
                // Item Name Input
                TextField("Add item...", text: $newItemName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AtlasTheme.Typography.body)
                
                // Amount Input
                TextField("Qty", value: $newItemAmount, format: .number)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AtlasTheme.Typography.body)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                
                // Unit Input
                TextField("Unit", text: $newItemUnit)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(AtlasTheme.Typography.body)
                    .frame(width: 60)
                
                // Add Button
                Button(action: addNewItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AtlasTheme.Colors.primary)
                }
                .disabled(newItemName.isEmpty)
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.top, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Items List Section
    private var itemsListSection: some View {
        ScrollView {
            LazyVStack(spacing: AtlasTheme.Spacing.sm) {
                // Active Items
                if !activeItems.isEmpty {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        HStack {
                            Text("To Buy (\(activeItems.count))")
                                .font(AtlasTheme.Typography.headline)
                                .foregroundColor(AtlasTheme.Colors.text)
                            Spacer()
                        }
                        .padding(.horizontal, AtlasTheme.Spacing.lg)
                        
                        ForEach(activeItems, id: \.uuid) { item in
                            ShoppingListItemRow(
                                item: item,
                                onToggle: {
                                    shoppingListService.toggleItemCompletion(item)
                                    loadItems()
                                },
                                onDelete: {
                                    shoppingListService.deleteItem(item)
                                    loadItems()
                                }
                            )
                        }
                    }
                }
                
                // Completed Items
                if !completedItems.isEmpty {
                    VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                        HStack {
                            Text("Completed (\(completedItems.count))")
                                .font(AtlasTheme.Typography.headline)
                                .foregroundColor(AtlasTheme.Colors.text)
                            Spacer()
                        }
                        .padding(.horizontal, AtlasTheme.Spacing.lg)
                        .padding(.top, activeItems.isEmpty ? 0 : AtlasTheme.Spacing.lg)
                        
                        ForEach(completedItems, id: \.uuid) { item in
                            ShoppingListItemRow(
                                item: item,
                                onToggle: {
                                    shoppingListService.toggleItemCompletion(item)
                                    loadItems()
                                },
                                onDelete: {
                                    shoppingListService.deleteItem(item)
                                    loadItems()
                                }
                            )
                        }
                    }
                }
                
                // Empty State
                if items.isEmpty {
                    emptyStateView
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: AtlasTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(AtlasTheme.Colors.primary)
            
            VStack(spacing: AtlasTheme.Spacing.sm) {
                Text("Shopping List is Empty")
                    .font(AtlasTheme.Typography.title)
                    .fontWeight(.bold)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Add items manually or import from recipes")
                    .font(AtlasTheme.Typography.body)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, AtlasTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Computed Properties
    private var activeItems: [ShoppingListItem] {
        items.filter { !$0.isCompleted }
    }
    
    private var completedItems: [ShoppingListItem] {
        items.filter { $0.isCompleted }
    }
    
    // MARK: - Helper Methods
    private func loadItems() {
        items = shoppingListService.fetchItems()
    }
    
    private func addNewItem() {
        guard !newItemName.isEmpty else { return }
        
        _ = shoppingListService.addItem(
            name: newItemName,
            amount: newItemAmount,
            unit: newItemUnit.isEmpty ? nil : newItemUnit
        )
        
        newItemName = ""
        newItemAmount = 1.0
        newItemUnit = ""
        loadItems()
    }
}

// MARK: - Shopping List Item Row Component
struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        FrostedCard(style: .compact) {
            HStack(spacing: AtlasTheme.Spacing.md) {
                // Checkbox
                Button(action: onToggle) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(item.isCompleted ? AtlasTheme.Colors.primary : AtlasTheme.Colors.secondaryText)
                }
                
                // Item Info
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.xs) {
                    Text(item.name ?? "Unknown Item")
                        .font(AtlasTheme.Typography.body)
                        .foregroundColor(item.isCompleted ? AtlasTheme.Colors.secondaryText : AtlasTheme.Colors.text)
                        .strikethrough(item.isCompleted)
                    
                    HStack(spacing: AtlasTheme.Spacing.sm) {
                        if item.amount > 0 {
                            Text("\(item.amount, specifier: "%.1f")")
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                        
                        if let unit = item.unit, !unit.isEmpty {
                            Text(unit)
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(AtlasTheme.Colors.secondaryText)
                        }
                        
                        if let sourceRecipe = item.sourceRecipe {
                            HStack(spacing: AtlasTheme.Spacing.xs) {
                                Image(systemName: "fork.knife")
                                    .font(.caption2)
                                Text(sourceRecipe.title ?? "Recipe")
                                    .font(AtlasTheme.Typography.caption)
                            }
                            .foregroundColor(AtlasTheme.Colors.primary)
                        }
                    }
                    
                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(AtlasTheme.Typography.caption2)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                            .italic()
                    }
                }
                
                Spacer()
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .opacity(item.isCompleted ? 0.6 : 1.0)
        .animation(AtlasTheme.Animations.smooth, value: item.isCompleted)
    }
}

#Preview {
    ShoppingListView(shoppingListService: ShoppingListService(dataManager: DataManager.shared))
}

