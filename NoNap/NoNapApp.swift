import AppKit
import SwiftUI

@main
struct NoNapApp: App {
    @StateObject private var manager = NoNapManager()
    @StateObject private var loginItemManager = LoginItemManager()

    var body: some Scene {
        MenuBarExtra {
            NoNapMenu(manager: manager, loginItemManager: loginItemManager)
        } label: {
            Label("NoNap", systemImage: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct NoNapMenu: View {
    @ObservedObject var manager: NoNapManager
    @ObservedObject var loginItemManager: LoginItemManager
    @AppStorage("selectedDuration") private var selectedDurationRawValue = NoNapDuration.indefinite.rawValue
    @AppStorage("keepDisplayAwake") private var keepDisplayAwake = false

    private var selectedDuration: NoNapDuration {
        NoNapDuration(rawValue: selectedDurationRawValue) ?? .indefinite
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .font(.title2)
                    .foregroundStyle(manager.isActive ? .blue : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("NoNap")
                        .font(.headline)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Toggle("Activate", isOn: activeBinding)
                .toggleStyle(.switch)

            Toggle("Keep Display On", isOn: keepDisplayAwakeBinding)
                .toggleStyle(.switch)

            Picker("Duration", selection: durationBinding) {
                ForEach(NoNapDuration.allCases) { duration in
                    Text(duration.title).tag(duration.rawValue)
                }
            }
            .pickerStyle(.menu)

            Divider()

            Toggle("Open at Login", isOn: openAtLoginBinding)
                .toggleStyle(.switch)

            if let lastError = manager.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let lastError = loginItemManager.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            loginItemManager.refresh()
        }
    }

    private var activeBinding: Binding<Bool> {
        Binding {
            manager.isActive
        } set: { isActive in
            if isActive {
                manager.activate(duration: selectedDuration, keepDisplayAwake: keepDisplayAwake)
            } else {
                manager.deactivate()
            }
        }
    }

    private var keepDisplayAwakeBinding: Binding<Bool> {
        Binding {
            keepDisplayAwake
        } set: { isOn in
            keepDisplayAwake = isOn
            manager.setKeepDisplayAwake(isOn)
        }
    }

    private var durationBinding: Binding<String> {
        Binding {
            selectedDurationRawValue
        } set: { newValue in
            selectedDurationRawValue = newValue

            if manager.isActive {
                manager.activate(duration: selectedDuration, keepDisplayAwake: keepDisplayAwake)
            }
        }
    }

    private var openAtLoginBinding: Binding<Bool> {
        Binding {
            loginItemManager.isEnabled
        } set: { isEnabled in
            loginItemManager.setEnabled(isEnabled)
        }
    }

    private var statusText: String {
        guard manager.isActive else {
            return "Inactive"
        }

        guard let remainingSeconds = manager.remainingSeconds else {
            return manager.keepsDisplayAwake ? "Active indefinitely, display on" : "Active indefinitely"
        }

        let suffix = manager.keepsDisplayAwake ? ", display on" : ""
        return "Active: \(formattedDuration(remainingSeconds)) remaining\(suffix)"
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
