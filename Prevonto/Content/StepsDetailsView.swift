// This is the Steps and Activity Page, which shows the user's calories burned, minutes moving, hours standing, and numbers of steps taken.
import SwiftUI
import Charts

struct StepsDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Chart state
    @State private var selectedTimeFrame: TimeFrame = .day
    @State private var selectedDataPoint: ChartDataPoint?

    // Chart data per time frame
    @State private var dayChartData: [ChartDataPoint] = []
    @State private var weekChartData: [ChartDataPoint] = []
    @State private var monthChartData: [ChartDataPoint] = []
    @State private var yearChartData: [ChartDataPoint] = []

    // Performance optimizations: cached values
    @State private var maxYValue: Int = 1000
    @State private var currentData: [ChartDataPoint] = []

    // Loading and error states
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Activity ring values (from API/HealthKit)
    @State private var caloriesCurrent: Double = 0
    @State private var caloriesTarget: Double = 500  // Neutral default when no wearable
    @State private var exerciseCurrent: Double = 0
    @State private var exerciseTarget: Double = 30
    @State private var standCurrent: Double = 0
    @State private var standTarget: Double = 12
    @State private var hasWearableData: Bool = false

    let healthKitManager = HealthKitManager()

    // Activity ring progress values
    var caloriesProgress: Double { min(caloriesCurrent / caloriesTarget, 1.0) }
    var exerciseProgress: Double { min(exerciseCurrent / exerciseTarget, 1.0) }
    var standProgress: Double { min(standCurrent / standTarget, 1.0) }
    
    // Day Mode spacing factor
    private var dayModeSpacingFactor: Double { 1.5 }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        titleSection
                        activityRingsSection
                        timeFrameButtons
                        stepsTrackerHeading
                        chartDisplayContainer
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .onAppear {
            loadChartData()
        }
        .onChange(of: selectedTimeFrame) { _, _ in
            selectedDataPoint = nil
            refreshForTimeFrame()
        }
    }
    
    // MARK: - View Components
    private var titleSection: some View { /* ... unchanged ... */ VStack(alignment: .leading, spacing: 12) {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Steps & Activity")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.proPrimary)
                Text("Your Steps & Activities is monitored through your watch which is in sync with the app.")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.25, green: 0.33, blue: 0.44))
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    } }
    
    private var activityRingsSection: some View { /* ... unchanged ... */
        HStack(alignment: .center, spacing: 0) {
            ZStack {
                Circle().stroke(Color.proPrimary.opacity(0.15), lineWidth: 12).frame(width: 160, height: 160)
                Circle().trim(from: 0, to: caloriesProgress)
                    .stroke(Color.proPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                Circle().stroke(Color.proTertiary.opacity(0.15), lineWidth: 12).frame(width: 120, height: 120)
                Circle().trim(from: 0, to: exerciseProgress)
                    .stroke(Color.proTertiary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                Circle().stroke(Color.proSecondary.opacity(0.15), lineWidth: 12).frame(width: 80, height: 80)
                Circle().trim(from: 0, to: standProgress)
                    .stroke(Color.proSecondary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
            }
            .alignmentGuide(.leading) { d in d[.leading] - 80 }
            .padding(.leading, 30)
            Spacer()
            VStack(alignment: .leading, spacing: 24) {
                statisticBlock(
                    title: "Move",
                    value: "\(Int(caloriesCurrent))/\(Int(caloriesTarget))",
                    subtitle: "Calories Burned",
                    color: .proPrimary
                )
                statisticBlock(
                    title: "Exercise",
                    value: "\(Int(exerciseCurrent))/\(Int(exerciseTarget))",
                    subtitle: "Minutes Moving",
                    color: .proTertiary
                )
                statisticBlock(
                    title: "Stand",
                    value: "\(Int(standCurrent))/\(Int(standTarget))",
                    subtitle: "Hours Standing",
                    color: .proSecondary
                )
            }
            .frame(maxWidth: 160)
            .padding(.trailing, 18)
        }
    }
    
    private var timeFrameButtons: some View { /* ... unchanged ... */ HStack {
        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
            Button(action: {
                selectedTimeFrame = timeFrame
            }) {
                Text(timeFrame.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedTimeFrame == timeFrame ? .white : Color(red: 0.5, green: 0.5, blue: 0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(selectedTimeFrame == timeFrame ? Color.proTertiary : Color.white)
                    .cornerRadius(10)
                    .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            if timeFrame != TimeFrame.allCases.last {
                Spacer()
            }
        }
    }
    .padding(.horizontal, 24)
    }
    
    private var stepsTrackerHeading: some View { /* ... unchanged ... */ HStack {
        Text("Steps Tracker")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.proPrimary)
        Spacer()
    }
    .padding(.horizontal, 24)
    }
    
    // MARK: - Chart Implementation with Centered Message Box
    private var chartDisplayContainer: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Rectangle().fill(Color.clear).frame(height: 80)
                    if let selectedPoint = selectedDataPoint {
                        HStack {
                            Spacer()
                            VStack(spacing: 0) {
                                Text("\(selectedPoint.steps)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text("steps")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.proTertiary)
                            .cornerRadius(8)
                            .overlay(
                                Triangle()
                                    .fill(Color.proTertiary)
                                    .frame(width: 10, height: 6)
                                    .offset(y: 8),
                                alignment: .bottom
                            )
                            Spacer()
                        }
                        .frame(height: 80)
                    }
                }
                chartSection
            }

            // Loading overlay
            if isLoading {
                Color.white.opacity(0.8)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }

            // Error overlay
            if let error = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Button("Retry") {
                        loadChartData()
                    }
                    .font(.subheadline)
                    .foregroundColor(.proTertiary)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 24)
    }
    
    private var chartSection: some View { /* ... unchanged ... */ VStack(spacing: 12) {
        Chart {
            ForEach(0..<(currentData.count + 1), id: \.self) { index in
                RuleMark(x: .value("Boundary", getBoundaryPosition(for: index)))
                    .foregroundStyle(Color.boundary)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
            }
            ForEach(Array(currentData.enumerated()), id: \.element.id) { index, point in
                BarMark(
                    x: .value("Position", getBarPosition(for: index)),
                    y: .value("Steps", point.steps)
                )
                .foregroundStyle(selectedDataPoint?.id == point.id ? Color.proTertiary : Color.barDefault)
                .cornerRadius(2)
            }
        }
        .chartYScale(domain: 0...maxYValue)
        .chartXScale(domain: getXAxisDomain())
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel()
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
        .chartXAxis {
            if selectedTimeFrame == .day {
                AxisMarks { _ in
                    AxisValueLabel("")
                }
            } else {
                AxisMarks(values: .stride(by: 1)) { value in
                    if let index = value.as(Int.self),
                       index >= 0 && index < currentData.count {
                        AxisValueLabel(currentData[index].label)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .frame(height: 200)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleChartTap(at: location, proxy: proxy, geometry: geometry)
                    }
            }
        }
        if selectedTimeFrame == .day {
            enhancedDayModeLabels
        }
    }
    .padding(16)
    }
    
    // MARK: - Enhanced Day Mode Labels with Proper Spacing
    private var enhancedDayModeLabels: some View { /* ... unchanged ... */
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<12, id: \.self) { index in
                    Group {
                        switch index {
                        case 3: Text("6 AM")
                        case 6: Text("12 PM")
                        case 9: Text("6 PM")
                        default: Text("")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.gray)
                    if index < 11 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            HStack {
                Image(systemName: "sun.max")
                    .foregroundColor(.gray)
                    .font(.title2)
                Spacer()
                Image(systemName: "moon")
                    .foregroundColor(.gray)
                    .font(.title2)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Spacing Helper Methods
    private func getBoundaryPosition(for index: Int) -> Double {
        if selectedTimeFrame == .day {
            return Double(index) * dayModeSpacingFactor
        } else {
            return Double(index)
        }
    }
    private func getBarPosition(for index: Int) -> Double {
        if selectedTimeFrame == .day {
            return (Double(index) + 0.5) * dayModeSpacingFactor
        } else {
            return Double(index) + 0.5
        }
    }
    private func getXAxisDomain() -> ClosedRange<Double> {
        if selectedTimeFrame == .day {
            let maxPosition = Double(currentData.count) * dayModeSpacingFactor
            return 0...maxPosition
        } else {
            return 0...Double(currentData.count)
        }
    }
    
    // MARK: - Enhanced Chart Interaction with Spacing
    private func handleChartTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else { return }
        let frame = geometry[plotFrame]
        let plotX = location.x - frame.origin.x
        guard let xValue = proxy.value(atX: plotX, as: Double.self) else { return }
        let barIndex: Int
        if selectedTimeFrame == .day {
            barIndex = Int(round((xValue / dayModeSpacingFactor) - 0.5))
        } else {
            barIndex = Int(round(xValue - 0.5))
        }
        guard barIndex >= 0 && barIndex < currentData.count else { return }
        let tappedDataPoint = currentData[barIndex]
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedDataPoint = (selectedDataPoint?.id == tappedDataPoint.id) ? nil : tappedDataPoint
        }
    }
    
    // MARK: - Performance Helper Methods
    private func refreshForTimeFrame() {
        currentData = getChartData()
        maxYValue = computeMaxYValue(from: currentData)
    }
    private func computeMaxYValue(from data: [ChartDataPoint]) -> Int {
        let maxSteps = data.map { $0.steps }.max() ?? 0
        switch maxSteps {
        case 0...1000:     return ((maxSteps / 100) + 1) * 100
        case 1001...5000:  return ((maxSteps / 500) + 1) * 500
        case 5001...10000: return ((maxSteps / 1000) + 1) * 1000
        default:           return ((maxSteps / 10000) + 1) * 10000
        }
    }
    private func getChartData() -> [ChartDataPoint] {
        switch selectedTimeFrame {
        case .day: return dayChartData
        case .week: return weekChartData
        case .month: return monthChartData
        case .year: return yearChartData
        }
    }

    // MARK: - Helper Methods
    private func statisticBlock(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
    // MARK: - API Data Loading
    private func loadChartData() {
        isLoading = true
        errorMessage = nil

        // First try to load from HealthKit
        loadHealthKitData()

        Task {
            do {
                // Load data for all time ranges in parallel
                async let dayData = AnalyticsAPI.shared.getTimeSeries(metricType: "steps_activity", range: .day)
                async let weekData = AnalyticsAPI.shared.getTimeSeries(metricType: "steps_activity", range: .week)
                async let monthData = AnalyticsAPI.shared.getTimeSeries(metricType: "steps_activity", range: .month)
                async let yearData = AnalyticsAPI.shared.getTimeSeries(metricType: "steps_activity", range: .year)
                async let statistics = AnalyticsAPI.shared.getStatistics(metricType: "steps_activity", range: .day)

                let (dayResponse, weekResponse, monthResponse, yearResponse, statsResponse) = try await (dayData, weekData, monthData, yearData, statistics)

                await MainActor.run {
                    dayChartData = convertToChartDataPoints(response: dayResponse, timeFrame: .day)
                    weekChartData = convertToChartDataPoints(response: weekResponse, timeFrame: .week)
                    monthChartData = convertToChartDataPoints(response: monthResponse, timeFrame: .month)
                    yearChartData = convertToChartDataPoints(response: yearResponse, timeFrame: .year)

                    // Update activity ring values from statistics if we have data
                    if statsResponse.count > 0 {
                        hasWearableData = true
                        caloriesTarget = 8000  // Real target when we have data
                        if let calories = statsResponse.average["calories"] {
                            caloriesCurrent = calories * Double(statsResponse.count)
                        }
                        if let exercise = statsResponse.average["exercise_minutes"] {
                            exerciseCurrent = exercise * Double(statsResponse.count) / 60.0
                        }
                        if let stand = statsResponse.average["stand_hours"] {
                            standCurrent = stand * Double(statsResponse.count)
                        }
                    }

                    isLoading = false
                    refreshForTimeFrame()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to load data"
                    // Initialize with empty data on error
                    initializeFallbackData()
                    refreshForTimeFrame()
                }
            }
        }
    }

    private func loadHealthKitData() {
        healthKitManager.requestAuthorization { success, error in
            if success {
                self.healthKitManager.fetchTodayStepCount { steps, error in
                    if let steps = steps, steps > 0 {
                        DispatchQueue.main.async {
                            self.hasWearableData = true
                            self.caloriesTarget = 8000
                        }
                    }
                }
                self.healthKitManager.fetchTodayCalories { calories, error in
                    if let calories = calories {
                        DispatchQueue.main.async {
                            self.caloriesCurrent = calories
                            if calories > 0 {
                                self.hasWearableData = true
                                self.caloriesTarget = 8000
                            }
                        }
                    }
                }
            }
        }
    }

    private func convertToChartDataPoints(response: TimeSeriesResponse, timeFrame: TimeFrame) -> [ChartDataPoint] {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return response.data_points.enumerated().map { index, dataPoint in
            let date = dateFormatter.date(from: dataPoint.timestamp) ?? Date()
            let steps = Int(dataPoint.value["steps"] ?? 0)
            let label = generateLabel(for: date, timeFrame: timeFrame, index: index)

            return ChartDataPoint(id: UUID(), label: label, steps: steps, date: date)
        }
    }

    private func generateLabel(for date: Date, timeFrame: TimeFrame, index: Int) -> String {
        let formatter = DateFormatter()

        switch timeFrame {
        case .day:
            let hours = ["12am", "2am", "4am", "6am", "8am", "10am", "12pm", "2pm", "4pm", "6pm", "8pm", "10pm"]
            return index < hours.count ? hours[index] : formatter.string(from: date)
        case .week:
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        case .month:
            return "Week \(index + 1)"
        case .year:
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
    }

    private func initializeFallbackData() {
        // Provide empty/default data when API fails
        dayChartData = []
        weekChartData = []
        monthChartData = []
        yearChartData = []
    }
}

// MARK: - TimeFrame to TimeRange Extension
extension TimeFrame {
    var toTimeRange: TimeRange {
        switch self {
        case .day: return .day
        case .week: return .week
        case .month: return .month
        case .year: return .year
        }
    }
}

// MARK: - Supporting Structures & Extensions

private extension Color {
    static let proPrimary = Color(red: 0.01, green: 0.33, blue: 0.18)
    static let proSecondary = Color(red: 0.39, green: 0.59, blue: 0.38)
    static let proTertiary = Color(red: 0.23, green: 0.51, blue: 0.36)
    static let barDefault = Color(red: 0.682, green: 0.698, blue: 0.788)
    static let boundary = Color(red: 0.839, green: 0.871, blue: 0.929).opacity(0.4)
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

enum TimeFrame: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct ChartDataPoint: Identifiable {
    let id: UUID
    let label: String
    let steps: Int
    let date: Date
}

struct StepsDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        StepsDetailsView()
    }
}

