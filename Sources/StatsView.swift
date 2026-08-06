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

            iconRow(icon: "arrow.down", value: stats.netDownText,
                    icon2: "arrow.up", value2: stats.netUpText)
            iconRow(icon: "arrow.down.doc", value: stats.diskReadText,
                    icon2: "arrow.up.doc", value2: stats.diskWriteText)

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

    /// Network row: down/up. Disk row: read/write. Same layout, different icons.
    private func iconRow(icon: String, value: String, icon2: String, value2: String) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(secondaryColor)
                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            HStack(spacing: 4) {
                Image(systemName: icon2)
                    .font(.system(size: 10))
                    .foregroundColor(secondaryColor)
                Text(value2)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            Spacer()
        }
    }
}
