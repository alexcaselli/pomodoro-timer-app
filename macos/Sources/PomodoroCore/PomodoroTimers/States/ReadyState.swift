import Foundation

struct ReadyState: TimerState {
    let kind: TimerStateKind = .ready

    func startPauseResume(_ timer: PomodoroTimer) {
        timer.start()
        timer.change(to: RunningState())
    }

    func stop(_ timer: PomodoroTimer) {}
    func completed(_ timer: PomodoroTimer) {}
    func activityPause(_ timer: PomodoroTimer) -> Bool { false }
    func activityResume(_ timer: PomodoroTimer) -> Bool { false }
}
