import AppKit

enum ScreenCapture {
    /// Runs macOS's own interactive region-selection UI — the same crosshair
    /// as ⌘⇧4 — and returns the captured image, or `nil` if the user pressed
    /// Esc to cancel. Shelling out to `/usr/sbin/screencapture` reuses
    /// Apple's selection UI and Screen Recording permission handling instead
    /// of reimplementing either.
    static func captureRegion() -> NSImage? {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("snaptext-\(UUID().uuidString).png")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        task.arguments = ["-i", "-t", "png", tmp.path]
        do { try task.run() } catch { return nil }
        task.waitUntilExit()

        defer { try? FileManager.default.removeItem(at: tmp) }
        // screencapture writes nothing at all if the user cancels the selection.
        guard FileManager.default.fileExists(atPath: tmp.path) else { return nil }
        return NSImage(contentsOf: tmp)
    }
}
