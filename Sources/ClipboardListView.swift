import SwiftUI

struct ClipboardListView: View {
    @ObservedObject var store: ClipboardStore
    let onSelect: (ClipboardItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if store.items.isEmpty {
                Spacer()
                Text("No clipboard history yet")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(store.items.prefix(12), id: \.id) { item in
                            Button(action: { onSelect(item) }) {
                                HStack {
                                    Text(rowTitle(for: item))
                                        .font(.system(size: 11))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(.horizontal, 6)
                                .frame(height: 22)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: 260, height: 190, alignment: .top)
    }

    private func rowTitle(for item: ClipboardItem) -> String {
        switch item.kind {
        case .text:
            let flat = item.preview.replacingOccurrences(of: "\n", with: " ")
            return flat.count > 40 ? String(flat.prefix(40)) + "…" : flat
        case .image:
            return "🖼 Image"
        }
    }
}
