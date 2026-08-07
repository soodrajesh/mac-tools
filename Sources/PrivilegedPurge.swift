import Foundation

enum PurgeResult {
    case success
    case cancelled
    case failed
}

/// Runs `/usr/sbin/purge` via AppleScript's administrator prompt (Touch ID or
/// login password). Must be called on the main thread so the system sheet can present.
enum PrivilegedPurge {
    static func runInteractive() -> PurgeResult {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [
            "-e",
            "do shell script \"/usr/sbin/purge\" with administrator privileges",
        ]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return .failed
        }

        let errText = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if task.terminationStatus == 0 {
            return .success
        }
        if errText.localizedCaseInsensitiveContains("user canceled")
            || errText.contains("-128")
        {
            return .cancelled
        }
        return .failed
    }
}
