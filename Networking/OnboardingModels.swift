import Foundation

// MARK: - Enums matching backend
enum Gender: String, Codable {
    case male, female, other, prefer_not_to_say
}

enum FitnessLevel: String, Codable {
    case beginner, intermediate, advanced, athlete
}

enum SleepLevel: String, Codable {
    case poor, fair, good, excellent
}

enum MoodLevel: String, Codable {
    case very_poor, poor, neutral, good, excellent
}

enum DietType: String, Codable {
    case vegan, vegetarian, pescatarian, omnivore, keto, paleo, mediterranean, other
}

// MARK: - DTOs
struct MedicationDTO: Codable, Hashable {
    var name: String
    var dosage: String
    var frequency: String
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
    
    init(
        gender: String? = nil,
        currentWeight: Double? = nil,
        weightUnit: String? = nil,
        age: Int? = nil,
        fitnessLevel: String? = nil,
        sleepLevel: String? = nil,
        currentMood: String? = nil,
        dietType: String? = nil,
        dietNotes: String? = nil,
        medications: [MedicationDTO]? = nil,
        symptomsOrAllergies: String? = nil,
        isCompleted: Bool? = nil
    ) {
        self.gender = gender
        self.current_weight = currentWeight
        self.weight_unit = weightUnit
        self.age = age
        self.fitness_level = fitnessLevel
        self.sleep_level = sleepLevel
        self.current_mood = currentMood
        self.diet_type = dietType
        self.diet_notes = dietNotes
        self.medications = medications
        self.symptoms_or_allergies = symptomsOrAllergies
        self.is_completed = isCompleted
    }
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
