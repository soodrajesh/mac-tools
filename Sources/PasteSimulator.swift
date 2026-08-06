import AppKit
import ApplicationServices

/// Synthesizes ⌘V into the frontmost app after a selection, so the user
/// doesn't have to press paste manually. CGEvent injection requires
/// Accessibility access; without it the item still lands on the clipboard,
/// just without the auto-paste — a silent, safe fallback.
enum PasteSimulator {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    /// Reactivates `app` and, once it's frontmost again, sends ⌘V.
    static func pasteInto(_ app: NSRunningApplication?) {
        app?.activate(options: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            sendPaste()
        }
    }

    private static func sendPaste() {
        guard isTrusted else { return }
        let src = CGEventSource(stateID: .hidSystemState)
        let vKey: CGKeyCode = 9 // kVK_ANSI_V
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
