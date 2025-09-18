import SwiftUI
import Charts

// MARK: - Chart Data Models
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String?
    
    init(date: Date, value: Double, label: String? = nil) {
        self.date = date
        self.value = value
        self.label = label
    }
}

struct CategoryDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let color: Color
    
    init(category: String, value: Double, color: Color) {
        self.category = category
        self.value = value
        self.color = color
    }
}

// MARK: - Line Chart Component
struct AnalyticsLineChart: View {
    let data: [ChartDataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(color)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, data.count / 7))) { value in
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.month().day())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Bar Chart Component
struct AnalyticsBarChart: View {
    let data: [ChartDataPoint]
    let title: String
    let yAxisLabel: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data) { dataPoint in
                BarMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(color)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, data.count / 7))) { value in
                    AxisGridLine()
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.month().day())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Pie Chart Component
struct AnalyticsPieChart: View {
    let data: [CategoryDataPoint]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart(data) { dataPoint in
                SectorMark(
                    angle: .value("Value", dataPoint.value),
                    innerRadius: .ratio(0.4),
                    angularInset: 2
                )
                .foregroundStyle(dataPoint.color)
                .opacity(0.8)
            }
            .frame(height: 200)
            .chartBackground { chartProxy in
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Legend
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(data) { dataPoint in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(dataPoint.color)
                            .frame(width: 12, height: 12)
                        
                        Text(dataPoint.category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(dataPoint.value))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Progress Ring Chart
struct AnalyticsProgressRing: View {
    let value: Double
    let maxValue: Double
    let title: String
    let color: Color
    let lineWidth: CGFloat
    
    private var progress: Double {
        min(value / maxValue, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: lineWidth)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(value))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("of \(Int(maxValue))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Trend Indicator
struct TrendIndicator: View {
    let value: Double
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption)
                .foregroundColor(isPositive ? .green : .red)
            
            Text("\(abs(value), specifier: "%.1f")%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((isPositive ? Color.green : Color.red).opacity(0.1))
        )
    }
}

// MARK: - Mini Chart Component
struct MiniChart: View {
    let data: [ChartDataPoint]
    let color: Color
    let height: CGFloat
    
    var body: some View {
        Chart(data) { dataPoint in
            LineMark(
                x: .value("Date", dataPoint.date),
                y: .value("Value", dataPoint.value)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .frame(height: height)
        .chartYAxis(.hidden)
        .chartXAxis(.hidden)
    }
}

// MARK: - Chart Container
struct ChartContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
    }
}

// MARK: - Preview
struct AnalyticsCharts_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sample data
                let sampleData = Array((0..<30).map { day in
                    ChartDataPoint(
                        date: Calendar.current.date(byAdding: .day, value: -day, to: Date()) ?? Date(),
                        value: Double.random(in: 0...100)
                    )
                }.reversed())
                
                let categoryData = [
                    CategoryDataPoint(category: "High", value: 25, color: .red),
                    CategoryDataPoint(category: "Medium", value: 45, color: .orange),
                    CategoryDataPoint(category: "Low", value: 30, color: .green)
                ]
                
                AnalyticsLineChart(
                    data: sampleData,
                    title: "Task Completion Trend",
                    yAxisLabel: "Tasks",
                    color: .blue
                )
                
                AnalyticsBarChart(
                    data: sampleData,
                    title: "Daily Activity",
                    yAxisLabel: "Count",
                    color: .green
                )
                
                HStack(spacing: 16) {
                    AnalyticsPieChart(
                        data: categoryData,
                        title: "Task Priority"
                    )
                    
                    AnalyticsProgressRing(
                        value: 75,
                        maxValue: 100,
                        title: "Completion Rate",
                        color: .blue,
                        lineWidth: 8
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}
