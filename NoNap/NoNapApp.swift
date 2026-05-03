import AppKit
import SwiftUI

@main
struct NoNapApp: App {
    @StateObject private var manager = CaffeineManager()
    @StateObject private var loginItemManager = LoginItemManager()

    var body: some Scene {
        MenuBarExtra {
            NoNapMenu(manager: manager, loginItemManager: loginItemManager)
        } label: {
            Label("NoNap", systemImage: manager.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct NoNapMenu: View {
    @ObservedObject var manager: CaffeineManager
    @ObservedObject var loginItemManager: LoginItemManager
    @AppStorage("selectedDuration") private var selectedDurationRawValue = CaffeineDuration.indefinite.rawValue
    @AppStorage("keepDisplayAwake") private var keepDisplayAwake = false

    private var selectedDuration: CaffeineDuration {
        CaffeineDuration(rawValue: selectedDurationRawValue) ?? .indefinite
    }

    var body: some View {
        Button {
            if manager.isActive {
                manager.deactivate()
            } else {
                manager.activate(duration: selectedDuration, keepDisplayAwake: keepDisplayAwake)
            }
        } label: {
            Label(manager.isActive ? "Deactivate" : "Activate", systemImage: manager.isActive ? "pause.circle" : "play.circle")
        }

        Text(statusText)

        if let lastError = manager.lastError {
            Text(lastError)
        }

        Divider()

        Button {
            keepDisplayAwake.toggle()
            manager.setKeepDisplayAwake(keepDisplayAwake)
        } label: {
            Label("Keep Display On", systemImage: keepDisplayAwake ? "checkmark.circle" : "circle")
        }

        Divider()

        ForEach(CaffeineDuration.allCases) { duration in
            Button {
                selectedDurationRawValue = duration.rawValue

                if manager.isActive {
                    manager.activate(duration: duration, keepDisplayAwake: keepDisplayAwake)
                }
            } label: {
                if duration == selectedDuration {
                    Label(duration.title, systemImage: "checkmark")
                } else {
                    Text(duration.title)
                }
            }
        }

        Divider()

        Button {
            loginItemManager.setEnabled(!loginItemManager.isEnabled)
        } label: {
            Label(loginItemManager.statusText, systemImage: loginItemManager.isEnabled ? "checkmark.circle" : "circle")
        }

        if let lastError = loginItemManager.lastError {
            Text(lastError)
        }

        Divider()

        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Label("Quit", systemImage: "power")
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
