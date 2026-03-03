// Mood Tracker page displays user's mood across week or month.
import SwiftUI
import Charts

struct MoodLogEntry: Identifiable {
    let id: UUID
    let date: Date
    let mood: MoodType
    let energy: Int

    init(date: Date, mood: MoodType, energy: Int) {
        self.id = UUID()
        self.date = date
        self.mood = mood
        self.energy = energy
    }

    init(id: UUID, date: Date, mood: MoodType, energy: Int) {
        self.id = id
        self.date = date
        self.mood = mood
        self.energy = energy
    }

    // Convert from MoodEntry (persisted) to MoodLogEntry (view model)
    init(from entry: MoodEntry) {
        self.id = entry.id
        self.date = entry.date
        self.mood = MoodType(rawValue: entry.moodValue) ?? .neutral
        self.energy = entry.energy
    }
}

enum MoodType: String, CaseIterable {
    case verySad = "Very Sad"
    case sad = "Sad"
    case neutral = "Neutral"
    case happy = "Happy"
    case veryHappy = "Very Happy"

    var color: Color {
        switch self {
        case .verySad: return Color(red: 0.60, green: 0.25, blue: 0.30) // Dark maroon/red
        case .sad: return Color(red: 0.65, green: 0.40, blue: 0.30) // Brown/rust
        case .neutral: return Color(red: 0.80, green: 0.65, blue: 0.25) // Yellow/gold
        case .happy: return Color(red: 0.85, green: 0.75, blue: 0.35) // Light yellow
        case .veryHappy: return Color(red: 0.90, green: 0.80, blue: 0.40) // Lighter yellow
        }
    }

    // Convert to API value (1-10 scale)
    var apiValue: Int {
        switch self {
        case .verySad: return 2
        case .sad: return 4
        case .neutral: return 5
        case .happy: return 7
        case .veryHappy: return 9
        }
    }
}

// Custom Mood Icon View matching Figma design
struct MoodIconView: View {
    let mood: MoodType
    var size: CGFloat = 50

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(mood.color)
                .frame(width: size, height: size)

            // Face
            VStack(spacing: size * 0.08) {
                // Eyes
                HStack(spacing: size * 0.25) {
                    eyeView
                    eyeView
                }

                // Mouth
                mouthView
            }
        }
    }

    @ViewBuilder
    private var eyeView: some View {
        switch mood {
        case .verySad:
            // Angry eyebrows with eyes
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: size * 0.15, height: size * 0.04)
                    .rotationEffect(.degrees(-20))
                Rectangle()
                    .fill(Color.white)
                    .frame(width: size * 0.10, height: size * 0.10)
                    .cornerRadius(size * 0.02)
            }
        case .sad:
            // Sad eyebrows with eyes
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: size * 0.12, height: size * 0.03)
                    .rotationEffect(.degrees(15))
                Rectangle()
                    .fill(Color.white)
                    .frame(width: size * 0.10, height: size * 0.10)
                    .cornerRadius(size * 0.02)
            }
        default:
            // Normal square eyes
            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.12, height: size * 0.12)
                .cornerRadius(size * 0.02)
        }
    }

    @ViewBuilder
    private var mouthView: some View {
        switch mood {
        case .verySad, .sad:
            // Frown - curved down
            Arc(startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                .stroke(Color.white, lineWidth: size * 0.06)
                .frame(width: size * 0.35, height: size * 0.12)
        case .neutral:
            // Straight line
            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.35, height: size * 0.06)
                .cornerRadius(size * 0.02)
        case .happy:
            // Smile - curved up
            Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                .stroke(Color.white, lineWidth: size * 0.06)
                .frame(width: size * 0.35, height: size * 0.12)
        case .veryHappy:
            // Big smile
            Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                .stroke(Color.white, lineWidth: size * 0.08)
                .frame(width: size * 0.40, height: size * 0.15)
        }
    }
}

// Arc shape for mouth curves
struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: clockwise)
        return path
    }
}

struct MoodEntryCard: View {
    @Binding var show: Bool
    var onNext: (MoodType) -> Void
    @State private var selectedMood = MoodType.neutral

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text(Date(), style: .date)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Clear") {
                        selectedMood = .neutral
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                }

                ProgressView(value: 0.5)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.primaryColor))

                Text("1 of 2")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("How are you feeling today?")
                    .font(.headline)

                // Mood icon selection - vertical stack
                VStack(spacing: 8) {
                    ForEach(MoodType.allCases, id: \.self) { mood in
                        Button(action: { selectedMood = mood }) {
                            MoodIconView(mood: mood, size: 45)
                                .opacity(selectedMood == mood ? 1.0 : 0.5)
                                .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 8)

                Text("I'm feeling \(selectedMood.rawValue.lowercased()).")
                    .font(.subheadline)

                Button("Next") {
                    onNext(selectedMood)
                    show = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.primaryColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Mood Tracker Manager
class MoodTrackerManager: ObservableObject {
    @Published var entries: [MoodLogEntry] = []
    @Published var isSaving = false
    private var repository: MoodRepository

    init(repository: MoodRepository = LocalMoodRepository()) {
        self.repository = repository
        loadEntries()
    }

    private func loadEntries() {
        entries = repository.fetchEntries().map { MoodLogEntry(from: $0) }
    }

    var averageEnergy: Double {
        guard !entries.isEmpty else { return 0 }
        return Double(entries.map { $0.energy }.reduce(0, +)) / Double(entries.count)
    }

    var latestMood: MoodType? {
        entries.first?.mood
    }

    var hasEntryForToday: Bool {
        repository.hasEntryForToday()
    }

    func addEntry(mood: MoodType, energy: Int) {
        // Save locally
        repository.addEntry(moodValue: mood.rawValue, energy: energy)
        loadEntries()

        // Also save to backend API
        isSaving = true
        Task {
            do {
                try await HealthMetricsAPI.shared.saveEnergyMood(energy: energy, mood: mood.apiValue)
                print("✅ Mood/Energy saved to API: energy=\(energy), mood=\(mood.apiValue)")
            } catch {
                print("❌ Failed to save mood/energy to API: \(error)")
            }
            await MainActor.run {
                self.isSaving = false
            }
        }
    }
}

struct EnergyEntryCard: View {
    @Binding var show: Bool
    var onSave: (Int) -> Void
    @State private var selectedEnergy = 7
    @State private var isSaving = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text(Date(), style: .date)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                    Button("Clear") {
                        selectedEnergy = 7
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                }

                ProgressView(value: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.primaryColor))

                Text("2 of 2")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("What would you rate your energy levels?")
                    .font(.headline)
                    .multilineTextAlignment(.center)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(1...10, id: \.self) { val in
                            Text("\(val)")
                                .font(.system(size: val == selectedEnergy ? 48 : 32, weight: .bold))
                                .frame(width: 80, height: 80)
                                .background(val == selectedEnergy ? Color.secondaryColor : Color.clear)
                                .cornerRadius(12)
                                .foregroundColor(val == selectedEnergy ? .white : .gray)
                                .onTapGesture {
                                    selectedEnergy = val
                                }
                        }
                    }
                    .padding(.vertical, 40)
                }
                .frame(height: 300)

                Text("\(selectedEnergy)/10")
                    .font(.headline)

                Button(action: {
                    onSave(selectedEnergy)
                    show = false
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isSaving ? "Saving..." : "Save")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isSaving)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, 30)
        }
    }
}



struct MoodTrackerView: View {
    @State private var selectedTab = "Month"
    @StateObject private var manager = MoodTrackerManager()
    @State private var showMoodEntry = false
    @State private var showEnergyEntry = false
    @State private var tempMood: MoodType? = nil

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    logButton
                    moodSummary
                    toggleTabs
                    calendarSection
                    energyChart
                    insightSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Mood Tracker")
            .navigationBarTitleDisplayMode(.inline)

            if showMoodEntry {
                MoodEntryCard(show: $showMoodEntry) { mood in
                    tempMood = mood
                    showEnergyEntry = true
                }
            }

            if showEnergyEntry {
                EnergyEntryCard(show: $showEnergyEntry) { energy in
                    if let mood = tempMood {
                        // Add to local entries and save to API
                        manager.addEntry(mood: mood, energy: energy)
                        tempMood = nil
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mood tracker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryColor)
                Text("Track your mood and energy levels throughout the week to identify patterns.")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "xmark")
                .foregroundColor(.gray)
        }
    }

    private var logButton: some View {
        Button(action: {
            showMoodEntry = true
        }) {
            HStack {
                if manager.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(manager.isSaving ? "Saving..." : (manager.hasEntryForToday ? "Update today's mood" : "Log energy levels"))
            }
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.primaryColor)
            .cornerRadius(12)
        }
        .disabled(manager.isSaving)
    }

    private var moodSummary: some View {
        VStack(spacing: 4) {
            if manager.entries.isEmpty {
                Image(systemName: "face.dashed")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("No mood logged yet")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Tap 'Log energy levels' to start")
                    .font(.footnote)
                    .foregroundColor(.gray.opacity(0.7))
            } else {
                let latestMood = manager.latestMood ?? .neutral
                let avgEnergy = manager.averageEnergy

                MoodIconView(mood: latestMood, size: 40)
                Text(latestMood.rawValue)
                    .font(.headline)
                Text("Avg energy level: \(String(format: "%.1f", avgEnergy))/10")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private var toggleTabs: some View {
        HStack(spacing: 8) {
            toggleButton("Week")
            toggleButton("Month")
        }
    }

    private func toggleButton(_ title: String) -> some View {
        Button(title) {
            selectedTab = title
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(selectedTab == title ? Color.secondaryColor : Color.gray.opacity(0.2))
        .foregroundColor(selectedTab == title ? .white : .black)
        .cornerRadius(8)
    }

    private var calendarSection: some View {
        ExampleCalendarView(entries: manager.entries)
    }

    private var energyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Energy levels")
                .font(.headline)
                .foregroundColor(.primaryColor)

            if manager.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 30))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No data yet")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(manager.entries) { entry in
                        BarMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Energy", entry.energy)
                        )
                        .foregroundStyle(Color.secondaryColor)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day(.defaultDigits))
                    }
                }
                .chartYScale(domain: 0...10)
                .frame(height: 150)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insight")
                .font(.headline)
                .foregroundColor(.primaryColor)

            HStack(alignment: .top) {
                Circle()
                    .fill(Color.secondaryColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                    .overlay(Text("1").font(.footnote).foregroundColor(.primaryColor))
                Text("On the days you get more than 8 hours of sleep, you tend to have a 20% increase in energy levels as compared to your average.")
                    .font(.footnote)
                    .foregroundColor(.black)
            }
        }
    }
}


struct ExampleCalendarView: View {
    @State private var currentDate = Date()
    let entries: [MoodLogEntry]  // <- add this

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var daysInMonth: [Date] {
        guard let monthInterval = Calendar.current.dateInterval(of: .month, for: currentDate) else { return [] }
        var dates: [Date] = []
        var date = monthInterval.start
        while date < monthInterval.end {
            dates.append(date)
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        return dates
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearString(for: currentDate))
                    .font(.headline)
                Spacer()
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            let columns = Array(repeating: GridItem(.flexible()), count: 7)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["Su", "M", "T", "W", "Th", "F", "Sa"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                let firstWeekday = Calendar.current.component(.weekday, from: daysInMonth.first ?? Date()) - 1
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Text("").frame(height: 32)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    dayCell(for: date)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 1)
        }
    }

    private func dayCell(for date: Date) -> some View {
        let day = Calendar.current.component(.day, from: date)
        let color = moodColor(for: date)

        return ZStack {
            if color != .clear {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
            }

            Text("\(day)")
                .foregroundColor(color == .clear ? .black : .white)
                .frame(height: 32)
        }
    }

    private func moodColor(for date: Date) -> Color {
        if let entry = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            return entry.mood.color
        }
        return .clear
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
        }
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}


struct MoodTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        MoodTrackerView()
    }
}
