import SwiftUI

struct StatsView: View {
    @ObservedObject var stats: StatsController

    private var secondaryColor: Color { Color(red: 0.6, green: 0.65, blue: 0.72) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            statRow(label: "CPU", value: stats.cpuText, high: stats.cpuHigh)
            statRow(label: "Memory", value: stats.memText, high: stats.memHigh)

            Text(stats.memDetail)
                .font(.system(size: 10))
                .foregroundColor(secondaryColor)
                .fixedSize(horizontal: false, vertical: true)

            Text(stats.topProcessText)
                .font(.system(size: 11))
                .foregroundColor(.white)

            Divider().overlay(Color.white.opacity(0.15))

            categoryRow(category: "wifi", down: stats.netDownText, up: stats.netUpText)
            categoryRow(category: "internaldrive", down: stats.diskReadText, up: stats.diskWriteText)

            Text(stats.diskCapacityText)
                .font(.system(size: 10))
                .foregroundColor(secondaryColor)

            Spacer(minLength: 0)

            Button(action: stats.freeMemory) {
                Text(stats.freeMemStatus)
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 26)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .disabled(stats.freeMemInProgress)
        }
        .frame(width: 260, height: 190, alignment: .top)
    }

    private func statRow(label: String, value: String, high: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(high ? .red : .white)
        }
    }

    /// A leading category glyph (wifi antenna for network, drive icon for
    /// disk) makes the row identity obvious at a glance — the down/up
    /// arrows alone looked identical between the network and disk rows.
    private func categoryRow(category: String, down: String, up: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: category)
                .font(.system(size: 11))
                .foregroundColor(secondaryColor)
                .frame(width: 14)

            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(secondaryColor)
                Text(down)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(secondaryColor)
                Text(up)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            Spacer()
        }
    }
}
