import Combine
import Foundation

/// Which tool tab is selected in the menu-bar popover (shared with global hotkeys).
final class PanelState: ObservableObject {
    @Published var selectedTab = 0 // 4 = Notepad

    func openNotepadTab() {
        selectedTab = 4
    }
}
