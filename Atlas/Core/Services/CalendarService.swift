import Foundation
@preconcurrency import EventKit
import Combine

enum CalendarPermissionStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}

enum EventType: String, CaseIterable {
    case meeting = "Meeting"
    case appointment = "Appointment"
    case reminder = "Reminder"
    case deadline = "Deadline"
    case personal = "Personal"
    case work = "Work"
    
    var color: String {
        switch self {
        case .meeting: return "blue"
        case .appointment: return "green"
        case .reminder: return "orange"
        case .deadline: return "red"
        case .personal: return "purple"
        case .work: return "gray"
        }
    }
}

@MainActor
class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    
    @Published var permissionStatus: CalendarPermissionStatus = .notDetermined
    @Published var events: [EKEvent] = []
    @Published var calendars: [EKCalendar] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        checkPermissionStatus()
        loadCalendars()
    }
    
    // MARK: - Permission Management
    
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            self.permissionStatus = granted ? .authorized : .denied
            if granted {
                loadCalendars()
            }
            return granted
        } catch {
            self.permissionStatus = .denied
            self.errorMessage = "Failed to request calendar access: \(error.localizedDescription)"
            return false
        }
    }
    
    private func checkPermissionStatus() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined:
            permissionStatus = .notDetermined
        case .denied:
            permissionStatus = .denied
        case .authorized:
            permissionStatus = .authorized
        case .restricted:
            permissionStatus = .restricted
        case .fullAccess:
            permissionStatus = .authorized
        case .writeOnly:
            permissionStatus = .denied
        @unknown default:
            permissionStatus = .notDetermined
        }
    }
    
    // MARK: - Calendar Management
    
    func loadCalendars() {
        guard permissionStatus == .authorized else { return }
        
        calendars = eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
    }
    
    func getDefaultCalendar() -> EKCalendar? {
        return calendars.first { $0.title == "Default" } ?? calendars.first
    }
    
    // MARK: - Event Management
    
    func loadEvents(for dateRange: DateInterval) {
        guard permissionStatus == .authorized else { return }
        
        isLoading = true
        errorMessage = nil
        
        let predicate = eventStore.predicateForEvents(withStart: dateRange.start, end: dateRange.end, calendars: calendars)
        let fetchedEvents = eventStore.events(matching: predicate)
        
        self.events = fetchedEvents.sorted { $0.startDate < $1.startDate }
        self.isLoading = false
    }
    
    func loadEventsForDate(_ date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        loadEvents(for: DateInterval(start: startOfDay, end: endOfDay))
    }
    
    func loadEventsForWeek(containing date: Date) {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date)
        
        if let interval = weekInterval {
            loadEvents(for: interval)
        }
    }
    
    func loadEventsForMonth(containing date: Date) {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: date)
        
        if let interval = monthInterval {
            loadEvents(for: interval)
        }
    }
    
    // MARK: - Event CRUD Operations
    
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        notes: String? = nil,
        location: String? = nil,
        eventType: EventType = .personal,
        calendar: EKCalendar? = nil,
        isAllDay: Bool = false,
        reminderMinutes: [Int] = [15]
    ) -> EKEvent? {
        guard permissionStatus == .authorized else {
            errorMessage = "Calendar access not authorized"
            return nil
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.location = location
        event.isAllDay = isAllDay
        event.calendar = calendar ?? getDefaultCalendar()
        
        // Add reminders
        for minutes in reminderMinutes {
            let alarm = EKAlarm(relativeOffset: -TimeInterval(minutes * 60))
            event.addAlarm(alarm)
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event
        } catch {
            errorMessage = "Failed to create event: \(error.localizedDescription)"
            return nil
        }
    }
    
    func updateEvent(
        _ event: EKEvent,
        title: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        notes: String? = nil,
        location: String? = nil,
        isAllDay: Bool? = nil
    ) -> Bool {
        guard permissionStatus == .authorized else {
            errorMessage = "Calendar access not authorized"
            return false
        }
        
        if let title = title { event.title = title }
        if let startDate = startDate { event.startDate = startDate }
        if let endDate = endDate { event.endDate = endDate }
        if let notes = notes { event.notes = notes }
        if let location = location { event.location = location }
        if let isAllDay = isAllDay { event.isAllDay = isAllDay }
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            errorMessage = "Failed to update event: \(error.localizedDescription)"
            return false
        }
    }
    
    func deleteEvent(_ event: EKEvent) -> Bool {
        guard permissionStatus == .authorized else {
            errorMessage = "Calendar access not authorized"
            return false
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            return true
        } catch {
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Time Blocking
    
    func createTimeBlock(
        title: String,
        startDate: Date,
        duration: TimeInterval,
        notes: String? = nil,
        isRecurring: Bool = false,
        recurrencePattern: String? = nil
    ) -> EKEvent? {
        let endDate = startDate.addingTimeInterval(duration)
        
        return createEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            notes: notes,
            eventType: .work,
            isAllDay: false,
            reminderMinutes: [5]
        )
    }
    
    func findAvailableTimeSlots(
        for date: Date,
        duration: TimeInterval,
        workingHours: (start: Int, end: Int) = (9, 17)
    ) -> [DateInterval] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let startHour = calendar.date(byAdding: .hour, value: workingHours.start, to: startOfDay)!
        let endHour = calendar.date(byAdding: .hour, value: workingHours.end, to: startOfDay)!
        
        let dayInterval = DateInterval(start: startHour, end: endHour)
        loadEvents(for: dayInterval)
        
        var availableSlots: [DateInterval] = []
        var currentTime = startHour
        
        while currentTime.addingTimeInterval(duration) <= endHour {
            let slotEnd = currentTime.addingTimeInterval(duration)
            let slot = DateInterval(start: currentTime, end: slotEnd)
            
            // Check if this slot conflicts with any existing events
            let hasConflict = events.contains { event in
                let eventInterval = DateInterval(start: event.startDate, end: event.endDate)
                return slot.intersects(eventInterval)
            }
            
            if !hasConflict {
                availableSlots.append(slot)
            }
            
            // Move to next 30-minute slot
            currentTime = calendar.date(byAdding: .minute, value: 30, to: currentTime)!
        }
        
        return availableSlots
    }
    
    // MARK: - Reminder Integration
    
    func syncTaskWithCalendar(_ task: Task) -> EKEvent? {
        guard let dueDate = task.dueDate else { return nil }
        
        let startDate = dueDate.addingTimeInterval(-3600) // 1 hour before due date
        let endDate = dueDate
        
        return createEvent(
            title: task.title ?? "Task",
            startDate: startDate,
            endDate: endDate,
            notes: task.notes,
            eventType: .deadline,
            reminderMinutes: [60, 15] // 1 hour and 15 minutes before
        )
    }
    
    // MARK: - Event Queries
    
    func getEventsForDate(_ date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }
    
    func getUpcomingEvents(limit: Int = 10) -> [EKEvent] {
        let now = Date()
        return events
            .filter { $0.startDate > now }
            .prefix(limit)
            .sorted { $0.startDate < $1.startDate }
    }
    
    func getEventsByType(_ type: EventType) -> [EKEvent] {
        return events.filter { event in
            // This is a simplified check - in a real app, you might store event types differently
            return event.title?.contains(type.rawValue) == true
        }
    }
    
    // MARK: - Statistics
    
    func getEventStatistics(for dateRange: DateInterval) -> CalendarStatistics {
        let eventsInRange = events.filter { event in
            dateRange.contains(event.startDate)
        }
        
        let totalEvents = eventsInRange.count
        let allDayEvents = eventsInRange.filter { $0.isAllDay }.count
        let timedEvents = totalEvents - allDayEvents
        
        let totalDuration = eventsInRange.reduce(0) { total, event in
            total + event.endDate.timeIntervalSince(event.startDate)
        }
        
        let averageDuration = totalEvents > 0 ? totalDuration / Double(totalEvents) : 0
        
        return CalendarStatistics(
            totalEvents: totalEvents,
            allDayEvents: allDayEvents,
            timedEvents: timedEvents,
            totalDuration: totalDuration,
            averageDuration: averageDuration
        )
    }
}

// MARK: - Calendar Statistics
struct CalendarStatistics {
    let totalEvents: Int
    let allDayEvents: Int
    let timedEvents: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    
    var totalDurationHours: Double {
        return totalDuration / 3600
    }
    
    var averageDurationMinutes: Double {
        return averageDuration / 60
    }
}
