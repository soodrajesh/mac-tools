import AppKit
import SwiftUI

/// AppKit text view so ⌘V and keyboard input work in the menu-bar popover
/// (SwiftUI `TextEditor` often does not become key in `LSUIElement` apps).
struct NotepadTextView: NSViewRepresentable {
    @Binding var text: String
    var focusOnAppear: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder

        let textView = NotepadNSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 11)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scroll.contentSize.width, height: .greatestFiniteMagnitude)
        textView.string = text
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        scroll.documentView = textView
        return scroll
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        if focusOnAppear {
            context.coordinator.focusEditorIfNeeded()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NotepadTextView
        weak var textView: NSTextView?
        private var lastFocusRequest = false

        init(parent: NotepadTextView) {
            self.parent = parent
        }

        func focusEditorIfNeeded() {
            guard !lastFocusRequest else { return }
            lastFocusRequest = true
            DispatchQueue.main.async { [weak self] in
                self?.focusEditor()
            }
        }

        func focusEditor() {
            NSApp.activate(ignoringOtherApps: true)
            guard let textView, let window = textView.window else { return }
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(textView)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
