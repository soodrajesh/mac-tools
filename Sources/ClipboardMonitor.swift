import AppKit

/// Polls the general pasteboard for changes. AppKit has no push notification
/// for clipboard updates, so change detection is a lightweight `changeCount`
/// diff on a timer — the same approach every macOS clipboard manager uses.
final class ClipboardMonitor {
    private let store: ClipboardStore
    private var lastChangeCount: Int
    private var timer: Timer?
    var onChange: (() -> Void)?

    /// Types password managers (1Password, etc.) mark a copy with to signal
    /// "don't persist this" — an informal but widely respected convention
    /// among clipboard tools. See org.nspasteboard.org.
    private static let concealedTypes: Set<NSPasteboard.PasteboardType> = [
        NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"),
        NSPasteboard.PasteboardType("org.nspasteboard.TransientType"),
    ]

    init(store: ClipboardStore) {
        self.store = store
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard Self.concealedTypes.isDisjoint(with: pb.types ?? []) else { return }

        if let text = pb.string(forType: .string), !text.isEmpty {
            store.addText(text)
            onChange?()
        } else if let image = NSImage(pasteboard: pb) {
            store.addImage(image)
            onChange?()
        }
    }
}
