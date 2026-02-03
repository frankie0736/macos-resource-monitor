import Foundation

// MARK: - API Response
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

// MARK: - System Info
struct SystemInfo: Codable {
    let cpu: CPUInfo
    let memory: MemoryInfo
    let disk: DiskInfo
    let network: NetworkInfo
}

struct CPUInfo: Codable {
    let usagePercent: Double
    let coreCount: Int

    enum CodingKeys: String, CodingKey {
        case usagePercent = "usage_percent"
        case coreCount = "core_count"
    }
}

struct MemoryInfo: Codable {
    let usagePercent: Double
    let totalGB: Double
    let usedGB: Double
    let availableGB: Double

    enum CodingKeys: String, CodingKey {
        case usagePercent = "usage_percent"
        case totalGB = "total_gb"
        case usedGB = "used_gb"
        case availableGB = "available_gb"
    }
}

struct DiskInfo: Codable {
    let usagePercent: Double
    let totalGB: Double
    let usedGB: Double
    let freeGB: Double

    enum CodingKeys: String, CodingKey {
        case usagePercent = "usage_percent"
        case totalGB = "total_gb"
        case usedGB = "used_gb"
        case freeGB = "free_gb"
    }
}

struct NetworkInfo: Codable {
    let bytesSentPerSec: UInt64
    let bytesRecvPerSec: UInt64

    enum CodingKeys: String, CodingKey {
        case bytesSentPerSec = "bytes_sent_per_sec"
        case bytesRecvPerSec = "bytes_recv_per_sec"
    }
}

// MARK: - Process Info
struct ProcessInfo: Codable, Identifiable {
    let pid: Int32
    let name: String
    let cpuPercent: Double
    let memoryMB: Double
    let childCount: Int?
    let childPIDs: [Int32]?
    let isGrouped: Bool?

    var id: Int32 { pid }

    enum CodingKeys: String, CodingKey {
        case pid
        case name
        case cpuPercent = "cpu_percent"
        case memoryMB = "memory_mb"
        case childCount = "child_count"
        case childPIDs = "child_pids"
        case isGrouped = "is_grouped"
    }
}

// MARK: - Alert
struct Alert: Codable, Identifiable {
    let level: String
    let message: String
    let type: String

    var id: String { "\(type)-\(level)" }
}

// MARK: - Kill Request
struct KillRequest: Codable {
    let pid: Int32
    let force: Bool
    let includeChildren: Bool

    enum CodingKeys: String, CodingKey {
        case pid
        case force
        case includeChildren = "include_children"
    }
}
