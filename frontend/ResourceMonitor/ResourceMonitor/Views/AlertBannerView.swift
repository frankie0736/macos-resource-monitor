import SwiftUI

struct AlertBannerView: View {
    let alerts: [Alert]

    var body: some View {
        if !alerts.isEmpty {
            VStack(spacing: 4) {
                ForEach(alerts) { alert in
                    AlertRow(alert: alert)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}

struct AlertRow: View {
    let alert: Alert

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconForLevel(alert.level))
                .font(.system(size: 11))
                .foregroundColor(colorForLevel(alert.level))

            Text(alert.message)
                .font(.system(size: 11))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(colorForLevel(alert.level).opacity(0.15))
        .cornerRadius(4)
    }

    private func iconForLevel(_ level: String) -> String {
        switch level {
        case "critical": return "exclamationmark.triangle.fill"
        case "warning": return "exclamationmark.triangle"
        default: return "info.circle"
        }
    }

    private func colorForLevel(_ level: String) -> Color {
        switch level {
        case "critical": return .red
        case "warning": return .orange
        default: return .blue
        }
    }
}
