import Foundation

extension Duration {
    /// Full-precision seconds. `components.seconds` alone truncates the fractional part, which
    /// would silently shave up to a second off `remaining` on every pause/resume round-trip.
    var seconds: TimeInterval {
        let c = components
        return TimeInterval(c.seconds) + TimeInterval(c.attoseconds) / 1e18
    }
}
