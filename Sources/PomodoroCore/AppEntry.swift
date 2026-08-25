import SwiftUI

/// The module's public surface: two entry points, nothing else.
public enum AppEntry {
    /// Starts the SwiftUI application. Does not return in practice.
    @MainActor
    public static func launch() {
        PomodoroTimerScene.main()
    }

    /// Runs the headless assertions and returns a process exit status.
    ///
    /// Stands in for `swift test`: XCTest and swift-testing ship with Xcode, not with the
    /// Command Line Tools, so `swift test` cannot run in this toolchain.
    @MainActor
    public static func selfCheck() async -> Int32 {
        await SelfCheck.run()
    }
}
