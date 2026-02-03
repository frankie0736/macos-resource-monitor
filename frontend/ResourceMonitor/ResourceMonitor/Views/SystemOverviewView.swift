import SwiftUI

struct SystemOverviewView: View {
    let systemInfo: SystemInfo?

    var body: some View {
        VStack(spacing: 6) {
            if let info = systemInfo {
                ResourceRow(
                    label: "CPU",
                    value: info.cpu.usagePercent,
                    detail: "\(info.cpu.coreCount)C"
                )

                ResourceRow(
                    label: "MEM",
                    value: info.memory.usagePercent,
                    detail: String(format: "%.0fG", info.memory.totalGB)
                )

                ResourceRow(
                    label: "DSK",
                    value: info.disk.usagePercent,
                    detail: String(format: "%.0fG", info.disk.totalGB)
                )

                NetworkRow(network: info.network)
            } else {
                Text("LOADING...")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.matrixDarkGreen)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct ResourceRow: View {
    let label: String
    let value: Double
    let detail: String

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color.matrixDarkGreen)
                .frame(width: 28, alignment: .leading)

            // Matrix-style progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.matrixGreen.opacity(0.1))

                    // Progress
                    Rectangle()
                        .fill(colorForPercent(value))
                        .frame(width: geometry.size.width * min(value / 100, 1.0))

                    // Scanline effect
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.1), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(value / 100, 1.0))
                }
            }
            .frame(height: 10)
            .cornerRadius(2)

            Text(String(format: "%02.0f%%", value))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(colorForPercent(value))
                .frame(width: 32, alignment: .trailing)

            Text(detail)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(Color.matrixDarkGreen)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private func colorForPercent(_ percent: Double) -> Color {
        if percent >= 90 {
            return .red
        } else if percent >= 70 {
            return .orange
        } else {
            return Color.matrixGreen
        }
    }
}

struct NetworkRow: View {
    let network: NetworkInfo

    var body: some View {
        HStack(spacing: 6) {
            Text("NET")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(Color.matrixDarkGreen)
                .frame(width: 28, alignment: .leading)

            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Text("↑")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.matrixGreen)
                    Text(formatBytes(network.bytesSentPerSec))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.matrixGreen)
                }

                HStack(spacing: 2) {
                    Text("↓")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.matrixGreen)
                    Text(formatBytes(network.bytesRecvPerSec))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Color.matrixGreen)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let kb = Double(bytes) / 1024
        let mb = kb / 1024

        if mb >= 1 {
            return String(format: "%.1fM", mb)
        } else if kb >= 1 {
            return String(format: "%.0fK", kb)
        } else {
            return String(format: "%dB", bytes)
        }
    }
}

struct CustomProgressStyle: ProgressViewStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.matrixGreen.opacity(0.1))

                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0))
            }
        }
    }
}
