import Cocoa
import SwiftUI
import Carbon.HIToolbox

// MARK: - App delegate
//
// One NSStatusItem showing mac-monitor's live two-line CPU/MEM readout.
// Left-click toggles an NSPopover (Stats/Calendar/Calculator/Clipboard/Notepad,
// from quick-tools). Right-click shows Free Up Memory / Accessibility /
// Quit. The ⌘⇧V paste-picker and ⌘⇧N notepad opener run via global hotkeys.

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var globalClickMonitor: Any?
    private var timer: Timer?
    private var frontmostBeforeShow: NSRunningApplication?

    private let stats = StatsController()
    private let clipboardStore = ClipboardStore()
    private let notepadStore = NotepadStore()
    private let panelState = PanelState()
    private var clipboardMonitor: ClipboardMonitor!
    private var picker: PickerController!
    private var hotKey: HotKey?
    private var notepadHotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ApplicationMenus.installStandardEditMenu()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.action = #selector(handleClick)
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        // Re-render when the menu bar switches between light/dark.
        statusItem.button?.addObserver(self, forKeyPath: "effectiveAppearance", options: [.new], context: nil)

        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 240)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        let hosting = NSHostingController(rootView: QuickToolsPanel(
            stats: stats,
            clipboardStore: clipboardStore,
            notepadStore: notepadStore,
            panelState: panelState,
            onSelectClipboardItem: { [weak self] item in self?.selectClipboardItem(item) }
        ))
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor
        popover.contentViewController = hosting

        clipboardMonitor = ClipboardMonitor(store: clipboardStore)
        clipboardMonitor.start()
        picker = PickerController(store: clipboardStore)

        // kVK_ANSI_V = 9; cmdKey|shiftKey are Carbon modifier masks for ⌘⇧.
        hotKey = HotKey(keyCode: 9, modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.picker.show()
        }

        // kVK_ANSI_N = 45 — open popover on Notepad tab.
        notepadHotKey = HotKey(keyCode: 45, modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.showNotepadFromHotkey()
        }

        if !PasteSimulator.isTrusted {
            PasteSimulator.requestAccessibility()
        }

        stats.refresh()
        refreshStatusItem()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.stats.refresh()
            self?.refreshStatusItem()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                                change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "effectiveAppearance" else { return }
        refreshStatusItem()
    }

    private func refreshStatusItem() {
        let isDark = statusItem.button?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        statusItem.button?.attributedTitle = NSAttributedString(string: "")
        statusItem.button?.image = makeStatusImage(
            cpuValue: stats.cpuText, cpuHigh: stats.cpuHigh,
            memValue: stats.memText, memHigh: stats.memHigh,
            isDark: isDark)
    }

    @objc func handleClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            closePopover()
        } else {
            openPopover(relativeTo: button)
        }
    }

    private func showNotepadFromHotkey() {
        panelState.openNotepadTab()
        guard let button = statusItem.button else { return }
        if popover.isShown {
            return
        }
        openPopover(relativeTo: button)
    }

    private func openPopover(relativeTo button: NSStatusBarButton) {
        frontmostBeforeShow = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        configurePopoverWindow()
        startGlobalClickMonitor()
    }

    /// `.transient` alone doesn't reliably close the popover when a click
    /// lands on a *different* app's status item — a global mouse-down
    /// monitor is the reliable fix (only fires for clicks outside our own
    /// app, so it can't interfere with our own button's toggle logic).
    private func configurePopoverWindow() {
        guard let window = popover.contentViewController?.view.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.makeKey()
    }

    private func startGlobalClickMonitor() {
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
    }

    private func selectClipboardItem(_ item: ClipboardItem) {
        closePopover()
        clipboardStore.copyToPasteboard(item)
        PasteSimulator.pasteInto(frontmostBeforeShow)
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let freeMemItem = NSMenuItem(title: "Free Up Memory", action: #selector(freeMemoryAction), keyEquivalent: "")
        freeMemItem.target = self
        menu.addItem(freeMemItem)

        if !PasteSimulator.isTrusted {
            let permItem = NSMenuItem(title: "Enable Accessibility for Auto-Paste…",
                                       action: #selector(requestAccessibility), keyEquivalent: "")
            permItem.target = self
            menu.addItem(permItem)
        }

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit MacTools", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func freeMemoryAction() {
        stats.freeMemory()
    }

    @objc func requestAccessibility() {
        PasteSimulator.requestAccessibility()
    }

    @objc func quit() {
        statusItem.button?.removeObserver(self, forKeyPath: "effectiveAppearance")
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidShow(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        configurePopoverWindow()
    }
}

// MARK: - Entry point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
