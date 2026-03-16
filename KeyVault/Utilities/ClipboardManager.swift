import Foundation
import AppKit

/// Copies sensitive values to the clipboard and auto-clears after a timeout.
enum ClipboardManager {

    private static var clearTask: DispatchWorkItem?

    /// Copy a string to the clipboard, auto-clearing after `seconds`.
    static func copy(_ value: String, clearAfter seconds: TimeInterval = 30) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)

        // Cancel any pending clear
        clearTask?.cancel()

        // Schedule auto-clear
        let task = DispatchWorkItem {
            // Only clear if the clipboard still contains our value
            if let current = pasteboard.string(forType: .string), current == value {
                pasteboard.clearContents()
            }
        }
        clearTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: task)
    }

    /// Immediately clear the clipboard.
    static func clear() {
        clearTask?.cancel()
        clearTask = nil
        NSPasteboard.general.clearContents()
    }
}
