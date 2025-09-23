import SwiftUI

struct MoodQuickLogView: View {
    // MARK: - Properties
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var moodValue: Double = 5.0
    @State private var isSaving: Bool = false
    @State private var showSuccess: Bool = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text("Quick Mood Log")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("How are you feeling right now?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Mood Slider
                VStack(spacing: 20) {
                    // Current Mood Display
                    VStack(spacing: 12) {
                        Text(moodEmoji)
                            .font(.system(size: 60))
                        
                        Text(moodDescription)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(moodColor)
                        
                        Text("\(Int(moodValue))/10")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Slider
                    VStack(spacing: 12) {
                        HStack {
                            Text("😢")
                                .font(.title2)
                            Spacer()
                            Text("😊")
                                .font(.title2)
                        }
                        
                        Slider(value: $moodValue, in: 1...10, step: 1)
                            .accentColor(moodColor)
                            .onChange(of: moodValue) { _, newValue in
                                // Haptic feedback on change
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveMood) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        
                        Text(isSaving ? "Saving..." : "Save Mood")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(moodColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Mood Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay(
                // Success overlay
                Group {
                    if showSuccess {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Mood Saved!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    private var moodEmoji: String {
        switch Int(moodValue) {
        case 1...2: return "😢"
        case 3...4: return "😔"
        case 5...6: return "😐"
        case 7...8: return "😊"
        case 9...10: return "😄"
        default: return "😐"
        }
    }
    
    private var moodDescription: String {
        switch Int(moodValue) {
        case 1...2: return "Very Low"
        case 3...4: return "Low"
        case 5...6: return "Neutral"
        case 7...8: return "Good"
        case 9...10: return "Excellent"
        default: return "Neutral"
        }
    }
    
    private var moodColor: Color {
        switch Int(moodValue) {
        case 1...2: return .red
        case 3...4: return .orange
        case 5...6: return .yellow
        case 7...8: return .green
        case 9...10: return .blue
        default: return .yellow
        }
    }
    
    // MARK: - Actions
    private func saveMood() {
        isSaving = true
        
        // Create mood entry
        dataManager.createMoodEntry(
            moodLevel: Int16(moodValue),
            emoji: moodEmoji,
            notes: nil
        )
        
        // Haptic feedback
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        // Show success animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            showSuccess = true
        }
    }
}

// MARK: - Preview
struct MoodQuickLogView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DataManager.shared
        
        MoodQuickLogView(dataManager: dataManager)
    }
}

