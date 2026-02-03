import SwiftUI

struct ProcessListView: View {
    let processes: [ProcessInfo]
    let onKill: (ProcessInfo) -> Void

    var body: some View {
        VStack(spacing: 2) {
            // Header
            HStack(spacing: 4) {
                Text("PROCESS")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("CPU")
                    .frame(width: 36, alignment: .trailing)
                Text("MEM")
                    .frame(width: 50, alignment: .trailing)
                Spacer().frame(width: 18)
            }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundColor(Color.matrixDarkGreen)
            .padding(.horizontal, 6)
            .padding(.bottom, 4)

            ForEach(processes) { process in
                ProcessRow(process: process, onKill: { onKill(process) })
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

struct ProcessRow: View {
    let process: ProcessInfo
    let onKill: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            // Process name
            Text(process.name)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.matrixGreen)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // CPU percent
            Text(String(format: "%02.0f%%", process.cpuPercent))
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(colorForCPU(process.cpuPercent))
                .frame(width: 36, alignment: .trailing)

            // Memory
            Text(formatMemory(process.memoryMB))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(Color.matrixDarkGreen)
                .frame(width: 50, alignment: .trailing)

            // Kill button (shown on hover)
            Button(action: onKill) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .frame(width: 18)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(isHovered ? Color.matrixGreen.opacity(0.1) : Color.clear)
        .cornerRadius(2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }

    private func colorForCPU(_ percent: Double) -> Color {
        if percent >= 50 {
            return .red
        } else if percent >= 25 {
            return .orange
        } else {
            return Color.matrixGreen
        }
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1fG", mb / 1024)
        } else {
            return String(format: "%.0fM", mb)
        }
    }
}
