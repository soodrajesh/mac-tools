import AppKit

/// Menu-bar (`LSUIElement`) apps have no visible menu bar, but without an Edit
/// menu ⌘C / ⌘V / ⌘X never reach the responder chain.
enum ApplicationMenus {
    static func installStandardEditMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = NSMenu(title: "Edit")
        guard let editMenu = editMenuItem.submenu else { return }

        func item(_ title: String, _ action: Selector, _ key: String, modifiers: NSEvent.ModifierFlags = .command) {
            let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
            menuItem.keyEquivalentModifierMask = modifiers
            menuItem.target = nil
            editMenu.addItem(menuItem)
        }

        item("Undo", Selector(("undo:")), "z")
        item("Redo", Selector(("redo:")), "Z", modifiers: [.command, .shift])
        editMenu.addItem(.separator())
        item("Cut", #selector(NSText.cut(_:)), "x")
        item("Copy", #selector(NSText.copy(_:)), "c")
        item("Paste", #selector(NSText.paste(_:)), "v")
        item("Select All", #selector(NSText.selectAll(_:)), "a")

        mainMenu.addItem(editMenuItem)
        NSApp.mainMenu = mainMenu
    }
}

/// NSTextView that claims standard editing shortcuts even when the popover
/// window is not fully integrated with the app menu.
final class NotepadNSTextView: NSTextView {
    override var acceptsFirstResponder: Bool { true }

    func selectEntireNote() {
        let full = NSRange(location: 0, length: (string as NSString).length)
        setSelectedRange(full)
        scrollRangeToVisible(full)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown, event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }

        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        let handled: Bool
        switch key {
        case "v":
            paste(self)
            handled = true
        case "c":
            copy(self)
            handled = selectedRange.length > 0 || !string.isEmpty
        case "x":
            cut(self)
            handled = selectedRange.length > 0
        case "a":
            selectEntireNote()
            handled = true
        case "z":
            if event.modifierFlags.contains(.shift) {
                handled = undoManager?.canRedo == true
                if handled { undoManager?.redo() }
            } else {
                handled = undoManager?.canUndo == true
                if handled { undoManager?.undo() }
            }
        default:
            handled = false
        }
        if handled { return true }
        return super.performKeyEquivalent(with: event)
    }
}
