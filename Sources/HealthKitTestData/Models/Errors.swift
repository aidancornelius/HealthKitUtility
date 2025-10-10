//
//  Errors.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

/// Errors that can occur during HealthKit test data operations
@available(iOS 18.0, *)
public enum HealthKitError: LocalizedError {
    /// HealthKit is not available on this device
    case healthKitUnavailable

    /// User denied access to HealthKit data
    case authorizationDenied

    /// Import/export operation is only available in the iOS Simulator
    case simulatorOnly

    /// Operation failed with a specific reason
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .healthKitUnavailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit access was denied"
        case .simulatorOnly:
            return "This operation is only available in the iOS Simulator"
        case .operationFailed(let reason):
            return "Operation failed: \(reason)"
        }
    }
}
