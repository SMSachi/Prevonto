// SpO2 page displays the user's SpO2 levels from wearable sync
import SwiftUI
import Charts

struct SpO2View: View {
    @Environment(\.dismiss) var dismiss

    // View state
    @State private var selectedTab: SpO2TimeTab = .week
    @State private var selectedDate = Date()
    @State private var isLoading = false

    // Data from HealthKit/API
    @State private var avgSpO2: Double = 0
    @State private var lowestSpO2: Double = 0
    @State private var avgHeartRate: Double = 0
    @State private var timelineData: [SpO2DataPoint] = []
    @State private var hasData = false

    let healthKitManager = HealthKitManager()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection

                    ScrollView {
                        VStack(spacing: 24) {
                            tabPicker
                            calendarWeekPicker
                            gaugeSection
                            statsSection
                            timelineSection
                            Spacer(minLength: 50)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadData() }
            .onChange(of: selectedDate) { _, _ in loadData() }
            .onChange(of: selectedTab) { _, _ in loadData() }
        }
    }

    // MARK: - Header
    var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Title and Tab Picker
    var tabPicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("SpO2")
                    .font(.custom("Noto Sans", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

                Text(hasData ? "Data synced from your wearable device" : "Connect a wearable device to track SpO2")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }

            HStack(spacing: 0) {
                ForEach(SpO2TimeTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.custom("Noto Sans", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? .white : Color(red: 0.40, green: 0.42, blue: 0.46))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? Color(red: 0.01, green: 0.33, blue: 0.18) : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(4)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(10)
        }
    }

    // MARK: - Calendar Week Picker
    var calendarWeekPicker: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button(action: { moveWeek(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                }

                Spacer()

                Text(monthYearString)
                    .font(.custom("Noto Sans", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                Spacer()

                Button(action: { moveWeek(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                }
            }

            // Week days
            HStack(spacing: 8) {
                ForEach(weekDays, id: \.date) { day in
                    VStack(spacing: 4) {
                        Text(day.dayName)
                            .font(.custom("Noto Sans", size: 12))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

                        Text("\(day.dayNumber)")
                            .font(.custom("Noto Sans", size: 14))
                            .fontWeight(day.isSelected ? .bold : .medium)
                            .foregroundColor(day.isSelected ? .white : Color(red: 0.40, green: 0.42, blue: 0.46))
                            .frame(width: 36, height: 36)
                            .background(day.isSelected ? Color(red: 0.01, green: 0.33, blue: 0.18) : Color.clear)
                            .cornerRadius(8)
                    }
                    .onTapGesture {
                        selectedDate = day.date
                    }
                }
            }
        }
    }

    // MARK: - Gauge Section
    var gaugeSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0.25, to: 0.75)
                    .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 20)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(180))

                // Progress arc - yellow section (low)
                Circle()
                    .trim(from: 0.25, to: 0.25 + (0.5 * min(gaugeProgress, 0.9)))
                    .stroke(
                        gaugeProgress < 0.9 ? Color(red: 0.85, green: 0.65, blue: 0.20) : Color(red: 0.36, green: 0.55, blue: 0.37),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(180))

                // Green section (normal)
                if gaugeProgress >= 0.9 {
                    Circle()
                        .trim(from: 0.25 + (0.5 * 0.9), to: 0.25 + (0.5 * gaugeProgress))
                        .stroke(
                            Color(red: 0.36, green: 0.55, blue: 0.37),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(180))
                }

                // Indicator dot
                Circle()
                    .fill(Color(red: 0.36, green: 0.55, blue: 0.37))
                    .frame(width: 16, height: 16)
                    .offset(y: -100)
                    .rotationEffect(.degrees(180 + (180 * gaugeProgress)))

                // Center text
                VStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                    } else if hasData {
                        Text("\(Int(avgSpO2))%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                        Text("Avg SpO\u{2082}")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    } else {
                        Text("--%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))

                        Text("No data")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    }
                }
                .offset(y: 20)
            }
            .frame(height: 180)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Stats Section
    var statsSection: some View {
        HStack(spacing: 0) {
            // Lowest SpO2
            VStack(alignment: .leading, spacing: 4) {
                Text(hasData ? "\(Int(lowestSpO2))%" : "--%")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                Text("Lowest SpO\u{2082}")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                .frame(width: 1, height: 50)

            // Avg Heart Rate
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(hasData ? "\(Int(avgHeartRate))" : "--")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                    Text("bpm")
                        .font(.custom("Noto Sans", size: 16))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                }

                Text("Avg Heart Rate")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 24)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Timeline Section
    var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SpO\u{2082} Timeline")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            if timelineData.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                    Text("No SpO2 data available")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    Text("Connect your wearable to sync data")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(12)
            } else {
                // Line chart
                Chart {
                    ForEach(timelineData) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("SpO2", point.value)
                        )
                        .foregroundStyle(Color(red: 0.36, green: 0.55, blue: 0.37))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", point.time),
                            y: .value("SpO2", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.36, green: 0.55, blue: 0.37).opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 150)
                .chartYScale(domain: 90...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var gaugeProgress: Double {
        guard hasData else { return 0 }
        // Map SpO2 (85-100) to progress (0-1)
        return max(0, min(1, (avgSpO2 - 85) / 15))
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private var weekDays: [WeekDay] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            let dayName = dayFormatter.string(from: date)
            let dayNumber = calendar.component(.day, from: date)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

            return WeekDay(date: date, dayName: dayName, dayNumber: dayNumber, isSelected: isSelected)
        }
    }

    // MARK: - Actions

    private func moveWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func loadData() {
        isLoading = true

        // Try to load from HealthKit
        healthKitManager.fetchTodayHeartRate { hr, _ in
            DispatchQueue.main.async {
                if let hr = hr {
                    self.avgHeartRate = hr
                }
            }
        }

        // Load SpO2 data from API
        Task {
            do {
                let range: TimeRange = selectedTab == .day ? .day : .week
                let history = try await HealthMetricsAPI.shared.getMetricHistory(type: "spo2", range: range)
                let stats = try await AnalyticsAPI.shared.getStatistics(metricType: "spo2", range: range)

                await MainActor.run {
                    if !history.isEmpty {
                        hasData = true
                        avgSpO2 = stats.average["value"] ?? 95
                        lowestSpO2 = stats.minimum["value"] ?? 95

                        // Convert to timeline data
                        timelineData = history.compactMap { record in
                            guard let value = record.value["value"], let date = record.date else { return nil }
                            return SpO2DataPoint(time: date, value: value)
                        }
                    } else {
                        hasData = false
                        timelineData = []
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    hasData = false
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum SpO2TimeTab: String, CaseIterable {
    case day = "Day"
    case week = "Week"
}

struct WeekDay {
    let date: Date
    let dayName: String
    let dayNumber: Int
    let isSelected: Bool
}

struct SpO2DataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

// Preview
struct SpO2View_Previews: PreviewProvider {
    static var previews: some View {
        SpO2View()
    }
}
