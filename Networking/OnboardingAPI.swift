import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(code: Int, body: String)
    case decodingError(String)
    case noToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code, let body): return "HTTP \(code): \(body)"
        case .decodingError(let msg): return "Decoding error: \(msg)"
        case .noToken: return "No auth token available"
        }
    }
}

final class OnboardingAPI {
    static let shared = OnboardingAPI()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    private init() {}
    
    // Generic save method for any onboarding data
    func saveOnboarding(_ requestData: OnboardingUpdateRequest) async throws {
        guard let token = AuthManager.shared.getToken() else {
            print("⚠️ No token, skipping API call")
            return
        }
        
        let url = baseURL.appendingPathComponent("api/onboarding/")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestData)
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: responseData, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }
        
        print("✅ Onboarding data saved")
    }
    
    // Convenience methods
    func saveGender(_ gender: String) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(gender: gender))
    }
    
    func saveWeight(_ weight: Double, unit: String) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(currentWeight: weight, weightUnit: unit))
    }
    
    func saveAge(_ age: Int) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(age: age))
    }
    
    func saveFitnessLevel(_ level: String) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(fitnessLevel: level))
    }
    
    func saveSleepLevel(_ level: String) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(sleepLevel: level))
    }
    
    func saveMood(_ mood: String) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(currentMood: mood))
    }
    
    func saveDiet(_ diet: String, notes: String? = nil) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(dietType: diet, dietNotes: notes))
    }
    
    func saveMedications(_ medications: [MedicationDTO]) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(medications: medications))
    }
    
    func saveSymptoms(_ symptoms: String) async throws {
        try await saveOnboarding(OnboardingUpdateRequest(symptomsOrAllergies: symptoms))
    }
    
    func completeOnboarding() async throws {
        try await saveOnboarding(OnboardingUpdateRequest(isCompleted: true))
    }
}
