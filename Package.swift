// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "PomodoroTimer",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PomodoroTimer", targets: ["pomodoro-app"]),
        .executable(name: "pomodoro-selfcheck", targets: ["pomodoro-selfcheck"]),
    ],
    targets: [
        // All app code lives in a library so the self-check executable can exercise it.
        // XCTest/swift-testing ship with Xcode, not the Command Line Tools, so `swift test`
        // is unavailable here and a plain executable takes its place.
        //
        // NOTE: deliberately NO `resources:` declaration. SwiftPM's generated `Bundle.module`
        // accessor resolves against `Bundle.main.bundleURL` (the bundle ROOT, not
        // Contents/Resources), so inside a hand-assembled .app it would look for
        // `PomodoroTimer.app/PomodoroTimer_*.bundle` — a codesign-invalid location — and
        // otherwise fall back to a hardcoded absolute path into .build/. Everything we ship
        // goes in Contents/Resources via scripts/make_app.sh and is read through Bundle.main.
        .target(
            name: "PomodoroCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "pomodoro-app",
            dependencies: ["PomodoroCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "pomodoro-selfcheck",
            dependencies: ["PomodoroCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
