import SwiftUI
import EventKit

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedView: CalendarViewType = .month
    
    enum CalendarViewType: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.permissionStatus == .notDetermined {
                    permissionRequestView
                } else if viewModel.permissionStatus == .denied {
                    permissionDeniedView
                } else {
                    calendarContentView
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") {
                        viewModel.goToToday()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { viewModel.showingTimeBlocking.toggle() }) {
                            Label("Time Block", systemImage: "clock")
                        }
                        Button(action: { viewModel.showingCreateEvent.toggle() }) {
                            Label("Add Event", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingCreateEvent) {
                CreateEventView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingTimeBlocking) {
                TimeBlockingView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Permission Request View
    private var permissionRequestView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Calendar Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Atlas needs access to your calendar to help you manage events and time blocks.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Grant Access") {
                _Concurrency.Task {
                    await viewModel.requestCalendarAccess()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Permission Denied View
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Calendar Access Denied")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please enable calendar access in Settings to use calendar features.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Calendar Content View
    private var calendarContentView: some View {
        VStack {
            // View Type Picker
            Picker("View", selection: $selectedView) {
                ForEach(CalendarViewType.allCases, id: \.self) { viewType in
                    Text(viewType.rawValue).tag(viewType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Calendar Content
            switch selectedView {
            case .day:
                DayView(viewModel: viewModel)
            case .week:
                WeekView(viewModel: viewModel)
            case .month:
                MonthView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Day View
struct DayView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack {
            // Date Navigation
            HStack {
                Button(action: { viewModel.goToPreviousDay() }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(viewModel.selectedDate, formatter: dayFormatter)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { viewModel.goToNextDay() }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
                // Events List
                if viewModel.isLoading {
                    ProgressView("Loading events...")
                } else {
                    List {
                        ForEach([EKEvent](), id: \.eventIdentifier) { event in
                            NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel)) {
                                EventRow(event: event)
                            }
                        }
                    }
                }
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
}

// MARK: - Week View
struct WeekView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack {
            // Week Navigation
            HStack {
                Button(action: { viewModel.goToPreviousWeek() }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(viewModel.selectedDate, formatter: weekFormatter)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { viewModel.goToNextWeek() }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Week Grid
            WeekGridView(viewModel: viewModel)
        }
    }
    
    private let weekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

// MARK: - Month View
struct MonthView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack {
            // Month Navigation
            HStack {
                Button(action: { viewModel.goToPreviousMonth() }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text(viewModel.selectedDate, formatter: monthFormatter)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { viewModel.goToNextMonth() }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            // Month Grid
            MonthGridView(viewModel: viewModel)
        }
    }
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

// MARK: - Event Row
struct EventRow: View {
    let event: EKEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title ?? "Untitled Event")
                .font(.headline)
            
            if let location = event.location, !location.isEmpty {
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text(event.startDate, formatter: timeFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !event.isAllDay {
                    Text(" - ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(event.endDate, formatter: timeFormatter)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
