package models

// SystemInfo represents overall system resource usage
type SystemInfo struct {
	CPU     CPUInfo     `json:"cpu"`
	Memory  MemoryInfo  `json:"memory"`
	Disk    DiskInfo    `json:"disk"`
	Network NetworkInfo `json:"network"`
}

type CPUInfo struct {
	UsagePercent float64 `json:"usage_percent"`
	CoreCount    int     `json:"core_count"`
}

type MemoryInfo struct {
	UsagePercent float64 `json:"usage_percent"`
	TotalGB      float64 `json:"total_gb"`
	UsedGB       float64 `json:"used_gb"`
	AvailableGB  float64 `json:"available_gb"`
}

type DiskInfo struct {
	UsagePercent float64 `json:"usage_percent"`
	TotalGB      float64 `json:"total_gb"`
	UsedGB       float64 `json:"used_gb"`
	FreeGB       float64 `json:"free_gb"`
}

type NetworkInfo struct {
	BytesSentPerSec uint64 `json:"bytes_sent_per_sec"`
	BytesRecvPerSec uint64 `json:"bytes_recv_per_sec"`
}

// ProcessInfo represents a single process or grouped application
type ProcessInfo struct {
	PID           int32   `json:"pid"`
	Name          string  `json:"name"`
	CPUPercent    float64 `json:"cpu_percent"`
	MemoryMB      float64 `json:"memory_mb"`
	ChildCount    int     `json:"child_count,omitempty"`    // for grouped processes
	ChildPIDs     []int32 `json:"child_pids,omitempty"`     // for grouped processes
	IsGrouped     bool    `json:"is_grouped,omitempty"`
}

// Alert represents a system alert/warning
type Alert struct {
	Level   string `json:"level"`   // "warning", "critical"
	Message string `json:"message"`
	Type    string `json:"type"`    // "memory", "cpu", "disk"
}

// KillRequest represents a request to kill a process
type KillRequest struct {
	PID             int32 `json:"pid"`
	Force           bool  `json:"force"`            // SIGKILL vs SIGTERM
	IncludeChildren bool  `json:"include_children"` // kill child processes too
}

// APIResponse is a generic response wrapper
type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}
