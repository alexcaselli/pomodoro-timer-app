import SwiftUI

/// Replaces the WinUI `ContentDialog` with two NumberBoxes.
///
/// macOS settings apply live rather than behind Save/Cancel, so changes are committed on
/// submit/stepper release and then drive the same reset-and-rebuild the Save button did.
struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var loginError: String?

    /// `model.settings` is a `let`, so `$model.settings.x` cannot form a writable binding.
    /// The store is itself `@Observable`, so bind through a local `@Bindable` view of it.
    private var settings: SettingsStore { model.settings }

    var body: some View {
        TabView {
            general.tabItem { Label("General", systemImage: "gearshape") }
            breakTab.tabItem { Label("Break", systemImage: "cup.and.saucer") }
        }
        .frame(width: 460)
        .padding(20)
    }

    private var general: some View {
        Form {
            Section {
                DurationRow(
                    title: "Work duration",
                    value: model.settings.workingTimerDurationMinutes,
                    range: SettingsStore.workRange,
                    step: 5,                     // WinUI SmallChange = 5
                    set: { model.settings.setWorkDuration($0); model.settingsChanged() }
                )

                DurationRow(
                    title: "Break duration",
                    value: model.settings.breakTimerDurationMinutes,
                    range: SettingsStore.breakRange,
                    step: 1,                     // WinUI SmallChange = 1
                    set: { model.settings.setBreakDuration($0); model.settingsChanged() }
                )
            } header: {
                Text("Timers")
            } footer: {
                Text("Changing a duration stops and resets the current timer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Startup") {
                Toggle("Open at login", isOn: Binding(
                    get: { model.settings.launchAtLogin },
                    set: { newValue in
                        model.settings.launchAtLogin = newValue
                        switch LaunchAtLoginService.set(newValue) {
                        case .success: loginError = nil
                        case .failure(let error): loginError = error.localizedDescription
                        }
                    }
                ))
                .disabled(!LaunchAtLoginService.isSupported)

                LabeledContent("Status") {
                    HStack(spacing: 8) {
                        Text(LaunchAtLoginService.statusDescription())
                            .foregroundStyle(.secondary)
                        if LaunchAtLoginService.status == .requiresApproval {
                            Button("Open…") { LaunchAtLoginService.openLoginItemsSettings() }
                                .controlSize(.small)
                        }
                    }
                }

                if let loginError {
                    Text(loginError).font(.footnote).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var breakTab: some View {
        @Bindable var settings = settings
        return Form {
            Section {
                Picker("When a break starts", selection: $settings.strictness) {
                    ForEach(BreakStrictness.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.inline)

                Text(settings.strictness.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Break screen")
            } footer: {
                Text("Esc, the Skip button and Cmd-Q always end a break, at every level.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Notifications") {
                Toggle("Notify when a timer finishes", isOn: $settings.notificationsEnabled)

                LabeledContent("Permission") {
                    HStack(spacing: 8) {
                        Text(authorizationText).foregroundStyle(.secondary)
                        if model.notifications.authorization == .denied {
                            Button("Open…") { openNotificationSettings() }
                                .controlSize(.small)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task { await model.notifications.refreshAuthorization() }
    }

    private var authorizationText: String {
        guard NotificationService.isAvailable else { return "Unavailable — run the built .app" }
        switch model.notifications.authorization {
        case .authorized, .provisional: return "Granted"
        case .denied: return "Denied"
        case .notDetermined: return "Asked when the first timer finishes"
        default: return "Unknown"
        }
    }

    private func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}


/// A minutes field with a stepper, replacing the WinUI `NumberBox`.
///
/// The stepper snaps to the step's lattice (see `DurationStep`) so the range's lower bound
/// cannot knock the sequence permanently off its multiples. The text field is there so any
/// value in range stays directly reachable regardless of the step.
private struct DurationRow: View {
    let title: String
    let value: Double
    let range: ClosedRange<Double>
    let step: Double
    let set: (Double) -> Void

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(width: 56)
                    .focused($focused)
                    .onSubmit(commit)
                    .onChange(of: focused) { _, isFocused in
                        if !isFocused { commit() }
                    }

                Text("min").foregroundStyle(.secondary)

                Stepper(title) {
                    set(DurationStep.increment(value, step: step, in: range))
                } onDecrement: {
                    set(DurationStep.decrement(value, step: step, in: range))
                }
                .labelsHidden()
            }
        }
        .onAppear { text = format(value) }
        .onChange(of: value) { _, new in
            if !focused { text = format(new) }
        }
    }

    private func format(_ v: Double) -> String { String(Int(v.rounded())) }

    private func commit() {
        guard let typed = Double(text.trimmingCharacters(in: .whitespaces)) else {
            text = format(value)
            return
        }
        set(typed)                       // the store clamps into range
        text = format(min(max(typed, range.lowerBound), range.upperBound))
    }
}
