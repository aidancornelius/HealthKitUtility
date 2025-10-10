//
//  HealthStoreWritable.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

#if os(iOS)
import HealthKit

// MARK: - HealthKit abstraction protocol

/// Abstracts HealthKit operations for testing and authorisation control
///
/// This protocol allows host apps to control the authorisation flow and enables
/// testing with mock implementations without requiring actual HealthKit access.
///
/// Note: requestAuthorization is not included in this protocol as HKHealthStore
/// already provides native async/await support for authorization.
@available(iOS 18.0, *)
public protocol HealthStoreWritable: Sendable {
    /// Save samples to HealthKit
    /// - Parameter samples: The samples to save
    /// - Throws: HealthKit errors if the save operation fails
    func save(_ samples: [HKSample]) async throws
}

// MARK: - HKHealthStore conformance

/// Default implementation using the real HealthKit store
@available(iOS 18.0, *)
extension HKHealthStore: HealthStoreWritable {
    public func save(_ samples: [HKSample]) async throws {
        guard !samples.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.save(samples) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
#endif
