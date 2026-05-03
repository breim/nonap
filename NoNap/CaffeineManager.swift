import AppKit
import Foundation
import IOKit.pwr_mgt

final class CaffeineManager: ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var remainingSeconds: Int?
    @Published private(set) var selectedDuration: CaffeineDuration = .indefinite
    @Published private(set) var keepsDisplayAwake = false
    @Published private(set) var lastError: String?

    private var systemAssertionID = IOPMAssertionID(0)
    private var displayAssertionID = IOPMAssertionID(0)
    private var expirationDate: Date?
    private var countdownTimer: Timer?
    private var terminationObserver: NSObjectProtocol?

    init() {
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.deactivate()
        }
    }

    deinit {
        if let terminationObserver {
            NotificationCenter.default.removeObserver(terminationObserver)
        }

        releaseAssertions()
        stopTimer()
    }

    func activate(duration: CaffeineDuration, keepDisplayAwake: Bool) {
        if isActive {
            releaseAssertions()
            stopTimer()
        }

        selectedDuration = duration
        keepsDisplayAwake = keepDisplayAwake
        lastError = nil

        guard createSystemAssertion() else {
            isActive = false
            remainingSeconds = nil
            return
        }

        if keepDisplayAwake, !createDisplayAssertion() {
            releaseAssertions()
            isActive = false
            remainingSeconds = nil
            return
        }

        isActive = true
        startTimer(for: duration)
    }

    func setKeepDisplayAwake(_ keepDisplayAwake: Bool) {
        keepsDisplayAwake = keepDisplayAwake
        lastError = nil

        guard isActive else {
            return
        }

        if keepDisplayAwake {
            _ = createDisplayAssertion()
        } else {
            releaseDisplayAssertion()
        }
    }

    func deactivate() {
        releaseAssertions()
        stopTimer()
        isActive = false
        remainingSeconds = nil
        lastError = nil
    }

    private func createSystemAssertion() -> Bool {
        var newAssertionID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "NoNap is keeping your Mac awake" as CFString,
            &newAssertionID
        )

        guard result == kIOReturnSuccess else {
            systemAssertionID = 0
            lastError = "Could not create system power assertion. IOKit returned \(result)."
            return false
        }

        systemAssertionID = newAssertionID
        return true
    }

    private func createDisplayAssertion() -> Bool {
        guard displayAssertionID == 0 else {
            return true
        }

        var newAssertionID = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "NoNap is keeping your display awake" as CFString,
            &newAssertionID
        )

        guard result == kIOReturnSuccess else {
            displayAssertionID = 0
            keepsDisplayAwake = false
            lastError = "Could not create display power assertion. IOKit returned \(result)."
            return false
        }

        displayAssertionID = newAssertionID
        return true
    }

    private func startTimer(for duration: CaffeineDuration) {
        guard let seconds = duration.seconds else {
            expirationDate = nil
            remainingSeconds = nil
            return
        }

        expirationDate = Date().addingTimeInterval(TimeInterval(seconds))
        remainingSeconds = seconds

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let expirationDate else {
            return
        }

        let remaining = max(0, Int(ceil(expirationDate.timeIntervalSinceNow)))
        remainingSeconds = remaining

        if remaining == 0 {
            deactivate()
        }
    }

    private func stopTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        expirationDate = nil
    }

    private func releaseAssertions() {
        releaseDisplayAssertion()
        releaseSystemAssertion()
    }

    private func releaseSystemAssertion() {
        guard systemAssertionID != 0 else { return }
        IOPMAssertionRelease(systemAssertionID)
        systemAssertionID = 0
    }

    private func releaseDisplayAssertion() {
        guard displayAssertionID != 0 else { return }
        IOPMAssertionRelease(displayAssertionID)
        displayAssertionID = 0
    }
}
