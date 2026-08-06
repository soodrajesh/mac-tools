import SwiftUI

struct StatsView: View {
    @ObservedObject var stats: StatsController

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            statRow(label: "CPU", value: stats.cpuText, high: stats.cpuHigh)
            statRow(label: "Memory", value: stats.memText, high: stats.memHigh)

            Text(stats.memDetail)
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                .fixedSize(horizontal: false, vertical: true)

            Text(stats.topProcessText)
                .font(.system(size: 11))
                .foregroundColor(.white)

            Spacer()

            Button(action: stats.freeMemory) {
                Text(stats.freeMemStatus)
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
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
}
