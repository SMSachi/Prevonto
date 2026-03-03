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

    /// Fetch existing onboarding data for the current user
    func getOnboarding() async throws -> OnboardingResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/onboarding/")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(OnboardingResponse.self, from: data)
    }

    /// Check if onboarding is completed for the current user
    func isOnboardingCompleted() async throws -> Bool {
        do {
            let onboarding = try await getOnboarding()
            return onboarding.is_completed ?? false
        } catch {
            // If we get a 404 or can't fetch, assume not completed
            return false
        }
    }

    func saveOnboarding(_ requestData: OnboardingUpdateRequest) async throws {
        guard let token = AuthManager.shared.getToken() else {
            print("⚠️ No token available, skipping API call")
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/onboarding/")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(requestData)
        request.httpBody = jsonData

        // Debug: Print what we're sending
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Sending onboarding data: \(jsonString)")
        }

        let (responseData, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let bodyString = String(data: responseData, encoding: .utf8) ?? ""
        print("📥 Response (\(http.statusCode)): \(bodyString)")

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        print("✅ Onboarding data saved successfully")
    }
    
    func saveGender(_ gender: String) async throws {
        var data = OnboardingUpdateRequest()
        data.gender = gender
        try await saveOnboarding(data)
    }
    
    func saveWeight(_ weight: Double, unit: String) async throws {
        var data = OnboardingUpdateRequest()
        data.current_weight = weight
        data.weight_unit = unit
        try await saveOnboarding(data)
    }
    
    func saveAge(_ age: Int) async throws {
        var data = OnboardingUpdateRequest()
        data.age = age
        try await saveOnboarding(data)
    }
    
    func saveFitnessLevel(_ level: String) async throws {
        var data = OnboardingUpdateRequest()
        data.fitness_level = level
        try await saveOnboarding(data)
    }
    
    func saveSleepLevel(_ level: String) async throws {
        var data = OnboardingUpdateRequest()
        data.sleep_level = level
        try await saveOnboarding(data)
    }
    
    func saveMood(_ mood: String) async throws {
        var data = OnboardingUpdateRequest()
        data.current_mood = mood
        try await saveOnboarding(data)
    }
    
    func saveDiet(_ diet: String, notes: String? = nil) async throws {
        var data = OnboardingUpdateRequest()
        data.diet_type = diet
        data.diet_notes = notes
        try await saveOnboarding(data)
    }
    
    func saveMedications(_ medications: [MedicationDTO]) async throws {
        var data = OnboardingUpdateRequest()
        data.medications = medications
        try await saveOnboarding(data)
    }
    
    func saveSymptoms(_ symptoms: String) async throws {
        var data = OnboardingUpdateRequest()
        data.symptoms_or_allergies = symptoms
        try await saveOnboarding(data)
    }
    
    func completeOnboarding() async throws {
        var data = OnboardingUpdateRequest()
        data.is_completed = true
        try await saveOnboarding(data)
    }
}
