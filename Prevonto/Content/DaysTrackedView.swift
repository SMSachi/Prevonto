// Days tracked page shows what days the user have tracked their metrics on
import SwiftUI

struct DaysTrackedView: View {
    @Environment(\.dismiss) var dismiss

    private enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }

    @State private var selectedPeriod: Period = .month
    @State private var currentMonth = Date()
    @State private var trackedDates: Set<Date> = []
    @State private var totalDaysTracked: Int = 0
    @State private var mostTrackedMetrics: String = "Loading..."
    @State private var isLoading = true
    @State private var todayTrackedItems: [String] = []
    @State private var trackedToday = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerSection

                    ScrollView {
                        VStack(spacing: 24) {
                            // Title
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Days Tracked")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                                Text("Track how consistently you log your health metrics.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)

                            // Today's Activity Box
                            if !isLoading {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: trackedToday ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(trackedToday ? Color(red: 0.36, green: 0.55, blue: 0.37) : .gray)
                                        Text("Today")
                                            .font(.headline)
                                            .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                                        Spacer()
                                        if trackedToday {
                                            Text("Tracked!")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color(red: 0.36, green: 0.55, blue: 0.37).opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }

                                    if trackedToday && !todayTrackedItems.isEmpty {
                                        HStack(spacing: 8) {
                                            ForEach(todayTrackedItems, id: \.self) { item in
                                                Text(item)
                                                    .font(.caption)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color(red: 0.01, green: 0.33, blue: 0.18).opacity(0.1))
                                                    .cornerRadius(6)
                                            }
                                        }
                                    } else if !trackedToday {
                                        Text("No metrics logged today yet")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .gray.opacity(0.1), radius: 6)
                                .padding(.horizontal, 16)
                            }

                            // Stats Box
                            VStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .padding()
                                } else {
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text("\(totalDaysTracked)")
                                            .font(.system(size: 48, weight: .bold))
                                            .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                                        Text("days this month")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Text(mostTrackedMetrics)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.1), radius: 6)
                            .padding(.horizontal, 16)

                            // Period Picker
                            HStack(spacing: 12) {
                                ForEach(Period.allCases, id: \.self) { period in
                                    Button {
                                        selectedPeriod = period
                                    } label: {
                                        Text(period.rawValue)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(selectedPeriod == period ? .white : .gray)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 24)
                                            .background(selectedPeriod == period ? Color(red: 0.01, green: 0.33, blue: 0.18) : Color.white)
                                            .cornerRadius(8)
                                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)

                            // Calendar
                            calendarView
                                .padding(.horizontal, 16)

                            Spacer(minLength: 50)
                        }
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadTrackedDays() }
            .onChange(of: currentMonth) { _, _ in loadTrackedDays() }
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

    // MARK: - Calendar View
    private var calendarView: some View {
        VStack(spacing: 12) {
            // Month Navigation
            HStack {
                Button(action: { moveMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                }
                Spacer()
                Text(monthYearString)
                    .font(.headline)
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                Spacer()
                Button(action: { moveMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                }
            }
            .padding(.horizontal, 8)

            // Weekday Headers
            let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Days Grid
            let days = generateCalendarDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    if let day = day {
                        let isTracked = isDateTracked(day)
                        let isToday = calendar.isDateInToday(day)

                        ZStack {
                            if isTracked {
                                Circle()
                                    .fill(Color(red: 0.01, green: 0.33, blue: 0.18))
                                    .frame(width: 36, height: 36)
                            } else if isToday {
                                Circle()
                                    .stroke(Color(red: 0.01, green: 0.33, blue: 0.18), lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }

                            Text("\(calendar.component(.day, from: day))")
                                .font(.subheadline)
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundColor(isTracked ? .white : (isToday ? Color(red: 0.01, green: 0.33, blue: 0.18) : .primary))
                        }
                        .frame(height: 40)
                    } else {
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 4)
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func generateCalendarDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date?] = []
        let firstDayOfMonth = monthInterval.start
        let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: monthInterval.end)!

        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1

        // Add empty cells for days before the month starts
        for _ in 0..<firstWeekday {
            days.append(nil)
        }

        // Add all days in the month
        var currentDay = firstDayOfMonth
        while currentDay <= lastDayOfMonth {
            days.append(currentDay)
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        }

        return days
    }

    private func isDateTracked(_ date: Date) -> Bool {
        trackedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    // MARK: - Load Data

    private func loadTrackedDays() {
        isLoading = true

        Task {
            do {
                // Get date range for current month
                guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
                    return
                }

                // Fetch metrics for the month
                let metrics = try await HealthMetricsAPI.shared.getMetricHistory(
                    type: "energy_mood",
                    range: .month,
                    limit: 100
                )

                // Also check weight and other metrics
                let weightMetrics = try await HealthMetricsAPI.shared.getMetricHistory(
                    type: "weight",
                    range: .month,
                    limit: 100
                )

                await MainActor.run {
                    var dates: Set<Date> = []
                    var todayItems: [String] = []
                    let today = calendar.startOfDay(for: Date())

                    for metric in metrics {
                        if let date = metric.date {
                            let dayStart = calendar.startOfDay(for: date)
                            dates.insert(dayStart)
                            if calendar.isDate(dayStart, inSameDayAs: today) {
                                if !todayItems.contains("Mood") {
                                    todayItems.append("Mood")
                                }
                            }
                        }
                    }

                    for metric in weightMetrics {
                        if let date = metric.date {
                            let dayStart = calendar.startOfDay(for: date)
                            dates.insert(dayStart)
                            if calendar.isDate(dayStart, inSameDayAs: today) {
                                if !todayItems.contains("Weight") {
                                    todayItems.append("Weight")
                                }
                            }
                        }
                    }

                    trackedDates = dates
                    totalDaysTracked = dates.count
                    todayTrackedItems = todayItems
                    trackedToday = dates.contains { calendar.isDate($0, inSameDayAs: today) }

                    if !metrics.isEmpty || !weightMetrics.isEmpty {
                        var trackedTypes: [String] = []
                        if !metrics.isEmpty { trackedTypes.append("Mood") }
                        if !weightMetrics.isEmpty { trackedTypes.append("Weight") }
                        mostTrackedMetrics = "Most tracked: \(trackedTypes.joined(separator: ", "))"
                    } else {
                        mostTrackedMetrics = "Start tracking to see your progress"
                    }

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    trackedDates = []
                    totalDaysTracked = 0
                    mostTrackedMetrics = "Connect to see tracked days"
                    isLoading = false
                }
            }
        }
    }
}

struct DaysTrackedView_Previews: PreviewProvider {
    static var previews: some View {
        DaysTrackedView()
    }
}
