//
//  HealthKitSyncAPI.swift
//  Prevonto
//
//  Apple Health Integration APIs for syncing HealthKit data to the backend.
//

import Foundation

// MARK: - Data Models

struct HealthKitDataPoint: Codable {
    let timestamp: String
    let value: [String: Double]
    let unit: String?
    let source_device: String?
}

struct HealthKitBatchUpload: Codable {
    let metric_type: String
    let source: String
    let data_points: [HealthKitDataPoint]
}

struct HealthKitSyncStatus: Codable {
    let metric_type: String
    let last_sync: String?
    let total_records: Int
    let pending_sync: Int
}

struct HealthKitSyncResponse: Codable {
    let success: Bool
    let synced_count: Int
    let failed_count: Int
    let message: String?
}

struct HealthKitSyncStatusResponse: Codable {
    let metrics: [HealthKitSyncStatus]
    let last_full_sync: String?
}

// MARK: - HealthKit Sync API

final class HealthKitSyncAPI {
    static let shared = HealthKitSyncAPI()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!

    private init() {}

    // MARK: - Batch Upload Methods

    /// Upload multiple data points for a single metric type
    func batchUpload(metricType: String, dataPoints: [HealthKitDataPoint]) async throws -> HealthKitSyncResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/healthkit/batch")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let upload = HealthKitBatchUpload(
            metric_type: metricType,
            source: "apple_health",
            data_points: dataPoints
        )

        request.httpBody = try JSONEncoder().encode(upload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(HealthKitSyncResponse.self, from: data)
    }

    /// Upload multiple metric types at once
    func batchUploadMultiple(uploads: [HealthKitBatchUpload]) async throws -> HealthKitSyncResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/healthkit/batch-multiple")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(uploads)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(HealthKitSyncResponse.self, from: data)
    }

    // MARK: - Single Metric Upload Methods

    /// Sync steps data from Apple Health
    func syncSteps(steps: Int, distance: Double?, calories: Double?, timestamp: Date, sourceDevice: String? = nil) async throws {
        var value: [String: Double] = ["steps": Double(steps)]
        if let distance = distance { value["distance_km"] = distance }
        if let calories = calories { value["calories"] = calories }

        try await uploadSingleMetric(
            metricType: "steps_activity",
            value: value,
            unit: "count",
            timestamp: timestamp,
            sourceDevice: sourceDevice
        )
    }

    /// Sync heart rate data from Apple Health
    func syncHeartRate(bpm: Double, timestamp: Date, sourceDevice: String? = nil) async throws {
        try await uploadSingleMetric(
            metricType: "heart_rate",
            value: ["bpm": bpm],
            unit: "bpm",
            timestamp: timestamp,
            sourceDevice: sourceDevice
        )
    }

    /// Sync active energy burned from Apple Health
    func syncActiveEnergy(calories: Double, timestamp: Date, sourceDevice: String? = nil) async throws {
        try await uploadSingleMetric(
            metricType: "active_energy",
            value: ["calories": calories],
            unit: "kcal",
            timestamp: timestamp,
            sourceDevice: sourceDevice
        )
    }

    /// Sync walking/running distance from Apple Health
    func syncDistance(kilometers: Double, timestamp: Date, sourceDevice: String? = nil) async throws {
        try await uploadSingleMetric(
            metricType: "distance",
            value: ["kilometers": kilometers],
            unit: "km",
            timestamp: timestamp,
            sourceDevice: sourceDevice
        )
    }

    /// Sync blood oxygen (SpO2) from Apple Health
    func syncSpO2(percentage: Double, timestamp: Date, sourceDevice: String? = nil) async throws {
        try await uploadSingleMetric(
            metricType: "spo2",
            value: ["value": percentage],
            unit: "%",
            timestamp: timestamp,
            sourceDevice: sourceDevice
        )
    }

    /// Sync sleep data from Apple Health
    func syncSleep(
        inBedMinutes: Double,
        asleepMinutes: Double,
        deepSleepMinutes: Double?,
        remSleepMinutes: Double?,
        timestamp: Date,
        sourceDevice: String? = nil
    ) async throws {
        var value: [String: Double] = [
            "in_bed_minutes": inBedMinutes,
            "asleep_minutes": asleepMinutes
        ]
        if let deep = deepSleepMinutes { value["deep_sleep_minutes"] = deep }
        if let rem = remSleepMinutes { value["rem_sleep_minutes"] = rem }

        try await uploadSingleMetric(
            metricType: "sleep",
            value: value,
            unit: "minutes",
            timestamp: timestamp,
            sourceDevice: sourceDevice
        )
    }

    /// Sync workout data from Apple Health
    func syncWorkout(
        workoutType: String,
        durationMinutes: Double,
        caloriesBurned: Double?,
        distanceKm: Double?,
        avgHeartRate: Double?,
        timestamp: Date,
        sourceDevice: String? = nil
    ) async throws {
        var value: [String: Double] = [
            "duration_minutes": durationMinutes
        ]
        if let calories = caloriesBurned { value["calories_burned"] = calories }
        if let distance = distanceKm { value["distance_km"] = distance }
        if let hr = avgHeartRate { value["avg_heart_rate"] = hr }

        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/healthkit/workout")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var body: [String: Any] = [
            "workout_type": workoutType,
            "timestamp": formatter.string(from: timestamp),
            "value": value,
            "source": "apple_health"
        ]
        if let device = sourceDevice { body["source_device"] = device }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: (response as? HTTPURLResponse)?.statusCode ?? 0, body: bodyString)
        }

        print("Workout synced successfully")
    }

    // MARK: - Sync Status Methods

    /// Get sync status for all metric types
    func getSyncStatus() async throws -> HealthKitSyncStatusResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/healthkit/sync-status")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }

        return try JSONDecoder().decode(HealthKitSyncStatusResponse.self, from: data)
    }

    /// Get last sync timestamp for a specific metric type
    func getLastSyncTimestamp(metricType: String) async throws -> Date? {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL
            .appendingPathComponent("api/healthkit/last-sync")
            .appending(queryItems: [URLQueryItem(name: "metric_type", value: metricType)])

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            return nil
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let timestampString = json?["last_sync"] as? String else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestampString)
    }

    /// Update last sync timestamp for a specific metric type
    func updateLastSyncTimestamp(metricType: String, timestamp: Date) async throws {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/healthkit/last-sync")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let body: [String: Any] = [
            "metric_type": metricType,
            "last_sync": formatter.string(from: timestamp)
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
    }

    // MARK: - Helper Methods

    private func uploadSingleMetric(
        metricType: String,
        value: [String: Double],
        unit: String?,
        timestamp: Date,
        sourceDevice: String?
    ) async throws {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }

        let url = baseURL.appendingPathComponent("api/healthkit/\(metricType)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var body: [String: Any] = [
            "timestamp": formatter.string(from: timestamp),
            "value": value,
            "source": "apple_health"
        ]
        if let unit = unit { body["unit"] = unit }
        if let device = sourceDevice { body["source_device"] = device }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(code: http.statusCode, body: bodyString)
        }

        print("\(metricType) synced from Apple Health")
    }
}
