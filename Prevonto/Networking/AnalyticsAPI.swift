import Foundation

enum TimeRange: String, Codable {
    case day, week, month, year, custom
}

enum TrendDirection: String, Codable {
    case increasing, decreasing, stable
}

struct TimeSeriesDataPoint: Codable {
    let timestamp: String
    let value: [String: Double]
    let unit: String?
}

struct TimeSeriesResponse: Codable {
    let metric_type: String
    let range: String
    let start_date: String
    let end_date: String
    let data_points: [TimeSeriesDataPoint]
    let total_points: Int
}

struct StatisticsResponse: Codable {
    let metric_type: String
    let range: String
    let count: Int
    let average: [String: Double]
    let minimum: [String: Double]
    let maximum: [String: Double]
    let median: [String: Double]
    let std_deviation: [String: Double]?
    let trend: String
    let change_from_previous: [String: Double]?
}

final class AnalyticsAPI {
    static let shared = AnalyticsAPI()
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    
    private init() {}
    
    func getTimeSeries(metricType: String, range: TimeRange = .week) async throws -> TimeSeriesResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }
        
        let url = baseURL.appendingPathComponent("api/analytics/\(metricType)/timeseries")
            .appending(queryItems: [URLQueryItem(name: "range", value: range.rawValue)])
        
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
        
        return try JSONDecoder().decode(TimeSeriesResponse.self, from: data)
    }
    
    func getStatistics(metricType: String, range: TimeRange = .week) async throws -> StatisticsResponse {
        guard let token = AuthManager.shared.getToken() else {
            throw APIError.noToken
        }
        
        let url = baseURL.appendingPathComponent("api/analytics/\(metricType)/statistics")
            .appending(queryItems: [URLQueryItem(name: "range", value: range.rawValue)])
        
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
        
        return try JSONDecoder().decode(StatisticsResponse.self, from: data)
    }
}
