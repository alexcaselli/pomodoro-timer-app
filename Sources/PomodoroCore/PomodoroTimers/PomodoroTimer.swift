import Foundation

enum ControlIcon: Sendable {
    case play, pause, stop

    var symbolName: String {
        switch self {
        case .play: "play.fill"
        case .pause: "pause.fill"
        case .stop: "stop.fill"
        }
    }
}

/// Port of `PomodoroTimers/PomodoroTimer.cs`.
///
/// The single most important property carried over: the countdown is derived from an absolute
/// deadline every tick, never decremented. A decrementing counter turns every late or coalesced
/// tick into permanent accumulated error, and across system sleep it is catastrophic — every
/// timer mechanism on macOS fires *once* on wake, not once per missed interval.
///
/// Unlike the C#, this holds no references to UI controls. It publishes state; views observe it.
@MainActor
@Observable
final class PomodoroTimer {
    let phase: TimerPhase
    private(set) var durationMinutes: Double
    private(set) var remaining: TimeInterval
    private(set) var stateKind: TimerStateKind = .ready

    @ObservationIgnored private var state: any TimerState = ReadyState()
    @ObservationIgnored private var deadline: ContinuousClock.Instant?
    @ObservationIgnored private let tick = TickDriver()
    @ObservationIgnored private var activityToken: (any NSObjectProtocol)?

    /// Replaces `event EventHandler<TimerCompletedEventArgs> TimerCompleted`. Only `AppModel`
    /// ever subscribes, so one closure beats an observer list; nil-ing it replaces the `-=`.
    @ObservationIgnored var onCompleted: (@MainActor (TimerPhase) -> Void)?

    init(phase: TimerPhase, durationMinutes: Double) {
        self.phase = phase
        self.durationMinutes = durationMinutes
        self.remaining = durationMinutes * 60
    }

    // MARK: - Display (replaces direct TextBlock / Button mutation)

    var displayText: String { TimeFormatting.mmss(remaining) }
    var isStopEnabled: Bool { stateKind != .ready }
    var primaryIcon: ControlIcon { stateKind == .running ? .pause : .play }
    var isRunning: Bool { stateKind == .running }

    // MARK: - Command surface (the Click* methods of the original)

    func clickStartPauseResume() { state.startPauseResume(self) }
    func clickStop() { state.stop(self) }
    @discardableResult func clickActivityPause() -> Bool { state.activityPause(self) }
    @discardableResult func clickActivityResume() -> Bool { state.activityResume(self) }

    // MARK: - Called by the states

    func change(to newState: any TimerState) {
        state = newState
        stateKind = newState.kind
    }

    /// `Init()` in the C#: reset to the full duration.
    func initialize() {
        remaining = durationMinutes * 60
        deadline = nil
    }

    func start() {
        deadline = ContinuousClock().now.advanced(by: .seconds(remaining))
        beginActivityAssertion()
        tick.start { [weak self] in self?.elapsed() }
    }

    func pause() {
        tick.stop()
        endActivityAssertion()
        if let deadline {
            remaining = max(0, ContinuousClock().now.duration(to: deadline).seconds)
        }
    }

    func resume() { start() }

    func stop() {
        tick.stop()
        endActivityAssertion()
        initialize()
    }

    func handleTimerCompletion() { onCompleted?(phase) }

    /// Recompute once on wake. Never replay missed ticks.
    func forceRecompute() {
        guard tick.isRunning else { return }
        elapsed()
    }

    func tearDown() {
        tick.stop()
        endActivityAssertion()
        onCompleted = nil
    }

    // MARK: - Internals

    private func elapsed() {
        guard let deadline else { return }
        let left = ContinuousClock().now.duration(to: deadline).seconds
        if left <= 0 {
            tick.stop()
            endActivityAssertion()
            remaining = 0
            state.completed(self)
        } else {
            remaining = left
        }
    }

    /// Without this, App Nap throttles our timers whenever the app is backgrounded with no
    /// visible window — the classic "my timer is wrong in the background" bug. The absolute
    /// deadline means throttling can never accumulate error, but it can still delay the
    /// completion event by minutes, which for a Pomodoro is the whole product.
    private func beginActivityAssertion() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Pomodoro \(phase.title) session running"
        )
    }

    private func endActivityAssertion() {
        if let activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }
    }

    // No `deinit` cleanup for the activity token: a nonisolated deinit cannot touch
    // MainActor state. Every path that stops the timer — pause(), stop(), completion in
    // elapsed(), tearDown() — releases the assertion, and `AppModel` always calls
    // `tearDown()` before dropping a timer, so there is no route to a leaked assertion.
}
