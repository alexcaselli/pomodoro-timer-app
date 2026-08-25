import Foundation

enum TimeFormatting {
    /// Renders `mm:ss`, clamped at zero.
    ///
    /// Mirrors C# `TimeSpan.ToString(@"mm\:ss")`, which prints only the *minutes component*:
    /// 90 minutes renders as "30:00", not "90:00". Faithful to the original; the 180-minute
    /// duration clamp keeps it out of reach in practice.
    static func mmss(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        return String(format: "%02d:%02d", (total / 60) % 60, total % 60)
    }
}
