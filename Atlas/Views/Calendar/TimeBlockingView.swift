import SwiftUI

struct TimeBlockingView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var duration: TimeInterval = 3600 // 1 hour
    @State private var notes: String = ""
    @State private var workingHours: (start: Int, end: Int) = (9, 17)
    @State private var availableSlots: [DateInterval] = []
    @State private var selectedSlot: DateInterval?
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Time Block Details") {
                        TextField("Block Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                    
                    Section("Duration") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration: \(formatDuration(duration))")
                                .font(.headline)
                            
                            Slider(value: $duration, in: 900...14400, step: 900) // 15 minutes to 4 hours
                                .onChange(of: duration) {
                                    findAvailableSlots()
                                }
                        }
                        
                        HStack {
                            ForEach([0.5, 1, 1.5, 2, 3, 4], id: \.self) { hours in
                                Button("\(Int(hours * 60))m") {
                                    duration = hours * 3600
                                    findAvailableSlots()
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                    }
                    
                    Section("Working Hours") {
                        HStack {
                            Text("Start")
                            Spacer()
                            Picker("Start Hour", selection: $workingHours.start) {
                                ForEach(6...12, id: \.self) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: workingHours.start) {
                                findAvailableSlots()
                            }
                        }
                        
                        HStack {
                            Text("End")
                            Spacer()
                            Picker("End Hour", selection: $workingHours.end) {
                                ForEach(13...22, id: \.self) { hour in
                                    Text("\(hour):00").tag(hour)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .onChange(of: workingHours.end) {
                                findAvailableSlots()
                            }
                        }
                    }
                    
                    Section("Available Time Slots") {
                        if availableSlots.isEmpty {
                            Text("No available time slots found for the selected duration.")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(Array(availableSlots.enumerated()), id: \.offset) { index, slot in
                                Button(action: {
                                    selectedSlot = slot
                                    startDate = slot.start
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(slot.start, formatter: timeFormatter)
                                                .font(.headline)
                                            Text("Duration: \(formatDuration(duration))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedSlot == slot {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("Time Blocking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Block") {
                        createTimeBlock()
                    }
                    .disabled(title.isEmpty || selectedSlot == nil || viewModel.isLoading)
                }
            }
            .onAppear {
                findAvailableSlots()
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView()
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    private func findAvailableSlots() {
        availableSlots = viewModel.findAvailableTimeSlots(
            duration: duration,
            workingHours: workingHours
        )
    }
    
    private func createTimeBlock() {
        guard let slot = selectedSlot else { return }
        
        viewModel.createTimeBlock(
            title: title,
            startDate: slot.start,
            duration: duration,
            notes: notes.isEmpty ? nil : notes
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
struct TimeBlockingView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CalendarViewModel()
        TimeBlockingView(viewModel: viewModel)
    }
}
