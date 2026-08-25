import Foundation
import os

/// Replaces `Helpers/IOHelper.cs`, which appended to a `debug_logs.txt` recreated on every
/// launch. Unified logging is the macOS idiom; read it with:
///   log stream --predicate 'subsystem == "studio.visionlab.pomodorotimer"'
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "studio.visionlab.pomodorotimer"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let timer = Logger(subsystem: subsystem, category: "timer")
    static let overlay = Logger(subsystem: subsystem, category: "overlay")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let login = Logger(subsystem: subsystem, category: "loginitem")
}
