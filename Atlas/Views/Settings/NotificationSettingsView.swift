import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @State private var dailyJournalTime = Date()
    @State private var moodTrackingTime = Date()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: notificationService.isEnabled ? "bell.fill" : "bell.slash")
                            .foregroundColor(notificationService.isEnabled ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text("Notifications")
                                .font(.headline)
                            Text(notificationStatusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !notificationService.isEnabled {
                            Button("Enable") {
                                requestNotificationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } header: {
                    Text("Permission Status")
                } footer: {
                    Text("Atlas needs notification permission to send you reminders for tasks, events, and daily check-ins.")
                }
                
                if notificationService.isEnabled {
                    Section("Daily Reminders") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(.blue)
                                Text("Journal Prompt")
                                    .font(.headline)
                                Spacer()
                                Toggle("", isOn: .constant(true))
                                    .disabled(true)
                            }
                            
                            DatePicker("Time", selection: $dailyJournalTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: dailyJournalTime) { _, newValue in
                                    notificationService.scheduleDailyJournalPrompt(time: newValue)
                                }
                            
                            Text("Get reminded to write in your journal each day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text("Mood Check-in")
                                    .font(.headline)
                                Spacer()
                                Toggle("", isOn: .constant(true))
                                    .disabled(true)
                            }
                            
                            DatePicker("Time", selection: $moodTrackingTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(CompactDatePickerStyle())
                                .onChange(of: moodTrackingTime) { _, newValue in
                                    notificationService.scheduleMoodTrackingReminder(time: newValue)
                                }
                            
                            Text("Get reminded to log your mood each day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section("Task Reminders") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Task Due Dates")
                                    .font(.headline)
                            }
                            
                            Text("You'll receive reminders for tasks with due dates. Reminder times can be set when creating or editing tasks.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section("Calendar Reminders") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.orange)
                                Text("Event Reminders")
                                    .font(.headline)
                            }
                            
                            Text("You'll receive reminders for calendar events. Reminder times can be set when creating or editing events.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Section {
                        Button("Clear All Notifications") {
                            notificationService.removeAllNotifications()
                        }
                        .foregroundColor(.red)
                    } footer: {
                        Text("This will remove all pending notifications from Atlas.")
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadNotificationTimes()
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive reminders from Atlas.")
            }
        }
    }
    
    private var notificationStatusText: String {
        switch notificationService.authorizationStatus {
        case .authorized:
            return "Enabled - You'll receive reminders"
        case .denied:
            return "Disabled - Enable in Settings"
        case .notDetermined:
            return "Not configured - Tap Enable to get started"
        case .provisional:
            return "Provisional - Limited notifications"
        case .ephemeral:
            return "Temporary - Limited notifications"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private func requestNotificationPermission() {
        _Concurrency.Task {
            let granted = await notificationService.requestAuthorization()
            if !granted {
                showingPermissionAlert = true
            } else {
                // Schedule default notifications
                notificationService.scheduleDailyJournalPrompt(time: dailyJournalTime)
                notificationService.scheduleMoodTrackingReminder(time: moodTrackingTime)
            }
        }
    }
    
    private func loadNotificationTimes() {
        // Set default times
        let calendar = Calendar.current
        dailyJournalTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        moodTrackingTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

// MARK: - Preview

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}
