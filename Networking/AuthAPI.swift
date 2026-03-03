import Foundation

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String  // Backend expects "name" not "full_name"
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let token_type: String
}

final class AuthAPI {
    static let shared = AuthAPI()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    private init() {}
    
    func register(email: String, password: String, fullName: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("api/auth/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RegisterRequest(email: email, password: password, name: fullName)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 Register request to: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        print("📥 Register response [\(http.statusCode)]: \(bodyString)")
        
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 Login request to: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        print("📥 Login response [\(http.statusCode)]: \(bodyString)")
        
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
}
