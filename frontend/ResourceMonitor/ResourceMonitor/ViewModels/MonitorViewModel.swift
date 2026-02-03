import Foundation
import Combine

@MainActor
class MonitorViewModel: ObservableObject {
    @Published var systemInfo: SystemInfo?
    @Published var processes: [ProcessInfo] = []
    @Published var alerts: [Alert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isConnected = false

    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 2.0

    init() {
        startRefreshing()
    }

    deinit {
        refreshTask?.cancel()
    }

    func startRefreshing() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
            }
        }
    }

    func refresh() async {
        do {
            async let sysTask = APIClient.shared.fetchSystemInfo()
            async let procTask = APIClient.shared.fetchProcesses()
            async let alertTask = APIClient.shared.fetchAlerts()

            let (sys, procs, alerts) = try await (sysTask, procTask, alertTask)

            self.systemInfo = sys
            self.processes = procs
            self.alerts = alerts
            self.isConnected = true
            self.errorMessage = nil
        } catch {
            self.isConnected = false
            self.errorMessage = error.localizedDescription
        }
    }

    func killProcess(_ process: ProcessInfo, force: Bool = false) async {
        do {
            // If grouped, kill all child processes
            if let childPIDs = process.childPIDs, !childPIDs.isEmpty {
                for pid in childPIDs {
                    try await APIClient.shared.killProcess(pid: pid, force: force, includeChildren: true)
                }
            } else {
                try await APIClient.shared.killProcess(pid: process.pid, force: force, includeChildren: true)
            }
            // Refresh after kill
            await refresh()
        } catch {
            self.errorMessage = "Failed to kill process: \(error.localizedDescription)"
        }
    }

    func purgeCache() async {
        do {
            try await APIClient.shared.purgeCache()
            await refresh()
        } catch {
            self.errorMessage = "Failed to purge cache: \(error.localizedDescription)"
        }
    }
}
