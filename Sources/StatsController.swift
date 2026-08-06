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
    @Published var netDownText = "-- KB/s"
    @Published var netUpText = "-- KB/s"
    @Published var diskReadText = "-- KB/s"
    @Published var diskWriteText = "-- KB/s"
    @Published var diskCapacityText = ""
    @Published var freeMemStatus = "Free Up Memory"
    @Published var freeMemInProgress = false

    private var prevCPUTicks: (busy: UInt64, total: UInt64)?
    private var prevNetBytes: (rx: UInt64, tx: UInt64)?
    private var prevDiskBytes: (read: UInt64, write: UInt64)?
    private var prevSampleTime: Date?

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

        // Network/disk are cumulative-since-boot counters — delta against
        // the actual elapsed time (not the nominal 2s timer interval, which
        // can drift) for an accurate live rate, same approach as cpuUsage.
        let now = Date()
        let elapsed = prevSampleTime.map { now.timeIntervalSince($0) } ?? 2.0
        prevSampleTime = now

        if let net = SystemStats.networkBytes() {
            if let prev = prevNetBytes, elapsed > 0 {
                let rxDelta = net.rx >= prev.rx ? net.rx - prev.rx : 0
                let txDelta = net.tx >= prev.tx ? net.tx - prev.tx : 0
                netDownText = Self.formatSpeed(Double(rxDelta) / elapsed)
                netUpText = Self.formatSpeed(Double(txDelta) / elapsed)
            }
            prevNetBytes = net
        }

        if let disk = SystemStats.diskBytes() {
            if let prev = prevDiskBytes, elapsed > 0 {
                let readDelta = disk.read >= prev.read ? disk.read - prev.read : 0
                let writeDelta = disk.write >= prev.write ? disk.write - prev.write : 0
                diskReadText = Self.formatSpeed(Double(readDelta) / elapsed)
                diskWriteText = Self.formatSpeed(Double(writeDelta) / elapsed)
            }
            prevDiskBytes = disk
        }

        if let cap = SystemStats.diskCapacity() {
            diskCapacityText = String(format: "%.0f GB free of %.0f GB", cap.freeGB, cap.totalGB)
        }
    }

    private static func formatSpeed(_ bytesPerSec: Double) -> String {
        let kb = bytesPerSec / 1024
        if kb < 1024 {
            return String(format: "%.0f KB/s", kb)
        }
        return String(format: "%.1f MB/s", kb / 1024)
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
