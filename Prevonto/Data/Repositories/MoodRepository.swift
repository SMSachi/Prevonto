// Fetches locally stored mood/energy data
import Foundation

protocol MoodRepository {
    func fetchEntries() -> [MoodEntry]
    func addEntry(moodValue: String, energy: Int)
    func hasEntryForToday() -> Bool
    func getTodaysEntry() -> MoodEntry?
}
