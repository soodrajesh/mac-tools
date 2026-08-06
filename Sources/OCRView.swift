import SwiftUI

struct OCRView: View {
    let onCapture: () -> Void
    let onChooseImage: () -> Void
    let isProcessing: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Extract text from screenshots or images")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                .multilineTextAlignment(.center)

            Button(action: onCapture) {
                Label("Capture Region", systemImage: "rectangle.dashed")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            Button(action: onChooseImage) {
                Label("Choose Image", systemImage: "photo")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)

            Spacer()

            Text(isProcessing ? "Processing…" : "Result copies to clipboard")
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.72))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(width: 260, height: 190, alignment: .top)
    }
}
