import Foundation

/// A cancellable 1 Hz clock, replacing `System.Timers.Timer(1000)` + `DispatcherQueue.TryEnqueue`.
///
/// Design notes:
/// - A `Task` created inside a `@MainActor` method *inherits* that isolation, so `onTick` is
///   statically MainActor with no hop and no `Sendable` friction. `Timer.publish`'s sink is
///   `@Sendable` and non-isolated, which under Swift 6 forces either an unchecked
///   `MainActor.assumeIsolated` or a hop per tick.
/// - It sleeps until an *absolute* instant rather than `sleep(for:)` in a loop, because the
///   latter accumulates drift: each iteration's overhead is added to the next deadline.
/// - `ContinuousClock` keeps advancing across system sleep and is immune to wall-clock/NTP
///   jumps. Callers still recompute from their own deadline, so a late or coalesced tick is
///   a display concern only, never a correctness one.
@MainActor
final class TickDriver {
    private var task: Task<Void, Never>?
    private let interval: Duration
    private let tolerance: Duration

    init(every interval: Duration = .seconds(1), tolerance: Duration = .milliseconds(200)) {
        self.interval = interval
        self.tolerance = tolerance
    }

    var isRunning: Bool { task != nil }

    func start(_ onTick: @escaping @MainActor () -> Void) {
        stop()
        let interval = self.interval
        let tolerance = self.tolerance
        task = Task {
            let clock = ContinuousClock()
            var next = clock.now
            while !Task.isCancelled {
                next = next.advanced(by: interval)
                try? await clock.sleep(until: next, tolerance: tolerance)
                if Task.isCancelled { return }
                onTick()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    deinit { task?.cancel() }
}
