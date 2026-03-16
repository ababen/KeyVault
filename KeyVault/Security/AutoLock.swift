import Foundation
import Combine
import AppKit

/// Monitors user activity and locks the vault after idle timeout or screen sleep.
@MainActor
final class AutoLock: ObservableObject {
    @Published var isLocked = false

    private var idleTimer: Timer?
    private var timeoutSeconds: TimeInterval
    private var cancellables = Set<AnyCancellable>()

    init(timeoutMinutes: Int = 5) {
        self.timeoutSeconds = TimeInterval(timeoutMinutes * 60)
        observeSystemEvents()
    }

    func unlock() {
        isLocked = false
        resetTimer()
    }

    func lock() {
        isLocked = true
        idleTimer?.invalidate()
        idleTimer = nil
    }

    func resetTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: timeoutSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.lock()
            }
        }
    }

    func userActivity() {
        guard !isLocked else { return }
        resetTimer()
    }

    func updateTimeout(minutes: Int) {
        timeoutSeconds = TimeInterval(minutes * 60)
        if !isLocked {
            resetTimer()
        }
    }

    private func observeSystemEvents() {
        // Lock on screen sleep
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.screensDidSleepNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.lock() }
            .store(in: &cancellables)

        // Lock on screen lock
        DistributedNotificationCenter.default()
            .publisher(for: Notification.Name("com.apple.screenIsLocked"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.lock() }
            .store(in: &cancellables)
    }
}
