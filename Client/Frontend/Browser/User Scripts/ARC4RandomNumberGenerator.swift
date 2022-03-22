// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// A seeded random number generator taken from GameplayKit which can be found here:
/// https://github.com/apple/swift/blob/bc8f9e61d333b8f7a625f74d48ef0b554726e349/stdlib/public/TensorFlow/Random.swift
public struct ARC4RandomNumberGenerator: RandomNumberGenerator {
    private var state: [UInt8] = Array(0...255)
    private var iPos: UInt8 = 0
    private var jPos: UInt8 = 0

    public init<T: BinaryInteger>(seed: T) {
        var newSeed: [UInt8] = []

        for i in 0..<(seed.bitWidth / UInt8.bitWidth) {
            newSeed.append(UInt8(truncatingIfNeeded: seed >> (UInt8.bitWidth * i)))
        }

        self.init(seed: newSeed)
    }

    /// Initialize ARC4RandomNumberGenerator using an array of UInt8. The array
    /// must have length between 1 and 256 inclusive.
    public init(seed: [UInt8]) {
        precondition(seed.count > 0, "Length of seed must be positive")
        precondition(seed.count <= 256, "Length of seed must be at most 256")
        var j: UInt8 = 0
        for i: UInt8 in 0...255 {
            j &+= S(i) &+ seed[Int(i) % seed.count]
            swapAt(i, j)
        }
    }

    /// Produce the next random UInt64 from the stream, and advance the internal state.
    public mutating func next() -> UInt64 {
        var result: UInt64 = 0
        for _ in 0..<UInt64.bitWidth / UInt8.bitWidth {
            result <<= UInt8.bitWidth
            result += UInt64(nextByte())
        }

        print(result)
        return result
    }

    /// Helper to access the state.
    private func S(_ index: UInt8) -> UInt8 {
        return state[Int(index)]
    }

    /// Helper to swap elements of the state.
    private mutating func swapAt(_ i: UInt8, _ j: UInt8) {
        state.swapAt(Int(i), Int(j))
    }

    /// Generates the next byte in the keystream.
    private mutating func nextByte() -> UInt8 {
        iPos &+= 1
        jPos &+= S(iPos)
        swapAt(iPos, jPos)
        return S(S(iPos) &+ S(jPos))
    }
}
