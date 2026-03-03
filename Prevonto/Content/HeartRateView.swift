// Heart Rate page displays user's heart rate from wearable sync
import SwiftUI
import Charts

struct HeartRateView: View {
    @Environment(\.dismiss) var dismiss

    // View state
    @State private var selectedTab: HeartRateTimeTab = .week
    @State private var selectedDate = Date()
    @State private var isLoading = false

    // Data from HealthKit/API
    @State private var currentBPM: Int = 0
    @State private var avgBPM: Int = 0
    @State private var minBPM: Int = 0
    @State private var maxBPM: Int = 0
    @State private var restingBPM: Int = 0
    @State private var timelineData: [HeartRateDataPoint] = []
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
                            titleSection
                            tabPicker
                            calendarWeekPicker
                            currentBPMSection
                            statsSection
                            chartSection
                            Spacer(minLength: 50)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
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

    // MARK: - Title Section
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Heart Rate")
                .font(.custom("Noto Sans", size: 28))
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            Text("Data synced from your wearable device")
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tab Picker
    var tabPicker: some View {
        HStack(spacing: 8) {
            ForEach(HeartRateTimeTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(.custom("Noto Sans", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == tab ? .white : Color(red: 0.40, green: 0.42, blue: 0.46))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? Color(red: 0.01, green: 0.33, blue: 0.18) : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedTab == tab ? Color.clear : Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Calendar Week Picker
    var calendarWeekPicker: some View {
        VStack(spacing: 12) {
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

    // MARK: - Current BPM Section
    var currentBPMSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)

                if hasData {
                    Text("\(currentBPM)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                    Text("BPM")
                        .font(.custom("Noto Sans", size: 18))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                } else {
                    Text("--")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))

                    Text("BPM")
                        .font(.custom("Noto Sans", size: 18))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                }
            }

            Text(hasData ? "Current heart rate" : "Connect wearable to see data")
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(16)
    }

    // MARK: - Stats Section
    var statsSection: some View {
        HStack(spacing: 12) {
            HeartRateStatCard(title: "Avg", value: hasData ? "\(avgBPM)" : "--", unit: "BPM", color: .blue)
            HeartRateStatCard(title: "Min", value: hasData ? "\(minBPM)" : "--", unit: "BPM", color: .green)
            HeartRateStatCard(title: "Max", value: hasData ? "\(maxBPM)" : "--", unit: "BPM", color: .orange)
            HeartRateStatCard(title: "Resting", value: hasData ? "\(restingBPM)" : "--", unit: "BPM", color: .purple)
        }
    }

    // MARK: - Chart Section
    var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Heart Rate Timeline")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            if timelineData.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                    Text("No heart rate data available")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    Text("Connect your wearable to sync data")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(12)
            } else {
                Chart {
                    ForEach(timelineData) { point in
                        LineMark(
                            x: .value("Time", point.time),
                            y: .value("BPM", point.value)
                        )
                        .foregroundStyle(Color.red)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", point.time),
                            y: .value("BPM", point.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.3), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 180)
                .chartYScale(domain: 40...160)
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

        // Load from HealthKit
        healthKitManager.fetchTodayHeartRate { hr, _ in
            DispatchQueue.main.async {
                if let hr = hr {
                    self.currentBPM = Int(hr)
                    self.hasData = true
                }
            }
        }

        // Load from API
        Task {
            do {
                let range: TimeRange = selectedTab == .day ? .day : selectedTab == .week ? .week : .month
                let history = try await HealthMetricsAPI.shared.getMetricHistory(type: "heart_rate", range: range)
                let stats = try await AnalyticsAPI.shared.getStatistics(metricType: "heart_rate", range: range)

                await MainActor.run {
                    if !history.isEmpty {
                        hasData = true
                        avgBPM = Int(stats.average["value"] ?? 0)
                        minBPM = Int(stats.minimum["value"] ?? 0)
                        maxBPM = Int(stats.maximum["value"] ?? 0)
                        restingBPM = Int(stats.average["value"] ?? 0) - 10 // Approximate resting

                        timelineData = history.compactMap { record in
                            guard let value = record.value["value"], let date = record.date else { return nil }
                            return HeartRateDataPoint(time: date, value: value)
                        }
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum HeartRateTimeTab: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

struct HeartRateStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.custom("Noto Sans", size: 12))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(unit)
                .font(.custom("Noto Sans", size: 10))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(12)
    }
}

// Preview
struct HeartRateView_Previews: PreviewProvider {
    static var previews: some View {
        HeartRateView()
    }
}
