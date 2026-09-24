import Foundation

/// One generator for a squad draw or a match. The simulator never calls the process-global random.
struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    /// Zero-centered bell curve, standard deviation 1, support clamped to `halfWidth` goals either side of zero.
    mutating func nextGoalNoise(halfWidth: Double = 3) -> Double {
        for _ in 0..<32 {
            let u1 = nextUnitInterval()
            let u2 = nextUnitInterval()
            let magnitude = (-2 * Foundation.log(u1)).squareRoot()
            let draw = magnitude * Foundation.cos(2 * Double.pi * u2)
            if draw >= -halfWidth, draw <= halfWidth {
                return draw
            }
        }
        return 0
    }

    private mutating func nextUnitInterval() -> Double {
        let bits = next() >> 11
        let unit = (Double(bits) + 0.5) / 9_007_199_254_740_992
        return min(max(unit, .leastNonzeroMagnitude), 1 - .leastNonzeroMagnitude)
    }
}
