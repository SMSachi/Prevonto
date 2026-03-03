// Weight data structure
import Foundation

struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weightLb: Double

    init(date: Date, weightLb: Double) {
        self.id = UUID()
        self.date = date
        self.weightLb = weightLb
    }

    init(id: UUID, date: Date, weightLb: Double) {
        self.id = id
        self.date = date
        self.weightLb = weightLb
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    func weight(in unit: String) -> Double {
        unit == "Kg" ? weightLb * 0.453592 : weightLb
    }
}
