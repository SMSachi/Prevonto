// Local storing of weight data
import Foundation

class LocalWeightRepository: WeightRepository {
    private let key = "weight_entries"
    private var entries: [WeightEntry] = []

    init() {
        load()
    }

    func fetchEntries() -> [WeightEntry] {
        entries
    }

    func addEntry(weight: Double) {
        // Check if entry exists for today - if so, update instead of adding
        if let todaysEntry = getTodaysEntry() {
            updateEntry(id: todaysEntry.id, weight: weight)
            return
        }

        let newEntry = WeightEntry(date: Date(), weightLb: weight)
        entries.insert(newEntry, at: 0)
        save()
    }

    func updateEntry(id: UUID, weight: Double) {
        if let index = entries.firstIndex(where: { $0.id == id }) {
            let existingEntry = entries[index]
            let updatedEntry = WeightEntry(id: existingEntry.id, date: existingEntry.date, weightLb: weight)
            entries[index] = updatedEntry
            save()
        }
    }

    func hasEntryForToday() -> Bool {
        return getTodaysEntry() != nil
    }

    func getTodaysEntry() -> WeightEntry? {
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
           let saved = try? JSONDecoder().decode([WeightEntry].self, from: data) {
            entries = saved
        }
    }
}
