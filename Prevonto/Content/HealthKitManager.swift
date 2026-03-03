import HealthKit

// MARK: - Health Data Sample Structure
struct HealthDataSample {
    let value: Double
    let unit: String
    let timestamp: Date
    let sourceDevice: String?
}

class HealthKitManager {
    let healthStore = HKHealthStore()

    // MARK: - Authorization

    /// Request authorization for all health data types
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let calorieType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
        else {
            completion(false, nil)
            return
        }

        let readTypes: Set<HKObjectType> = [stepCountType, calorieType, distanceType, heartRateType]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    /// Request authorization with extended health data types for sync
    func requestExtendedAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        var readTypes: Set<HKObjectType> = []

        // Add all supported quantity types
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .distanceWalkingRunning,
            .heartRate,
            .oxygenSaturation,
            .bodyMass,
            .height,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .bloodGlucose,
            .bodyTemperature,
            .respiratoryRate
        ]

        for identifier in quantityTypes {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                readTypes.insert(type)
            }
        }

        // Add category types
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleepType)
        }

        // Add workout type
        readTypes.insert(HKObjectType.workoutType())

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    // Fetch today's step count
    func fetchTodayStepCount(completion: @escaping (Double?, Error?) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
            if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async { completion(steps, nil) }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch today's calories burned
    func fetchTodayCalories(completion: @escaping (Double?, Error?) -> Void) {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(nil, nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
            if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            // Calories are returned in kilocalories
            let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie())
            DispatchQueue.main.async { completion(calories, nil) }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch today's walking/running distance
    func fetchTodayDistance(completion: @escaping (Double?, Error?) -> Void) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(nil, nil)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
            if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }
            
            // Distance is typically returned in meters; convert to kilometers
            let distanceMeters = result?.sumQuantity()?.doubleValue(for: HKUnit.meter())
            let distanceKilometers = distanceMeters.map { $0 / 1000.0 }
            DispatchQueue.main.async { completion(distanceKilometers, nil) }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch today's average heart rate (in beats per minute)
    func fetchTodayHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(nil, nil)
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        // Use .discreteAverage to compute the average heart rate for the day
        let query = HKStatisticsQuery(quantityType: heartRateType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { _, result, error in
            if let error = error {
                DispatchQueue.main.async { completion(nil, error) }
                return
            }

            let avgHeartRate = result?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            DispatchQueue.main.async { completion(avgHeartRate, nil) }
        }

        healthStore.execute(query)
    }

    // MARK: - Historical Data Fetching for Sync

    /// Fetch step count samples within a date range
    func fetchStepSamples(from startDate: Date, to endDate: Date, completion: @escaping ([HealthDataSample], Error?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([], nil)
            return
        }

        fetchQuantitySamples(
            type: stepType,
            unit: HKUnit.count(),
            unitString: "count",
            from: startDate,
            to: endDate,
            completion: completion
        )
    }

    /// Fetch heart rate samples within a date range
    func fetchHeartRateSamples(from startDate: Date, to endDate: Date, completion: @escaping ([HealthDataSample], Error?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion([], nil)
            return
        }

        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        fetchQuantitySamples(
            type: heartRateType,
            unit: unit,
            unitString: "bpm",
            from: startDate,
            to: endDate,
            completion: completion
        )
    }

    /// Fetch active energy samples within a date range
    func fetchActiveEnergySamples(from startDate: Date, to endDate: Date, completion: @escaping ([HealthDataSample], Error?) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion([], nil)
            return
        }

        fetchQuantitySamples(
            type: energyType,
            unit: HKUnit.kilocalorie(),
            unitString: "kcal",
            from: startDate,
            to: endDate,
            completion: completion
        )
    }

    /// Fetch distance samples within a date range
    func fetchDistanceSamples(from startDate: Date, to endDate: Date, completion: @escaping ([HealthDataSample], Error?) -> Void) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion([], nil)
            return
        }

        fetchQuantitySamples(
            type: distanceType,
            unit: HKUnit.meterUnit(with: .kilo),
            unitString: "km",
            from: startDate,
            to: endDate,
            completion: completion
        )
    }

    /// Fetch SpO2 samples within a date range
    func fetchSpO2Samples(from startDate: Date, to endDate: Date, completion: @escaping ([HealthDataSample], Error?) -> Void) {
        guard let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion([], nil)
            return
        }

        fetchQuantitySamples(
            type: spo2Type,
            unit: HKUnit.percent(),
            unitString: "%",
            from: startDate,
            to: endDate,
            completion: completion
        )
    }

    /// Fetch weight samples within a date range
    func fetchWeightSamples(from startDate: Date, to endDate: Date, completion: @escaping ([HealthDataSample], Error?) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion([], nil)
            return
        }

        fetchQuantitySamples(
            type: weightType,
            unit: HKUnit.pound(),
            unitString: "lbs",
            from: startDate,
            to: endDate,
            completion: completion
        )
    }

    /// Generic method to fetch quantity samples
    private func fetchQuantitySamples(
        type: HKQuantityType,
        unit: HKUnit,
        unitString: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping ([HealthDataSample], Error?) -> Void
    ) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            if let error = error {
                DispatchQueue.main.async { completion([], error) }
                return
            }

            let healthSamples = (samples as? [HKQuantitySample])?.map { sample in
                HealthDataSample(
                    value: sample.quantity.doubleValue(for: unit),
                    unit: unitString,
                    timestamp: sample.startDate,
                    sourceDevice: sample.device?.name
                )
            } ?? []

            DispatchQueue.main.async { completion(healthSamples, nil) }
        }

        healthStore.execute(query)
    }

    // MARK: - Aggregated Data Fetching

    /// Fetch daily aggregated steps for a date range
    func fetchDailySteps(from startDate: Date, to endDate: Date, completion: @escaping ([(date: Date, steps: Int)], Error?) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([], nil)
            return
        }

        fetchDailyStatistics(
            type: stepType,
            unit: HKUnit.count(),
            options: .cumulativeSum,
            from: startDate,
            to: endDate
        ) { results, error in
            let mapped = results.map { (date: $0.date, steps: Int($0.value)) }
            completion(mapped, error)
        }
    }

    /// Fetch daily aggregated calories for a date range
    func fetchDailyCalories(from startDate: Date, to endDate: Date, completion: @escaping ([(date: Date, calories: Double)], Error?) -> Void) {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion([], nil)
            return
        }

        fetchDailyStatistics(
            type: calorieType,
            unit: HKUnit.kilocalorie(),
            options: .cumulativeSum,
            from: startDate,
            to: endDate
        ) { results, error in
            let mapped = results.map { (date: $0.date, calories: $0.value) }
            completion(mapped, error)
        }
    }

    /// Fetch daily average heart rate for a date range
    func fetchDailyHeartRate(from startDate: Date, to endDate: Date, completion: @escaping ([(date: Date, avgBPM: Double)], Error?) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion([], nil)
            return
        }

        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        fetchDailyStatistics(
            type: heartRateType,
            unit: unit,
            options: .discreteAverage,
            from: startDate,
            to: endDate
        ) { results, error in
            let mapped = results.map { (date: $0.date, avgBPM: $0.value) }
            completion(mapped, error)
        }
    }

    /// Generic method to fetch daily statistics
    private func fetchDailyStatistics(
        type: HKQuantityType,
        unit: HKUnit,
        options: HKStatisticsOptions,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping ([(date: Date, value: Double)], Error?) -> Void
    ) {
        let calendar = Calendar.current
        var interval = DateComponents()
        interval.day = 1

        let anchorDate = calendar.startOfDay(for: startDate)

        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: nil,
            options: options,
            anchorDate: anchorDate,
            intervalComponents: interval
        )

        query.initialResultsHandler = { _, results, error in
            if let error = error {
                DispatchQueue.main.async { completion([], error) }
                return
            }

            var dailyData: [(date: Date, value: Double)] = []

            results?.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let value: Double
                if options.contains(.cumulativeSum) {
                    value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                } else {
                    value = statistics.averageQuantity()?.doubleValue(for: unit) ?? 0
                }
                dailyData.append((date: statistics.startDate, value: value))
            }

            DispatchQueue.main.async { completion(dailyData, nil) }
        }

        healthStore.execute(query)
    }

    // MARK: - Async/Await Wrappers

    /// Async wrapper for fetching step samples
    func fetchStepSamples(from startDate: Date, to endDate: Date) async throws -> [HealthDataSample] {
        try await withCheckedThrowingContinuation { continuation in
            fetchStepSamples(from: startDate, to: endDate) { samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples)
                }
            }
        }
    }

    /// Async wrapper for fetching heart rate samples
    func fetchHeartRateSamples(from startDate: Date, to endDate: Date) async throws -> [HealthDataSample] {
        try await withCheckedThrowingContinuation { continuation in
            fetchHeartRateSamples(from: startDate, to: endDate) { samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples)
                }
            }
        }
    }

    /// Async wrapper for fetching active energy samples
    func fetchActiveEnergySamples(from startDate: Date, to endDate: Date) async throws -> [HealthDataSample] {
        try await withCheckedThrowingContinuation { continuation in
            fetchActiveEnergySamples(from: startDate, to: endDate) { samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples)
                }
            }
        }
    }

    /// Async wrapper for fetching distance samples
    func fetchDistanceSamples(from startDate: Date, to endDate: Date) async throws -> [HealthDataSample] {
        try await withCheckedThrowingContinuation { continuation in
            fetchDistanceSamples(from: startDate, to: endDate) { samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: samples)
                }
            }
        }
    }
}
