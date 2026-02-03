import SwiftUI

// Matrix green color
extension Color {
    static let matrixGreen = Color(red: 0, green: 1, blue: 0.4)
    static let matrixDarkGreen = Color(red: 0, green: 0.6, blue: 0.2)
    static let matrixBg = Color(red: 0.05, green: 0.05, blue: 0.05)
}

struct ContentView: View {
    @StateObject private var viewModel = MonitorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Title bar with purge button
            titleBar

            // System overview
            SystemOverviewView(systemInfo: viewModel.systemInfo)

            // Alerts (if any)
            if !viewModel.alerts.isEmpty {
                AlertBannerView(alerts: viewModel.alerts)
            }

            // Process list
            ScrollView {
                ProcessListView(processes: viewModel.processes) { process in
                    Task {
                        await viewModel.killProcess(process)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 280, height: 420)
        .background(Color.matrixBg.opacity(0.95))
    }

    private var titleBar: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(viewModel.isConnected ? Color.matrixGreen : Color.red)
                .frame(width: 6, height: 6)
                .shadow(color: viewModel.isConnected ? Color.matrixGreen : Color.red, radius: 3)

            Text("SYSTEM")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color.matrixGreen)

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.red)
                    .lineLimit(1)
            }

            // Purge button - small icon
            Button(action: {
                Task {
                    await viewModel.purgeCache()
                }
            }) {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.matrixDarkGreen)
            }
            .buttonStyle(.plain)
            .help("Purge Memory")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

#Preview {
    ContentView()
}
