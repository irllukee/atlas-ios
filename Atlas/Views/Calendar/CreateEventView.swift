import SwiftUI
import EventKit

struct CreateEventView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600) // 1 hour later
    @State private var notes: String = ""
    @State private var location: String = ""
    @State private var eventType: EventType = .personal
    @State private var isAllDay: Bool = false
    @State private var reminderMinutes: [Int] = [15]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Event Details") {
                        TextField("Event Title", text: $title)
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
                        
                        TextField("Location", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Section("Date & Time") {
                        Toggle("All Day", isOn: $isAllDay)
                        
                        if !isAllDay {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                            
                            DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                        } else {
                            DatePicker("Date", selection: $startDate, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                    }
                    
                    Section("Event Type") {
                        Picker("Type", selection: $eventType) {
                            ForEach(EventType.allCases, id: \.self) { type in
                                HStack {
                                    Circle()
                                        .fill(Color(type.color))
                                        .frame(width: 12, height: 12)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Section("Reminders") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reminder Times")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                                ForEach([5, 15, 30, 60, 120, 1440], id: \.self) { minutes in
                                    Button(action: {
                                        toggleReminder(minutes)
                                    }) {
                                        Text(formatReminderTime(minutes))
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(reminderMinutes.contains(minutes) ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(reminderMinutes.contains(minutes) ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty || viewModel.isLoading)
                }
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
    private func saveEvent() {
        guard !title.isEmpty else { return }
        
        viewModel.createEvent(
            title: title,
            startDate: startDate,
            endDate: isAllDay ? startDate : endDate,
            notes: notes.isEmpty ? nil : notes,
            location: location.isEmpty ? nil : location,
            eventType: eventType,
            isAllDay: isAllDay,
            reminderMinutes: reminderMinutes
        )
    }
    
    private func toggleReminder(_ minutes: Int) {
        if reminderMinutes.contains(minutes) {
            reminderMinutes.removeAll { $0 == minutes }
        } else {
            reminderMinutes.append(minutes)
        }
    }
    
    private func formatReminderTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours)h"
        } else {
            let days = minutes / 1440
            return "\(days)d"
        }
    }
}

// MARK: - Preview
struct CreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CalendarViewModel()
        CreateEventView(viewModel: viewModel)
    }
}
