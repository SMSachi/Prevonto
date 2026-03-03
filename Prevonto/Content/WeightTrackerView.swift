// Weight Tracker page shows the user's weight across week or month.
import Foundation
import SwiftUI
import Charts

struct WeightChartView: View {
    let data: [(String, Double)]

    private var yAxisRange: ClosedRange<Double> {
        let values = data.map { $0.1 }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 100...200
        }
        let padding = max((maxVal - minVal) * 0.2, 5) // At least 5 lbs padding
        return (minVal - padding)...(maxVal + padding)
    }

    var body: some View {
        Chart {
            ForEach(data, id: \.0) { day, value in
                LineMark(
                    x: .value("Day", day),
                    y: .value("Weight", value)
                )
                .foregroundStyle(Color(red: 0.01, green: 0.33, blue: 0.18))
                .interpolationMethod(.monotone)
                .symbol(Circle())
                .symbolSize(30)

                AreaMark(
                    x: .value("Day", day),
                    y: .value("Weight", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.01, green: 0.33, blue: 0.18).opacity(0.3), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartYScale(domain: yAxisRange)
        .frame(height: 180)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}


class WeightTrackerManager: ObservableObject {
    @Published var entries: [WeightEntry] = []
    @Published var isSaving = false
    private var repository: WeightRepository

    init(repository: WeightRepository = LocalWeightRepository()) {
        self.repository = repository
        self.entries = repository.fetchEntries()
    }

    var averageWeightLb: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map { $0.weightLb }.reduce(0, +) / Double(entries.count)
    }

    var hasEntryForToday: Bool {
        repository.hasEntryForToday()
    }

    var todaysEntry: WeightEntry? {
        repository.getTodaysEntry()
    }

    func addOrUpdateEntry(weight: Double, unit: String = "lbs") {
        // Save locally (repository handles add vs update)
        repository.addEntry(weight: weight)
        entries = repository.fetchEntries()

        // Also save to backend API
        isSaving = true
        Task {
            do {
                try await HealthMetricsAPI.shared.saveWeight(weight: weight, unit: unit)
                print("✅ Weight saved to API: \(weight) \(unit)")
            } catch {
                print("❌ Failed to save weight to API: \(error)")
            }
            await MainActor.run {
                self.isSaving = false
            }
        }
    }

    func updateEntry(id: UUID, weight: Double, unit: String = "lbs") {
        repository.updateEntry(id: id, weight: weight)
        entries = repository.fetchEntries()

        // Also save to backend API
        isSaving = true
        Task {
            do {
                try await HealthMetricsAPI.shared.saveWeight(weight: weight, unit: unit)
                print("✅ Weight updated to API: \(weight) \(unit)")
            } catch {
                print("❌ Failed to update weight to API: \(error)")
            }
            await MainActor.run {
                self.isSaving = false
            }
        }
    }
}



// MARK: - WeightTrackerView

struct WeightTrackerView: View {
    @State private var selectedUnit: String = "Lb"
    @State private var selectedTab: String = "Week"
    @State private var inputWeight: String = ""
    @State private var editingEntry: WeightEntry? = nil
    @State private var showEditAlert: Bool = false
    @State private var editWeight: String = ""
    @ObservedObject private var manager = WeightTrackerManager()


    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                inputSection
                averageSection
                weekMonthToggle
                graphPlaceholder
                trendsSection
                loggedEntriesSection
            }
            .padding(.horizontal)  // Add padding once here
            .padding(.top)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Weight Full Page")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        Text("Weight Tracker")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if manager.hasEntryForToday {
                Text("Update today's weight")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
            }

            HStack {
                TextField("Enter weight", text: $inputWeight)
                    .keyboardType(.decimalPad)
                    .padding(12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(width: 120)

                Text(selectedUnit)
                    .foregroundColor(.gray)

                Spacer()

                Button(action: {
                    if let value = Double(inputWeight) {
                        let unit = selectedUnit == "Kg" ? "kg" : "lbs"
                        manager.addOrUpdateEntry(weight: value, unit: unit)
                        inputWeight = ""
                    }
                }) {
                    HStack(spacing: 4) {
                        if manager.isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: manager.hasEntryForToday ? "pencil.circle" : "plus.circle")
                        }
                        Text(manager.isSaving ? "Saving..." : (manager.hasEntryForToday ? "Update" : "Add"))
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(manager.isSaving || inputWeight.isEmpty)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private var averageSection: some View {
        let avg = manager.averageWeightLb
        let displayWeight = selectedUnit == "Kg" ? avg * 0.453592 : avg

        return VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Average")
                .font(.subheadline)
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("\(String(format: "%.1f", displayWeight)) \(selectedUnit.lowercased()).")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.gray)

                unitToggle
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 1)
        }
        .padding(.horizontal) // Padding around the entire section
    }
    private var unitToggle: some View {
        HStack(spacing: 0) {
            Button(action: { selectedUnit = "Lb" }) {
                Text("Lb")
                    .padding(.vertical, 6)
                    .padding(.horizontal, 20)
                    .background(selectedUnit == "Lb" ? Color.secondaryColor : Color.gray.opacity(0.2))
                    .foregroundColor(selectedUnit == "Lb" ? .white : .black)
            }
            .cornerRadius(6)

            Button(action: { selectedUnit = "Kg" }) {
                Text("Kg")
                    .padding(.vertical, 6)
                    .padding(.horizontal, 20)
                    .background(selectedUnit == "Kg" ? Color.secondaryColor : Color.gray.opacity(0.2))
                    .foregroundColor(selectedUnit == "Kg" ? .white : .black)
            }
            .cornerRadius(6)
        }
    }

    private var weekMonthToggle: some View {
        HStack {
            Button("Week") {
                selectedTab = "Week"
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(selectedTab == "Week" ? Color.secondaryColor : Color.gray.opacity(0.2))
            .foregroundColor(selectedTab == "Week" ? .white : .black)
            .cornerRadius(8)

            Button("Month") {
                selectedTab = "Month"
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(selectedTab == "Month" ? Color.secondaryColor : Color.gray.opacity(0.2))
            .foregroundColor(selectedTab == "Month" ? .white : .black)
            .cornerRadius(8)
        }
    }

    private var graphPlaceholder: some View {
        VStack {
            if manager.entries.isEmpty {
                // No data state
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(Color.gray.opacity(0.5))
                    Text("No weight data yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Add your first entry above")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(height: 150)
            } else {
                // Get most recent entries and sort by date ascending (oldest first for chart)
                let recentEntries = Array(manager.entries.prefix(7)).sorted { $0.date < $1.date }
                let chartData: [(String, Double)] = recentEntries.enumerated().map { index, entry in
                    let formatter = DateFormatter()
                    // Use index to make labels unique if same day
                    if recentEntries.filter({ Calendar.current.isDate($0.date, inSameDayAs: entry.date) }).count > 1 {
                        formatter.dateFormat = "h:mm a"
                    } else {
                        formatter.dateFormat = "E"
                    }
                    return (formatter.string(from: entry.date), entry.weightLb)
                }
                WeightChartView(data: chartData)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private var trendsSection: some View {
        let trendInfo = calculateTrend()

        return VStack(alignment: .leading, spacing: 8) {
            Text("Trends")
                .font(.headline)
                .foregroundColor(.black)

            if manager.entries.count < 2 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                    Text("Add more weight entries to see your trends over time.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else {
                HStack {
                    Image(systemName: trendInfo.icon)
                        .foregroundColor(trendInfo.color)
                        .frame(width: 20, height: 20)
                    Text(trendInfo.message)
                        .font(.footnote)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(trendInfo.color.opacity(0.1))
                .cornerRadius(12)

                if let change = trendInfo.weeklyChange {
                    HStack {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .foregroundColor(change >= 0 ? .orange : .green)
                            .frame(width: 20, height: 20)
                        Text("Weekly change: \(change >= 0 ? "+" : "")\(String(format: "%.1f", change)) \(selectedUnit.lowercased())")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    private func calculateTrend() -> (message: String, icon: String, color: Color, weeklyChange: Double?) {
        guard manager.entries.count >= 2 else {
            return ("Not enough data", "chart.line.uptrend.xyaxis", .gray, nil)
        }

        let sortedEntries = manager.entries.sorted { $0.date > $1.date }
        let latest = sortedEntries[0].weightLb
        let previous = sortedEntries[1].weightLb
        let change = latest - previous

        // Weekly change calculation
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let weekOldEntry = sortedEntries.first { $0.date <= weekAgo }
        let weeklyChange: Double? = weekOldEntry.map { latest - $0.weightLb }

        if abs(change) < 0.5 {
            return ("Weight stable — great consistency!", "checkmark.circle.fill", Color(red: 0.36, green: 0.55, blue: 0.37), weeklyChange)
        } else if change > 0 {
            return ("Weight increased by \(String(format: "%.1f", change)) lbs since last entry", "arrow.up.circle.fill", .orange, weeklyChange)
        } else {
            return ("Weight decreased by \(String(format: "%.1f", abs(change))) lbs since last entry", "arrow.down.circle.fill", .green, weeklyChange)
        }
    }

    private var loggedEntriesSection: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Logged Entries")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                Spacer()
                Image(systemName: "chevron.down")
            }

            if manager.entries.isEmpty {
                Text("No entries yet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                ForEach(manager.entries) { entry in
                    HStack {
                        Text(entry.formattedDate)
                        Spacer()
                        Text(String(format: "%.1f", entry.weight(in: selectedUnit)))
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingEntry = entry
                        editWeight = String(format: "%.1f", entry.weight(in: selectedUnit))
                        showEditAlert = true
                    }
                    Divider()
                }
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3))
        )
        .alert("Edit Weight", isPresented: $showEditAlert) {
            TextField("Weight", text: $editWeight)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {
                editingEntry = nil
            }
            Button("Save") {
                if let entry = editingEntry, let newWeight = Double(editWeight) {
                    let weightInLb = selectedUnit == "Kg" ? newWeight / 0.453592 : newWeight
                    let unit = selectedUnit == "Kg" ? "kg" : "lbs"
                    manager.updateEntry(id: entry.id, weight: weightInLb, unit: unit)
                }
                editingEntry = nil
            }
        } message: {
            Text("Enter new weight in \(selectedUnit)")
        }
    }
}

// MARK: - Preview

struct WeightTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        WeightTrackerView()
    }
}
