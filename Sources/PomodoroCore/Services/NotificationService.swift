import Foundation
import UserNotifications

/// Replaces `ToastContentBuilder` + the COM toast activator.
///
/// Nothing here is load-bearing: the break overlay is the primary signal and fires
/// unconditionally. If authorization is denied or the process is not a registered bundle, the
/// only loss is the banner.
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    nonisolated static let categoryID = "POMODORO_PHASE_COMPLETE"
    nonisolated static let openActionID = "OPEN_WINDOW"     // the "action=openWindow" toast argument

    /// `UNUserNotificationCenter.current()` calls `bundleProxyForCurrentProcess` and raises an
    /// **uncatchable** ObjC exception when that is nil — i.e. whenever the executable is run
    /// outside a LaunchServices-registered .app. Swift cannot catch it, so it is a hard crash,
    /// and it is the first thing you hit on `swift run`. Every access is gated on this.
    nonisolated static var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app"
    }

    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    var onOpenRequested: (@MainActor () -> Void)?

    func bootstrap() {
        guard Self.isAvailable else {
            Log.notifications.warning("notifications unavailable (not a registered .app bundle)")
            return
        }
        let center = UNUserNotificationCenter.current()
        // Must be set before anything is scheduled, or launch-time deliveries are lost.
        center.delegate = self

        let open = UNNotificationAction(
            identifier: Self.openActionID,
            title: "Start break",
            options: [.foreground]
        )
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: Self.categoryID,
                actions: [open],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        ])

        Task { await refreshAuthorization() }
    }

    func refreshAuthorization() async {
        guard Self.isAvailable else { return }
        authorization = await UNUserNotificationCenter.current()
            .notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard Self.isAvailable else { return false }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            await refreshAuthorization()
            return granted
        } catch {
            Log.notifications.error("requestAuthorization failed: \(error.localizedDescription)")
            await refreshAuthorization()
            return false
        }
    }

    /// The Windows app notified only on work completion, although its README promised both.
    func notifyCompleted(phase: TimerPhase, enabled: Bool) {
        guard Self.isAvailable, enabled else { return }
        Task {
            // Asked lazily, on the first completion — never as a cold prompt at first launch,
            // which is the reliable way to get denied permanently.
            if authorization == .notDetermined {
                _ = await requestAuthorization()
            }
            guard authorization == .authorized || authorization == .provisional else { return }

            let content = UNMutableNotificationContent()
            content.title = "Pomodoro Timer"
            switch phase {
            case .work:
                content.body = "Work session finished — time for a break."
            case .rest:
                content.body = "Break over — back to work."
            }
            content.sound = .default
            content.categoryIdentifier = Self.categoryID
            // Closest analogue of the WinUI ToastScenario.Reminder: breaks through Focus when
            // the user has granted Time Sensitive, degrades to a plain banner otherwise.
            content.interruptionLevel = .timeSensitive

            do {
                try await UNUserNotificationCenter.current().add(
                    UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: nil        // deliver immediately
                    )
                )
            } catch {
                Log.notifications.error("add() failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // The overlay has just activated us, so without this the banner would be suppressed.
        [.banner, .sound, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let id = response.actionIdentifier
        guard id == Self.openActionID || id == UNNotificationDefaultActionIdentifier else { return }
        await MainActor.run { self.onOpenRequested?() }
    }
}
