// Blood Glucose page displays user's blood glucose levels by day, week, or month
import SwiftUI
import Charts

struct BloodGlucoseView: View {
    @Environment(\.dismiss) var dismiss

    // View state
    @State private var selectedTab: GlucoseTimeTab = .week
    @State private var selectedDate = Date()
    @State private var isLoading = false

    // Data
    @State private var weeklyAverage: Double = 0
    @State private var chartData: [GlucoseDataPoint] = []
    @State private var highlights: [String] = []
    @State private var hasData = false

    // Input state
    @State private var showingInputSheet = false
    @State private var glucoseInput = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection

                    ScrollView {
                        VStack(spacing: 24) {
                            titleSection
                            averageSection
                            tabPicker
                            calendarWeekPicker
                            chartSection
                            highlightsSection
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }

                // Floating Log Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingInputSheet = true }) {
                            Text("Log")
                                .font(.custom("Noto Sans", size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                                .cornerRadius(24)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadData() }
            .onChange(of: selectedDate) { _, _ in loadData() }
            .onChange(of: selectedTab) { _, _ in loadData() }
            .sheet(isPresented: $showingInputSheet) {
                logInputSheet
            }
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Blood glucose")
                .font(.custom("Noto Sans", size: 28))
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            Text("Your blood glucose levels must be recorded by you on a bi-weekly basis.")
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Average Section
    var averageSection: some View {
        VStack(spacing: 4) {
            if hasData {
                Text("\(Int(weeklyAverage)) mg/dl")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
            } else {
                Text("-- mg/dl")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
            }

            Text("\(selectedTab.rawValue)ly Average")
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(16)
    }

    // MARK: - Tab Picker
    var tabPicker: some View {
        HStack(spacing: 8) {
            ForEach(GlucoseTimeTab.allCases, id: \.self) { tab in
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

    // MARK: - Chart Section
    var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chartData.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "drop")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                    Text("No glucose data available")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    Text("Tap Log to record your first reading")
                        .font(.custom("Noto Sans", size: 12))
                        .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(12)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                // Chart based on selected tab
                if selectedTab == .day {
                    // Line chart for day view
                    Chart {
                        ForEach(chartData) { point in
                            LineMark(
                                x: .value("Time", point.label),
                                y: .value("mg/dL", point.value)
                            )
                            .foregroundStyle(Color(red: 0.36, green: 0.55, blue: 0.37))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Time", point.label),
                                y: .value("mg/dL", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.36, green: 0.55, blue: 0.37).opacity(0.3), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Time", point.label),
                                y: .value("mg/dL", point.value)
                            )
                            .foregroundStyle(Color(red: 0.36, green: 0.55, blue: 0.37))
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text("\(Int(val))")
                                        .font(.custom("Noto Sans", size: 10))
                                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                                }
                            }
                            AxisGridLine()
                        }
                    }
                } else {
                    // Bar chart for week/month view
                    Chart {
                        ForEach(chartData) { point in
                            BarMark(
                                x: .value("Day", point.label),
                                y: .value("mg/dL", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.01, green: 0.33, blue: 0.18), Color(red: 0.36, green: 0.55, blue: 0.37)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .cornerRadius(4)
                        }

                        // Average line
                        if weeklyAverage > 0 {
                            RuleMark(y: .value("Avg", weeklyAverage))
                                .foregroundStyle(Color.orange)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("\(Int(weeklyAverage)) mg/dl")
                                        .font(.custom("Noto Sans", size: 10))
                                        .foregroundColor(.orange)
                                }
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let val = value.as(Double.self) {
                                    Text("\(Int(val))")
                                        .font(.custom("Noto Sans", size: 10))
                                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                                }
                            }
                            AxisGridLine()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Highlights Section
    var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            if highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HighlightRow(number: 1, text: "Log more readings to see insights")
                    HighlightRow(number: 2, text: "Track trends over time")
                }
            } else {
                ForEach(Array(highlights.enumerated()), id: \.offset) { index, highlight in
                    HighlightRow(number: index + 1, text: highlight)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Log Input Sheet
    var logInputSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(formattedDate)
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

                VStack(spacing: 8) {
                    Text("Enter glucose level")
                        .font(.custom("Noto Sans", size: 16))
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                    HStack {
                        TextField("0", text: $glucoseInput)
                            .keyboardType(.numberPad)
                            .font(.system(size: 48, weight: .medium))
                            .multilineTextAlignment(.center)
                            .frame(width: 150)

                        Text("mg/dl")
                            .font(.custom("Noto Sans", size: 18))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    }
                }

                Spacer()

                Button(action: saveGlucose) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save")
                            .font(.custom("Noto Sans", size: 18))
                            .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(glucoseInput.isEmpty ? Color.gray : Color(red: 0.01, green: 0.33, blue: 0.18))
                .cornerRadius(12)
                .disabled(glucoseInput.isEmpty || isSaving)
            }
            .padding(24)
            .navigationTitle("Log Glucose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingInputSheet = false
                        glucoseInput = ""
                    }
                }
            }
        }
        .presentationDetents([.height(350)])
    }

    // MARK: - Computed Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, yyyy"
        return formatter.string(from: Date())
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

        Task {
            let range: TimeRange = selectedTab == .day ? .day : selectedTab == .week ? .week : .month

            // Load history first (this is the primary data)
            do {
                let history = try await HealthMetricsAPI.shared.getMetricHistory(type: "blood_glucose", range: range)

                await MainActor.run {
                    if !history.isEmpty {
                        hasData = true

                        // Convert to chart data - sort by date and ensure unique labels
                        let sortedHistory = history.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
                        chartData = sortedHistory.enumerated().compactMap { index, record in
                            guard let value = record.value["value"] else { return nil }
                            let label = formatLabel(for: record.date, tab: selectedTab, index: index)
                            return GlucoseDataPoint(label: label, value: value)
                        }

                        // Calculate average from actual data
                        let values = chartData.map { $0.value }
                        weeklyAverage = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)

                        // Generate highlights from real data
                        highlights = generateHighlightsFromData(values: values)
                    } else {
                        hasData = false
                        chartData = []
                        weeklyAverage = 0
                        highlights = []
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    hasData = false
                    chartData = []
                    weeklyAverage = 0
                    highlights = []
                    isLoading = false
                }
            }
        }
    }

    private func generateHighlightsFromData(values: [Double]) -> [String] {
        var result: [String] = []
        guard !values.isEmpty else { return result }

        let avg = values.reduce(0, +) / Double(values.count)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0

        // Range insight
        if maxVal - minVal > 50 {
            result.append("Your glucose varied by \(Int(maxVal - minVal)) mg/dL - consider consistent meal timing")
        } else if maxVal - minVal < 20 {
            result.append("Your glucose levels are stable - great consistency!")
        }

        // Average assessment
        if avg < 100 {
            result.append("Average of \(Int(avg)) mg/dL is within normal fasting range")
        } else if avg < 125 {
            result.append("Average of \(Int(avg)) mg/dL is slightly elevated - monitor closely")
        } else {
            result.append("Average of \(Int(avg)) mg/dL is high - consult your healthcare provider")
        }

        // Trend
        if values.count >= 3 {
            let firstHalf = Array(values.prefix(values.count / 2))
            let secondHalf = Array(values.suffix(values.count / 2))
            let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)

            if secondAvg < firstAvg - 5 {
                result.append("Your levels are trending downward")
            } else if secondAvg > firstAvg + 5 {
                result.append("Your levels are trending upward")
            }
        }

        return result
    }

    private func formatLabel(for date: Date?, tab: GlucoseTimeTab, index: Int) -> String {
        guard let date = date else {
            return tab == .day ? "\(index * 3)a" : tab == .week ? ["M", "T", "W", "T", "F", "S", "S"][index % 7] : "\(index + 1)"
        }

        let formatter = DateFormatter()
        switch tab {
        case .day:
            formatter.dateFormat = "ha"
        case .week:
            formatter.dateFormat = "E"
        case .month:
            formatter.dateFormat = "d"
        }
        return formatter.string(from: date)
    }

    private func generateHighlights(stats: StatisticsResponse) -> [String] {
        var result: [String] = []

        if let avg = stats.average["value"] {
            if avg < 100 {
                result.append("Your average is within normal range")
            } else if avg < 125 {
                result.append("Your average is slightly elevated")
            } else {
                result.append("Consider consulting your doctor about your levels")
            }
        }

        if stats.trend == "decreasing" {
            result.append("Your glucose levels are trending down")
        } else if stats.trend == "increasing" {
            result.append("Your glucose levels are trending up")
        }

        return result
    }

    private func saveGlucose() {
        guard let value = Double(glucoseInput) else { return }
        isSaving = true

        Task {
            do {
                try await HealthMetricsAPI.shared.saveBloodGlucose(value: value)
                await MainActor.run {
                    isSaving = false
                    showingInputSheet = false
                    glucoseInput = ""
                    loadData()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum GlucoseTimeTab: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct GlucoseDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct HighlightRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.custom("Noto Sans", size: 14))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            Text(text)
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
        }
    }
}

// Preview
struct BloodGlucoseView_Previews: PreviewProvider {
    static var previews: some View {
        BloodGlucoseView()
    }
}
