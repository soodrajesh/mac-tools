import SwiftUI

/// Single popover content: icon-only segmented switcher (Stats / Calendar /
/// Calculator / Clipboard / Notepad). All tabs share the same fixed content
/// size so switching never resizes the panel. Opens on Stats.
struct QuickToolsPanel: View {
    @ObservedObject var stats: StatsController
    @ObservedObject var clipboardStore: ClipboardStore
    @ObservedObject var notepadStore: NotepadStore
    @ObservedObject var panelState: PanelState
    let onSelectClipboardItem: (ClipboardItem) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $panelState.selectedTab) {
                Image(systemName: "cpu").tag(0)
                Image(systemName: "calendar").tag(1)
                Image(systemName: "plus.slash.minus").tag(2)
                Image(systemName: "doc.on.clipboard").tag(3)
                Image(systemName: "note.text").tag(4)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch panelState.selectedTab {
            case 0: StatsView(stats: stats)
            case 1: CalendarView()
            case 2: CalculatorView()
            case 3: ClipboardListView(store: clipboardStore, onSelect: onSelectClipboardItem)
            default: NotepadView(store: notepadStore)
            }
        }
        .padding(10)
        .frame(width: 280, height: 240)
        .background(PopoverVisualEffect())
    }
}
