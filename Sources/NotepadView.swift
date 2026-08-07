import SwiftUI

struct NotepadView: View {
    @ObservedObject var store: NotepadStore
    @State private var confirmClear = false
    @State private var copiedFlash = false
    @State private var focusEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            NotepadTextView(text: $store.text, focusOnAppear: focusEditor)
                .padding(6)
                .background(Color(nsColor: .quaternaryLabelColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
                )

            HStack(spacing: 8) {
                Text(copiedFlash ? "Copied" : "Saved automatically")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Copy") {
                    store.copyToPasteboard()
                    copiedFlash = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        copiedFlash = false
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(.primary)

                Button("Clear") {
                    if store.text.isEmpty {
                        return
                    }
                    confirmClear = true
                }
                .font(.system(size: 10, weight: .medium))
                .buttonStyle(.plain)
                .foregroundStyle(store.text.isEmpty ? Color.secondary : Color.red)
                .disabled(store.text.isEmpty)
            }
        }
        .frame(width: 260, height: 190, alignment: .top)
        .onAppear {
            focusEditor = true
            NSApp.activate(ignoringOtherApps: true)
        }
        .confirmationDialog("Clear all notepad text?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                store.clear()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
