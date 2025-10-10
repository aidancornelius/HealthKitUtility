#!/usr/bin/env swift

//
//  GenerateFixtures.swift
//  HealthKitUtility
//
//  Script to generate test fixture JSON files for health data testing
//  Run with: swift Scripts/GenerateFixtures.swift
//

import Foundation

// MARK: - Models (copied from HealthKitTestData to make script standalone)

struct ExportedHealthBundle: Codable {
    let exportDate: Date
    let startDate: Date
    let endDate: Date
    let heartRate: [HeartRateSample]
    let hrv: [HRVSample]
    let activity: [ActivitySample]
    let sleep: [SleepSample]
    let workouts: [WorkoutSample]
    let restingHeartRate: [RestingHeartRateSample]
    let respiratoryRate: [RespiratorySample]?
    let bloodOxygen: [OxygenSample]?
    let skinTemperature: [TemperatureSample]?
    let wheelchairActivity: [WheelchairActivitySample]?
    let exerciseTime: [ExerciseTimeSample]?
    let bodyTemperature: [BodyTemperatureSample]?
    let menstrualFlow: [MenstrualFlowSample]?
    let mindfulMinutes: [MindfulMinutesSample]?
    let stateOfMind: [StateOfMindSample]?
}

struct HeartRateSample: Codable {
    let date: Date
    let value: Double
    let source: String
}

struct RestingHeartRateSample: Codable {
    let date: Date
    let value: Double
    let source: String
}

struct HRVSample: Codable {
    let date: Date
    let value: Double
    let source: String
}

struct ActivitySample: Codable {
    let date: Date
    let endDate: Date
    let stepCount: Double
    let distance: Double?
    let activeCalories: Double?
    let source: String
}

struct WheelchairActivitySample: Codable {
    let date: Date
    let endDate: Date
    let pushCount: Double
    let distance: Double?
    let source: String
}

struct ExerciseTimeSample: Codable {
    let date: Date
    let endDate: Date
    let minutes: Double
    let source: String
}

struct BodyTemperatureSample: Codable {
    let date: Date
    let value: Double
    let source: String
}

struct MenstrualFlowSample: Codable {
    let date: Date
    let endDate: Date
    let flowLevel: MenstrualFlowLevel
    let isCycleStart: Bool
    let source: String
}

enum MenstrualFlowLevel: String, Codable {
    case unspecified = "unspecified"
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"
    case none = "none"
}

struct SleepSample: Codable {
    let startDate: Date
    let endDate: Date
    let stage: SleepStage
    let source: String
}

enum SleepStage: String, Codable {
    case awake = "awake"
    case light = "light"
    case deep = "deep"
    case rem = "rem"
    case unknown = "unknown"
}

struct WorkoutSample: Codable {
    let startDate: Date
    let endDate: Date
    let type: String
    let calories: Double?
    let distance: Double?
    let averageHeartRate: Double?
    let source: String
}

struct RespiratorySample: Codable {
    let date: Date
    let value: Double
}

struct MindfulMinutesSample: Codable {
    let date: Date
    let endDate: Date
    let duration: Double
    let source: String
}

struct StateOfMindSample: Codable {
    let date: Date
    let valence: Double
    let arousal: Double
    let labels: [String]
    let source: String
}

struct OxygenSample: Codable {
    let date: Date
    let value: Double
}

struct TemperatureSample: Codable {
    let date: Date
    let value: Double
}

// MARK: - Seeded Random Generator

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(seed)
        if state == 0 { state = 1 }
    }

    mutating func next() -> UInt64 {
        state = state &* 2862933555777941757 &+ 3037000493
        return state
    }
}

// MARK: - Fixture Generator

class FixtureGenerator {
    var rng: SeededRandomGenerator
    let source = "Test Data Generator"

    init(seed: Int) {
        self.rng = SeededRandomGenerator(seed: seed)
    }

    func generateHighStressWeek() -> ExportedHealthBundle {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        var heartRate: [HeartRateSample] = []
        var hrv: [HRVSample] = []
        var activity: [ActivitySample] = []
        var sleep: [SleepSample] = []
        var workouts: [WorkoutSample] = []
        var restingHR: [RestingHeartRateSample] = []
        var respiratory: [RespiratorySample] = []
        var oxygen: [OxygenSample] = []
        var bodyTemp: [BodyTemperatureSample] = []

        for day in 0..<7 {
            let dayStart = Calendar.current.date(byAdding: .day, value: day, to: startDate)!

            // High stress: elevated heart rate 80-100 BPM every 5 minutes
            for minute in stride(from: 0, to: 24 * 60, by: 5) {
                let date = dayStart.addingTimeInterval(TimeInterval(minute * 60))
                let hr = Double.random(in: 80...100, using: &rng)
                heartRate.append(HeartRateSample(date: date, value: hr, source: source))
            }

            // Low HRV: 20-40 ms every hour (stress indicator)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hrvValue = Double.random(in: 20...40, using: &rng)
                hrv.append(HRVSample(date: date, value: hrvValue, source: source))
            }

            // Activity: lower step count due to stress
            for hour in 6..<22 {
                let hourStart = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hourEnd = hourStart.addingTimeInterval(3600)
                let steps = Double.random(in: 100...400, using: &rng)
                let distance = steps * 0.7
                let calories = Double.random(in: 30...80, using: &rng)
                activity.append(ActivitySample(date: hourStart, endDate: hourEnd, stepCount: steps, distance: distance, activeCalories: calories, source: source))
            }

            // Poor sleep: less deep sleep, more awake time (5-6 hours total)
            let sleepStart = dayStart.addingTimeInterval(TimeInterval(23 * 3600))
            var currentTime = sleepStart

            // Awake before sleep
            currentTime = currentTime.addingTimeInterval(TimeInterval.random(in: 1800...3600, using: &rng))

            // Light sleep
            let lightDuration = TimeInterval.random(in: 3600...5400, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(lightDuration), stage: .light, source: source))
            currentTime = currentTime.addingTimeInterval(lightDuration)

            // Brief deep sleep
            let deepDuration = TimeInterval.random(in: 1800...2700, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(deepDuration), stage: .deep, source: source))
            currentTime = currentTime.addingTimeInterval(deepDuration)

            // Awake period (stress-related wake)
            let awakeDuration = TimeInterval.random(in: 900...1800, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(awakeDuration), stage: .awake, source: source))
            currentTime = currentTime.addingTimeInterval(awakeDuration)

            // REM sleep
            let remDuration = TimeInterval.random(in: 2700...3600, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(remDuration), stage: .rem, source: source))
            currentTime = currentTime.addingTimeInterval(remDuration)

            // More light sleep
            let finalLightDuration = TimeInterval.random(in: 3600...5400, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(finalLightDuration), stage: .light, source: source))

            // Fewer workouts due to stress (every 3 days)
            if day % 3 == 0 {
                let workoutStart = dayStart.addingTimeInterval(TimeInterval(18 * 3600))
                let duration = TimeInterval.random(in: 1200...1800, using: &rng)
                workouts.append(WorkoutSample(
                    startDate: workoutStart,
                    endDate: workoutStart.addingTimeInterval(duration),
                    type: "Walking",
                    calories: Double.random(in: 100...150, using: &rng),
                    distance: Double.random(in: 1500...2500, using: &rng),
                    averageHeartRate: Double.random(in: 95...110, using: &rng),
                    source: source
                ))
            }

            // Resting heart rate (elevated)
            restingHR.append(RestingHeartRateSample(date: dayStart, value: Double.random(in: 68...78, using: &rng), source: source))

            // Respiratory rate (slightly elevated)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                respiratory.append(RespiratorySample(date: date, value: Double.random(in: 16...20, using: &rng)))
            }

            // Blood oxygen (normal)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                oxygen.append(OxygenSample(date: date, value: Double.random(in: 95...99, using: &rng)))
            }

            // Body temperature (twice daily, slightly elevated)
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(8 * 3600)), value: Double.random(in: 36.8...37.2, using: &rng), source: source))
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(20 * 3600)), value: Double.random(in: 36.7...37.1, using: &rng), source: source))
        }

        return ExportedHealthBundle(
            exportDate: endDate,
            startDate: startDate,
            endDate: endDate,
            heartRate: heartRate,
            hrv: hrv,
            activity: activity,
            sleep: sleep,
            workouts: workouts,
            restingHeartRate: restingHR,
            respiratoryRate: respiratory,
            bloodOxygen: oxygen,
            skinTemperature: nil,
            wheelchairActivity: nil,
            exerciseTime: nil,
            bodyTemperature: bodyTemp,
            menstrualFlow: nil,
            mindfulMinutes: nil,
            stateOfMind: nil
        )
    }

    func generateLowStressWeek() -> ExportedHealthBundle {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        var heartRate: [HeartRateSample] = []
        var hrv: [HRVSample] = []
        var activity: [ActivitySample] = []
        var sleep: [SleepSample] = []
        var workouts: [WorkoutSample] = []
        var restingHR: [RestingHeartRateSample] = []
        var respiratory: [RespiratorySample] = []
        var oxygen: [OxygenSample] = []
        var bodyTemp: [BodyTemperatureSample] = []

        for day in 0..<7 {
            let dayStart = Calendar.current.date(byAdding: .day, value: day, to: startDate)!

            // Low stress: normal heart rate 55-70 BPM every 5 minutes
            for minute in stride(from: 0, to: 24 * 60, by: 5) {
                let date = dayStart.addingTimeInterval(TimeInterval(minute * 60))
                let hr = Double.random(in: 55...70, using: &rng)
                heartRate.append(HeartRateSample(date: date, value: hr, source: source))
            }

            // High HRV: 45-80 ms every hour (good health indicator)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hrvValue = Double.random(in: 45...80, using: &rng)
                hrv.append(HRVSample(date: date, value: hrvValue, source: source))
            }

            // Activity: moderate step count
            for hour in 6..<22 {
                let hourStart = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hourEnd = hourStart.addingTimeInterval(3600)
                let steps = Double.random(in: 300...800, using: &rng)
                let distance = steps * 0.75
                let calories = Double.random(in: 40...100, using: &rng)
                activity.append(ActivitySample(date: hourStart, endDate: hourEnd, stepCount: steps, distance: distance, activeCalories: calories, source: source))
            }

            // Good sleep: 7-8 hours with proper stages
            let sleepStart = dayStart.addingTimeInterval(TimeInterval(23 * 3600))
            var currentTime = sleepStart

            // Light sleep to start
            let initialLight = TimeInterval.random(in: 1800...2700, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(initialLight), stage: .light, source: source))
            currentTime = currentTime.addingTimeInterval(initialLight)

            // Deep sleep (good quality)
            let deepDuration = TimeInterval.random(in: 5400...7200, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(deepDuration), stage: .deep, source: source))
            currentTime = currentTime.addingTimeInterval(deepDuration)

            // REM sleep
            let remDuration = TimeInterval.random(in: 5400...7200, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(remDuration), stage: .rem, source: source))
            currentTime = currentTime.addingTimeInterval(remDuration)

            // Light sleep
            let lightDuration = TimeInterval.random(in: 7200...9000, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(lightDuration), stage: .light, source: source))
            currentTime = currentTime.addingTimeInterval(lightDuration)

            // Brief awake before waking
            let awakeDuration = TimeInterval.random(in: 300...600, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(awakeDuration), stage: .awake, source: source))

            // Regular workouts (every 2 days)
            if day % 2 == 0 {
                let workoutStart = dayStart.addingTimeInterval(TimeInterval(17 * 3600))
                let duration = TimeInterval.random(in: 2400...3600, using: &rng)
                let types = ["Running", "Cycling", "Yoga", "Swimming"]
                workouts.append(WorkoutSample(
                    startDate: workoutStart,
                    endDate: workoutStart.addingTimeInterval(duration),
                    type: types.randomElement(using: &rng)!,
                    calories: Double.random(in: 200...400, using: &rng),
                    distance: Double.random(in: 3000...6000, using: &rng),
                    averageHeartRate: Double.random(in: 120...140, using: &rng),
                    source: source
                ))
            }

            // Resting heart rate (healthy)
            restingHR.append(RestingHeartRateSample(date: dayStart, value: Double.random(in: 52...62, using: &rng), source: source))

            // Respiratory rate (normal)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                respiratory.append(RespiratorySample(date: date, value: Double.random(in: 12...16, using: &rng)))
            }

            // Blood oxygen (excellent)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                oxygen.append(OxygenSample(date: date, value: Double.random(in: 96...100, using: &rng)))
            }

            // Body temperature (twice daily, normal)
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(8 * 3600)), value: Double.random(in: 36.4...36.8, using: &rng), source: source))
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(20 * 3600)), value: Double.random(in: 36.3...36.7, using: &rng), source: source))
        }

        return ExportedHealthBundle(
            exportDate: endDate,
            startDate: startDate,
            endDate: endDate,
            heartRate: heartRate,
            hrv: hrv,
            activity: activity,
            sleep: sleep,
            workouts: workouts,
            restingHeartRate: restingHR,
            respiratoryRate: respiratory,
            bloodOxygen: oxygen,
            skinTemperature: nil,
            wheelchairActivity: nil,
            exerciseTime: nil,
            bodyTemperature: bodyTemp,
            menstrualFlow: nil,
            mindfulMinutes: nil,
            stateOfMind: nil
        )
    }

    func generateCycleTracking() -> ExportedHealthBundle {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -28, to: now)!
        let endDate = now

        var heartRate: [HeartRateSample] = []
        var hrv: [HRVSample] = []
        var activity: [ActivitySample] = []
        var sleep: [SleepSample] = []
        var workouts: [WorkoutSample] = []
        var restingHR: [RestingHeartRateSample] = []
        var menstrualFlow: [MenstrualFlowSample] = []
        var bodyTemp: [BodyTemperatureSample] = []

        for day in 0..<28 {
            let dayStart = Calendar.current.date(byAdding: .day, value: day, to: startDate)!

            // Menstrual flow pattern (28-day cycle)
            if day < 5 {
                // Days 1-5: Menstrual phase
                let flowLevels: [MenstrualFlowLevel] = [.heavy, .heavy, .medium, .light, .light]
                let flowStart = dayStart
                let flowEnd = Calendar.current.date(byAdding: .day, value: 1, to: flowStart)!
                menstrualFlow.append(MenstrualFlowSample(
                    date: flowStart,
                    endDate: flowEnd,
                    flowLevel: flowLevels[day],
                    isCycleStart: day == 0,
                    source: source
                ))
            }

            // Heart rate varies with cycle phase
            let cyclePhase = day / 7 // 0=menstrual, 1=follicular, 2=ovulation, 3=luteal
            let baseHR: ClosedRange<Double> = {
                switch cyclePhase {
                case 0: return 60...75  // Menstrual: slightly elevated
                case 1: return 55...70  // Follicular: lower
                case 2: return 65...80  // Ovulation: elevated
                default: return 70...85 // Luteal: elevated
                }
            }()

            for minute in stride(from: 0, to: 24 * 60, by: 5) {
                let date = dayStart.addingTimeInterval(TimeInterval(minute * 60))
                let hr = Double.random(in: baseHR, using: &rng)
                heartRate.append(HeartRateSample(date: date, value: hr, source: source))
            }

            // HRV varies with cycle
            let baseHRV: ClosedRange<Double> = {
                switch cyclePhase {
                case 0: return 35...55  // Menstrual: lower
                case 1: return 45...70  // Follicular: higher
                case 2: return 40...65  // Ovulation: moderate
                default: return 30...50 // Luteal: lower
                }
            }()

            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hrvValue = Double.random(in: baseHRV, using: &rng)
                hrv.append(HRVSample(date: date, value: hrvValue, source: source))
            }

            // Activity
            for hour in 6..<22 {
                let hourStart = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hourEnd = hourStart.addingTimeInterval(3600)
                let steps = Double.random(in: 200...600, using: &rng)
                let distance = steps * 0.75
                let calories = Double.random(in: 30...90, using: &rng)
                activity.append(ActivitySample(date: hourStart, endDate: hourEnd, stepCount: steps, distance: distance, activeCalories: calories, source: source))
            }

            // Sleep (varies with cycle)
            let sleepStart = dayStart.addingTimeInterval(TimeInterval(23 * 3600))
            var currentTime = sleepStart

            let lightDuration = TimeInterval.random(in: 3600...5400, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(lightDuration), stage: .light, source: source))
            currentTime = currentTime.addingTimeInterval(lightDuration)

            let deepDuration = TimeInterval.random(in: 3600...5400, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(deepDuration), stage: .deep, source: source))
            currentTime = currentTime.addingTimeInterval(deepDuration)

            let remDuration = TimeInterval.random(in: 3600...5400, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(remDuration), stage: .rem, source: source))
            currentTime = currentTime.addingTimeInterval(remDuration)

            let finalLight = TimeInterval.random(in: 5400...7200, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(finalLight), stage: .light, source: source))

            // Workouts (every 2-3 days, less during menstruation)
            if day > 5 && day % 2 == 0 {
                let workoutStart = dayStart.addingTimeInterval(TimeInterval(17 * 3600))
                let duration = TimeInterval.random(in: 2400...3600, using: &rng)
                workouts.append(WorkoutSample(
                    startDate: workoutStart,
                    endDate: workoutStart.addingTimeInterval(duration),
                    type: "Running",
                    calories: Double.random(in: 200...350, using: &rng),
                    distance: Double.random(in: 3000...5000, using: &rng),
                    averageHeartRate: Double.random(in: 125...145, using: &rng),
                    source: source
                ))
            }

            // Resting heart rate (varies with cycle)
            let restingHRValue: Double = {
                switch cyclePhase {
                case 0: return Double.random(in: 58...65, using: &rng)
                case 1: return Double.random(in: 52...60, using: &rng)
                case 2: return Double.random(in: 60...68, using: &rng)
                default: return Double.random(in: 62...70, using: &rng)
                }
            }()
            restingHR.append(RestingHeartRateSample(date: dayStart, value: restingHRValue, source: source))

            // Body temperature (higher in luteal phase)
            let tempRange: ClosedRange<Double> = cyclePhase >= 2 ? 36.6...37.0 : 36.2...36.6
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(8 * 3600)), value: Double.random(in: tempRange, using: &rng), source: source))
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(20 * 3600)), value: Double.random(in: tempRange, using: &rng), source: source))
        }

        return ExportedHealthBundle(
            exportDate: endDate,
            startDate: startDate,
            endDate: endDate,
            heartRate: heartRate,
            hrv: hrv,
            activity: activity,
            sleep: sleep,
            workouts: workouts,
            restingHeartRate: restingHR,
            respiratoryRate: nil,
            bloodOxygen: nil,
            skinTemperature: nil,
            wheelchairActivity: nil,
            exerciseTime: nil,
            bodyTemperature: bodyTemp,
            menstrualFlow: menstrualFlow,
            mindfulMinutes: nil,
            stateOfMind: nil
        )
    }

    func generateEdgeCases() -> ExportedHealthBundle {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        var heartRate: [HeartRateSample] = []
        var hrv: [HRVSample] = []
        var activity: [ActivitySample] = []
        var sleep: [SleepSample] = []
        var workouts: [WorkoutSample] = []
        var restingHR: [RestingHeartRateSample] = []
        var respiratory: [RespiratorySample] = []
        var oxygen: [OxygenSample] = []
        var bodyTemp: [BodyTemperatureSample] = []

        for day in 0..<7 {
            let dayStart = Calendar.current.date(byAdding: .day, value: day, to: startDate)!

            // Extreme heart rate values
            for minute in stride(from: 0, to: 24 * 60, by: 10) {
                let date = dayStart.addingTimeInterval(TimeInterval(minute * 60))
                let hr: Double
                if minute % 120 == 0 {
                    hr = Double.random(in: 40...50, using: &rng)  // Very low
                } else if minute % 60 == 0 {
                    hr = Double.random(in: 150...180, using: &rng) // Very high
                } else {
                    hr = Double.random(in: 60...80, using: &rng)   // Normal
                }
                heartRate.append(HeartRateSample(date: date, value: hr, source: source))
            }

            // Extreme HRV values
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hrvValue: Double
                if hour % 6 == 0 {
                    hrvValue = Double.random(in: 10...20, using: &rng)  // Very low
                } else if hour % 4 == 0 {
                    hrvValue = Double.random(in: 100...150, using: &rng) // Very high
                } else {
                    hrvValue = Double.random(in: 30...60, using: &rng)   // Normal
                }
                hrv.append(HRVSample(date: date, value: hrvValue, source: source))
            }

            // Extreme activity values
            for hour in 6..<22 {
                let hourStart = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hourEnd = hourStart.addingTimeInterval(3600)
                let steps: Double
                if hour == 12 {
                    steps = 0 // Zero activity
                } else if hour == 18 {
                    steps = Double.random(in: 5000...8000, using: &rng) // Extreme activity
                } else {
                    steps = Double.random(in: 100...500, using: &rng)
                }
                let distance = steps * 0.75
                let calories = steps * 0.04
                activity.append(ActivitySample(date: hourStart, endDate: hourEnd, stepCount: steps, distance: distance, activeCalories: calories, source: source))
            }

            // Very short sleep (insomnia case)
            let sleepStart = dayStart.addingTimeInterval(TimeInterval(23 * 3600))
            var currentTime = sleepStart

            // Mostly awake
            let awakeDuration = TimeInterval.random(in: 7200...10800, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(awakeDuration), stage: .awake, source: source))
            currentTime = currentTime.addingTimeInterval(awakeDuration)

            // Brief light sleep
            let lightDuration = TimeInterval.random(in: 1800...3600, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(lightDuration), stage: .light, source: source))
            currentTime = currentTime.addingTimeInterval(lightDuration)

            // Very brief deep sleep
            let deepDuration = TimeInterval.random(in: 900...1800, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(deepDuration), stage: .deep, source: source))

            // Extreme workout (marathon case)
            if day == 3 {
                let workoutStart = dayStart.addingTimeInterval(TimeInterval(6 * 3600))
                let duration = TimeInterval(14400) // 4 hours
                workouts.append(WorkoutSample(
                    startDate: workoutStart,
                    endDate: workoutStart.addingTimeInterval(duration),
                    type: "Running",
                    calories: 2500,
                    distance: 42195, // Marathon distance in metres
                    averageHeartRate: 165,
                    source: source
                ))
            }

            // Extreme resting heart rate values
            let restingValue: Double
            if day % 2 == 0 {
                restingValue = Double.random(in: 35...45, using: &rng) // Athlete-level low
            } else {
                restingValue = Double.random(in: 85...95, using: &rng) // Concerning high
            }
            restingHR.append(RestingHeartRateSample(date: dayStart, value: restingValue, source: source))

            // Extreme respiratory rate
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let respValue: Double
                if hour % 8 == 0 {
                    respValue = Double.random(in: 8...10, using: &rng)  // Very low
                } else if hour % 5 == 0 {
                    respValue = Double.random(in: 25...30, using: &rng) // Very high
                } else {
                    respValue = Double.random(in: 12...16, using: &rng)
                }
                respiratory.append(RespiratorySample(date: date, value: respValue))
            }

            // Extreme blood oxygen
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let oxygenValue: Double
                if hour % 6 == 0 {
                    oxygenValue = Double.random(in: 88...92, using: &rng) // Concerning low
                } else {
                    oxygenValue = Double.random(in: 95...100, using: &rng)
                }
                oxygen.append(OxygenSample(date: date, value: oxygenValue))
            }

            // Extreme body temperature
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(8 * 3600)), value: Double.random(in: 35.5...36.0, using: &rng), source: source)) // Hypothermia risk
            bodyTemp.append(BodyTemperatureSample(date: dayStart.addingTimeInterval(TimeInterval(20 * 3600)), value: Double.random(in: 38.0...38.5, using: &rng), source: source)) // Fever
        }

        return ExportedHealthBundle(
            exportDate: endDate,
            startDate: startDate,
            endDate: endDate,
            heartRate: heartRate,
            hrv: hrv,
            activity: activity,
            sleep: sleep,
            workouts: workouts,
            restingHeartRate: restingHR,
            respiratoryRate: respiratory,
            bloodOxygen: oxygen,
            skinTemperature: nil,
            wheelchairActivity: nil,
            exerciseTime: nil,
            bodyTemperature: bodyTemp,
            menstrualFlow: nil,
            mindfulMinutes: nil,
            stateOfMind: nil
        )
    }

    func generateActiveLifestyle() -> ExportedHealthBundle {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let endDate = now

        var heartRate: [HeartRateSample] = []
        var hrv: [HRVSample] = []
        var activity: [ActivitySample] = []
        var sleep: [SleepSample] = []
        var workouts: [WorkoutSample] = []
        var restingHR: [RestingHeartRateSample] = []
        var respiratory: [RespiratorySample] = []
        var oxygen: [OxygenSample] = []
        var exerciseTime: [ExerciseTimeSample] = []

        for day in 0..<7 {
            let dayStart = Calendar.current.date(byAdding: .day, value: day, to: startDate)!

            // Athletic heart rate with workout spikes
            for minute in stride(from: 0, to: 24 * 60, by: 5) {
                let date = dayStart.addingTimeInterval(TimeInterval(minute * 60))
                let hour = minute / 60
                let hr: Double
                if hour == 6 || hour == 18 { // Workout times
                    hr = Double.random(in: 130...165, using: &rng)
                } else {
                    hr = Double.random(in: 50...70, using: &rng) // Athletic resting HR
                }
                heartRate.append(HeartRateSample(date: date, value: hr, source: source))
            }

            // Good HRV (athletic)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hrvValue = Double.random(in: 60...95, using: &rng)
                hrv.append(HRVSample(date: date, value: hrvValue, source: source))
            }

            // High activity throughout day
            for hour in 6..<22 {
                let hourStart = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                let hourEnd = hourStart.addingTimeInterval(3600)
                let steps = Double.random(in: 800...2000, using: &rng)
                let distance = steps * 0.8
                let calories = Double.random(in: 80...200, using: &rng)
                activity.append(ActivitySample(date: hourStart, endDate: hourEnd, stepCount: steps, distance: distance, activeCalories: calories, source: source))
            }

            // Good sleep (athlete recovery)
            let sleepStart = dayStart.addingTimeInterval(TimeInterval(22 * 3600))
            var currentTime = sleepStart

            let lightDuration = TimeInterval.random(in: 1800...2700, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(lightDuration), stage: .light, source: source))
            currentTime = currentTime.addingTimeInterval(lightDuration)

            let deepDuration = TimeInterval.random(in: 7200...9000, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(deepDuration), stage: .deep, source: source))
            currentTime = currentTime.addingTimeInterval(deepDuration)

            let remDuration = TimeInterval.random(in: 5400...7200, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(remDuration), stage: .rem, source: source))
            currentTime = currentTime.addingTimeInterval(remDuration)

            let finalLight = TimeInterval.random(in: 5400...7200, using: &rng)
            sleep.append(SleepSample(startDate: currentTime, endDate: currentTime.addingTimeInterval(finalLight), stage: .light, source: source))

            // Multiple workouts per day
            let workoutTypes = ["Running", "Cycling", "Swimming", "HIIT", "Strength Training", "Yoga"]

            // Morning workout
            let morningWorkoutStart = dayStart.addingTimeInterval(TimeInterval(6 * 3600))
            let morningDuration = TimeInterval.random(in: 2400...3600, using: &rng)
            let morningType = workoutTypes.randomElement(using: &rng)!
            workouts.append(WorkoutSample(
                startDate: morningWorkoutStart,
                endDate: morningWorkoutStart.addingTimeInterval(morningDuration),
                type: morningType,
                calories: Double.random(in: 300...500, using: &rng),
                distance: morningType == "Running" || morningType == "Cycling" ? Double.random(in: 5000...10000, using: &rng) : nil,
                averageHeartRate: Double.random(in: 140...165, using: &rng),
                source: source
            ))

            // Evening workout (most days)
            if day % 2 == 0 {
                let eveningWorkoutStart = dayStart.addingTimeInterval(TimeInterval(18 * 3600))
                let eveningDuration = TimeInterval.random(in: 1800...3600, using: &rng)
                let eveningType = workoutTypes.randomElement(using: &rng)!
                workouts.append(WorkoutSample(
                    startDate: eveningWorkoutStart,
                    endDate: eveningWorkoutStart.addingTimeInterval(eveningDuration),
                    type: eveningType,
                    calories: Double.random(in: 200...400, using: &rng),
                    distance: eveningType == "Running" || eveningType == "Cycling" ? Double.random(in: 3000...8000, using: &rng) : nil,
                    averageHeartRate: Double.random(in: 130...155, using: &rng),
                    source: source
                ))
            }

            // Athletic resting heart rate
            restingHR.append(RestingHeartRateSample(date: dayStart, value: Double.random(in: 42...55, using: &rng), source: source))

            // Respiratory rate (athletic)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                respiratory.append(RespiratorySample(date: date, value: Double.random(in: 10...14, using: &rng)))
            }

            // Blood oxygen (excellent)
            for hour in 0..<24 {
                let date = dayStart.addingTimeInterval(TimeInterval(hour * 3600))
                oxygen.append(OxygenSample(date: date, value: Double.random(in: 97...100, using: &rng)))
            }

            // Exercise time (tracking active minutes)
            let exerciseStart = dayStart.addingTimeInterval(TimeInterval(6 * 3600))
            let exerciseMinutes = Double.random(in: 60...120, using: &rng)
            exerciseTime.append(ExerciseTimeSample(
                date: exerciseStart,
                endDate: exerciseStart.addingTimeInterval(exerciseMinutes * 60),
                minutes: exerciseMinutes,
                source: source
            ))
        }

        return ExportedHealthBundle(
            exportDate: endDate,
            startDate: startDate,
            endDate: endDate,
            heartRate: heartRate,
            hrv: hrv,
            activity: activity,
            sleep: sleep,
            workouts: workouts,
            restingHeartRate: restingHR,
            respiratoryRate: respiratory,
            bloodOxygen: oxygen,
            skinTemperature: nil,
            wheelchairActivity: nil,
            exerciseTime: exerciseTime,
            bodyTemperature: nil,
            menstrualFlow: nil,
            mindfulMinutes: nil,
            stateOfMind: nil
        )
    }

    func saveFixture(_ bundle: ExportedHealthBundle, filename: String, to directory: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(bundle)
        let url = URL(fileURLWithPath: directory).appendingPathComponent(filename)
        try data.write(to: url)
        print("✓ Generated \(filename)")
    }
}

// MARK: - Main

let outputDirectory = "/Users/acb/Code/HealthKitExporter/Sources/HealthKitTestHelpers/Resources/Fixtures"

// Create output directory if it doesn't exist
let fileManager = FileManager.default
if !fileManager.fileExists(atPath: outputDirectory) {
    try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)
}

print("Generating health data fixtures...")
print("Output directory: \(outputDirectory)\n")

do {
    // Generate fixtures with different seeds for variety
    let highStressGen = FixtureGenerator(seed: 100)
    let highStressBundle = highStressGen.generateHighStressWeek()
    try highStressGen.saveFixture(highStressBundle, filename: "high-stress-week.json", to: outputDirectory)

    let lowStressGen = FixtureGenerator(seed: 200)
    let lowStressBundle = lowStressGen.generateLowStressWeek()
    try lowStressGen.saveFixture(lowStressBundle, filename: "low-stress-week.json", to: outputDirectory)

    let cycleGen = FixtureGenerator(seed: 300)
    let cycleBundle = cycleGen.generateCycleTracking()
    try cycleGen.saveFixture(cycleBundle, filename: "cycle-tracking.json", to: outputDirectory)

    let edgeCaseGen = FixtureGenerator(seed: 400)
    let edgeCaseBundle = edgeCaseGen.generateEdgeCases()
    try edgeCaseGen.saveFixture(edgeCaseBundle, filename: "edge-cases.json", to: outputDirectory)

    let activeGen = FixtureGenerator(seed: 500)
    let activeBundle = activeGen.generateActiveLifestyle()
    try activeGen.saveFixture(activeBundle, filename: "active-lifestyle.json", to: outputDirectory)

    print("\n✓ Successfully generated all 5 fixture files!")
    print("\nFixtures created:")
    print("  - high-stress-week.json - High stress scenario (HR 80-100, HRV 20-40, poor sleep)")
    print("  - low-stress-week.json - Low stress scenario (HR 55-70, HRV 45-80, good sleep)")
    print("  - cycle-tracking.json - 28-day menstrual cycle with flow tracking")
    print("  - edge-cases.json - Extreme values for testing edge cases")
    print("  - active-lifestyle.json - Athletic lifestyle with multiple daily workouts")

} catch {
    print("Error generating fixtures: \(error)")
    exit(1)
}
