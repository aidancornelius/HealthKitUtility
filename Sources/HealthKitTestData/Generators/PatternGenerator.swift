//
//  PatternGenerator.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

/// Applies pattern transformations to health data samples
///
/// Use this to modify existing health data with various stress patterns,
/// creating realistic variations for testing different scenarios.
@available(iOS 18.0, *)
public struct PatternGenerator {
    /// Applies a pattern transformation to heart rate samples
    ///
    /// - Parameters:
    ///   - pattern: The pattern type to apply
    ///   - samples: The original heart rate samples
    ///   - seed: Random seed for reproducible generation
    /// - Returns: Transformed heart rate samples
    public static func apply(pattern: PatternType, to samples: [HeartRateSample], seed: Int = 0) -> [HeartRateSample] {
        var rng = SeededRandomGenerator(seed: seed)

        switch pattern {
        case .similar:
            return samples.map { sample in
                let variation = Double.random(in: -2...2, using: &rng)
                return HeartRateSample(
                    date: sample.date,
                    value: sample.value + variation,
                    source: sample.source
                )
            }

        case .amplified:
            return samples.map { sample in
                let factor = Double.random(in: 1.2...1.4, using: &rng)
                let baselineHR = 70.0
                let amplifiedValue = baselineHR + (sample.value - baselineHR) * factor
                return HeartRateSample(
                    date: sample.date,
                    value: min(200, amplifiedValue),
                    source: sample.source
                )
            }

        case .reduced:
            return samples.map { sample in
                let factor = Double.random(in: 0.6...0.8, using: &rng)
                let baselineHR = 70.0
                let reducedValue = baselineHR + (sample.value - baselineHR) * factor
                return HeartRateSample(
                    date: sample.date,
                    value: max(40, reducedValue),
                    source: sample.source
                )
            }

        case .inverted:
            let avgHR = samples.map(\.value).reduce(0, +) / Double(samples.count)
            return samples.map { sample in
                let invertedValue = 2 * avgHR - sample.value
                return HeartRateSample(
                    date: sample.date,
                    value: min(200, max(40, invertedValue)),
                    source: sample.source
                )
            }

        case .random:
            return samples.map { sample in
                let variation = Double.random(in: -15...15, using: &rng)
                return HeartRateSample(
                    date: sample.date,
                    value: min(200, max(40, sample.value + variation)),
                    source: sample.source
                )
            }
        }
    }

    /// Applies a pattern transformation to HRV samples
    ///
    /// - Parameters:
    ///   - pattern: The pattern type to apply
    ///   - samples: The original HRV samples
    ///   - seed: Random seed for reproducible generation
    /// - Returns: Transformed HRV samples
    public static func apply(pattern: PatternType, to samples: [HRVSample], seed: Int = 0) -> [HRVSample] {
        var rng = SeededRandomGenerator(seed: seed)

        switch pattern {
        case .similar:
            return samples.map { sample in
                let variation = Double.random(in: -2...2, using: &rng)
                return HRVSample(
                    date: sample.date,
                    value: max(0, sample.value + variation),
                    source: sample.source
                )
            }

        case .amplified:
            return samples.map { sample in
                let factor = Double.random(in: 0.6...0.8, using: &rng) // Lower HRV = more stress
                return HRVSample(
                    date: sample.date,
                    value: max(10, sample.value * factor),
                    source: sample.source
                )
            }

        case .reduced:
            return samples.map { sample in
                let factor = Double.random(in: 1.2...1.4, using: &rng) // Higher HRV = less stress
                return HRVSample(
                    date: sample.date,
                    value: min(200, sample.value * factor),
                    source: sample.source
                )
            }

        case .inverted:
            let avgHRV = samples.map(\.value).reduce(0, +) / Double(samples.count)
            return samples.map { sample in
                let invertedValue = 2 * avgHRV - sample.value
                return HRVSample(
                    date: sample.date,
                    value: min(200, max(10, invertedValue)),
                    source: sample.source
                )
            }

        case .random:
            return samples.map { sample in
                let variation = Double.random(in: -10...10, using: &rng)
                return HRVSample(
                    date: sample.date,
                    value: min(200, max(10, sample.value + variation)),
                    source: sample.source
                )
            }
        }
    }
}
