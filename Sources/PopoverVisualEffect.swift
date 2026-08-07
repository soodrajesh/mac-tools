import AppKit
import SwiftUI

/// Matches system menu-bar popovers (Weather, Control Center): popover material
/// with emphasized vibrancy from the first frame, not only after a control click.
struct PopoverVisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .popover
        nsView.state = .active
        nsView.isEmphasized = true
    }
}
