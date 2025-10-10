//
//  HealthKitWriter.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

#if os(iOS)
import HealthKit

/// Writes synthetic health data to HealthKit (iOS Simulator only)
///
/// This class handles converting `ExportedHealthBundle` data into HealthKit samples
/// and writing them to the HealthKit store. Import operations are only available
/// when running in the iOS Simulator.
///
/// ## Usage
/// ```swift
/// let healthStore = HKHealthStore()
/// try await healthStore.requestAuthorization(toShare: typesToWrite, read: [])
///
/// let writer = HealthKitWriter(healthStore: healthStore)
/// let bundle = SyntheticDataGenerator.generateHealthData(preset: .normal, ...)
/// try await writer.importData(bundle)
/// ```
@available(iOS 18.0, *)
public class HealthKitWriter {
    private let healthStore: HealthStoreWritable

    /// Initialise with a HealthKit store
    ///
    /// - Parameter healthStore: A HealthKit store with write permissions already granted.
    ///   Pass `HKHealthStore()` for production use, or a mock for testing.
    public init(healthStore: HealthStoreWritable = HKHealthStore()) {
        self.healthStore = healthStore
    }

    /// Request authorisation for writing test data to HealthKit
    ///
    /// Call this before importing data to ensure your app has write permissions.
    /// This method requests write access to all supported health data types.
    ///
    /// - Throws: ``HealthKitError/healthKitUnavailable`` if HealthKit is not available,
    ///          ``HealthKitError/simulatorOnly`` if not running in simulator,
    ///          or other HealthKit errors if authorisation fails.
    public func requestAuthorization() async throws {
        #if targetEnvironment(simulator)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthKitUnavailable
        }

        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .pushCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWheelchair)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .menstrualFlow)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
        ]

        // Call requestAuthorization on HKHealthStore directly
        // (HealthStoreWritable protocol doesn't include this as HKHealthStore has native support)
        guard let hkStore = healthStore as? HKHealthStore else {
            throw HealthKitError.operationFailed("requestAuthorization requires HKHealthStore")
        }
        try await hkStore.requestAuthorization(toShare: typesToWrite, read: [])
        #else
        throw HealthKitError.simulatorOnly
        #endif
    }

    /// Import a health data bundle into HealthKit
    ///
    /// Converts all samples in the bundle to HealthKit format and writes them to the store.
    /// This operation is only available in the iOS Simulator.
    ///
    /// - Parameter bundle: The health data bundle to import
    /// - Throws: ``HealthKitError/simulatorOnly`` if not running in simulator,
    ///          ``HealthKitError/healthKitUnavailable`` if HealthKit is not available,
    ///          or other HealthKit errors if the import fails.
    public func importData(_ bundle: ExportedHealthBundle) async throws {
        #if targetEnvironment(simulator)
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthKitUnavailable
        }

        // Convert bundle to HealthKit samples
        var allSamples: [HKSample] = []

        // Heart rate
        if !bundle.heartRate.isEmpty {
            allSamples.append(contentsOf: try convertHeartRateSamples(bundle.heartRate))
        }

        // HRV
        if !bundle.hrv.isEmpty {
            allSamples.append(contentsOf: try convertHRVSamples(bundle.hrv))
        }

        // Activity (steps + distance + calories)
        if !bundle.activity.isEmpty {
            allSamples.append(contentsOf: try convertActivitySamples(bundle.activity))
        }

        // Sleep
        if !bundle.sleep.isEmpty {
            allSamples.append(contentsOf: try convertSleepSamples(bundle.sleep))
        }

        // Workouts
        if !bundle.workouts.isEmpty {
            allSamples.append(contentsOf: try convertWorkoutSamples(bundle.workouts))
        }

        // Wheelchair activity
        if let wheelchair = bundle.wheelchairActivity, !wheelchair.isEmpty {
            allSamples.append(contentsOf: try convertWheelchairSamples(wheelchair))
        }

        // Body temperature
        if let bodyTemp = bundle.bodyTemperature, !bodyTemp.isEmpty {
            allSamples.append(contentsOf: try convertBodyTemperatureSamples(bodyTemp))
        }

        // Menstrual flow
        if let menstrual = bundle.menstrualFlow, !menstrual.isEmpty {
            allSamples.append(contentsOf: try convertMenstrualFlowSamples(menstrual))
        }

        // Save all samples
        if !allSamples.isEmpty {
            try await healthStore.save(allSamples)
        }
        #else
        throw HealthKitError.simulatorOnly
        #endif
    }

    // MARK: - Sample conversion methods

    private func convertHeartRateSamples(_ samples: [HeartRateSample]) throws -> [HKQuantitySample] {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let unit = HKUnit.count().unitDivided(by: .minute())

        return samples.map { sample in
            let quantity = HKQuantity(unit: unit, doubleValue: sample.value)
            return HKQuantitySample(
                type: type,
                quantity: quantity,
                start: sample.date,
                end: sample.date
            )
        }
    }

    private func convertHRVSamples(_ samples: [HRVSample]) throws -> [HKQuantitySample] {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let unit = HKUnit.secondUnit(with: .milli)

        return samples.map { sample in
            let quantity = HKQuantity(unit: unit, doubleValue: sample.value)
            return HKQuantitySample(
                type: type,
                quantity: quantity,
                start: sample.date,
                end: sample.date
            )
        }
    }

    private func convertActivitySamples(_ samples: [ActivitySample]) throws -> [HKQuantitySample] {
        var result: [HKQuantitySample] = []

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let stepUnit = HKUnit.count()

        // Steps
        result.append(contentsOf: samples.map { sample in
            let quantity = HKQuantity(unit: stepUnit, doubleValue: sample.stepCount)
            return HKQuantitySample(
                type: stepType,
                quantity: quantity,
                start: sample.date,
                end: sample.endDate
            )
        })

        // Distance (if available)
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let distanceUnit = HKUnit.meter()

        result.append(contentsOf: samples.compactMap { sample -> HKQuantitySample? in
            guard let distance = sample.distance else { return nil }
            let quantity = HKQuantity(unit: distanceUnit, doubleValue: distance)
            return HKQuantitySample(
                type: distanceType,
                quantity: quantity,
                start: sample.date,
                end: sample.endDate
            )
        })

        // Calories (if available)
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let caloriesUnit = HKUnit.kilocalorie()

        result.append(contentsOf: samples.compactMap { sample -> HKQuantitySample? in
            guard let calories = sample.activeCalories else { return nil }
            let quantity = HKQuantity(unit: caloriesUnit, doubleValue: calories)
            return HKQuantitySample(
                type: caloriesType,
                quantity: quantity,
                start: sample.date,
                end: sample.endDate
            )
        })

        return result
    }

    private func convertSleepSamples(_ samples: [SleepSample]) throws -> [HKCategorySample] {
        let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

        return samples.compactMap { sample -> HKCategorySample? in
            let value: HKCategoryValueSleepAnalysis
            switch sample.stage {
            case .awake: value = .awake
            case .light: value = .asleepCore
            case .deep: value = .asleepDeep
            case .rem: value = .asleepREM
            case .unknown: value = .asleepUnspecified
            }

            return HKCategorySample(
                type: type,
                value: value.rawValue,
                start: sample.startDate,
                end: sample.endDate
            )
        }
    }

    private func convertWorkoutSamples(_ samples: [WorkoutSample]) throws -> [HKWorkout] {
        return samples.map { sample in
            let workoutType = workoutActivityType(from: sample.type)

            return HKWorkout(
                activityType: workoutType,
                start: sample.startDate,
                end: sample.endDate,
                duration: sample.endDate.timeIntervalSince(sample.startDate),
                totalEnergyBurned: sample.calories.map { HKQuantity(unit: .kilocalorie(), doubleValue: $0) },
                totalDistance: sample.distance.map { HKQuantity(unit: .meter(), doubleValue: $0) },
                metadata: nil
            )
        }
    }

    private func convertWheelchairSamples(_ samples: [WheelchairActivitySample]) throws -> [HKQuantitySample] {
        var result: [HKQuantitySample] = []

        let pushType = HKQuantityType.quantityType(forIdentifier: .pushCount)!
        let pushUnit = HKUnit.count()

        // Pushes
        result.append(contentsOf: samples.map { sample in
            let quantity = HKQuantity(unit: pushUnit, doubleValue: sample.pushCount)
            return HKQuantitySample(
                type: pushType,
                quantity: quantity,
                start: sample.date,
                end: sample.endDate
            )
        })

        // Distance (if available)
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWheelchair)!
        let distanceUnit = HKUnit.meter()

        result.append(contentsOf: samples.compactMap { sample -> HKQuantitySample? in
            guard let distance = sample.distance else { return nil }
            let quantity = HKQuantity(unit: distanceUnit, doubleValue: distance)
            return HKQuantitySample(
                type: distanceType,
                quantity: quantity,
                start: sample.date,
                end: sample.endDate
            )
        })

        return result
    }

    private func convertBodyTemperatureSamples(_ samples: [BodyTemperatureSample]) throws -> [HKQuantitySample] {
        let type = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
        let unit = HKUnit.degreeCelsius()

        return samples.map { sample in
            let quantity = HKQuantity(unit: unit, doubleValue: sample.value)
            return HKQuantitySample(
                type: type,
                quantity: quantity,
                start: sample.date,
                end: sample.date
            )
        }
    }

    private func convertMenstrualFlowSamples(_ samples: [MenstrualFlowSample]) throws -> [HKCategorySample] {
        let type = HKCategoryType.categoryType(forIdentifier: .menstrualFlow)!

        return samples.compactMap { sample -> HKCategorySample? in
            let value: HKCategoryValueVaginalBleeding
            switch sample.flowLevel {
            case .unspecified: value = .unspecified
            case .light: value = .light
            case .medium: value = .medium
            case .heavy: value = .heavy
            case .none: value = .none
            }

            let metadata: [String: Any] = [
                HKMetadataKeyMenstrualCycleStart: sample.isCycleStart
            ]

            return HKCategorySample(
                type: type,
                value: value.rawValue,
                start: sample.date,
                end: sample.endDate,
                metadata: metadata
            )
        }
    }

    // MARK: - Helper methods

    private func workoutActivityType(from name: String) -> HKWorkoutActivityType {
        switch name.lowercased() {
        case "running": return .running
        case "walking": return .walking
        case "cycling": return .cycling
        case "swimming": return .swimming
        case "yoga": return .yoga
        case "strength training", "weight training": return .functionalStrengthTraining
        case "hiit": return .highIntensityIntervalTraining
        case "hiking": return .hiking
        case "elliptical": return .elliptical
        case "rowing": return .rowing
        case "dance": return .socialDance
        case "pilates": return .pilates
        case "boxing": return .boxing
        default: return .other
        }
    }
}
#endif
