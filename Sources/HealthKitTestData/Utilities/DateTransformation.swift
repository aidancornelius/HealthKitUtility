//
//  DateTransformation.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

/// Transforms dates from one time range to another while preserving relative timing
///
/// Used to transpose historical health data to current dates, maintaining the same
/// patterns and intervals between samples.
@available(iOS 18.0, *)
public struct DateTransformation: Codable, Sendable {
    public let originalStartDate: Date
    public let originalEndDate: Date
    public let targetStartDate: Date
    public let targetEndDate: Date

    public init(originalStartDate: Date, originalEndDate: Date, targetStartDate: Date, targetEndDate: Date) {
        self.originalStartDate = originalStartDate
        self.originalEndDate = originalEndDate
        self.targetStartDate = targetStartDate
        self.targetEndDate = targetEndDate
    }

    /// Transforms a date from the original range to the target range
    ///
    /// The transformation maintains relative position within the time range,
    /// so a date at 25% through the original range will be at 25% through the target range.
    public func transform(_ date: Date) -> Date {
        let originalInterval = originalEndDate.timeIntervalSince(originalStartDate)
        let targetInterval = targetEndDate.timeIntervalSince(targetStartDate)

        let progress = date.timeIntervalSince(originalStartDate) / originalInterval
        let scaledProgress = progress * targetInterval

        return targetStartDate.addingTimeInterval(scaledProgress)
    }

    /// Transposes a bundle's dates to end at the current time
    ///
    /// This is useful for taking historical health data and shifting it to current dates
    /// while maintaining the same duration and relative timing between samples.
    ///
    /// - Parameter bundle: The bundle with historical dates
    /// - Returns: A new bundle with dates transposed to end now
    public static func transposeBundleDatesToToday(_ bundle: ExportedHealthBundle) -> ExportedHealthBundle {
        let originalDuration = bundle.endDate.timeIntervalSince(bundle.startDate)
        let newEndDate = Date()
        let newStartDate = newEndDate.addingTimeInterval(-originalDuration)

        // Calculate time offset to apply to all dates
        let timeOffset = newEndDate.timeIntervalSince(bundle.endDate)

        // Helper function to transpose a date
        func transposeDate(_ date: Date) -> Date {
            return date.addingTimeInterval(timeOffset)
        }

        // Transpose all samples
        let transposedHeartRate = bundle.heartRate.map { sample in
            HeartRateSample(
                date: transposeDate(sample.date),
                value: sample.value,
                source: sample.source
            )
        }

        let transposedHRV = bundle.hrv.map { sample in
            HRVSample(
                date: transposeDate(sample.date),
                value: sample.value,
                source: sample.source
            )
        }

        let transposedActivity = bundle.activity.map { sample in
            ActivitySample(
                date: transposeDate(sample.date),
                endDate: transposeDate(sample.endDate),
                stepCount: sample.stepCount,
                distance: sample.distance,
                activeCalories: sample.activeCalories,
                source: sample.source
            )
        }

        let transposedSleep = bundle.sleep.map { sample in
            SleepSample(
                startDate: transposeDate(sample.startDate),
                endDate: transposeDate(sample.endDate),
                stage: sample.stage,
                source: sample.source
            )
        }

        let transposedWorkouts = bundle.workouts.map { workout in
            WorkoutSample(
                startDate: transposeDate(workout.startDate),
                endDate: transposeDate(workout.endDate),
                type: workout.type,
                calories: workout.calories,
                distance: workout.distance,
                averageHeartRate: workout.averageHeartRate,
                source: workout.source
            )
        }

        let transposedRestingHeartRate = bundle.restingHeartRate.map { sample in
            RestingHeartRateSample(
                date: transposeDate(sample.date),
                value: sample.value,
                source: sample.source
            )
        }

        // Transpose optional arrays
        let transposedRespiratory = bundle.respiratoryRate?.map { sample in
            RespiratorySample(
                date: transposeDate(sample.date),
                value: sample.value
            )
        }

        let transposedOxygen = bundle.bloodOxygen?.map { sample in
            OxygenSample(
                date: transposeDate(sample.date),
                value: sample.value
            )
        }

        let transposedTemperature = bundle.skinTemperature?.map { sample in
            TemperatureSample(
                date: transposeDate(sample.date),
                value: sample.value
            )
        }

        let transposedWheelchair = bundle.wheelchairActivity?.map { sample in
            WheelchairActivitySample(
                date: transposeDate(sample.date),
                endDate: transposeDate(sample.endDate),
                pushCount: sample.pushCount,
                distance: sample.distance,
                source: sample.source
            )
        }

        let transposedExercise = bundle.exerciseTime?.map { sample in
            ExerciseTimeSample(
                date: transposeDate(sample.date),
                endDate: transposeDate(sample.endDate),
                minutes: sample.minutes,
                source: sample.source
            )
        }

        let transposedBodyTemp = bundle.bodyTemperature?.map { sample in
            BodyTemperatureSample(
                date: transposeDate(sample.date),
                value: sample.value,
                source: sample.source
            )
        }

        let transposedMenstrual = bundle.menstrualFlow?.map { sample in
            MenstrualFlowSample(
                date: transposeDate(sample.date),
                endDate: transposeDate(sample.endDate),
                flowLevel: sample.flowLevel,
                isCycleStart: sample.isCycleStart,
                source: sample.source
            )
        }

        let transposedMindful = bundle.mindfulMinutes?.map { sample in
            MindfulMinutesSample(
                date: transposeDate(sample.date),
                endDate: transposeDate(sample.endDate),
                duration: sample.duration,
                source: sample.source
            )
        }

        let transposedStateOfMind = bundle.stateOfMind?.map { sample in
            StateOfMindSample(
                date: transposeDate(sample.date),
                valence: sample.valence,
                arousal: sample.arousal,
                labels: sample.labels,
                source: sample.source
            )
        }

        return ExportedHealthBundle(
            exportDate: Date(),
            startDate: newStartDate,
            endDate: newEndDate,
            heartRate: transposedHeartRate,
            hrv: transposedHRV,
            activity: transposedActivity,
            sleep: transposedSleep,
            workouts: transposedWorkouts,
            restingHeartRate: transposedRestingHeartRate,
            respiratoryRate: transposedRespiratory,
            bloodOxygen: transposedOxygen,
            skinTemperature: transposedTemperature,
            wheelchairActivity: transposedWheelchair,
            exerciseTime: transposedExercise,
            bodyTemperature: transposedBodyTemp,
            menstrualFlow: transposedMenstrual,
            mindfulMinutes: transposedMindful,
            stateOfMind: transposedStateOfMind
        )
    }
}
