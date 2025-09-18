import SwiftUI
import EventKit

struct EventDetailView: View {
    // MARK: - Properties
    let event: EKEvent
    @ObservedObject var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var notes: String = ""
    @State private var location: String = ""
    @State private var isAllDay: Bool = false
    @State private var hasChanges = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Form {
                    Section("Event Details") {
                        TextField("Event Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: title) { checkForChanges() }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            TextEditor(text: $notes)
                                .frame(minHeight: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .onChange(of: notes) { checkForChanges() }
                        }
                        
                        TextField("Location", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: location) { checkForChanges() }
                    }
                    
                    Section("Date & Time") {
                        Toggle("All Day", isOn: $isAllDay)
                            .onChange(of: isAllDay) { checkForChanges() }
                        
                        if !isAllDay {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: startDate) { checkForChanges() }
                            
                            DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: endDate) { checkForChanges() }
                        } else {
                            DatePicker("Date", selection: $startDate, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: startDate) { checkForChanges() }
                        }
                    }
                    
                    Section("Event Info") {
                        HStack {
                            Text("Calendar")
                            Spacer()
                            Text(event.calendar?.title ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        if let url = event.url {
                            HStack {
                                Text("URL")
                                Spacer()
                                Link("Open", destination: url)
                            }
                        }
                        
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(event.creationDate?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Modified")
                            Spacer()
                            Text(event.lastModifiedDate?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let alarms = event.alarms, !alarms.isEmpty {
                        Section("Reminders") {
                            ForEach(alarms, id: \.self) { alarm in
                                HStack {
                                    Image(systemName: "bell")
                                    Text(formatAlarm(alarm))
                                }
                            }
                        }
                    }
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(!hasChanges || viewModel.isLoading)
                }
            }
            .onAppear {
                loadEventData()
            }
        }
    }
    
    // MARK: - Bottom Actions
    private var bottomActions: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                ProgressView("Saving event...")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            
            HStack(spacing: 12) {
                Button("Delete Event") {
                    deleteEvent()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                
                Button("Save Changes") {
                    saveEvent()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(!hasChanges || viewModel.isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    private func loadEventData() {
        title = event.title ?? ""
        startDate = event.startDate
        endDate = event.endDate
        notes = event.notes ?? ""
        location = event.location ?? ""
        isAllDay = event.isAllDay
    }
    
    private func checkForChanges() {
        hasChanges = title != (event.title ?? "") ||
                    notes != (event.notes ?? "") ||
                    location != (event.location ?? "") ||
                    startDate != event.startDate ||
                    endDate != event.endDate ||
                    isAllDay != event.isAllDay
    }
    
    private func saveEvent() {
        guard hasChanges else { return }
        
        viewModel.updateEvent(
            event,
            title: title,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            location: location,
            isAllDay: isAllDay
        )
        
        dismiss()
    }
    
    private func deleteEvent() {
        viewModel.deleteEvent(event)
        dismiss()
    }
    
    private func formatAlarm(_ alarm: EKAlarm) -> String {
        if let absoluteDate = alarm.absoluteDate {
            return "At \(absoluteDate.formatted(date: .omitted, time: .shortened))"
        } else {
            let relativeOffset = alarm.relativeOffset
            let minutes = Int(abs(relativeOffset) / 60)
            if minutes < 60 {
                return "\(minutes) minutes before"
            } else {
                let hours = minutes / 60
                return "\(hours) hour\(hours > 1 ? "s" : "") before"
            }
        }
    }
}

// MARK: - Preview
struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Note: In a real preview, you'd need to create a mock EKEvent
        // For now, this will show the structure
        Text("Event Detail View")
    }
}
