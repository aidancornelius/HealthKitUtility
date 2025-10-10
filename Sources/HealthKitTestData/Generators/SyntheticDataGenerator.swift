//
//  SyntheticDataGenerator.swift
//  HealthKitTestData
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

// MARK: - Synthetic Data Generator

/// Generates realistic synthetic health data for testing.
///
/// The generator creates physiologically plausible health data based on presets
/// and manipulation strategies. All generation is deterministic when using the same seed.
@available(iOS 18.0, *)
public struct SyntheticDataGenerator {
    /// Generates a complete health data bundle.
    ///
    /// - Parameters:
    ///   - preset: The stress/health profile to generate
    ///   - manipulation: How to handle existing data
    ///   - startDate: Start of the date range
    ///   - endDate: End of the date range
    ///   - existingBundle: Optional existing data to modify
    ///   - seed: Random seed for reproducible results
    ///   - includeMenstrualData: Whether to include menstrual cycle data
    /// - Returns: A complete health data bundle
    public static func generateHealthData(
        preset: GenerationPreset,
        manipulation: DataManipulation,
        startDate: Date,
        endDate: Date,
        existingBundle: ExportedHealthBundle? = nil,
        seed: Int = 0,
        includeMenstrualData: Bool = false
    ) -> ExportedHealthBundle {
        var rng = SeededRandomGenerator(seed: seed)
        let calendar = Calendar.current
        _ = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 7

        // Generate or modify data based on manipulation type
        switch manipulation {
        case .keepOriginal:
            return existingBundle ?? generateCompleteBundle(preset: preset, startDate: startDate, endDate: endDate, includeMenstrualData: includeMenstrualData, rng: &rng)

        case .generateMissing:
            return fillMissingData(in: existingBundle, preset: preset, startDate: startDate, endDate: endDate, includeMenstrualData: includeMenstrualData, rng: &rng)

        case .smoothReplace:
            return generateCompleteBundle(preset: preset, startDate: startDate, endDate: endDate, includeMenstrualData: includeMenstrualData, rng: &rng)

        case .accessibilityMode:
            return generateAccessibilityBundle(preset: preset, startDate: startDate, endDate: endDate, existingBundle: existingBundle, includeMenstrualData: includeMenstrualData, rng: &rng)
        }
    }

    private static func generateCompleteBundle(
        preset: GenerationPreset,
        startDate: Date,
        endDate: Date,
        includeMenstrualData: Bool,
        rng: inout SeededRandomGenerator
    ) -> ExportedHealthBundle {
        let heartRate = generateHeartRateData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng)
        let hrv = generateHRVData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng)
        let activity = generateActivityData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng)
        let sleep = generateSleepData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng)
        let workouts = generateWorkoutData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng)

        return ExportedHealthBundle(
            exportDate: Date(),
            startDate: startDate,
            endDate: endDate,
            heartRate: heartRate,
            hrv: hrv,
            activity: activity,
            sleep: sleep,
            workouts: workouts,
            restingHeartRate: generateRestingHeartRateData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            respiratoryRate: generateRespiratoryData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            bloodOxygen: generateOxygenData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            skinTemperature: generateTemperatureData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            wheelchairActivity: nil,
            exerciseTime: generateExerciseTimeData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            bodyTemperature: generateBodyTemperatureData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            menstrualFlow: includeMenstrualData ? generateMenstrualData(startDate: startDate, endDate: endDate, rng: &rng) : nil,
            mindfulMinutes: nil,
            stateOfMind: nil
        )
    }

    private static func fillMissingData(
        in bundle: ExportedHealthBundle?,
        preset: GenerationPreset,
        startDate: Date,
        endDate: Date,
        includeMenstrualData: Bool,
        rng: inout SeededRandomGenerator
    ) -> ExportedHealthBundle {
        guard let bundle = bundle else {
            return generateCompleteBundle(preset: preset, startDate: startDate, endDate: endDate, includeMenstrualData: includeMenstrualData, rng: &rng)
        }

        return ExportedHealthBundle(
            exportDate: Date(),
            startDate: startDate,
            endDate: endDate,
            heartRate: bundle.heartRate.isEmpty ? generateHeartRateData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng) : bundle.heartRate,
            hrv: bundle.hrv.isEmpty ? generateHRVData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng) : bundle.hrv,
            activity: bundle.activity.isEmpty ? generateActivityData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng) : bundle.activity,
            sleep: bundle.sleep.isEmpty ? generateSleepData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng) : bundle.sleep,
            workouts: bundle.workouts.isEmpty ? generateWorkoutData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng) : bundle.workouts,
            restingHeartRate: bundle.restingHeartRate.isEmpty ? generateRestingHeartRateData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng) : bundle.restingHeartRate,
            respiratoryRate: bundle.respiratoryRate ?? generateRespiratoryData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            bloodOxygen: bundle.bloodOxygen ?? generateOxygenData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            skinTemperature: bundle.skinTemperature ?? generateTemperatureData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            wheelchairActivity: bundle.wheelchairActivity ?? (Bool.random(using: &rng) ? generateWheelchairData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng) : nil),
            exerciseTime: bundle.exerciseTime ?? generateExerciseTimeData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            bodyTemperature: bundle.bodyTemperature ?? generateBodyTemperatureData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng),
            menstrualFlow: bundle.menstrualFlow ?? (includeMenstrualData ? generateMenstrualData(startDate: startDate, endDate: endDate, rng: &rng) : nil),
            mindfulMinutes: bundle.mindfulMinutes,
            stateOfMind: bundle.stateOfMind
        )
    }

    private static func generateAccessibilityBundle(
        preset: GenerationPreset,
        startDate: Date,
        endDate: Date,
        existingBundle: ExportedHealthBundle?,
        includeMenstrualData: Bool,
        rng: inout SeededRandomGenerator
    ) -> ExportedHealthBundle {
        // Convert steps to wheelchair pushes
        let wheelchairData = generateWheelchairData(preset: preset, startDate: startDate, endDate: endDate, rng: &rng)

        if let bundle = existingBundle {
            return ExportedHealthBundle(
                exportDate: Date(),
                startDate: startDate,
                endDate: endDate,
                heartRate: bundle.heartRate,
                hrv: bundle.hrv,
                activity: [], // Remove steps
                sleep: bundle.sleep,
                workouts: bundle.workouts,
                restingHeartRate: bundle.restingHeartRate,
                respiratoryRate: bundle.respiratoryRate,
                bloodOxygen: bundle.bloodOxygen,
                skinTemperature: bundle.skinTemperature,
                wheelchairActivity: wheelchairData, // Add wheelchair data
                exerciseTime: bundle.exerciseTime,
                bodyTemperature: bundle.bodyTemperature,
                menstrualFlow: includeMenstrualData ? bundle.menstrualFlow : nil,
                mindfulMinutes: bundle.mindfulMinutes,
                stateOfMind: bundle.stateOfMind
            )
        } else {
            let bundle = generateCompleteBundle(preset: preset, startDate: startDate, endDate: endDate, includeMenstrualData: includeMenstrualData, rng: &rng)
            return ExportedHealthBundle(
                exportDate: bundle.exportDate,
                startDate: bundle.startDate,
                endDate: bundle.endDate,
                heartRate: bundle.heartRate,
                hrv: bundle.hrv,
                activity: [], // Remove steps
                sleep: bundle.sleep,
                workouts: bundle.workouts,
                restingHeartRate: bundle.restingHeartRate,
                respiratoryRate: bundle.respiratoryRate,
                bloodOxygen: bundle.bloodOxygen,
                skinTemperature: bundle.skinTemperature,
                wheelchairActivity: wheelchairData, // Add wheelchair data
                exerciseTime: bundle.exerciseTime,
                bodyTemperature: bundle.bodyTemperature,
                menstrualFlow: includeMenstrualData ? bundle.menstrualFlow : nil,
                mindfulMinutes: bundle.mindfulMinutes,
                stateOfMind: bundle.stateOfMind
            )
        }
    }

    // Individual data generators
    private static func generateHeartRateData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [HeartRateSample] {
        var samples: [HeartRateSample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let value = Double.random(in: preset.heartRateRange, using: &rng)
            samples.append(HeartRateSample(date: currentDate, value: value, source: "HealthKitExporter"))
            currentDate = currentDate.addingTimeInterval(300) // Every 5 minutes
        }
        return samples
    }

    private static func generateRestingHeartRateData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [RestingHeartRateSample] {
        var samples: [RestingHeartRateSample] = []
        var currentDate = startDate
        let calendar = Calendar.current

        // Resting heart rate is typically calculated daily
        while currentDate < endDate {
            // Resting HR is generally lower than average HR
            let baseValue: Double
            switch preset {
            case .lowerStress: baseValue = Double.random(in: 50...60, using: &rng)
            case .normal: baseValue = Double.random(in: 55...65, using: &rng)
            case .higherStress: baseValue = Double.random(in: 60...75, using: &rng)
            case .edgeCases: baseValue = Double.random(in: 40...90, using: &rng)
            }

            samples.append(RestingHeartRateSample(date: currentDate, value: baseValue, source: "HealthKitExporter"))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate.addingTimeInterval(86400)
        }
        return samples
    }

    private static func generateHRVData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [HRVSample] {
        var samples: [HRVSample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let value = Double.random(in: preset.hrvRange, using: &rng)
            samples.append(HRVSample(date: currentDate, value: value, source: "HealthKitExporter"))
            currentDate = currentDate.addingTimeInterval(3600) // Every hour
        }
        return samples
    }

    private static func generateActivityData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [ActivitySample] {
        var samples: [ActivitySample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let endHour = currentDate.addingTimeInterval(3600)
            let steps = Double.random(in: preset.stepsRange, using: &rng) / 24 // Hourly steps
            let distance = steps * 0.75 // Average step length in meters
            let calories = steps * 0.05 // Rough calorie estimate

            samples.append(ActivitySample(
                date: currentDate,
                endDate: endHour,
                stepCount: steps,
                distance: distance,
                activeCalories: calories,
                source: "HealthKitExporter"
            ))
            currentDate = endHour
        }
        return samples
    }

    private static func generateSleepData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [SleepSample] {
        var samples: [SleepSample] = []
        var currentDate = startDate
        let calendar = Calendar.current

        while currentDate < endDate {
            // Sleep from 10 PM to 6 AM (adjust based on preset)
            let sleepStart = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: currentDate)!
            let sleepHours = Double.random(in: preset.sleepHours, using: &rng)
            let sleepEnd = sleepStart.addingTimeInterval(sleepHours * 3600)

            // Generate sleep stages
            var sleepTime = sleepStart
            while sleepTime < sleepEnd {
                let stageDuration = Double.random(in: 20...90, using: &rng) * 60 // 20-90 minute stages
                let stageEnd = min(sleepTime.addingTimeInterval(stageDuration), sleepEnd)

                let stages: [SleepStage] = [.light, .deep, .rem]
                let stage = stages.randomElement(using: &rng)!

                samples.append(SleepSample(
                    startDate: sleepTime,
                    endDate: stageEnd,
                    stage: stage,
                    source: "HealthKitExporter"
                ))

                sleepTime = stageEnd
            }

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return samples
    }

    private static func generateWorkoutData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [WorkoutSample] {
        var samples: [WorkoutSample] = []
        var currentDate = startDate
        let calendar = Calendar.current

        while currentDate < endDate {
            // One workout per day
            let workoutStart = calendar.date(bySettingHour: Int.random(in: 6...20, using: &rng), minute: 0, second: 0, of: currentDate)!
            let duration = Double.random(in: 20...60, using: &rng) * 60 // 20-60 minutes
            let workoutEnd = workoutStart.addingTimeInterval(duration)

            let types = ["Running", "Walking", "Cycling", "Yoga", "Strength training"]
            let type = types.randomElement(using: &rng)!

            samples.append(WorkoutSample(
                startDate: workoutStart,
                endDate: workoutEnd,
                type: type,
                calories: Double.random(in: 100...500, using: &rng),
                distance: type == "Running" || type == "Cycling" ? Double.random(in: 1000...10000, using: &rng) : nil,
                averageHeartRate: Double.random(in: preset.heartRateRange, using: &rng),
                source: "HealthKitExporter"
            ))

            currentDate = calendar.date(byAdding: .day, value: Int.random(in: 1...3, using: &rng), to: currentDate)!
        }
        return samples
    }

    private static func generateWheelchairData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [WheelchairActivitySample] {
        var samples: [WheelchairActivitySample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let endHour = currentDate.addingTimeInterval(3600)
            let pushes = Double.random(in: 50...200, using: &rng) // Hourly pushes
            let distance = pushes * 2.5 // Average push distance in meters

            samples.append(WheelchairActivitySample(
                date: currentDate,
                endDate: endHour,
                pushCount: pushes,
                distance: distance,
                source: "HealthKitExporter"
            ))
            currentDate = endHour
        }
        return samples
    }

    private static func generateExerciseTimeData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [ExerciseTimeSample] {
        var samples: [ExerciseTimeSample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let minutes = Double.random(in: 0...60, using: &rng)
            if minutes > 5 { // Only record if more than 5 minutes
                samples.append(ExerciseTimeSample(
                    date: currentDate,
                    endDate: currentDate.addingTimeInterval(minutes * 60),
                    minutes: minutes,
                    source: "HealthKitExporter"
                ))
            }
            currentDate = currentDate.addingTimeInterval(86400) // Daily
        }
        return samples
    }

    private static func generateRespiratoryData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [RespiratorySample] {
        var samples: [RespiratorySample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let rate = preset == .higherStress ? Double.random(in: 16...20, using: &rng) : Double.random(in: 12...16, using: &rng)
            samples.append(RespiratorySample(date: currentDate, value: rate))
            currentDate = currentDate.addingTimeInterval(3600) // Hourly
        }
        return samples
    }

    private static func generateOxygenData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [OxygenSample] {
        var samples: [OxygenSample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let oxygen = preset == .edgeCases ? Double.random(in: 85...100, using: &rng) : Double.random(in: 95...100, using: &rng)
            samples.append(OxygenSample(date: currentDate, value: oxygen))
            currentDate = currentDate.addingTimeInterval(3600) // Hourly
        }
        return samples
    }

    private static func generateTemperatureData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [TemperatureSample] {
        var samples: [TemperatureSample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let temp = Double.random(in: 36.0...37.5, using: &rng)
            samples.append(TemperatureSample(date: currentDate, value: temp))
            currentDate = currentDate.addingTimeInterval(3600) // Hourly
        }
        return samples
    }

    private static func generateBodyTemperatureData(preset: GenerationPreset, startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [BodyTemperatureSample] {
        var samples: [BodyTemperatureSample] = []
        var currentDate = startDate

        while currentDate < endDate {
            let temp = preset == .higherStress ? Double.random(in: 37.2...38.0, using: &rng) : Double.random(in: 36.5...37.2, using: &rng)
            samples.append(BodyTemperatureSample(date: currentDate, value: temp, source: "HealthKitExporter"))
            currentDate = currentDate.addingTimeInterval(43200) // Twice daily
        }
        return samples
    }

    private static func generateMenstrualData(startDate: Date, endDate: Date, rng: inout SeededRandomGenerator) -> [MenstrualFlowSample] {
        var samples: [MenstrualFlowSample] = []
        var currentDate = startDate
        let calendar = Calendar.current

        // Generate monthly cycles
        while currentDate < endDate {
            // Period lasts 3-7 days
            let periodDays = Int.random(in: 3...7, using: &rng)

            for day in 0..<periodDays {
                let dayStart = calendar.date(byAdding: .day, value: day, to: currentDate)!
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

                let flowLevel: MenstrualFlowLevel
                if day == 0 || day == periodDays - 1 {
                    flowLevel = .light
                } else if day == 1 || day == 2 {
                    flowLevel = Bool.random(using: &rng) ? .medium : .heavy
                } else {
                    flowLevel = .medium
                }

                samples.append(MenstrualFlowSample(
                    date: dayStart,
                    endDate: dayEnd,
                    flowLevel: flowLevel,
                    isCycleStart: day == 0, // First day of period is cycle start
                    source: "HealthKitExporter"
                ))
            }

            // Next cycle in 28-35 days
            currentDate = calendar.date(byAdding: .day, value: Int.random(in: 28...35, using: &rng), to: currentDate)!
        }
        return samples
    }
}
