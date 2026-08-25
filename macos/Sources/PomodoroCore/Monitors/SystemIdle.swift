import CoreGraphics
import Foundation

/// macOS replacement for Win32 `GetLastInputInfo`.
enum SystemIdle {
    /// Seconds since the last hardware HID input event, system-wide.
    ///
    /// Two details that are easy to get wrong:
    ///
    /// 1. `kCGAnyInputEventType` is a C cast macro — `((CGEventType)(~0))` — so the clang
    ///    importer skips it. There is no `CGEventType.anyInputEventType` in Swift. `CGEventType`
    ///    is an *open* (non-frozen) CF_ENUM, so per SE-0192 its `init?(rawValue:)` bit-casts and
    ///    never returns nil; the force-unwrap cannot trap.
    ///
    /// 2. `.hidSystemState`, never `.combinedSessionState`. The latter also counts *synthetic*
    ///    events posted by other processes — mouse jigglers, Zoom, remote desktop — which would
    ///    make an idle detector believe the user is at the keyboard when nobody is there. That
    ///    is precisely backwards for this app.
    ///
    /// Requires no TCC permission: this reads an aggregate timestamp, not event content.
    /// (`CGEvent.tapCreate` would need Input Monitoring; this does not.)
    static func duration() -> TimeInterval {
        let anyInput = CGEventType(rawValue: ~0)!
        return CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInput)
    }
}
