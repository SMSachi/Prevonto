// Local storing of mood/energy data
import Foundation

class LocalMoodRepository: MoodRepository {
    private let key = "mood_entries"
    private var entries: [MoodEntry] = []

    init() {
        load()
    }

    func fetchEntries() -> [MoodEntry] {
        entries
    }

    func addEntry(moodValue: String, energy: Int) {
        // Check if entry exists for today - if so, update instead of adding
        if let todaysEntry = getTodaysEntry() {
            if let index = entries.firstIndex(where: { $0.id == todaysEntry.id }) {
                let updatedEntry = MoodEntry(id: todaysEntry.id, date: todaysEntry.date, moodValue: moodValue, energy: energy)
                entries[index] = updatedEntry
                save()
                return
            }
        }

        let newEntry = MoodEntry(date: Date(), moodValue: moodValue, energy: energy)
        entries.insert(newEntry, at: 0)
        save()
    }

    func hasEntryForToday() -> Bool {
        return getTodaysEntry() != nil
    }

    func getTodaysEntry() -> MoodEntry? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.first { entry in
            calendar.startOfDay(for: entry.date) == today
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            entries = saved
        }
    }
}
