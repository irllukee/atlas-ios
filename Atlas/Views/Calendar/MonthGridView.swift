import SwiftUI
import EventKit

struct MonthGridView: View {
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
            
            // Month grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
                ForEach(getMonthDates(), id: \.self) { date in
                    MonthDayView(
                        date: date,
                        events: [],
                        isSelected: calendar.isDate(date, inSameDayAs: viewModel.selectedDate),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: calendar.isDate(date, equalTo: viewModel.selectedDate, toGranularity: .month)
                    ) {
                        viewModel.selectedDate = date
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func getMonthDates() -> [Date] {
        let startOfMonth = calendar.dateInterval(of: .month, for: viewModel.selectedDate)?.start ?? viewModel.selectedDate
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: startOfMonth)?.start ?? startOfMonth
        
        var dates: [Date] = []
        var currentDate = startOfWeek
        
        // Generate 6 weeks (42 days) to ensure we cover the entire month
        for _ in 0..<42 {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
}

struct MonthDayView: View {
    let date: Date
    let events: [EKEvent]
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundColor(
                        isToday ? .white :
                        isSelected ? .blue :
                        isCurrentMonth ? .primary : .secondary
                    )
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isToday ? Color.blue : (isSelected ? Color.blue.opacity(0.2) : Color.clear))
                    )
                
                // Event indicators
                HStack(spacing: 1) {
                    ForEach(events.prefix(3), id: \.eventIdentifier) { event in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    }
                    
                    if events.count > 3 {
                        Text("+")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct MonthGridView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CalendarViewModel()
        MonthGridView(viewModel: viewModel)
    }
}
