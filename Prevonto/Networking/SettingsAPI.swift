//
//  SettingsAPI.swift
//  Prevonto
//
//  Created by Sachi Shah on 1/18/26.
//
import Foundation

struct UserSettings: Codable {
    var email_notifications_enabled: Bool?
    var push_notifications_enabled: Bool?
    var daily_summary_enabled: Bool?
    var anomaly_alerts_enabled: Bool?
}

struct UserProfile: Codable {
    var full_name: String?
    var email: String?
    var phone_number: String?
    var date_of_birth: String?
}

struct DeleteAccountRequest: Codable {
    let password: String?
    let confirmation: String
}

final class SettingsAPI {
    static let shared = SettingsAPI()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    private init() {}
    
    func getSettings() async throws -> [String: Any] {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }
        
        let url = baseURL.appendingPathComponent("api/settings/")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return json
    }
    
    func updateNotifications(email: Bool, push: Bool, dailySummary: Bool, anomalyAlerts: Bool) async throws {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }
        
        let url = baseURL.appendingPathComponent("api/settings/notifications")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email_notifications_enabled": email,
            "push_notifications_enabled": push,
            "daily_summary_enabled": dailySummary,
            "anomaly_alerts_enabled": anomalyAlerts
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        
        print("✅ Notification settings updated")
    }
    
    func logout() {
        AuthManager.shared.clearToken()
        print("✅ Logged out")
    }
    
    func deleteAccount(password: String?) async throws {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/settings/delete-account")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "password": password ?? "",
            "confirmation": "DELETE MY ACCOUNT"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? ""

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        // Clear local token after successful deletion
        AuthManager.shared.clearToken()
        print("✅ Account deleted")
    }

    func getProfile() async throws -> UserProfile {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/settings/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    func updateProfile(fullName: String?, email: String?, phoneNumber: String?, dateOfBirth: String?) async throws {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/settings/profile")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [:]
        if let fullName = fullName { body["full_name"] = fullName }
        if let email = email { body["email"] = email }
        if let phoneNumber = phoneNumber { body["phone_number"] = phoneNumber }
        if let dateOfBirth = dateOfBirth { body["date_of_birth"] = dateOfBirth }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        print("✅ Profile updated")
    }

    func getNotificationSettings() async throws -> UserSettings {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/settings/notifications")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(UserSettings.self, from: data)
    }
}
