//
//  LiveStreamActivityAttributes.swift
//  HealthKitExporter
//
//  Live Activity support for streaming health data
//

import Foundation
import ActivityKit

/// Live Activity attributes for displaying live health data generation status.
///
/// Used by the Live Activity widget to show real-time streaming progress
/// on the Dynamic Island and lock screen.
struct LiveStreamActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isStreaming: Bool
        var scenario: String
        var totalSamples: Int
        var lastHeartRate: Double?
        var lastHRV: Double?
        var streamingStatus: String
        var detailedStatus: String
        var backgroundProcessingActive: Bool
        var lastUpdateTime: Date
    }
    
    var startTime: Date
    var interval: TimeInterval
}