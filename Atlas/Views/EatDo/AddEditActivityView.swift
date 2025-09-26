import SwiftUI

struct AddEditActivityView: View {
    @ObservedObject var eatDoService: EatDoService
    @Environment(\.dismiss) private var dismiss
    
    // Form Fields
    @State private var name = ""
    @State private var city = ""
    @State private var state = ""
    @State private var rating = 5
    @State private var pros = ""
    @State private var cons = ""
    @State private var priceRange = 2
    @State private var category = "Outdoor"
    
    // UI State
    @State private var isSubmitting = false
    
    private var isFormValid: Bool {
        !name.isEmpty && !city.isEmpty && !state.isEmpty
    }
    
    var body: some View {
        ZStack {
            AtlasTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Form Content
                ScrollView {
                    VStack(spacing: AtlasTheme.Spacing.lg) {
                        // Basic Information
                        basicInfoSection
                        
                        // Rating and Price
                        ratingAndPriceSection
                        
                        // Category
                        categorySection
                        
                        // Pros and Cons
                        prosAndConsSection
                    }
                    .padding(.horizontal, AtlasTheme.Spacing.lg)
                    .padding(.bottom, AtlasTheme.Spacing.xl)
                }
                
                // Submit Button
                submitButton
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                AtlasTheme.Haptics.light()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
                    .frame(width: 44, height: 44)
                    .glassmorphism(style: .light, cornerRadius: 22)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Add Activity")
                    .font(AtlasTheme.Typography.largeTitle)
                    .foregroundColor(AtlasTheme.Colors.text)
                
                Text("Share your favorite activity")
                    .font(AtlasTheme.Typography.subheadline)
                    .foregroundColor(AtlasTheme.Colors.secondaryText)
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.top, AtlasTheme.Spacing.md)
        .padding(.bottom, AtlasTheme.Spacing.lg)
    }
    
    // MARK: - Basic Information Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Basic Information")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            VStack(spacing: AtlasTheme.Spacing.md) {
                // Activity Name
                AtlasTextField(
                    "Activity Name",
                    placeholder: "Enter activity name",
                    text: $name,
                    icon: "figure.walk"
                )
                
                // City and State
                HStack(spacing: AtlasTheme.Spacing.md) {
                    AtlasTextField(
                        "City",
                        placeholder: "Enter city",
                        text: $city,
                        icon: "building.2"
                    )
                    
                    AtlasTextField(
                        "State",
                        placeholder: "Enter state",
                        text: $state,
                        icon: "location"
                    )
                }
            }
        }
    }
    
    // MARK: - Rating and Price Section
    private var ratingAndPriceSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Rating & Price")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            HStack(spacing: AtlasTheme.Spacing.lg) {
                // Rating
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Rating: \(rating)/10")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    
                    HStack(spacing: 4) {
                        ForEach(1...10, id: \.self) { star in
                            Button(action: {
                                AtlasTheme.Haptics.selection()
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(AtlasTheme.Colors.warning)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Price Range
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    Text("Price Range")
                        .font(AtlasTheme.Typography.caption)
                        .foregroundColor(AtlasTheme.Colors.secondaryText)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { price in
                            Button(action: {
                                AtlasTheme.Haptics.selection()
                                priceRange = price
                            }) {
                                Text("$")
                                    .font(AtlasTheme.Typography.title3)
                                    .foregroundColor(price <= priceRange ? AtlasTheme.Colors.accent : AtlasTheme.Colors.secondaryText)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Category Section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Category")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AtlasTheme.Spacing.sm) {
                    ForEach(EatDoCategories.activityCategories, id: \.self) { cat in
                        Button(action: {
                            AtlasTheme.Haptics.selection()
                            category = cat
                        }) {
                            Text(cat)
                                .font(AtlasTheme.Typography.caption)
                                .foregroundColor(category == cat ? AtlasTheme.Colors.text : AtlasTheme.Colors.secondaryText)
                                .padding(.horizontal, AtlasTheme.Spacing.md)
                                .padding(.vertical, AtlasTheme.Spacing.sm)
                                .glassmorphism(
                                    style: category == cat ? .medium : .light,
                                    cornerRadius: AtlasTheme.CornerRadius.medium
                                )
                        }
                    }
                }
                .padding(.horizontal, AtlasTheme.Spacing.lg)
            }
        }
    }
    
    // MARK: - Pros and Cons Section
    private var prosAndConsSection: some View {
        VStack(alignment: .leading, spacing: AtlasTheme.Spacing.md) {
            Text("Pros & Cons")
                .font(AtlasTheme.Typography.title3)
                .foregroundColor(AtlasTheme.Colors.text)
            
            VStack(spacing: AtlasTheme.Spacing.md) {
                // Pros
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AtlasTheme.Colors.success)
                        Text("Pros")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    AtlasTextEditor(
                        "Pros",
                        placeholder: "What did you love about this activity?",
                        text: $pros
                    )
                }
                
                // Cons
                VStack(alignment: .leading, spacing: AtlasTheme.Spacing.sm) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AtlasTheme.Colors.error)
                        Text("Cons")
                            .font(AtlasTheme.Typography.caption)
                            .foregroundColor(AtlasTheme.Colors.secondaryText)
                    }
                    
                    AtlasTextEditor(
                        "Cons",
                        placeholder: "What could be improved?",
                        text: $cons
                    )
                }
            }
        }
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: submitActivity) {
            HStack(spacing: AtlasTheme.Spacing.sm) {
                if isSubmitting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(AtlasTheme.Colors.text)
                } else {
                    Image(systemName: "plus")
                        .font(.title3)
                }
                
                Text(isSubmitting ? "Adding..." : "Add Activity")
                    .font(AtlasTheme.Typography.button)
            }
            .foregroundColor(AtlasTheme.Colors.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AtlasTheme.Spacing.md)
            .glassmorphism(
                style: isFormValid ? .medium : .light,
                cornerRadius: AtlasTheme.CornerRadius.medium
            )
        }
        .disabled(!isFormValid || isSubmitting)
        .padding(.horizontal, AtlasTheme.Spacing.lg)
        .padding(.bottom, AtlasTheme.Spacing.md)
    }
    
    // MARK: - Actions
    private func submitActivity() {
        guard isFormValid else { return }
        
        AtlasTheme.Haptics.success()
        isSubmitting = true
        
        let activity = Activity(
            name: name,
            city: city,
            state: state,
            rating: rating,
            pros: pros,
            cons: cons,
            priceRange: priceRange,
            category: category
        )
        
        eatDoService.addActivity(activity)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            dismiss()
        }
    }
}

#Preview {
    AddEditActivityView(eatDoService: EatDoService())
}