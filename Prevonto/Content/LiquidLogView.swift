// Liquid Log - Track water and alcohol intake
import SwiftUI

struct LiquidLogView: View {
    @Environment(\.dismiss) private var dismiss

    // View state
    @State private var selectedTab: LiquidType = .water
    @State private var selectedDate = Date()
    @State private var intakeAmount: Double = 200
    @State private var dailyGoal: Double = 1790
    @State private var todayIntake: Double = 500
    @State private var entries: [LiquidEntry] = []
    @State private var showingOtherSheet = false
    @State private var otherName = ""
    @State private var selectedAlcoholType: AlcoholType = .beer

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
                            dropletSection
                            progressSection
                            sliderSection
                            typeButtons
                            logButton
                            entriesSection
                            Spacer(minLength: 50)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadEntries() }
            .sheet(isPresented: $showingOtherSheet) {
                otherDrinkSheet
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

    // MARK: - Title and Tab Picker
    var tabPicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Liquid Log")
                    .font(.custom("Noto Sans", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

                Text("Track your liquid intake")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }

            HStack(spacing: 0) {
                ForEach(LiquidType.allCases, id: \.self) { tab in
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

    // MARK: - Droplet Section
    var dropletSection: some View {
        ZStack {
            // Droplet background
            Image(systemName: "drop.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .foregroundColor(Color(red: 0.85, green: 0.90, blue: 0.95))

            // Fill level (from bottom)
            GeometryReader { geo in
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.70, green: 0.85, blue: 0.95), Color(red: 0.50, green: 0.75, blue: 0.90)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geo.size.height * fillPercentage)
                        .mask(
                            Image(systemName: "drop.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        )
                }
            }
            .frame(height: 200)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Progress Section
    var progressSection: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(todayIntake))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

                Text("/ \(Int(dailyGoal)) \(selectedTab == .water ? "ml" : "oz")")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
            }

            Button(action: { /* Set goal */ }) {
                Text("Set Goal")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    .underline()
            }
        }
    }

    // MARK: - Slider Section
    var sliderSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("100")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

                Spacer()

                Text("\(Int(intakeAmount))")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))

                Spacer()

                Text("300")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }

            Slider(value: $intakeAmount, in: 100...300, step: 10)
                .tint(Color(red: 0.01, green: 0.33, blue: 0.18))

            Text(selectedTab == .water ? "ml" : "oz")
                .font(.custom("Noto Sans", size: 14))
                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
        }
        .padding()
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(12)
    }

    // MARK: - Type Buttons
    var typeButtons: some View {
        HStack(spacing: 12) {
            if selectedTab == .water {
                Button(action: { /* Select water */ }) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                        Text("Water")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                    )
                }

                Button(action: { showingOtherSheet = true }) {
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))
                        Text("Other")
                            .font(.custom("Noto Sans", size: 14))
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                    )
                }
            } else {
                ForEach(AlcoholType.allCases, id: \.self) { type in
                    Button(action: { selectedAlcoholType = type }) {
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 12))
                                .foregroundColor(selectedAlcoholType == type ? .white : Color(red: 0.01, green: 0.33, blue: 0.18))
                            Text(type.rawValue)
                                .font(.custom("Noto Sans", size: 12))
                                .foregroundColor(selectedAlcoholType == type ? .white : Color(red: 0.40, green: 0.42, blue: 0.46))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(selectedAlcoholType == type ? Color(red: 0.01, green: 0.33, blue: 0.18) : Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedAlcoholType == type ? Color.clear : Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Log Button
    var logButton: some View {
        Button(action: logIntake) {
            Text("Log")
                .font(.custom("Noto Sans", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 0.01, green: 0.33, blue: 0.18))
                .cornerRadius(12)
        }
    }

    // MARK: - Entries Section
    var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Logged Entries")
                    .font(.custom("Noto Sans", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.01, green: 0.33, blue: 0.18))

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
            }

            if entries.isEmpty {
                Text("No entries yet for today")
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(entries.prefix(3)) { entry in
                    HStack {
                        Image(systemName: entry.type == .water ? "drop.fill" : "wineglass")
                            .foregroundColor(entry.type == .water ? .blue : .purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name ?? entry.type.rawValue)
                                .font(.custom("Noto Sans", size: 14))
                                .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                            Text(entry.timeString)
                                .font(.custom("Noto Sans", size: 12))
                                .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                        }

                        Spacer()

                        Text("\(Int(entry.amount)) \(entry.type == .water ? "ml" : "oz")")
                            .font(.custom("Noto Sans", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.46))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(Color(red: 0.96, green: 0.97, blue: 0.98))
        .cornerRadius(12)
    }

    // MARK: - Other Drink Sheet
    var otherDrinkSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                HStack {
                    Text(formattedDate)
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

                    Spacer()

                    Button("Clear") {
                        otherName = ""
                    }
                    .font(.custom("Noto Sans", size: 14))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.custom("Noto Sans", size: 14))
                        .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60))

                    TextField("Gatorade", text: $otherName)
                        .font(.custom("Noto Sans", size: 16))
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.85, green: 0.85, blue: 0.85), lineWidth: 1)
                        )
                }

                Button(action: {
                    logOtherDrink()
                    showingOtherSheet = false
                }) {
                    Text("Save")
                        .font(.custom("Noto Sans", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(otherName.isEmpty ? Color.gray : Color(red: 0.01, green: 0.33, blue: 0.18))
                        .cornerRadius(12)
                }
                .disabled(otherName.isEmpty)

                Spacer()
            }
            .padding(24)
            .navigationBarHidden(true)
        }
        .presentationDetents([.height(280)])
    }

    // MARK: - Computed Properties

    private var fillPercentage: Double {
        min(1.0, todayIntake / dailyGoal)
    }

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

    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "liquidEntries"),
           let decoded = try? JSONDecoder().decode([LiquidEntry].self, from: data) {
            entries = decoded.filter { Calendar.current.isDateInToday($0.date) }
            todayIntake = entries.filter { $0.type == .water }.reduce(0) { $0 + $1.amount }
        }
    }

    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "liquidEntries")
        }
    }

    private func logIntake() {
        let entry = LiquidEntry(
            type: selectedTab,
            amount: intakeAmount,
            name: selectedTab == .alcohol ? selectedAlcoholType.rawValue : nil,
            date: Date()
        )
        entries.insert(entry, at: 0)
        todayIntake += intakeAmount
        saveEntries()
    }

    private func logOtherDrink() {
        let entry = LiquidEntry(
            type: .water,
            amount: intakeAmount,
            name: otherName,
            date: Date()
        )
        entries.insert(entry, at: 0)
        todayIntake += intakeAmount
        saveEntries()
        otherName = ""
    }
}

// MARK: - Supporting Types

enum LiquidType: String, CaseIterable, Codable {
    case water = "Water"
    case alcohol = "Alcohol"
}

enum AlcoholType: String, CaseIterable {
    case beer = "Beer"
    case wine = "Wine"
    case spirits = "Spirits"

    var icon: String {
        switch self {
        case .beer: return "mug.fill"
        case .wine: return "wineglass"
        case .spirits: return "drop.fill"
        }
    }
}

struct LiquidEntry: Identifiable, Codable {
    var id = UUID()
    var type: LiquidType
    var amount: Double
    var name: String?
    var date: Date

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Preview
struct LiquidLogView_Previews: PreviewProvider {
    static var previews: some View {
        LiquidLogView()
    }
}
