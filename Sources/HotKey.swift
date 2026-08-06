import Carbon.HIToolbox
import AppKit

/// A single global keyboard shortcut, registered via the Carbon Event
/// Manager — still the only API that lets an unsigned, non-sandboxed app
/// receive a hotkey while another app has focus, and unlike a CGEventTap it
/// needs no Accessibility permission just to register.
final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private let id: UInt32
    private let action: () -> Void

    private static var registry: [UInt32: HotKey] = [:]
    private static var nextID: UInt32 = 1
    private static var handlerInstalled = false

    init?(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.id = HotKey.nextID
        HotKey.nextID += 1
        self.action = action

        HotKey.installHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: OSType(bitPattern: 0x434c4950), id: id) // 'CLIP'
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        guard status == noErr else { return nil }
        HotKey.registry[id] = self
    }

    private static func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                               nil, MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            HotKey.registry[hkID.id]?.action()
            return noErr
        }, 1, &eventType, nil, nil)
    }

    deinit {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        HotKey.registry[id] = nil
    }
}
