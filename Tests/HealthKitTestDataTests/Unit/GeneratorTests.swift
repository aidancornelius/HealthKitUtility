//
//  GeneratorTests.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import XCTest
@testable import HealthKitTestData

@available(iOS 16.0, *)
final class GeneratorTests: XCTestCase {
    func testGeneratesConsistentDataWithSeed() {
        // Generate two bundles with the same seed
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 86400)

        let bundle1 = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: startDate,
            endDate: endDate,
            seed: 42
        )

        let bundle2 = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: startDate,
            endDate: endDate,
            seed: 42
        )

        // Should generate identical data
        XCTAssertEqual(bundle1.heartRate.count, bundle2.heartRate.count)
        XCTAssertEqual(bundle1.heartRate.first?.value, bundle2.heartRate.first?.value)
        XCTAssertEqual(bundle1.hrv.count, bundle2.hrv.count)
        XCTAssertEqual(bundle1.hrv.first?.value, bundle2.hrv.first?.value)
    }

    func testGeneratesDifferentDataWithDifferentSeeds() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(7 * 86400)

        let bundle1 = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: startDate,
            endDate: endDate,
            seed: 42
        )

        let bundle2 = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: startDate,
            endDate: endDate,
            seed: 99
        )

        // Should generate different values (extremely unlikely to match)
        XCTAssertNotEqual(bundle1.heartRate.first?.value, bundle2.heartRate.first?.value)
    }

    func testGeneratesDataWithinPresetRanges() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400) // 1 day

        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: startDate,
            endDate: endDate,
            seed: 42
        )

        // Check heart rate is within normal range
        for sample in bundle.heartRate {
            XCTAssertGreaterThanOrEqual(sample.value, 60)
            XCTAssertLessThanOrEqual(sample.value, 85)
        }

        // Check HRV is within normal range
        for sample in bundle.hrv {
            XCTAssertGreaterThanOrEqual(sample.value, 30)
            XCTAssertLessThanOrEqual(sample.value, 70)
        }
    }

    func testSampleCountIsReasonable() {
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(86400) // 1 day

        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: startDate,
            endDate: endDate,
            seed: 42
        )

        // Should generate samples at reasonable intervals
        // Heart rate every 5 minutes = 288 per day
        XCTAssertGreaterThan(bundle.heartRate.count, 200)
        XCTAssertLessThan(bundle.heartRate.count, 400)

        // HRV every hour = 24 per day
        XCTAssertGreaterThan(bundle.hrv.count, 20)
        XCTAssertLessThan(bundle.hrv.count, 30)
    }
}
