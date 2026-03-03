// Mood and energy data structure
import Foundation

struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let moodValue: String  // Store the raw value string
    let energy: Int

    init(date: Date, moodValue: String, energy: Int) {
        self.id = UUID()
        self.date = date
        self.moodValue = moodValue
        self.energy = energy
    }

    init(id: UUID, date: Date, moodValue: String, energy: Int) {
        self.id = id
        self.date = date
        self.moodValue = moodValue
        self.energy = energy
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
