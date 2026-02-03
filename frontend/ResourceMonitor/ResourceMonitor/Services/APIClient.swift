import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL = "http://127.0.0.1:19527"
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
    }

    // MARK: - System Info
    func fetchSystemInfo() async throws -> SystemInfo {
        let url = URL(string: "\(baseURL)/api/system")!
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(APIResponse<SystemInfo>.self, from: data)

        guard response.success, let info = response.data else {
            throw APIError.serverError(response.error ?? "Unknown error")
        }
        return info
    }

    // MARK: - Processes
    func fetchProcesses(sortBy: String = "cpu", limit: Int = 10, grouped: Bool = true) async throws -> [ProcessInfo] {
        var components = URLComponents(string: "\(baseURL)/api/processes")!
        components.queryItems = [
            URLQueryItem(name: "sort", value: sortBy),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "group", value: grouped ? "true" : "false")
        ]

        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(APIResponse<[ProcessInfo]>.self, from: data)

        guard response.success, let procs = response.data else {
            throw APIError.serverError(response.error ?? "Unknown error")
        }
        return procs
    }

    // MARK: - Alerts
    func fetchAlerts() async throws -> [Alert] {
        let url = URL(string: "\(baseURL)/api/alerts")!
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(APIResponse<[Alert]>.self, from: data)

        guard response.success else {
            throw APIError.serverError(response.error ?? "Unknown error")
        }
        // Return empty array if data is null (no alerts)
        return response.data ?? []
    }

    // MARK: - Kill Process
    func killProcess(pid: Int32, force: Bool = false, includeChildren: Bool = true) async throws {
        let url = URL(string: "\(baseURL)/api/process/kill")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = KillRequest(pid: pid, force: force, includeChildren: includeChildren)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(APIResponse<[String: Bool]>.self, from: data)

        guard response.success else {
            throw APIError.serverError(response.error ?? "Failed to kill process")
        }
    }

    // MARK: - Purge Cache
    func purgeCache() async throws {
        let url = URL(string: "\(baseURL)/api/cache/purge")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(APIResponse<[String: Bool]>.self, from: data)

        guard response.success else {
            throw APIError.serverError(response.error ?? "Failed to purge cache")
        }
    }
}

enum APIError: LocalizedError {
    case serverError(String)
    case networkError

    var errorDescription: String? {
        switch self {
        case .serverError(let msg): return msg
        case .networkError: return "Network connection failed"
        }
    }
}
