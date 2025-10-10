//
//  LiveDataLoop.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

#if os(iOS)

/// Configuration for continuous data generation
@available(iOS 18.0, *)
public struct LiveGenerationConfig: Sendable {
    /// Interval between sample batches (seconds)
    public var samplingInterval: TimeInterval

    /// Number of samples to generate per batch
    public var samplesPerBatch: Int

    /// Generation preset to use
    public var preset: GenerationPreset

    /// Random seed for reproducibility (nil for random)
    public var seed: Int?

    public init(
        samplingInterval: TimeInterval = 300,  // 5 minutes
        samplesPerBatch: Int = 1,
        preset: GenerationPreset = .normal,
        seed: Int? = nil
    ) {
        self.samplingInterval = samplingInterval
        self.samplesPerBatch = samplesPerBatch
        self.preset = preset
        self.seed = seed
    }
}

/// Continuously generates and imports health data into the simulator
///
/// This class provides a simple loop for generating HealthKit data at regular intervals.
/// Useful for testing apps that respond to ongoing health data changes.
///
/// ## Usage
/// ```swift
/// let config = LiveGenerationConfig(preset: .normal, samplingInterval: 60)
/// let loop = LiveDataLoop(config: config, writer: healthKitWriter)
///
/// try await loop.start()
/// // ... data generates continuously ...
/// loop.stop()
/// ```
///
/// **Note:** For production apps with background generation requirements, implement
/// your own background task handling using BGTaskScheduler and AVAudioSession.
/// See the host app's LiveStreamManager for an example.
@available(iOS 18.0, *)
public actor LiveDataLoop {
    public var config: LiveGenerationConfig
    private nonisolated(unsafe) let writer: HealthKitWriter
    private var task: Task<Void, Never>?
    private var isRunning = false

    /// Initialise a live data generation loop
    ///
    /// - Parameters:
    ///   - config: Configuration for generation intervals and presets
    ///   - writer: HealthKit writer for importing generated data
    public init(config: LiveGenerationConfig, writer: HealthKitWriter) {
        self.config = config
        self.writer = writer
    }

    /// Start generating data continuously
    ///
    /// Generates health data at the configured interval and writes it to HealthKit.
    /// This method returns immediately; generation happens in the background.
    ///
    /// - Throws: HealthKit errors if data cannot be written
    public func start() async throws {
        guard !isRunning else { return }
        isRunning = true

        task = Task {
            while !Task.isCancelled && isRunning {
                do {
                    // Generate a small bundle for the current interval
                    let now = Date()
                    let intervalStart = now.addingTimeInterval(-config.samplingInterval)

                    let bundle = SyntheticDataGenerator.generateHealthData(
                        preset: config.preset,
                        manipulation: .smoothReplace,
                        startDate: intervalStart,
                        endDate: now,
                        seed: config.seed ?? Int.random(in: 0...10000)
                    )

                    // Import to HealthKit
                    try await writer.importData(bundle)

                    // Wait for next interval
                    try await Task.sleep(nanoseconds: UInt64(config.samplingInterval * 1_000_000_000))
                } catch {
                    // Log error but continue generating
                    print("LiveDataLoop error: \(error)")
                }
            }
        }
    }

    /// Stop generating data
    ///
    /// Call this to stop the generation loop. The loop stops after the current
    /// generation cycle completes.
    public func stop() {
        isRunning = false
        task?.cancel()
        task = nil
    }

    /// Whether the loop is currently running
    public var running: Bool {
        isRunning
    }
}
#endif
