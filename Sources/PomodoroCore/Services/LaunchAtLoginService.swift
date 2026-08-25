import Foundation
import ServiceManagement

enum LaunchAtLoginError: LocalizedError {
    case notBundled

    var errorDescription: String? {
        "Launch at login needs the built .app bundle — run scripts/make_app.sh and launch that."
    }
}

/// `SMAppService.h` states that apps using these APIs must be code signed. A self-signed
/// certificate satisfies that; ad-hoc technically does too, but its designated requirement is a
/// bare cdhash that changes on every rebuild, so registrations go stale silently.
@MainActor
enum LaunchAtLoginService {
    static var isSupported: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    static var status: SMAppService.Status { SMAppService.mainApp.status }
    static var isEnabled: Bool { status == .enabled }

    @discardableResult
    static func set(_ enabled: Bool) -> Result<Void, Error> {
        guard isSupported else { return .failure(LaunchAtLoginError.notBundled) }
        do {
            if enabled {
                // Unregister first so a stale cdhash from a previous build is refreshed rather
                // than leaving a dead entry behind.
                if status == .enabled { try? SMAppService.mainApp.unregister() }
                try SMAppService.mainApp.register()
            } else if status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
            return .success(())
        } catch {
            Log.login.error("SMAppService failed: \(error.localizedDescription)")
            return .failure(error)
        }
    }

    /// Background Task Management records the app **by path**, so moving the bundle after
    /// registration silently breaks the login item. Reconcile on every launch.
    static func syncOnLaunch(desired: Bool) {
        guard isSupported else { return }
        if desired && status != .enabled {
            set(true)
        } else if !desired && status == .enabled {
            set(false)
        }
    }

    static func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    static func statusDescription() -> String {
        guard isSupported else { return "Unavailable — run the built .app" }
        switch status {
        case .enabled: return "Enabled"
        case .notRegistered: return "Not registered"
        case .notFound: return "Not found — the app may have been moved"
        case .requiresApproval: return "Needs approval in System Settings › General › Login Items"
        @unknown default: return "Unknown"
        }
    }
}
