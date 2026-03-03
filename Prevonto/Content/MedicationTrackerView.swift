// Medication Log - Track daily medications with time-based scheduling
import SwiftUI

struct MedicationTrackerView: View {
    @Environment(\.dismiss) private var dismiss

    // View state
    @State private var selectedTab: MedicationViewTab = .daily
    @State private var selectedDate = Date()
    @State private var medications: [TrackedMedication] = []
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerSection

                    ScrollView {
                        VStack(spacing: 20) {
                            tabPicker
                            calendarWeekPicker

                            if selectedTab == .daily {
                                dailyView
                            } else {
                                weeklyView
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadMedications() }
            .sheet(isPresented: $showingAddSheet) {
                AddMedicationSheet(onSave: { medication in
                    medications.append(medication)
                    saveMedications()
                })
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

            Text("Medication Log")
                .font(.custom("Noto Sans", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            Spacer()

            Button(action: { showingAddSheet = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Picker
    var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(MedicationViewTab.allCases, id: \.self) { tab in
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

    // MARK: - Daily View
    var dailyView: some View {
        VStack(spacing: 0) {
            if medications.isEmpty {
                emptyState
            } else {
                // Group medications by time
                ForEach(groupedMedications, id: \.time) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Time header
                        Text(group.time)
                            .font(.custom("Noto Sans", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                            .padding(.top, 16)

                        // Medication cards for this time
                        ForEach(group.medications) { medication in
                            DailyMedicationCard(
                                medication: medication,
                                onTaken: { markMedicationStatus(medication, status: .taken) },
                                onSkipped: { markMedicationStatus(medication, status: .skipped) }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weekly View
    var weeklyView: some View {
        VStack(spacing: 20) {
            // Weekly completion ring
            weeklyCompletionCard

            // Daily breakdown
            ForEach(weeklyBreakdown, id: \.date) { day in
                WeeklyDaySection(day: day, medications: medicationsForDay(day.date))
            }
        }
    }

    // MARK: - Weekly Completion Card
    var weeklyCompletionCard: some View {
        HStack(spacing: 16) {
            // Completion ring
            ZStack {
                Circle()
                    .stroke(Color(red: 0.90, green: 0.90, blue: 0.90), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: weeklyCompletionRate)
                    .stroke(Color(red: 0.36, green: 0.55, blue: 0.37), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(weeklyCompletionRate * 100))%")
                    .font(.custom("Noto Sans", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.36, green: 0.55, blue: 0.37))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Completion")
                    .font(.custom("Noto Sans", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                Text(weekDateRange)
                    .font(.custom("Noto Sans", size: 12))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(12)
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills")
                .font(.system(size: 50))
                .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))

            Text("No medications added")
                .font(.custom("Noto Sans", size: 18))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

            Text("Tap + to add your medications and set reminders")
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.70))
                .multilineTextAlignment(.center)

            Button(action: { showingAddSheet = true }) {
                Text("Add Medication")
                    .font(.custom("Noto Sans", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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

    private var groupedMedications: [MedicationTimeGroup] {
        let grouped = Dictionary(grouping: medications) { $0.reminderTime ?? "No time set" }
        return grouped.map { MedicationTimeGroup(time: $0.key, medications: $0.value) }
            .sorted { $0.time < $1.time }
    }

    private var weeklyBreakdown: [WeekDay] {
        weekDays.filter { $0.date <= Date() }
    }

    private var weeklyCompletionRate: Double {
        let total = medications.count * 7
        guard total > 0 else { return 0 }
        let taken = medications.filter { $0.todayStatus == .taken }.count * 7
        return Double(taken) / Double(total)
    }

    private var weekDateRange: String {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }

    private func medicationsForDay(_ date: Date) -> [TrackedMedication] {
        // In a real app, filter by date
        return medications
    }

    // MARK: - Actions

    private func moveWeek(by weeks: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func loadMedications() {
        if let data = UserDefaults.standard.data(forKey: "trackedMedications"),
           let decoded = try? JSONDecoder().decode([TrackedMedication].self, from: data) {
            medications = decoded
        }
    }

    private func saveMedications() {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: "trackedMedications")
        }
    }

    private func markMedicationStatus(_ medication: TrackedMedication, status: MedicationStatus) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index].todayStatus = status
            if status == .taken {
                medications[index].lastTakenDate = Date()
            }
            saveMedications()
        }
    }
}

// MARK: - Daily Medication Card
struct DailyMedicationCard: View {
    let medication: TrackedMedication
    let onTaken: () -> Void
    let onSkipped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.custom("Noto Sans", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                Text(medication.dosage ?? "Instructions for intake")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }

            if medication.todayStatus == .pending {
                HStack(spacing: 12) {
                    Button(action: onTaken) {
                        Text("Taken")
                            .font(.custom("Noto Sans", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                            .cornerRadius(8)
                    }

                    Button(action: onSkipped) {
                        Text("Skipped")
                            .font(.custom("Noto Sans", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                            )
                    }
                }
            } else {
                HStack {
                    Image(systemName: medication.todayStatus == .taken ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(medication.todayStatus == .taken ? Color(red: 0.36, green: 0.55, blue: 0.37) : .orange)
                    Text(medication.todayStatus == .taken ? "Taken" : "Skipped")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(medication.todayStatus == .taken ? Color(red: 0.36, green: 0.55, blue: 0.37) : .orange)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Weekly Day Section
struct WeeklyDaySection: View {
    let day: WeekDay
    let medications: [TrackedMedication]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formattedDayHeader)
                .font(.custom("Noto Sans", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

            ForEach(medications) { medication in
                HStack {
                    Image(systemName: medication.todayStatus == .taken ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(medication.todayStatus == .taken ? Color(red: 0.36, green: 0.55, blue: 0.37) : Color(red: 0.85, green: 0.85, blue: 0.85))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(medication.name)
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                        Text(medication.reminderTime ?? "")
                            .font(.custom("Noto Sans", size: 12))
                            .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(12)
    }

    private var formattedDayHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: day.date)
    }
}

// MARK: - Add Medication Sheet
struct AddMedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Daily"
    @State private var reminderTime = Date()
    @State private var enableReminder = true

    let frequencyOptions = ["Daily", "Twice daily", "Weekly", "As needed"]
    let onSave: (TrackedMedication) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Medication name", text: $name)
                    TextField("Dosage (e.g., 10mg)", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencyOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }

                Section("Reminder") {
                    Toggle("Set reminder", isOn: $enableReminder)
                    if enableReminder {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedication()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveMedication() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let timeString = enableReminder ? formatter.string(from: reminderTime) : nil

        let medication = TrackedMedication(
            name: name,
            dosage: dosage.isEmpty ? nil : dosage,
            frequency: frequency,
            reminderTime: timeString,
            lastTakenDate: nil,
            todayStatus: .pending
        )
        onSave(medication)
    }
}

// MARK: - Supporting Types

enum MedicationViewTab: String, CaseIterable {
    case daily = "Daily View"
    case weekly = "Weekly View"
}

struct MedicationTimeGroup {
    let time: String
    let medications: [TrackedMedication]
}

struct TrackedMedication: Identifiable, Codable {
    var id = UUID()
    var name: String
    var dosage: String?
    var frequency: String?
    var reminderTime: String?
    var lastTakenDate: Date?
    var todayStatus: MedicationStatus = .pending
}

enum MedicationStatus: String, Codable {
    case pending
    case taken
    case skipped
}

// Preview
struct MedicationTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        MedicationTrackerView()
    }
}
