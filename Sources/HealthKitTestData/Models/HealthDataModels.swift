//
//  HealthDataModels.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

// MARK: - Exported data bundle

/// A complete bundle of exported health data from HealthKit
///
/// This structure contains all supported health metrics formatted for serialisation to JSON.
/// Use this to package health data for import into the iOS Simulator.
@available(iOS 18.0, *)
public struct ExportedHealthBundle: Codable, Sendable {
    public let exportDate: Date
    public let startDate: Date
    public let endDate: Date
    public let heartRate: [HeartRateSample]
    public let hrv: [HRVSample]
    public let activity: [ActivitySample]
    public let sleep: [SleepSample]
    public let workouts: [WorkoutSample]
    public let restingHeartRate: [RestingHeartRateSample]
    public let respiratoryRate: [RespiratorySample]?
    public let bloodOxygen: [OxygenSample]?
    public let skinTemperature: [TemperatureSample]?
    public let wheelchairActivity: [WheelchairActivitySample]?
    public let exerciseTime: [ExerciseTimeSample]?
    public let bodyTemperature: [BodyTemperatureSample]?
    public let menstrualFlow: [MenstrualFlowSample]?
    public let mindfulMinutes: [MindfulMinutesSample]?
    public let stateOfMind: [StateOfMindSample]?

    public init(
        exportDate: Date,
        startDate: Date,
        endDate: Date,
        heartRate: [HeartRateSample],
        hrv: [HRVSample],
        activity: [ActivitySample],
        sleep: [SleepSample],
        workouts: [WorkoutSample],
        restingHeartRate: [RestingHeartRateSample],
        respiratoryRate: [RespiratorySample]? = nil,
        bloodOxygen: [OxygenSample]? = nil,
        skinTemperature: [TemperatureSample]? = nil,
        wheelchairActivity: [WheelchairActivitySample]? = nil,
        exerciseTime: [ExerciseTimeSample]? = nil,
        bodyTemperature: [BodyTemperatureSample]? = nil,
        menstrualFlow: [MenstrualFlowSample]? = nil,
        mindfulMinutes: [MindfulMinutesSample]? = nil,
        stateOfMind: [StateOfMindSample]? = nil
    ) {
        self.exportDate = exportDate
        self.startDate = startDate
        self.endDate = endDate
        self.heartRate = heartRate
        self.hrv = hrv
        self.activity = activity
        self.sleep = sleep
        self.workouts = workouts
        self.restingHeartRate = restingHeartRate
        self.respiratoryRate = respiratoryRate
        self.bloodOxygen = bloodOxygen
        self.skinTemperature = skinTemperature
        self.wheelchairActivity = wheelchairActivity
        self.exerciseTime = exerciseTime
        self.bodyTemperature = bodyTemperature
        self.menstrualFlow = menstrualFlow
        self.mindfulMinutes = mindfulMinutes
        self.stateOfMind = stateOfMind
    }

    /// Total number of samples in this bundle
    public var sampleCount: Int {
        var count = 0
        count += heartRate.count
        count += hrv.count
        count += activity.count
        count += sleep.count
        count += workouts.count
        count += restingHeartRate.count
        count += respiratoryRate?.count ?? 0
        count += bloodOxygen?.count ?? 0
        count += skinTemperature?.count ?? 0
        count += wheelchairActivity?.count ?? 0
        count += exerciseTime?.count ?? 0
        count += bodyTemperature?.count ?? 0
        count += menstrualFlow?.count ?? 0
        count += mindfulMinutes?.count ?? 0
        count += stateOfMind?.count ?? 0
        return count
    }
}

// MARK: - Sample types

/// A heart rate measurement in beats per minute (BPM)
@available(iOS 18.0, *)
public struct HeartRateSample: Codable, Sendable {
    public let date: Date
    /// Heart rate in beats per minute (BPM)
    public let value: Double
    public let source: String

    public init(date: Date, value: Double, source: String) {
        self.date = date
        self.value = value
        self.source = source
    }
}

/// A resting heart rate measurement in beats per minute (BPM)
///
/// Resting heart rate is typically calculated by the device based on heart rate measurements
/// taken during periods of inactivity.
@available(iOS 18.0, *)
public struct RestingHeartRateSample: Codable, Sendable {
    public let date: Date
    /// Resting heart rate in beats per minute (BPM)
    public let value: Double
    public let source: String

    public init(date: Date, value: Double, source: String) {
        self.date = date
        self.value = value
        self.source = source
    }
}

/// A heart rate variability (HRV) measurement using SDNN
///
/// HRV is measured as the standard deviation of NN intervals (SDNN) in milliseconds.
/// Higher values generally indicate better cardiovascular fitness and lower stress.
@available(iOS 18.0, *)
public struct HRVSample: Codable, Sendable {
    public let date: Date
    /// HRV value in milliseconds (SDNN)
    public let value: Double
    public let source: String

    public init(date: Date, value: Double, source: String) {
        self.date = date
        self.value = value
        self.source = source
    }
}

@available(iOS 18.0, *)
public struct ActivitySample: Codable, Sendable {
    public let date: Date
    public let endDate: Date
    public let stepCount: Double
    public let distance: Double? // metres
    public let activeCalories: Double?
    public let source: String

    public init(date: Date, endDate: Date, stepCount: Double, distance: Double?, activeCalories: Double?, source: String) {
        self.date = date
        self.endDate = endDate
        self.stepCount = stepCount
        self.distance = distance
        self.activeCalories = activeCalories
        self.source = source
    }
}

@available(iOS 18.0, *)
public struct WheelchairActivitySample: Codable, Sendable {
    public let date: Date
    public let endDate: Date
    public let pushCount: Double
    public let distance: Double? // metres
    public let source: String

    public init(date: Date, endDate: Date, pushCount: Double, distance: Double?, source: String) {
        self.date = date
        self.endDate = endDate
        self.pushCount = pushCount
        self.distance = distance
        self.source = source
    }
}

@available(iOS 18.0, *)
public struct ExerciseTimeSample: Codable, Sendable {
    public let date: Date
    public let endDate: Date
    public let minutes: Double
    public let source: String

    public init(date: Date, endDate: Date, minutes: Double, source: String) {
        self.date = date
        self.endDate = endDate
        self.minutes = minutes
        self.source = source
    }
}

@available(iOS 18.0, *)
public struct BodyTemperatureSample: Codable, Sendable {
    public let date: Date
    public let value: Double // Celsius
    public let source: String

    public init(date: Date, value: Double, source: String) {
        self.date = date
        self.value = value
        self.source = source
    }
}

@available(iOS 18.0, *)
public struct MenstrualFlowSample: Codable, Sendable {
    public let date: Date
    public let endDate: Date
    public let flowLevel: MenstrualFlowLevel
    public let isCycleStart: Bool
    public let source: String

    public init(date: Date, endDate: Date, flowLevel: MenstrualFlowLevel, isCycleStart: Bool, source: String) {
        self.date = date
        self.endDate = endDate
        self.flowLevel = flowLevel
        self.isCycleStart = isCycleStart
        self.source = source
    }
}

@available(iOS 18.0, *)
public enum MenstrualFlowLevel: String, CaseIterable, Codable, Sendable {
    case unspecified = "unspecified"
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"
    case none = "none"
}

@available(iOS 18.0, *)
public struct SleepSample: Codable, Sendable {
    public let startDate: Date
    public let endDate: Date
    public let stage: SleepStage
    public let source: String

    public init(startDate: Date, endDate: Date, stage: SleepStage, source: String) {
        self.startDate = startDate
        self.endDate = endDate
        self.stage = stage
        self.source = source
    }
}

/// Sleep stage categories recognised by HealthKit
@available(iOS 18.0, *)
public enum SleepStage: String, CaseIterable, Codable, Sendable {
    case awake = "awake"
    case light = "light"
    case deep = "deep"
    /// Rapid eye movement (REM) sleep
    case rem = "rem"
    case unknown = "unknown"
}

@available(iOS 18.0, *)
public struct WorkoutSample: Codable, Sendable {
    public let startDate: Date
    public let endDate: Date
    public let type: String
    public let calories: Double?
    public let distance: Double? // metres
    public let averageHeartRate: Double?
    public let source: String

    public init(startDate: Date, endDate: Date, type: String, calories: Double?, distance: Double?, averageHeartRate: Double?, source: String) {
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
        self.calories = calories
        self.distance = distance
        self.averageHeartRate = averageHeartRate
        self.source = source
    }
}

@available(iOS 18.0, *)
public struct RespiratorySample: Codable, Sendable {
    public let date: Date
    public let value: Double // breaths per minute

    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

@available(iOS 18.0, *)
public struct MindfulMinutesSample: Codable, Sendable {
    public let date: Date
    public let endDate: Date
    public let duration: Double // minutes
    public let source: String

    public init(date: Date, endDate: Date, duration: Double, source: String) {
        self.date = date
        self.endDate = endDate
        self.duration = duration
        self.source = source
    }
}

/// A logged state of mind entry (iOS 18+)
///
/// State of mind captures emotional state using valence (pleasant/unpleasant)
/// and arousal (energy level), along with descriptive labels.
@available(iOS 18.0, *)
public struct StateOfMindSample: Codable, Sendable {
    public let date: Date
    /// Emotional valence from -1 (unpleasant) to 1 (pleasant)
    public let valence: Double
    /// Energy level from -1 (low) to 1 (high)
    public let arousal: Double
    /// Descriptive labels such as "happy", "excited", "calm"
    public let labels: [String]
    public let source: String

    public init(date: Date, valence: Double, arousal: Double, labels: [String], source: String) {
        self.date = date
        self.valence = valence
        self.arousal = arousal
        self.labels = labels
        self.source = source
    }
}

@available(iOS 18.0, *)
public struct OxygenSample: Codable, Sendable {
    public let date: Date
    public let value: Double // percentage

    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

@available(iOS 18.0, *)
public struct TemperatureSample: Codable, Sendable {
    public let date: Date
    public let value: Double // Celsius

    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

// MARK: - Data type selection

/// All health data types supported by HealthKit Utility
///
/// Use this enum to select which data types to export, import, or generate.
@available(iOS 18.0, *)
public enum HealthDataType: String, CaseIterable, Sendable {
    case heartRate = "Heart rate"
    case hrv = "Heart rate variability"
    case activity = "Activity"
    case sleep = "Sleep"
    case workouts = "Workouts"
    case respiratoryRate = "Respiratory rate"
    case bloodOxygen = "Blood oxygen"
    case skinTemperature = "Skin temperature"
    case wheelchairActivity = "Wheelchair activity"
    case exerciseTime = "Exercise time"
    case bodyTemperature = "Body temperature"
    case menstrualFlow = "Menstrual flow"
    case mindfulMinutes = "Mindful minutes"
    case stateOfMind = "State of mind"

    public var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .activity: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .workouts: return "figure.run"
        case .respiratoryRate: return "lungs.fill"
        case .bloodOxygen: return "drop.fill"
        case .skinTemperature: return "thermometer"
        case .wheelchairActivity: return "figure.roll"
        case .exerciseTime: return "timer"
        case .bodyTemperature: return "thermometer.medium"
        case .menstrualFlow: return "drop.circle"
        case .mindfulMinutes: return "brain.head.profile"
        case .stateOfMind: return "face.smiling"
        }
    }

    /// Whether this data type requires enhanced device capabilities (e.g., Apple Watch Series 8+)
    public var isEnhanced: Bool {
        switch self {
        case .respiratoryRate, .bloodOxygen, .skinTemperature, .bodyTemperature, .menstrualFlow, .stateOfMind:
            return true
        default:
            return false
        }
    }

    /// Whether this data type is an accessibility feature (e.g., wheelchair activity)
    public var isAccessibilityFeature: Bool {
        switch self {
        case .wheelchairActivity:
            return true
        default:
            return false
        }
    }
}
