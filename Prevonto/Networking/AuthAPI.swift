import Foundation

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let full_name: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let token_type: String
    let expires_in: Int?
}

struct RefreshTokenRequest: Codable {
    let refresh_token: String
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ResetPasswordRequest: Codable {
    let token: String
    let new_password: String
}

struct ChangePasswordRequest: Codable {
    let current_password: String
    let new_password: String
}

struct MessageResponse: Codable {
    let message: String
}

struct UserInfoResponse: Codable {
    let id: String
    let email: String
    let name: String?
    let created_at: String?
    let is_active: Bool?
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
        
        let body = RegisterRequest(email: email, password: password, full_name: fullName)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
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

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    /// Refresh the access token using a refresh token
    func refreshToken(refreshToken: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("api/auth/refresh")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = RefreshTokenRequest(refresh_token: refreshToken)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    /// Request a password reset email
    func forgotPassword(email: String) async throws -> MessageResponse {
        let url = baseURL.appendingPathComponent("api/auth/forgot-password")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ForgotPasswordRequest(email: email)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(MessageResponse.self, from: data)
    }

    /// Reset password using a reset token
    func resetPassword(token: String, newPassword: String) async throws -> MessageResponse {
        let url = baseURL.appendingPathComponent("api/auth/reset-password")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ResetPasswordRequest(token: token, new_password: newPassword)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(MessageResponse.self, from: data)
    }

    /// Change password for logged-in user
    func changePassword(currentPassword: String, newPassword: String) async throws -> MessageResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/auth/change-password")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ChangePasswordRequest(current_password: currentPassword, new_password: newPassword)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(MessageResponse.self, from: data)
    }

    /// Get current user info
    func getCurrentUser() async throws -> UserInfoResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/auth/me")
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

        return try JSONDecoder().decode(UserInfoResponse.self, from: data)
    }

    /// Validate if the current token is still valid
    func validateToken() async throws -> Bool {
        guard let token = AuthManager.shared.getToken() else {
            return false
        }

        let url = baseURL.appendingPathComponent("api/auth/validate")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            return false
        }

        return (200...299).contains(http.statusCode)
    }

    /// Logout (invalidate token on server)
    func logout() async throws {
        guard let token = AuthManager.shared.getToken() else {
            AuthManager.shared.clearToken()
            return
        }

        let url = baseURL.appendingPathComponent("api/auth/logout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Fire and forget - clear local token regardless of server response
        _ = try? await URLSession.shared.data(for: request)
        AuthManager.shared.clearToken()
    }
}
