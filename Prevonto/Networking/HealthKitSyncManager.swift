//
//  HealthKitSyncManager.swift
//  Prevonto
//
//  Manages automatic synchronization of Apple Health data to the backend.
//

import Foundation
import Combine
import HealthKit

// MARK: - Sync Configuration

struct HealthKitSyncConfig {
    /// How far back to sync historical data on first sync (in days)
    let historicalSyncDays: Int

    /// Minimum interval between syncs (in seconds)
    let minSyncInterval: TimeInterval

    /// Maximum number of data points per batch upload
    let maxBatchSize: Int

    static let `default` = HealthKitSyncConfig(
        historicalSyncDays: 30,
        minSyncInterval: 300, // 5 minutes
        maxBatchSize: 100
    )
}

// MARK: - Sync State

enum SyncState: Equatable {
    case idle
    case syncing
    case error(String)
    case completed(syncedCount: Int)
}

// MARK: - HealthKit Sync Manager

final class HealthKitSyncManager: ObservableObject {
    static let shared = HealthKitSyncManager()

    // Published properties for UI binding
    @Published var syncState: SyncState = .idle
    @Published var lastSyncDate: Date?
    @Published var isSyncEnabled: Bool = true

    // Dependencies
    private let healthKitManager = HealthKitManager()
    private let syncAPI = HealthKitSyncAPI.shared
    private let config: HealthKitSyncConfig

    // Sync tracking
    private var lastSyncTimestamps: [String: Date] = [:]
    private var syncTask: Task<Void, Never>?

    // UserDefaults keys
    private let lastSyncKey = "HealthKitLastSync"
    private let syncEnabledKey = "HealthKitSyncEnabled"
    private let lastSyncTimestampsKey = "HealthKitLastSyncTimestamps"

    private init(config: HealthKitSyncConfig = .default) {
        self.config = config
        loadSyncState()
    }

    // MARK: - Public Methods

    /// Start a full sync of all health data
    func startSync() {
        guard syncState != .syncing else { return }

        syncTask?.cancel()
        syncTask = Task {
            await performFullSync()
        }
    }

    /// Sync a specific metric type
    func syncMetric(_ metricType: HealthMetricType) async {
        guard syncState != .syncing else { return }

        await MainActor.run {
            syncState = .syncing
        }

        do {
            try await syncSingleMetric(metricType)
            await MainActor.run {
                syncState = .completed(syncedCount: 1)
                lastSyncDate = Date()
                saveSyncState()
            }
        } catch {
            await MainActor.run {
                syncState = .error(error.localizedDescription)
            }
        }
    }

    /// Stop any ongoing sync
    func stopSync() {
        syncTask?.cancel()
        syncTask = nil
        syncState = .idle
    }

    /// Enable or disable automatic syncing
    func setSyncEnabled(_ enabled: Bool) {
        isSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: syncEnabledKey)
    }

    /// Get the last sync timestamp for a specific metric
    func getLastSyncTimestamp(for metric: HealthMetricType) -> Date? {
        return lastSyncTimestamps[metric.rawValue]
    }

    // MARK: - Private Sync Methods

    private func performFullSync() async {
        await MainActor.run {
            syncState = .syncing
        }

        // Sync each metric type and collect results
        var syncResults: [Int] = []
        for metricType in HealthMetricType.allCases {
            do {
                let count = try await syncSingleMetric(metricType)
                syncResults.append(count)
            } catch {
                print("Failed to sync \(metricType.rawValue): \(error)")
                syncResults.append(0)
            }
        }

        let totalSynced = syncResults.reduce(0, +)

        await MainActor.run {
            syncState = .completed(syncedCount: totalSynced)
            lastSyncDate = Date()
            saveSyncState()
        }
    }

    @discardableResult
    private func syncSingleMetric(_ metricType: HealthMetricType) async throws -> Int {
        // Determine start date for sync
        let startDate: Date
        if let lastSync = lastSyncTimestamps[metricType.rawValue] {
            startDate = lastSync
        } else {
            // First sync - go back configured number of days
            startDate = Calendar.current.date(
                byAdding: .day,
                value: -config.historicalSyncDays,
                to: Date()
            ) ?? Date()
        }

        let endDate = Date()

        // Fetch samples from HealthKit
        let samples = try await fetchSamples(for: metricType, from: startDate, to: endDate)

        guard !samples.isEmpty else {
            return 0
        }

        // Convert to API format
        let dataPoints = samples.map { sample in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            return HealthKitDataPoint(
                timestamp: formatter.string(from: sample.timestamp),
                value: [metricType.valueKey: sample.value],
                unit: sample.unit,
                source_device: sample.sourceDevice
            )
        }

        // Batch upload in chunks
        var syncedCount = 0
        for chunk in dataPoints.chunked(into: config.maxBatchSize) {
            let response = try await syncAPI.batchUpload(metricType: metricType.rawValue, dataPoints: chunk)
            syncedCount += response.synced_count
        }

        // Update last sync timestamp
        lastSyncTimestamps[metricType.rawValue] = endDate
        saveSyncState()

        return syncedCount
    }

    private func fetchSamples(for metricType: HealthMetricType, from startDate: Date, to endDate: Date) async throws -> [HealthDataSample] {
        switch metricType {
        case .steps:
            return try await healthKitManager.fetchStepSamples(from: startDate, to: endDate)
        case .heartRate:
            return try await healthKitManager.fetchHeartRateSamples(from: startDate, to: endDate)
        case .activeEnergy:
            return try await healthKitManager.fetchActiveEnergySamples(from: startDate, to: endDate)
        case .distance:
            return try await healthKitManager.fetchDistanceSamples(from: startDate, to: endDate)
        }
    }

    // MARK: - Persistence

    private func loadSyncState() {
        isSyncEnabled = UserDefaults.standard.object(forKey: syncEnabledKey) as? Bool ?? true
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date

        if let data = UserDefaults.standard.data(forKey: lastSyncTimestampsKey),
           let timestamps = try? JSONDecoder().decode([String: Date].self, from: data) {
            lastSyncTimestamps = timestamps
        }
    }

    private func saveSyncState() {
        UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)

        if let data = try? JSONEncoder().encode(lastSyncTimestamps) {
            UserDefaults.standard.set(data, forKey: lastSyncTimestampsKey)
        }
    }
}

// MARK: - Health Metric Types

enum HealthMetricType: String, CaseIterable {
    case steps = "steps_activity"
    case heartRate = "heart_rate"
    case activeEnergy = "active_energy"
    case distance = "distance"

    var valueKey: String {
        switch self {
        case .steps: return "steps"
        case .heartRate: return "bpm"
        case .activeEnergy: return "calories"
        case .distance: return "kilometers"
        }
    }

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .heartRate: return "Heart Rate"
        case .activeEnergy: return "Active Energy"
        case .distance: return "Distance"
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Background Sync Support

extension HealthKitSyncManager {
    /// Perform a background sync (called from AppDelegate or SceneDelegate)
    func performBackgroundSync() async {
        guard isSyncEnabled else { return }
        guard AuthManager.shared.getToken() != nil else { return }

        // Check if enough time has passed since last sync
        if let lastSync = lastSyncDate {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            guard timeSinceLastSync >= config.minSyncInterval else { return }
        }

        await performFullSync()
    }

    /// Register for HealthKit background delivery
    func enableBackgroundDelivery() {
        let healthStore = healthKitManager.healthStore

        // Enable background delivery for each metric type
        let types: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .heartRate,
            .activeEnergyBurned,
            .distanceWalkingRunning
        ]

        for identifier in types {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }

            healthStore.enableBackgroundDelivery(for: type, frequency: .hourly) { success, error in
                if success {
                    print("Background delivery enabled for \(identifier.rawValue)")
                } else if let error = error {
                    print("Failed to enable background delivery: \(error)")
                }
            }
        }
    }
}

// MARK: - Sync Status View Model

extension HealthKitSyncManager {
    /// Get a summary of sync status for all metrics
    func getSyncSummary() -> [(metric: HealthMetricType, lastSync: Date?)] {
        return HealthMetricType.allCases.map { metric in
            (metric: metric, lastSync: lastSyncTimestamps[metric.rawValue])
        }
    }

    /// Format last sync date for display
    func formatLastSync(_ date: Date?) -> String {
        guard let date = date else { return "Never" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
