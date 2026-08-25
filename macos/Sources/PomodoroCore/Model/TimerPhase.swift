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

    /// Outlined SF Symbol, matching the style of the toolbar and settings icons.
    ///
    /// `apple.logo` exists but is the Apple corporate mark — always filled, and wrong as a
    /// generic "work" glyph — and SF Symbols has no apple-as-fruit, so work uses a laptop.
    var symbolName: String {
        switch self {
        case .work: "laptopcomputer"
        case .rest: "cup.and.saucer"
        }
    }

    var other: TimerPhase {
        switch self {
        case .work: .rest
        case .rest: .work
        }
    }
}
