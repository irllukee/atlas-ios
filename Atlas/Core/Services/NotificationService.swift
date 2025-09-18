import Foundation
@preconcurrency import UserNotifications
import Combine

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isEnabled: Bool = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
                self.isEnabled = granted
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Task Reminders
    
    func scheduleTaskReminder(
        taskId: String,
        title: String,
        dueDate: Date,
        reminderMinutes: [Int] = [60, 15] // 1 hour and 15 minutes before
    ) {
        guard isEnabled else { return }
        
        // Remove existing notifications for this task
        removeTaskReminders(taskId: taskId)
        
        for minutes in reminderMinutes {
            let triggerDate = dueDate.addingTimeInterval(-TimeInterval(minutes * 60))
            
            // Don't schedule if the reminder time has already passed
            guard triggerDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Task Reminder"
            content.body = "\(title) is due in \(formatReminderTime(minutes))"
            content.sound = .default
            content.badge = 1
            content.userInfo = [
                "type": "task_reminder",
                "taskId": taskId,
                "reminderMinutes": minutes
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: triggerDate.timeIntervalSinceNow,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "task_\(taskId)_\(minutes)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule task reminder: \(error)")
                }
            }
        }
    }
    
    func removeTaskReminders(taskId: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let taskReminderIds = requests
                .filter { $0.identifier.hasPrefix("task_\(taskId)_") }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: taskReminderIds)
        }
    }
    
    // MARK: - Calendar Event Notifications
    
    func scheduleEventReminder(
        eventId: String,
        title: String,
        startDate: Date,
        reminderMinutes: [Int] = [15]
    ) {
        guard isEnabled else { return }
        
        // Remove existing notifications for this event
        removeEventReminders(eventId: eventId)
        
        for minutes in reminderMinutes {
            let triggerDate = startDate.addingTimeInterval(-TimeInterval(minutes * 60))
            
            // Don't schedule if the reminder time has already passed
            guard triggerDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Event Reminder"
            content.body = "\(title) starts in \(formatReminderTime(minutes))"
            content.sound = .default
            content.userInfo = [
                "type": "event_reminder",
                "eventId": eventId,
                "reminderMinutes": minutes
            ]
            
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: triggerDate.timeIntervalSinceNow,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "event_\(eventId)_\(minutes)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule event reminder: \(error)")
                }
            }
        }
    }
    
    func removeEventReminders(eventId: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let eventReminderIds = requests
                .filter { $0.identifier.hasPrefix("event_\(eventId)_") }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: eventReminderIds)
        }
    }
    
    // MARK: - Daily Journal Prompts
    
    func scheduleDailyJournalPrompt(time: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()) {
        guard isEnabled else { return }
        
        // Remove existing daily journal prompts
        removeDailyJournalPrompts()
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Journal"
        content.body = "How was your day? Take a moment to reflect and write in your journal."
        content.sound = .default
        content.userInfo = ["type": "daily_journal"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_journal_prompt",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule daily journal prompt: \(error)")
            }
        }
    }
    
    func removeDailyJournalPrompts() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_journal_prompt"])
    }
    
    // MARK: - Mood Tracking Reminders
    
    func scheduleMoodTrackingReminder(time: Date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()) {
        guard isEnabled else { return }
        
        // Remove existing mood tracking reminders
        removeMoodTrackingReminders()
        
        let content = UNMutableNotificationContent()
        content.title = "Mood Check-in"
        content.body = "How are you feeling today? Log your mood to track your emotional well-being."
        content.sound = .default
        content.userInfo = ["type": "mood_tracking"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "mood_tracking_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule mood tracking reminder: \(error)")
            }
        }
    }
    
    func removeMoodTrackingReminders() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["mood_tracking_reminder"])
    }
    
    // MARK: - Utility Methods
    
    func removeAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.deliveredNotifications()
    }
    
    private func formatReminderTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            let days = minutes / 1440
            return "\(days) day\(days > 1 ? "s" : "")"
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String {
            switch type {
            case "task_reminder":
                // Handle task reminder tap
                if let taskId = userInfo["taskId"] as? String {
                    // Navigate to task or show task details
                    print("Task reminder tapped for task: \(taskId)")
                }
            case "event_reminder":
                // Handle event reminder tap
                if let eventId = userInfo["eventId"] as? String {
                    // Navigate to calendar or show event details
                    print("Event reminder tapped for event: \(eventId)")
                }
            case "daily_journal":
                // Navigate to journal
                print("Daily journal prompt tapped")
            case "mood_tracking":
                // Navigate to mood tracking
                print("Mood tracking reminder tapped")
            default:
                break
            }
        }
        
        completionHandler()
    }
}
