//
//  HealthKitFixtures.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation
import HealthKitTestData

/// Pre-built health data fixtures for testing
///
/// ⚠️ **TEST-ONLY** - Do not import HealthKitTestHelpers in production code.
/// This module contains JSON fixture data that should only be used in test targets.
/// Including it in production will unnecessarily increase your app bundle size.
///
/// These fixtures contain realistic health data patterns loaded from JSON resources.
/// Use them in your tests to quickly populate HealthKit with known data sets.
///
/// ## Usage
/// ```swift
/// // In your test target only:
/// import HealthKitTestHelpers
///
/// let bundle = HealthKitFixtures.normalWeek
/// try await writer.importData(bundle)
/// ```
@available(iOS 18.0, *)
public enum HealthKitFixtures {
    /// A week of typical, healthy health data
    ///
    /// Contains:
    /// - Heart rate: 60-80 BPM
    /// - HRV: 30-70 ms
    /// - 7 days of data
    public static var normalWeek: ExportedHealthBundle {
        loadFixture(named: "normal-week")
    }

    /// A week of high stress health data
    ///
    /// Contains:
    /// - Heart rate: 80-100 BPM (elevated)
    /// - HRV: 20-40 ms (low, indicating stress)
    /// - Poor sleep quality (5-6 hours, frequent wake periods)
    /// - Lower activity levels
    /// - 7 days of data
    public static var highStressWeek: ExportedHealthBundle {
        loadFixture(named: "high-stress-week")
    }

    /// A week of low stress, optimal health data
    ///
    /// Contains:
    /// - Heart rate: 55-70 BPM (healthy)
    /// - HRV: 45-80 ms (high, indicating good health)
    /// - Good sleep quality (7-8 hours with proper stages)
    /// - Regular workout schedule
    /// - 7 days of data
    public static var lowStressWeek: ExportedHealthBundle {
        loadFixture(named: "low-stress-week")
    }

    /// A 28-day menstrual cycle with flow tracking
    ///
    /// Contains:
    /// - Complete 28-day cycle with menstrual flow data
    /// - Heart rate and HRV variations across cycle phases
    /// - Body temperature changes (higher in luteal phase)
    /// - Reduced activity during menstruation
    /// - 28 days of data
    public static var cycleTracking: ExportedHealthBundle {
        loadFixture(named: "cycle-tracking")
    }

    /// Extreme health values for testing edge cases
    ///
    /// Contains:
    /// - Heart rate: 40-180 BPM (extreme variations)
    /// - HRV: 10-150 ms (extreme variations)
    /// - Zero activity periods and extreme activity bursts
    /// - Very short sleep (insomnia scenario)
    /// - Marathon workout (4 hours, 42km)
    /// - Extreme body temperatures (fever and hypothermia risk)
    /// - 7 days of data
    public static var edgeCases: ExportedHealthBundle {
        loadFixture(named: "edge-cases")
    }

    /// Athletic lifestyle with high activity levels
    ///
    /// Contains:
    /// - Heart rate: 50-70 BPM at rest, 130-165 during workouts
    /// - HRV: 60-95 ms (athletic range)
    /// - Multiple daily workouts (morning and evening)
    /// - High step counts (15,000-25,000 daily)
    /// - Good sleep for recovery (8+ hours)
    /// - 7 days of data
    public static var activeLifestyle: ExportedHealthBundle {
        loadFixture(named: "active-lifestyle")
    }

    /// Load a fixture by name from the bundle resources
    ///
    /// - Parameter name: The fixture name (without .json extension)
    /// - Returns: The loaded health data bundle
    private static func loadFixture(named name: String) -> ExportedHealthBundle {
        // Runtime guard: fail in release builds to prevent shipping test fixtures
        #if !DEBUG
        assertionFailure("""
            ⚠️ CRITICAL: HealthKitTestHelpers used in RELEASE build!

            This is a test-only library and should NEVER be imported in production code.
            You are bundling unnecessary test fixture data (~2.5MB) in your app.

            Fix: Remove HealthKitTestHelpers from your main app target dependencies.
            Only add it to testTarget() declarations in Package.swift.
            """)
        #endif

        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            fatalError("Missing fixture: \(name).json - ensure it's included in Package resources")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ExportedHealthBundle.self, from: data)
        } catch {
            fatalError("Failed to load fixture \(name): \(error)")
        }
    }
}
