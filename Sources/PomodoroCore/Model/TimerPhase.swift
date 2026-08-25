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

    /// Shown in the segmented picker.
    ///
    /// An emoji rather than an SF Symbol because a macOS segmented `Picker` renders `Label`
    /// as title-only — the icon simply never appears. Emoji are part of the string, so they
    /// always draw. This mirrors the WinUI selector, which paired each tab with a glyph
    /// (Segoe Fluent E770 for work, the Emoji2 smiley for break).
    var emoji: String {
        switch self {
        case .work: "🍅"
        case .rest: "☕️"
        }
    }

    /// Used where a template image is the right idiom: the menu bar item and the break overlay.
    var symbolName: String {
        switch self {
        case .work: "hammer.fill"
        case .rest: "cup.and.saucer.fill"
        }
    }

    /// Emoji + title, for the segmented picker.
    var pickerLabel: String { "\(emoji)  \(title)" }

    var other: TimerPhase {
        switch self {
        case .work: .rest
        case .rest: .work
        }
    }
}
