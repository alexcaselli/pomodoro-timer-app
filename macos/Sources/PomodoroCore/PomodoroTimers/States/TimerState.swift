import Foundation

enum TimerStateKind: Sendable {
    case ready, running, paused
}

/// The State pattern from `PomodoroTimers/States/`, transcribed.
///
/// Divergence from the C#: the Windows `State` stores `protected PomodoroTimer _timer` while
/// the timer stores `_state`, a reference cycle that ARC would leak. These are stateless
/// structs that take the timer as a parameter instead — same five operations, one type per
/// state, no cycle, no allocation per transition.
///
/// The `Bool` returns are load-bearing: they tell the activity manager whether *it* caused the
/// pause, so an automatic resume can never clobber a pause the user made by hand.
@MainActor
protocol TimerState: Sendable {
    var kind: TimerStateKind { get }
    func startPauseResume(_ timer: PomodoroTimer)
    func stop(_ timer: PomodoroTimer)
    func completed(_ timer: PomodoroTimer)
    func activityPause(_ timer: PomodoroTimer) -> Bool
    func activityResume(_ timer: PomodoroTimer) -> Bool
}
