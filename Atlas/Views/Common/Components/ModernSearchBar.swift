import SwiftUI

/// Modern, reusable search bar component with glassmorphism effects and animations
struct ModernSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onSearch: (String) -> Void
    let onClear: () -> Void
    
    @State private var isFocused = false
    @State private var searchIconRotation: Double = 0
    @State private var clearButtonScale: CGFloat = 0.8
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search...",
        onSearch: @escaping (String) -> Void = { _ in },
        onClear: @escaping () -> Void = {}
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onSearch = onSearch
        self.onClear = onClear
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Search Icon with Animation
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isFocused ? AtlasTheme.Colors.primary : AtlasTheme.Colors.text.opacity(0.6))
                .rotationEffect(.degrees(searchIconRotation))
                .animation(.easeInOut(duration: 0.3), value: searchIconRotation)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Text Field
            TextField(placeholder, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AtlasTheme.Colors.text)
                .onSubmit {
                    onSearch(searchText)
                }
                .onChange(of: searchText) { _, newValue in
                    onSearch(newValue)
                }
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFocused = true
                        searchIconRotation = 15
                    }
                }
            
            // Clear Button with Animation
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        searchText = ""
                        clearButtonScale = 1.2
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            clearButtonScale = 1.0
                        }
                    }
                    
                    onClear()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AtlasTheme.Colors.text.opacity(0.6))
                }
                .scaleEffect(clearButtonScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: clearButtonScale)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            ZStack {
                // Glass Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(AtlasTheme.Colors.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AtlasTheme.Colors.glassBorder.opacity(0.8),
                                        AtlasTheme.Colors.glassBorder.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Focus Glow Effect
                if isFocused {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AtlasTheme.Colors.primary.opacity(0.6),
                                    AtlasTheme.Colors.primary.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .blur(radius: 4)
                        .opacity(0.8)
                }
            }
        )
        .shadow(
            color: isFocused ? AtlasTheme.Colors.primary.opacity(0.2) : Color.black.opacity(0.1),
            radius: isFocused ? 8 : 4,
            x: 0,
            y: isFocused ? 4 : 2
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onTapGesture {
            // Handle tap outside to lose focus
            if !isFocused {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = true
                    searchIconRotation = 15
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = false
                    searchIconRotation = 0
                }
            }
        }
    }
}

/// Enhanced search bar with suggestions and filters
struct ModernSearchBarWithSuggestions: View {
    @Binding var searchText: String
    let placeholder: String
    let suggestions: [String]
    let onSearch: (String) -> Void
    let onClear: () -> Void
    let onSuggestionTap: (String) -> Void
    
    @State private var isFocused = false
    @State private var showingSuggestions = false
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search...",
        suggestions: [String] = [],
        onSearch: @escaping (String) -> Void = { _ in },
        onClear: @escaping () -> Void = {},
        onSuggestionTap: @escaping (String) -> Void = { _ in }
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.suggestions = suggestions
        self.onSearch = onSearch
        self.onClear = onClear
        self.onSuggestionTap = onSuggestionTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Search Bar
            ModernSearchBar(
                searchText: $searchText,
                placeholder: placeholder,
                onSearch: onSearch,
                onClear: onClear
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused = true
                    showingSuggestions = !suggestions.isEmpty && !searchText.isEmpty
                }
            }
            
            // Suggestions Dropdown
            if showingSuggestions && !suggestions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            searchText = suggestion
                            onSuggestionTap(suggestion)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingSuggestions = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AtlasTheme.Colors.text.opacity(0.6))
                                
                                Text(suggestion)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AtlasTheme.Colors.text)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if suggestion != suggestions.last {
                            Divider()
                                .background(AtlasTheme.Colors.glassBorder.opacity(0.3))
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AtlasTheme.Colors.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AtlasTheme.Colors.glassBorder.opacity(0.5), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Preview
struct ModernSearchBar_Previews: PreviewProvider {
    @State static var searchText = ""
    
    static var previews: some View {
        VStack(spacing: 20) {
            ModernSearchBar(
                searchText: $searchText,
                placeholder: "Search notes...",
                onSearch: { text in
                    print("Searching for: \(text)")
                },
                onClear: {
                    print("Cleared search")
                }
            )
            
            ModernSearchBarWithSuggestions(
                searchText: $searchText,
                placeholder: "Search with suggestions...",
                suggestions: ["Recent search", "Popular tag", "Smart suggestion"],
                onSearch: { text in
                    print("Searching for: \(text)")
                },
                onClear: {
                    print("Cleared search")
                },
                onSuggestionTap: { suggestion in
                    print("Selected suggestion: \(suggestion)")
                }
            )
        }
        .padding()
        .background(AtlasTheme.Colors.background)
        .previewLayout(.sizeThatFits)
    }
}

