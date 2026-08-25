import Foundation

/// Port of `Monitors/UserMonitor.cs` and its two subclasses.
///
/// The Windows `UserInactivityMonitor` and `UserActivityMonitor` differed only in which
/// threshold constant they compared against, so they collapse into one type with two factories.
///
/// **Bug fixed here.** The C# managers did `var monitor = new UserInactivityMonitor();
/// monitor.AddObserver(this);` on a *local* variable — never stored, never stopped, with its
/// 1 s timer already started by the base constructor. Every tab switch, settings save and cycle
/// transition leaked another monitor that kept firing forever against dead objects. Here the
/// monitor is owned, observers are held weakly, and `stop()` is called from `tearDown()`.
@MainActor
final class IdleMonitor {
    static let workInactivityThreshold: TimeInterval = 15   // WorkInactivityThreshold
    static let breakActivityThreshold: TimeInterval = 10    // BreakActivityThreshold

    let threshold: TimeInterval

    private struct WeakObserver {
        weak var value: (any ActivityObserver)?
    }

    private var observers: [WeakObserver] = []
    private let poll = TickDriver()

    private init(threshold: TimeInterval) {
        self.threshold = threshold
    }

    static func forWork(threshold: TimeInterval = IdleMonitor.workInactivityThreshold) -> IdleMonitor {
        IdleMonitor(threshold: threshold)
    }

    static func forBreak(threshold: TimeInterval = IdleMonitor.breakActivityThreshold) -> IdleMonitor {
        IdleMonitor(threshold: threshold)
    }

    func add(_ observer: any ActivityObserver) {
        observers.append(WeakObserver(value: observer))
    }

    func remove(_ observer: any ActivityObserver) {
        observers.removeAll { $0.value === observer || $0.value == nil }
    }

    func start() {
        poll.start { [weak self] in self?.checkActivity() }
    }

    func stop() {
        poll.stop()
    }

    /// Level-triggered on purpose, mirroring `UserMonitor.CheckActivity()`: it fires every
    /// second regardless of whether anything changed, rather than only on transitions.
    ///
    /// This is not an oversight to "fix". If the user is already idle when they press play from
    /// Ready, an edge-triggered monitor would have emitted its "went inactive" edge while the
    /// timer was still in Ready (where `activityPause` returns false) and would never fire
    /// again — the work timer would run on unattended. The `pausedDueTo…` flags plus the state
    /// machine make repeated notification idempotent.
    private func checkActivity() {
        observers.removeAll { $0.value == nil }
        let idle = SystemIdle.duration()
        let snapshot = observers            // copy: a callback may mutate the list
        if idle > threshold {
            for o in snapshot { o.value?.onUserInactive() }
        } else {
            for o in snapshot { o.value?.onUserActive() }
        }
    }

    deinit { }
}
