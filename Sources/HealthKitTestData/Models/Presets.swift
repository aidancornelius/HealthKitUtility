//
//  Presets.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

// MARK: - Generation presets

/// Presets for generating synthetic health data with different stress profiles
///
/// Each preset defines physiologically appropriate ranges for various health metrics.
/// Note that higher HRV indicates *lower* stress, while higher heart rate indicates *higher* stress.
@available(iOS 18.0, *)
public enum GenerationPreset: String, CaseIterable, Sendable {
    case lowerStress = "Lower stress"
    case normal = "Normal results"
    case higherStress = "Higher stress"
    case edgeCases = "Edge cases"

    public var description: String {
        switch self {
        case .lowerStress: return "Healthy, relaxed patterns"
        case .normal: return "Typical daily patterns"
        case .higherStress: return "Elevated stress indicators"
        case .edgeCases: return "Extreme values for testing"
        }
    }

    public var heartRateRange: ClosedRange<Double> {
        switch self {
        case .lowerStress: return 55...75
        case .normal: return 60...85
        case .higherStress: return 75...110
        case .edgeCases: return 40...180
        }
    }

    /// HRV range in milliseconds. Higher values indicate lower stress.
    public var hrvRange: ClosedRange<Double> {
        switch self {
        case .lowerStress: return 50...100  // Higher HRV = less stress
        case .normal: return 30...70
        case .higherStress: return 15...40  // Lower HRV = more stress
        case .edgeCases: return 5...150
        }
    }

    public var stepsRange: ClosedRange<Double> {
        switch self {
        case .lowerStress: return 8000...12000
        case .normal: return 5000...10000
        case .higherStress: return 2000...5000
        case .edgeCases: return 0...30000
        }
    }

    public var sleepHours: ClosedRange<Double> {
        switch self {
        case .lowerStress: return 7.5...9.0
        case .normal: return 6.5...8.0
        case .higherStress: return 4.0...6.5
        case .edgeCases: return 2.0...12.0
        }
    }
}

// MARK: - Pattern types

/// Pattern transformation types for modifying existing health data
///
/// These patterns modify existing health data to create variations for testing.
/// Stress-related patterns affect both heart rate and HRV in physiologically appropriate ways.
@available(iOS 18.0, *)
public enum PatternType: String, CaseIterable, Sendable {
    /// Keep similar patterns with minor random variations
    case similar = "Similar pattern"
    /// Increase stress indicators (higher HR, lower HRV)
    case amplified = "Amplified (more stress)"
    /// Decrease stress indicators (lower HR, higher HRV)
    case reduced = "Reduced (less stress)"
    /// Flip high and low stress periods
    case inverted = "Inverted pattern"
    /// Add significant random variations
    case random = "Random variation"

    public var description: String {
        switch self {
        case .similar: return "Keep the same stress patterns"
        case .amplified: return "Increase stress levels by 20-40%"
        case .reduced: return "Decrease stress levels by 20-40%"
        case .inverted: return "Flip high and low stress periods"
        case .random: return "Add random variations to the data"
        }
    }
}

// MARK: - Data manipulation options

/// Data manipulation strategies for generating synthetic health data
@available(iOS 18.0, *)
public enum DataManipulation: String, CaseIterable, Sendable {
    /// Preserve existing data without changes
    case keepOriginal = "Keep original"
    /// Add synthetic data only for categories that are empty
    case generateMissing = "Generate missing data"
    /// Replace all data with smoothed synthetic versions
    case smoothReplace = "Smooth & replace"
    /// Replace step data with wheelchair push data
    case accessibilityMode = "Accessibility mode"

    public var description: String {
        switch self {
        case .keepOriginal: return "Preserve existing data patterns"
        case .generateMissing: return "Add data for empty categories"
        case .smoothReplace: return "Replace with synthetic data"
        case .accessibilityMode: return "Replace steps with wheelchair data"
        }
    }
}
