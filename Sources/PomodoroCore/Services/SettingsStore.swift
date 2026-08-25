import Foundation

/// Port of the Windows `ApplicationData.Current.LocalSettings` composite.
///
/// The original stored one `ApplicationDataCompositeValue` under "TimersDurationMinutes" with
/// two Double members. UserDefaults has no composite type, so the two members become dotted
/// keys — the on-disk shape differs but the schema maps one-to-one.
@MainActor
@Observable
final class SettingsStore {
    static let workKey = "TimersDurationMinutes.WorkingTimerDurationMinutes"
    static let breakKey = "TimersDurationMinutes.BreakTimerDurationMinutes"
    static let launchAtLoginKey = "LaunchAtLogin"
    static let strictnessKey = "BreakStrictness"
    static let notificationsKey = "NotificationsEnabled"

    // Fallback_WorkingTimerDurationMinutes / Fallback_BreakTimerDurationMinutes
    static let fallbackWorkMinutes: Double = 25
    static let fallbackBreakMinutes: Double = 3

    // The Windows NumberBoxes had no Minimum/Maximum, so 0 and negative durations were
    // accepted and produced a timer that completed instantly, forever.
    static let workRange: ClosedRange<Double> = 1...180
    static let breakRange: ClosedRange<Double> = 1...60

    @ObservationIgnored private let defaults: UserDefaults

    // Clamping happens in explicit setters, NOT in a `didSet`. Under the `@Observable` macro a
    // stored property becomes a computed one, so a `didSet` that reassigns its own property
    // recurses into the synthesised setter until the stack overflows (SIGSEGV). The remaining
    // `didSet`s below are safe because they only write to UserDefaults.
    private(set) var workingTimerDurationMinutes: Double
    private(set) var breakTimerDurationMinutes: Double

    func setWorkDuration(_ minutes: Double) {
        workingTimerDurationMinutes = minutes.clamped(to: Self.workRange)
        defaults.set(workingTimerDurationMinutes, forKey: Self.workKey)
    }

    func setBreakDuration(_ minutes: Double) {
        breakTimerDurationMinutes = minutes.clamped(to: Self.breakRange)
        defaults.set(breakTimerDurationMinutes, forKey: Self.breakKey)
    }

    var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Self.launchAtLoginKey) }
    }

    var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Self.notificationsKey) }
    }

    var strictness: BreakStrictness {
        didSet { defaults.set(strictness.rawValue, forKey: Self.strictnessKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // `double(forKey:)` returns 0 for a missing key, not nil — reading it directly would
        // turn "never configured" into a zero-length timer.
        let work = (defaults.object(forKey: Self.workKey) as? Double) ?? Self.fallbackWorkMinutes
        let rest = (defaults.object(forKey: Self.breakKey) as? Double) ?? Self.fallbackBreakMinutes
        self.workingTimerDurationMinutes = work.clamped(to: Self.workRange)
        self.breakTimerDurationMinutes = rest.clamped(to: Self.breakRange)
        self.launchAtLogin = defaults.bool(forKey: Self.launchAtLoginKey)
        self.notificationsEnabled = (defaults.object(forKey: Self.notificationsKey) as? Bool) ?? true
        self.strictness = BreakStrictness(rawValue: defaults.string(forKey: Self.strictnessKey) ?? "")
            ?? .firm
    }

    func duration(for phase: TimerPhase) -> Double {
        switch phase {
        case .work: workingTimerDurationMinutes
        case .rest: breakTimerDurationMinutes
        }
    }

    // MARK: - Debug overrides (see scripts/debug_defaults.sh). All no-ops unless set.

    /// Interprets the "minutes" settings as SECONDS, so a full work->break->work round trip
    /// takes under a minute to exercise by hand.
    var durationUnitSeconds: Bool { defaults.bool(forKey: "debug.durationUnitSeconds") }

    var workInactivityThreshold: TimeInterval {
        let v = defaults.double(forKey: "debug.workInactivityThreshold")
        return v > 0 ? v : IdleMonitor.workInactivityThreshold
    }

    var breakActivityThreshold: TimeInterval {
        let v = defaults.double(forKey: "debug.breakActivityThreshold")
        return v > 0 ? v : IdleMonitor.breakActivityThreshold
    }

    var showDebugLabel: Bool { defaults.bool(forKey: "debug.showDebugLabel") }

    /// Minutes as the timer should actually interpret them.
    func effectiveDuration(for phase: TimerPhase) -> Double {
        let minutes = duration(for: phase)
        return durationUnitSeconds ? minutes / 60 : minutes
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
