//
//  MockHealthStore.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

#if os(iOS)
import HealthKit
import HealthKitTestData

/// Mock HealthKit store for testing without requiring actual HealthKit access
@available(iOS 18.0, *)
public final class MockHealthStore: HealthStoreWritable, @unchecked Sendable {
    public var savedSamples: [HKSample] = []
    public var authorizationRequested = false
    public var shouldThrowOnSave = false
    public var shouldThrowOnAuthorization = false

    public init() {}

    public func save(_ samples: [HKSample]) async throws {
        if shouldThrowOnSave {
            throw HealthKitError.operationFailed("Mock error")
        }
        savedSamples.append(contentsOf: samples)
    }

    public func requestAuthorization(toShare: Set<HKSampleType>, read: Set<HKObjectType>) async throws {
        if shouldThrowOnAuthorization {
            throw HealthKitError.authorizationDenied
        }
        authorizationRequested = true
    }

    public func reset() {
        savedSamples.removeAll()
        authorizationRequested = false
        shouldThrowOnSave = false
        shouldThrowOnAuthorization = false
    }
}
#endif
