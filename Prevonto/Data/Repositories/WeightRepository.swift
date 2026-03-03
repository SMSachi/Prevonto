// Fetches locally stored weight data to display in the Weight Tracker page
import Foundation

protocol WeightRepository {
    func fetchEntries() -> [WeightEntry]
    func addEntry(weight: Double)
    func updateEntry(id: UUID, weight: Double)
    func hasEntryForToday() -> Bool
    func getTodaysEntry() -> WeightEntry?
}
