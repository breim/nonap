import Foundation
import ServiceManagement

final class LoginItemManager: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var statusText = ""
    @Published private(set) var lastError: String?

    init() {
        refresh()
    }

    func setEnabled(_ enabled: Bool) {
        lastError = nil

        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            lastError = error.localizedDescription
        }

        refresh()
    }

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled
        statusText = Self.statusText(for: status)
    }

    private static func statusText(for status: SMAppService.Status) -> String {
        switch status {
        case .enabled:
            return "Open at Login: On"
        case .notRegistered:
            return "Open at Login: Off"
        case .requiresApproval:
            return "Open at Login: Needs Approval"
        case .notFound:
            return "Open at Login: Unavailable"
        @unknown default:
            return "Open at Login: Unknown"
        }
    }
}

