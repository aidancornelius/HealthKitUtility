//
//  HealthKitWriterTests.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import XCTest
@testable import HealthKitTestData

#if os(iOS)

@available(iOS 16.0, *)
final class HealthKitWriterTests: XCTestCase {
    func testImportDataWithMockStore() async throws {
        // Create mock store and writer
        let mockStore = MockHealthStore()
        let writer = HealthKitWriter(healthStore: mockStore)

        // Generate test data
        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date(),
            seed: 42
        )

        // Import data
        try await writer.importData(bundle)

        // Verify samples were saved
        XCTAssertFalse(mockStore.savedSamples.isEmpty)
        XCTAssertGreaterThan(mockStore.savedSamples.count, 200) // Should have many samples
    }

    func testImportDataThrowsWhenStoreThrows() async throws {
        let mockStore = MockHealthStore()
        mockStore.shouldThrowOnSave = true
        let writer = HealthKitWriter(healthStore: mockStore)

        let bundle = SyntheticDataGenerator.generateHealthData(
            preset: .normal,
            manipulation: .smoothReplace,
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            seed: 42
        )

        // Should throw when mock store is configured to throw
        do {
            try await writer.importData(bundle)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected
        }
    }

    func testRequestAuthorization() async throws {
        #if targetEnvironment(simulator)
        let mockStore = MockHealthStore()
        let writer = HealthKitWriter(healthStore: mockStore)

        // Request authorization
        try await writer.requestAuthorization()

        // Verify authorization was requested
        XCTAssertTrue(mockStore.authorizationRequested)
        #else
        throw XCTSkip("Authorization tests only run in iOS Simulator environment")
        #endif
    }
}

#endif
