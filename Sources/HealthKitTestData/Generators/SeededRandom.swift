//
//  SeededRandom.swift
//  HealthKitUtility
//
//  Created by Aidan Cornelius-Bell.
//

import Foundation

/// A seeded random number generator for reproducible random sequences
///
/// Implements Swift's `RandomNumberGenerator` protocol using a simple
/// linear congruential generator (LCG) algorithm.
///
/// ## Usage
/// ```swift
/// var rng = SeededRandomGenerator(seed: 42)
/// let value = Double.random(in: 0...100, using: &rng)
/// ```
@available(iOS 18.0, *)
public struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: Int) {
        self.state = UInt64(seed)
        if state == 0 { state = 1 }
    }

    public mutating func next() -> UInt64 {
        state = state &* 2862933555777941757 &+ 3037000493
        return state
    }
}
