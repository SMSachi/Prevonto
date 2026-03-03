//
//  AIAgentAPI.swift
//  Prevonto
//
//  Created by Sachi Shah on 1/19/26.
import Foundation

enum AnomalySeverity: String, Codable {
    case low, medium, high, critical
}

struct Anomaly: Codable, Identifiable {
    let id = UUID()
    let metric_type: String
    let detected_at: String
    let measured_at: String
    let value: [String: Double]
    let expected_range: [String: Double]
    let severity: String
    let description: String
    let recommendation: String?
    
    enum CodingKeys: String, CodingKey {
        case metric_type, detected_at, measured_at, value, expected_range, severity, description, recommendation
    }
}

struct Insight: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let insight_type: String
    let metrics_involved: [String]
    let generated_at: String
    let confidence: Double
    let actionable: Bool
    let action_text: String?
}

struct DailySummary: Codable {
    let date: String
    let metrics_tracked: [String]
    let insights: [Insight]
    let anomalies: [Anomaly]
    let overall_score: Int?
    let summary_text: String
}

struct AnalyzeResponse: Codable {
    let insights: [Insight]
    let anomalies: [Anomaly]
    let analyzed_at: String
}

struct AIMessage: Codable, Identifiable {
    let id: String
    let role: String  // "user" or "assistant"
    let content: String
    let timestamp: String
}

struct AIChatRequest: Codable {
    let message: String
    let context: [String]?  // Optional metric types for context
}

struct AIChatResponse: Codable {
    let response: String
    let suggestions: [String]?
    let related_metrics: [String]?
}

struct HealthRecommendation: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let priority: String  // "high", "medium", "low"
    let category: String  // "exercise", "nutrition", "sleep", etc.
    let action_items: [String]
}

final class AIAgentAPI {
    static let shared = AIAgentAPI()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    private init() {}
    
    func getAnomalies(metricType: String? = nil, daysBack: Int = 30) async throws -> [Anomaly] {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("api/ai/anomalies"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "days_back", value: String(daysBack))]
        if let metricType = metricType {
            queryItems.append(URLQueryItem(name: "metric_type", value: metricType))
        }
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
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
        
        return try JSONDecoder().decode([Anomaly].self, from: data)
    }
    
    func getInsights(daysBack: Int = 30) async throws -> [Insight] {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }
        
        var components = URLComponents(url: baseURL.appendingPathComponent("api/ai/insights"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "days_back", value: String(daysBack))]
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
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
        
        return try JSONDecoder().decode([Insight].self, from: data)
    }
    
    func getDailySummary() async throws -> DailySummary {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }
        
        let url = baseURL.appendingPathComponent("api/ai/daily-summary")
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
        
        return try JSONDecoder().decode(DailySummary.self, from: data)
    }

    /// Send a chat message to the AI health assistant
    func chat(message: String, context: [String]? = nil) async throws -> AIChatResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/ai/chat")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let chatRequest = AIChatRequest(message: message, context: context)
        request.httpBody = try JSONEncoder().encode(chatRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(AIChatResponse.self, from: data)
    }

    /// Get personalized health recommendations
    func getRecommendations() async throws -> [HealthRecommendation] {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/ai/recommendations")
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

        return try JSONDecoder().decode([HealthRecommendation].self, from: data)
    }

    /// Get quick health tips based on recent data
    func getQuickTips(limit: Int = 3) async throws -> [String] {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("api/ai/quick-tips"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        guard let url = components.url else {
            throw APIError.invalidResponse
        }

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

        return try JSONDecoder().decode([String].self, from: data)
    }

    /// Get count of unread/critical anomalies for badge display
    func getAnomalyCount() async throws -> Int {
        let anomalies = try await getAnomalies(daysBack: 7)
        return anomalies.filter { $0.severity.lowercased() == "high" || $0.severity.lowercased() == "critical" }.count
    }
}
