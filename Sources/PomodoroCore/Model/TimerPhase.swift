import Foundation

/// Replaces the `WorkTimer` / `BreakTimer` subclasses of the Windows app.
///
/// Those two classes overrode exactly one method, to stamp a `TimerType` string onto the
/// completion event, and both left `StartActivityTracker()` throwing `NotImplementedException`.
/// A phase enum carries the same information with exhaustive switching and no dead members.
enum TimerPhase: String, CaseIterable, Sendable, Identifiable {
    case work
    case rest   // `break` is a Swift keyword; the user-facing string stays "Break"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work: "Work"
        case .rest: "Break"
        }
    }

    /// Closest SF Symbol to the WinUI glyphs (Segoe Fluent E770 for work, Emoji2 for break).
    var symbolName: String {
        switch self {
        case .work: "hammer.fill"
        case .rest: "cup.and.saucer.fill"
        }
    }

    var other: TimerPhase {
        switch self {
        case .work: .rest
        case .rest: .work
        }
    }
}
