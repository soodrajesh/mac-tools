import SwiftUI

/// Single popover content: an icon-only segmented switcher up top (Stats /
/// Calendar / Calculator / Clipboard) — text labels don't fit four-wide at
/// this size. All four tabs share the exact same fixed content size so
/// switching never resizes the panel. Opens on Stats.
struct QuickToolsPanel: View {
    @ObservedObject var stats: StatsController
    @ObservedObject var clipboardStore: ClipboardStore
    let onSelectClipboardItem: (ClipboardItem) -> Void

    @State private var selection = 0 // 0 = Stats, 1 = Calendar, 2 = Calculator, 3 = Clipboard

    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $selection) {
                Image(systemName: "cpu").tag(0)
                Image(systemName: "calendar").tag(1)
                Image(systemName: "plus.slash.minus").tag(2)
                Image(systemName: "doc.on.clipboard").tag(3)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch selection {
            case 0: StatsView(stats: stats)
            case 1: CalendarView()
            case 2: CalculatorView()
            default: ClipboardListView(store: clipboardStore, onSelect: onSelectClipboardItem)
            }
        }
        .padding(10)
        .frame(width: 280, height: 240)
        .background(Color.clear)
    }
}
