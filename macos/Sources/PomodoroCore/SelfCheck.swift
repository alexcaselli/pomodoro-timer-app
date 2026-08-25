import Foundation

/// Headless assertions over the ported core, runnable as `PomodoroTimer --self-check`.
///
/// XCTest and swift-testing ship with Xcode, not with the Command Line Tools, so `swift test`
/// is unavailable in this toolchain. This covers the same ground for the logic that actually
/// carries risk: the state-transition table, the deadline arithmetic, the activity-manager
/// polarity, and the settings clamping.
@MainActor
enum SelfCheck {
    nonisolated(unsafe) private static var failures: [String] = []

    static func run() async -> Int32 {
        checkDurationStepping()
        checkTimeFormatting()
        checkStateTable()
        checkSettingsClamping()
        await checkTimerLifecycle()
        await checkCompletion()
        await checkActivityPolarity()

        if failures.isEmpty {
            print("self-check: all checks passed")
            return 0
        }
        for failure in failures { print("FAIL: \(failure)") }
        print("self-check: \(failures.count) failure(s)")
        return 1
    }

    private static func expect(_ condition: Bool, _ message: @autoclosure () -> String) {
        if !condition { failures.append(message()) }
    }

    private static func expectEqual<T: Equatable>(_ a: T, _ b: T, _ label: String) {
        if a != b { failures.append("\(label): expected \(b), got \(a)") }
    }

    // MARK: - Duration stepping

    private static func checkDurationStepping() {
        let range: ClosedRange<Double> = 1...180
        let step: Double = 5

        func up(_ v: Double) -> Double { DurationStep.increment(v, step: step, in: range) }
        func down(_ v: Double) -> Double { DurationStep.decrement(v, step: step, in: range) }

        expectEqual(down(25), 20, "25 steps down to 20")
        expectEqual(down(10), 5, "10 steps down to 5")
        expectEqual(down(5), 1, "5 steps down to the lower bound")
        expectEqual(down(1), 1, "lower bound holds")

        // The regression: from the clamped floor, incrementing must rejoin the lattice, not
        // walk 1 -> 6 -> 11 -> 16, which made 25 unreachable.
        expectEqual(up(1), 5, "1 steps up onto the lattice, not to 6")
        expectEqual(up(5), 10, "5 steps up to 10")
        expectEqual(up(20), 25, "20 steps up to 25")

        // A full round trip must return to where it started.
        var v: Double = 25
        for _ in 0..<10 { v = down(v) }
        for _ in 0..<10 { v = up(v) }
        expect(v >= 25, "round trip returns to at least 25, got \(v)")

        // Off-lattice values snap to the neighbouring multiples.
        expectEqual(up(23), 25, "23 steps up to 25")
        expectEqual(down(23), 20, "23 steps down to 20")

        expectEqual(up(180), 180, "upper bound holds")
        expectEqual(up(178), 180, "clamps to the upper bound")
    }

    // MARK: - Formatting

    private static func checkTimeFormatting() {
        expectEqual(TimeFormatting.mmss(0), "00:00", "mmss(0)")
        expectEqual(TimeFormatting.mmss(59), "00:59", "mmss(59)")
        expectEqual(TimeFormatting.mmss(60), "01:00", "mmss(60)")
        expectEqual(TimeFormatting.mmss(1500), "25:00", "mmss(1500)")
        expectEqual(TimeFormatting.mmss(-5), "00:00", "mmss negative clamps")
        // C# TimeSpan @"mm\:ss" prints only the minutes component: 90 min -> "30:00".
        expectEqual(TimeFormatting.mmss(90 * 60), "30:00", "mmss minutes-component-only")
    }

    // MARK: - State transition table (PomodoroTimers/States)

    private static func checkStateTable() {
        // Ready
        var t = PomodoroTimer(phase: .work, durationMinutes: 1)
        expectEqual(t.stateKind, .ready, "fresh timer is ready")
        expect(t.clickActivityPause() == false, "Ready.activityPause returns false")
        expect(t.clickActivityResume() == false, "Ready.activityResume returns false")
        t.clickStop()
        expectEqual(t.stateKind, .ready, "Ready.stop is a no-op")
        t.clickStartPauseResume()
        expectEqual(t.stateKind, .running, "Ready.startPauseResume -> running")

        // Running
        expect(t.clickActivityResume() == false, "Running.activityResume returns false")
        expect(t.clickActivityPause() == true, "Running.activityPause returns true")
        expectEqual(t.stateKind, .paused, "Running.activityPause -> paused")

        // Paused
        expect(t.clickActivityPause() == false, "Paused.activityPause returns false")
        expect(t.clickActivityResume() == true, "Paused.activityResume returns true")
        expectEqual(t.stateKind, .running, "Paused.activityResume -> running")

        t.clickStartPauseResume()
        expectEqual(t.stateKind, .paused, "Running.startPauseResume -> paused")
        t.clickStartPauseResume()
        expectEqual(t.stateKind, .running, "Paused.startPauseResume -> running")
        t.clickStop()
        expectEqual(t.stateKind, .ready, "Running.stop -> ready")

        t = PomodoroTimer(phase: .work, durationMinutes: 1)
        t.clickStartPauseResume()
        t.clickStartPauseResume()   // -> paused
        t.clickStop()
        expectEqual(t.stateKind, .ready, "Paused.stop -> ready")
    }

    // MARK: - Settings

    private static func checkSettingsClamping() {
        let suite = UserDefaults(suiteName: "selfcheck.pomodoro")!
        suite.removePersistentDomain(forName: "selfcheck.pomodoro")

        let fresh = SettingsStore(defaults: suite)
        expectEqual(fresh.workingTimerDurationMinutes, 25, "work fallback")
        expectEqual(fresh.breakTimerDurationMinutes, 3, "break fallback")

        // The WinUI NumberBoxes had no Minimum/Maximum, so 0 and negatives were accepted.
        fresh.setWorkDuration(0)
        expectEqual(fresh.workingTimerDurationMinutes, 1, "work clamps up to 1")
        fresh.setWorkDuration(9_999)
        expectEqual(fresh.workingTimerDurationMinutes, 180, "work clamps down to 180")
        fresh.setBreakDuration(-4)
        expectEqual(fresh.breakTimerDurationMinutes, 1, "break clamps up to 1")

        // A missing key must not read as 0 via double(forKey:).
        suite.removePersistentDomain(forName: "selfcheck.pomodoro")
        let reread = SettingsStore(defaults: suite)
        expectEqual(reread.workingTimerDurationMinutes, 25, "missing key -> fallback, not 0")
        suite.removePersistentDomain(forName: "selfcheck.pomodoro")
    }

    // MARK: - Timer lifecycle

    private static func checkTimerLifecycle() async {
        let t = PomodoroTimer(phase: .work, durationMinutes: 1)
        expectEqual(t.displayText, "01:00", "initial display")
        expect(t.isStopEnabled == false, "stop disabled while ready")
        expect(t.primaryIcon == .play, "play icon while ready")

        t.clickStartPauseResume()
        expect(t.isStopEnabled == true, "stop enabled while running")
        expect(t.primaryIcon == .pause, "pause icon while running")

        try? await Task.sleep(for: .milliseconds(1_200))
        let afterTick = t.remaining
        expect(afterTick < 60 && afterTick > 57, "counted down ~1s, got \(afterTick)")

        // A pause must freeze `remaining`: the deadline is recomputed on resume, never decayed.
        t.clickStartPauseResume()
        let atPause = t.remaining
        try? await Task.sleep(for: .milliseconds(900))
        expect(abs(t.remaining - atPause) < 0.05,
               "remaining frozen across pause: \(atPause) -> \(t.remaining)")

        t.clickStartPauseResume()
        try? await Task.sleep(for: .milliseconds(1_200))
        expect(t.remaining < atPause - 0.5, "resumed counting: \(t.remaining) vs \(atPause)")

        t.clickStop()
        expectEqual(t.remaining, 60, "stop resets to full duration")
        expectEqual(t.displayText, "01:00", "stop resets display")
        t.tearDown()
    }

    private static func checkCompletion() async {
        var completedWith: TimerPhase?
        let t = PomodoroTimer(phase: .work, durationMinutes: 2.0 / 60.0)   // 2 seconds
        t.onCompleted = { phase in completedWith = phase }
        t.clickStartPauseResume()

        try? await Task.sleep(for: .milliseconds(3_500))
        expectEqual(completedWith, .work, "completion fired with its phase")
        expectEqual(t.stateKind, .ready, "state is ready after completion")
        expectEqual(t.remaining, 0, "remaining is zero at completion")
        expectEqual(t.displayText, "00:00", "displays 00:00 at completion")
        t.tearDown()
    }

    // MARK: - Activity managers

    private static func checkActivityPolarity() async {
        // WORK: inactivity pauses, activity resumes.
        let work = PomodoroTimer(phase: .work, durationMinutes: 5)
        let workManager = UserActivityWorkTimerManager(timer: work, threshold: 9_999)
        work.clickStartPauseResume()

        workManager.onUserInactive()
        expectEqual(work.stateKind, .paused, "work: inactivity pauses")
        expect(workManager.isStopwatchVisible, "work: idle stopwatch shown on auto-pause")
        workManager.onUserInactive()    // level-triggered: repeats must be idempotent
        expectEqual(work.stateKind, .paused, "work: repeated inactivity stays paused")
        workManager.onUserActive()
        expectEqual(work.stateKind, .running, "work: activity resumes")
        expect(workManager.isStopwatchVisible, "work: stopwatch stays visible after resume")

        // A pause the user made by hand must never be auto-resumed.
        work.clickStartPauseResume()
        expectEqual(work.stateKind, .paused, "work: manual pause")
        workManager.onUserActive()
        expectEqual(work.stateKind, .paused, "work: manual pause survives onUserActive")
        workManager.tearDown()
        work.tearDown()

        // BREAK: mirrored — activity pauses, inactivity resumes.
        let rest = PomodoroTimer(phase: .rest, durationMinutes: 5)
        let restManager = UserActivityBreakTimerManager(timer: rest, threshold: 0)
        rest.clickStartPauseResume()

        restManager.onUserActive()
        expectEqual(rest.stateKind, .paused, "break: activity pauses")
        restManager.onUserInactive()
        expectEqual(rest.stateKind, .running, "break: inactivity resumes")
        restManager.tearDown()
        rest.tearDown()
    }
}
