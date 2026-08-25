import Foundation

/// Stepping that stays on the step's lattice.
///
/// A plain `Stepper(value:in:step:)` adds and subtracts blindly, so clamping at a bound that is
/// not a multiple of the step permanently shifts the sequence. With `1...180` and `step: 5`,
/// walking down from 25 reaches 5, then 0 clamps to 1 — and from there every increment lands on
/// 6, 11, 16, 21, 26. The original 25 becomes unreachable.
///
/// Snapping to the neighbouring multiple instead keeps the lattice intact, while the range bound
/// stays reachable as an end stop.
enum DurationStep {
    static func increment(_ value: Double, step: Double, in range: ClosedRange<Double>) -> Double {
        let next = ((value / step).rounded(.down) + 1) * step
        return min(max(next, range.lowerBound), range.upperBound)
    }

    static func decrement(_ value: Double, step: Double, in range: ClosedRange<Double>) -> Double {
        let previous = ((value / step).rounded(.up) - 1) * step
        return min(max(previous, range.lowerBound), range.upperBound)
    }
}
