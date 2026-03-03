import Foundation

struct MedicationDTO: Codable, Hashable {
    var name: String
    var dosage: String?
    var frequency: String?
}

struct OnboardingUpdateRequest: Codable {
    var gender: String?
    var current_weight: Double?
    var weight_unit: String?
    var age: Int?
    var fitness_level: String?
    var sleep_level: String?
    var current_mood: String?
    var diet_type: String?
    var diet_notes: String?
    var medications: [MedicationDTO]?
    var symptoms_or_allergies: String?
    var is_completed: Bool?
}

struct OnboardingResponse: Codable {
    let id: Int?
    let user_id: Int?
    let gender: String?
    let current_weight: Double?
    let weight_unit: String?
    let age: Int?
    let fitness_level: String?
    let sleep_level: String?
    let current_mood: String?
    let diet_type: String?
    let medications: [MedicationDTO]?
    let symptoms_or_allergies: String?
    let is_completed: Bool?
}
