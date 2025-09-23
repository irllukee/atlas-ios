import SwiftUI
import CoreData

// MARK: - Create Journal Entry View
struct CreateJournalEntryView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedType = JournalEntryType.daily
    @State private var isEncrypted = false
    @State private var selectedTemplate: JournalTemplate?
    @State private var showingTemplates = false
    
    // Mood tracking
    @State private var selectedMoodLevel = 5
    @State private var selectedMoodScale = MoodScale.fivePoint
    @State private var includeMood = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Mood Tracking Section
                    if includeMood {
                        moodTrackingSection
                    }
                    
                    // Entry Type Selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entry Type")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(JournalEntryType.allCases, id: \.self) { type in
                                TypeSelectionCard(
                                    type: type,
                                    isSelected: selectedType == type,
                                    action: { selectedType = type }
                                )
                            }
                        }
                    }
                    
                    // Template Selection
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Template")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Browse Templates") {
                                showingTemplates = true
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                        
                        if let template = selectedTemplate {
                            TemplateCard(template: template) {
                                selectedTemplate = nil
                                content = ""
                            }
                        }
                    }
                    
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title (Optional)")
                            .font(.headline)
                        
                        TextField("Enter a title for your entry...", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Content Editor
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.headline)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Options")
                            .font(.headline)
                        
                        Toggle("Include mood tracking", isOn: $includeMood)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        
                        Toggle("Encrypt this entry", isOn: $isEncrypted)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        
                        if isEncrypted {
                            Label("This entry will be encrypted and secure", systemImage: "lock.shield")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.createEntry(
                            title: title.isEmpty ? nil : title,
                            content: content,
                            type: selectedType,
                            isEncrypted: isEncrypted
                        )
                        
                        // Log mood if included
                        if includeMood {
                            viewModel.logMood(
                                level: selectedMoodLevel,
                                scale: selectedMoodScale,
                                notes: nil
                            )
                        }
                        
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
            .sheet(isPresented: $showingTemplates) {
                TemplateSelectionView(
                    selectedType: selectedType,
                    onTemplateSelected: { template in
                        selectedTemplate = template
                        content = template.content ?? ""
                    }
                )
            }
        }
    }
    
    // MARK: - Mood Tracking Section
    private var moodTrackingSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rate Your Mood")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(selectedMoodScale.description(for: selectedMoodLevel)) \(selectedMoodLevel)/\(selectedMoodScale.range.upperBound)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.2))
                    )
            }
            
            // Mood Slider with Emojis
            VStack(spacing: 12) {
                HStack {
                    Button(action: { selectedMoodLevel = max(selectedMoodScale.range.lowerBound, selectedMoodLevel - 1) }) {
                        Image(systemName: "minus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Emoji faces
                    HStack(spacing: 8) {
                        ForEach(selectedMoodScale.range, id: \.self) { level in
                            Button(action: { selectedMoodLevel = level }) {
                                Text(selectedMoodScale.emoji(for: level))
                                    .font(.title)
                                    .scaleEffect(selectedMoodLevel == level ? 1.2 : 1.0)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedMoodLevel == level ? Color.accentColor : Color.clear, lineWidth: 2)
                                            .scaleEffect(1.3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { selectedMoodLevel = min(selectedMoodScale.range.upperBound, selectedMoodLevel + 1) }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Slider
                Slider(value: Binding(
                    get: { Double(selectedMoodLevel) },
                    set: { selectedMoodLevel = Int($0) }
                ), in: Double(selectedMoodScale.range.lowerBound)...Double(selectedMoodScale.range.upperBound), step: 1)
                .accentColor(.accentColor)
                .sensoryFeedback(.selection, trigger: selectedMoodLevel)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Type Selection Card
struct TypeSelectionCard: View {
    let type: JournalEntryType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.largeTitle)
                
                Text(type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: JournalTemplate
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name ?? "Untitled Template")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Template • \((template.content ?? "").count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Remove") {
                onRemove()
            }
            .font(.caption)
            .foregroundColor(.red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
        )
    }
}

// MARK: - Template Selection View
struct TemplateSelectionView: View {
    let selectedType: JournalEntryType
    let onTemplateSelected: (JournalTemplate) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var templates: [JournalTemplate] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading templates...")
                } else if templates.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No templates available",
                        subtitle: "Templates help you get started with structured entries",
                        buttonTitle: "Create Custom Template",
                        action: { /* Handle custom template creation */ }
                    )
                } else {
                    List(templates) { template in
                        JournalTemplateRow(template: template) {
                            onTemplateSelected(template)
                            dismiss()
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("\(selectedType.displayName) Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadTemplates()
        }
    }
    
    private func loadTemplates() {
        _Concurrency.Task {
            defer { isLoading = false }
            
            do {
                let repository = DependencyContainer.shared.journalRepository
                templates = try await repository.fetchTemplates(for: selectedType)
            } catch {
                print("Error loading templates: \(error)")
            }
        }
    }
}

// MARK: - Template Row
struct JournalTemplateRow: View {
    let template: JournalTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.name ?? "Untitled Template")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if template.isBuiltIn {
                        Text("Built-in")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.accentColor)
                            )
                    }
                }
                
                Text((template.content ?? "").prefix(100) + ((template.content ?? "").count > 100 ? "..." : ""))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    Label("Used \(template.usageCount) times", systemImage: "chart.bar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text((template.createdAt ?? Date()).formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
