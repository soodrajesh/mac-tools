import SwiftUI

/// Bridges mac-monitor's stats/purge logic (AppKit-side timer sampling,
/// `Process`) into SwiftUI's Stats tab. `AppDelegate` owns one instance and
/// calls `refresh()` on the same 2s timer that drives the menu-bar image;
/// `StatsView` just observes it.
final class StatsController: ObservableObject {
    @Published var cpuText = "--%"
    @Published var memText = "--%"
    @Published var memDetail = ""
    @Published var topProcessText = "Top CPU: --"
    @Published var cpuHigh = false
    @Published var memHigh = false
    @Published var freeMemStatus = "Free Up Memory"
    @Published var freeMemInProgress = false

    private var prevCPUTicks: (busy: UInt64, total: UInt64)?

    func refresh() {
        let cpu = SystemStats.cpuUsage(previous: &prevCPUTicks)
        let mem = SystemStats.memoryUsage()
        let cpuPct = cpu >= 0 ? cpu : 0

        cpuText = cpu >= 0 ? String(format: "%.0f%%", cpu) : "--%"
        memText = String(format: "%.0f%%", mem.percent)
        memDetail = String(format: "%.0f%% used, %.0f%% pressure (%.1f / %.1f GB)", mem.percent, mem.pressure, mem.usedGB, mem.totalGB)
        cpuHigh = cpuPct >= cpuHighThreshold
        memHigh = mem.pressure >= memPressureThreshold

        if let top = SystemStats.topCPUProcess() {
            topProcessText = String(format: "Top CPU: %@ (%.0f%%)", top.name, top.cpu)
        }
    }

    /// Frees inactive/cached memory using macOS's built-in `purge`, via a
    /// narrow passwordless-sudo rule for /usr/sbin/purge (see README). No
    /// Touch ID gate — that sudoers rule is already the real access control;
    /// `purge` is Apple's own tool and only flushes reclaimable caches, so a
    /// biometric prompt on every click was friction without added safety.
    func freeMemory() {
        runPurge()
    }

    private func runPurge() {
        freeMemStatus = "Freeing memory…"
        freeMemInProgress = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            task.arguments = ["-n", "/usr/sbin/purge"]
            var succeeded = false
            do {
                try task.run()
                task.waitUntilExit()
                succeeded = task.terminationStatus == 0
            } catch {
                succeeded = false
            }
            DispatchQueue.main.async {
                self?.freeMemStatus = succeeded ? "Freed!" : "Failed — see README (sudoers setup)"
                self?.freeMemInProgress = false
                self?.refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + (succeeded ? 2 : 5)) {
                    self?.freeMemStatus = "Free Up Memory"
                }
            }
        }
    }
}
