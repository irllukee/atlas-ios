import SwiftUI
import EventKit

struct WeekGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    private let calendar = Calendar.current
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            
            // Week grid
            HStack(spacing: 0) {
                ForEach(getWeekDates(), id: \.self) { date in
                    WeekDayView(
                        date: date,
                        events: [],
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: calendar.isDateInToday(date)
                    ) {
                        viewModel.selectedDate = date
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func getWeekDates() -> [Date] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: viewModel.selectedDate)?.start ?? viewModel.selectedDate
        var dates: [Date] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                dates.append(date)
            }
        }
        
        return dates
    }
}

struct WeekDayView: View {
    let date: Date
    let events: [EKEvent]
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? .white : (isSelected ? .blue : .primary))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isToday ? Color.blue : (isSelected ? Color.blue.opacity(0.2) : Color.clear))
                    )
                
                // Event indicators
                VStack(spacing: 2) {
                    ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                    
                    if events.count > 3 {
                        Text("+\(events.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxHeight: 20)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct WeekGridView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CalendarViewModel()
        WeekGridView(viewModel: viewModel)
    }
}
