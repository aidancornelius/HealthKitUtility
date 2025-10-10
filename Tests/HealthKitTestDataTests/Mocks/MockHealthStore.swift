//
//  MockHealthStore.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

#if os(iOS)
import HealthKit
@testable import HealthKitTestData

/// Mock HealthKit store for testing without requiring actual HealthKit access
@available(iOS 16.0, *)
final class MockHealthStore: HealthStoreWritable, @unchecked Sendable {
    var savedSamples: [HKSample] = []
    var authorizationRequested = false
    var shouldThrowOnSave = false
    var shouldThrowOnAuthorization = false

    func save(_ samples: [HKSample]) async throws {
        if shouldThrowOnSave {
            throw HealthKitError.operationFailed("Mock error")
        }
        savedSamples.append(contentsOf: samples)
    }

    func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws {
        if shouldThrowOnAuthorization {
            throw HealthKitError.authorizationDenied
        }
        authorizationRequested = true
    }

    func reset() {
        savedSamples.removeAll()
        authorizationRequested = false
        shouldThrowOnSave = false
        shouldThrowOnAuthorization = false
    }
}
#endif
