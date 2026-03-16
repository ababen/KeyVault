import Foundation
import SwiftData
import UserNotifications

/// Monitors entries for upcoming expirations and sends macOS notifications.
@MainActor
final class ExpirationMonitor {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Check for entries expiring within the given number of days and notify.
    func checkExpirations(warningDays: Int = 7) async {
        let now = Date()
        guard let threshold = Calendar.current.date(byAdding: .day, value: warningDays, to: now) else { return }

        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate<Entry> { entry in
                entry.expiresAt != nil
            }
        )

        guard let entries = try? modelContext.fetch(descriptor) else { return }

        let expiring = entries.filter { entry in
            guard let expiresAt = entry.expiresAt else { return false }
            return expiresAt > now && expiresAt <= threshold
        }

        let expired = entries.filter { entry in
            guard let expiresAt = entry.expiresAt else { return false }
            return expiresAt <= now
        }

        for entry in expiring {
            await sendNotification(
                title: "API Key Expiring Soon",
                body: "\(entry.name) (\(entry.provider)) expires \(entry.expiresAt?.relativeDisplay ?? "soon")"
            )
        }

        for entry in expired {
            await sendNotification(
                title: "API Key Expired",
                body: "\(entry.name) (\(entry.provider)) has expired"
            )
        }
    }

    /// Request notification permissions.
    static func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
