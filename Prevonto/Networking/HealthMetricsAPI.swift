//
//  HealthMetricsAPI.swift
//  Prevonto
//
//  Created by Sachi Shah on 1/18/26.
//
import Foundation

// MARK: - Response Models (matching backend schemas)

struct MetricRecord: Codable, Identifiable {
    let id: Int
    let user_id: Int
    let metric_type: String
    let source: String
    let measured_at: String
    let value: [String: Double]
    let unit: String?
    let notes: String?
    let created_at: String
    let updated_at: String

    var date: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: measured_at) {
            return date
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: measured_at)
    }
}

// Backend returns this format for list endpoints
struct MetricListResponse: Codable {
    let metrics: [MetricRecord]
    let total: Int
    let page: Int
    let page_size: Int
}

// Request model matching backend MetricCreate schema
struct MetricCreateRequest: Codable {
    let metric_type: String
    let measured_at: String
    let value: [String: Double]
    let unit: String?
    let notes: String?
    let source: String
}

final class HealthMetricsAPI {
    static let shared = HealthMetricsAPI()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!

    private init() {}

    private func getISO8601Date(_ date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func getDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    // MARK: - Fetch Methods

    /// Get the latest record for a metric type
    /// Uses list endpoint with page_size=1 sorted by most recent
    func getLatestMetric(type: String) async throws -> MetricRecord? {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        // Use list endpoint with page_size=1 to get latest
        var components = URLComponents(url: baseURL.appendingPathComponent("api/metrics/\(type)"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("📤 GET \(components.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? ""
        print("📥 Response (\(http.statusCode)): \(bodyString.prefix(500))")

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        let decoded = try JSONDecoder().decode(MetricListResponse.self, from: data)
        return decoded.metrics.first
    }

    /// Get metric history for a time range
    func getMetricHistory(type: String, range: TimeRange = .week, limit: Int = 50) async throws -> [MetricRecord] {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        // Calculate date range
        let endDate = Date()
        let startDate: Date
        switch range {
        case .day:
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
        case .week:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate)!
        case .year:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        case .custom:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("api/metrics/\(type)"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "start_date", value: getDateString(startDate)),
            URLQueryItem(name: "end_date", value: getDateString(endDate)),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: String(limit))
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("📤 GET \(components.url!.absoluteString)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8) ?? ""
        print("📥 Response (\(http.statusCode)): \(bodyString.prefix(500))")

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        let decoded = try JSONDecoder().decode(MetricListResponse.self, from: data)
        return decoded.metrics
    }

    // Convenience fetch methods for each metric type
    func getLatestHeartRate() async throws -> Int? {
        let record = try await getLatestMetric(type: "heart_rate")
        return record?.value["bpm"].map { Int($0) }
    }

    func getLatestBloodGlucose() async throws -> Double? {
        let record = try await getLatestMetric(type: "blood_glucose")
        return record?.value["value"]
    }

    func getLatestSpO2() async throws -> Double? {
        let record = try await getLatestMetric(type: "spo2")
        return record?.value["value"]
    }

    func getLatestWeight() async throws -> (weight: Double, unit: String)? {
        let record = try await getLatestMetric(type: "weight")
        guard let weight = record?.value["weight"] else { return nil }
        return (weight: weight, unit: record?.unit ?? "lbs")
    }

    func getLatestMood() async throws -> (energy: Int, mood: Int)? {
        let record = try await getLatestMetric(type: "energy_mood")
        guard let energy = record?.value["energy"],
              let mood = record?.value["mood"] else { return nil }
        return (energy: Int(energy), mood: Int(mood))
    }

    // MARK: - Save Methods

    func saveMetric(type: String, value: [String: Double], unit: String? = nil, notes: String? = nil) async throws {
        guard let token = AuthManager.shared.getToken() else {
            print("⚠️ No token, skipping API call")
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/metrics/\(type)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Backend requires metric_type in the body
        let body = MetricCreateRequest(
            metric_type: type,
            measured_at: getISO8601Date(),
            value: value,
            unit: unit,
            notes: notes,
            source: "manual"
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 POST \(url.absoluteString)")
            print("📤 Body: \(jsonString)")
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

        print("✅ \(type) metric saved")
    }

    // Convenience methods for each metric type
    func saveBloodPressure(systolic: Int, diastolic: Int, pulse: Int? = nil) async throws {
        var value: [String: Double] = ["systolic": Double(systolic), "diastolic": Double(diastolic)]
        if let pulse = pulse { value["pulse"] = Double(pulse) }
        try await saveMetric(type: "blood_pressure", value: value, unit: "mmHg")
    }

    func saveHeartRate(bpm: Int) async throws {
        try await saveMetric(type: "heart_rate", value: ["bpm": Double(bpm)], unit: "bpm")
    }

    func saveBloodGlucose(value: Double) async throws {
        try await saveMetric(type: "blood_glucose", value: ["value": value], unit: "mg/dL")
    }

    func saveSpO2(value: Double) async throws {
        try await saveMetric(type: "spo2", value: ["value": value], unit: "%")
    }

    func saveWeight(weight: Double, unit: String = "lbs") async throws {
        try await saveMetric(type: "weight", value: ["weight": weight], unit: unit)
    }

    func saveSteps(steps: Int, distance: Double? = nil) async throws {
        var value: [String: Double] = ["steps": Double(steps)]
        if let distance = distance { value["distance"] = distance }
        try await saveMetric(type: "steps_activity", value: value)
    }

    func saveEnergyMood(energy: Int, mood: Int) async throws {
        try await saveMetric(type: "energy_mood", value: ["energy": Double(energy), "mood": Double(mood)])
    }
}
