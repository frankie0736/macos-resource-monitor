package services

import (
	"sync"
	"time"

	"github.com/fx/resource-monitor/models"
	"github.com/shirou/gopsutil/v4/cpu"
	"github.com/shirou/gopsutil/v4/disk"
	"github.com/shirou/gopsutil/v4/mem"
	"github.com/shirou/gopsutil/v4/net"
)

type Monitor struct {
	mu              sync.RWMutex
	lastNetStats    net.IOCountersStat
	lastNetTime     time.Time
	networkInitDone bool
}

func NewMonitor() *Monitor {
	m := &Monitor{}
	// Initialize network baseline
	m.initNetworkStats()
	return m
}

func (m *Monitor) initNetworkStats() {
	stats, err := net.IOCounters(false)
	if err == nil && len(stats) > 0 {
		m.lastNetStats = stats[0]
		m.lastNetTime = time.Now()
		m.networkInitDone = true
	}
}

func (m *Monitor) GetSystemInfo() (*models.SystemInfo, error) {
	info := &models.SystemInfo{}

	// CPU
	cpuPercent, err := cpu.Percent(0, false)
	if err == nil && len(cpuPercent) > 0 {
		info.CPU.UsagePercent = cpuPercent[0]
	}
	cpuCount, err := cpu.Counts(true) // logical cores
	if err == nil {
		info.CPU.CoreCount = cpuCount
	}

	// Memory
	memStat, err := mem.VirtualMemory()
	if err == nil {
		info.Memory.UsagePercent = memStat.UsedPercent
		info.Memory.TotalGB = float64(memStat.Total) / (1024 * 1024 * 1024)
		info.Memory.UsedGB = float64(memStat.Used) / (1024 * 1024 * 1024)
		info.Memory.AvailableGB = float64(memStat.Available) / (1024 * 1024 * 1024)
	}

	// Disk (root partition)
	diskStat, err := disk.Usage("/")
	if err == nil {
		info.Disk.UsagePercent = diskStat.UsedPercent
		info.Disk.TotalGB = float64(diskStat.Total) / (1024 * 1024 * 1024)
		info.Disk.UsedGB = float64(diskStat.Used) / (1024 * 1024 * 1024)
		info.Disk.FreeGB = float64(diskStat.Free) / (1024 * 1024 * 1024)
	}

	// Network (calculate rate)
	info.Network = m.calculateNetworkRate()

	return info, nil
}

func (m *Monitor) calculateNetworkRate() models.NetworkInfo {
	m.mu.Lock()
	defer m.mu.Unlock()

	netInfo := models.NetworkInfo{}

	stats, err := net.IOCounters(false)
	if err != nil || len(stats) == 0 {
		return netInfo
	}

	currentStats := stats[0]
	now := time.Now()

	if m.networkInitDone {
		duration := now.Sub(m.lastNetTime).Seconds()
		if duration > 0 {
			netInfo.BytesSentPerSec = uint64(float64(currentStats.BytesSent-m.lastNetStats.BytesSent) / duration)
			netInfo.BytesRecvPerSec = uint64(float64(currentStats.BytesRecv-m.lastNetStats.BytesRecv) / duration)
		}
	}

	m.lastNetStats = currentStats
	m.lastNetTime = now
	m.networkInitDone = true

	return netInfo
}

func (m *Monitor) GetAlerts() []models.Alert {
	info, err := m.GetSystemInfo()
	if err != nil {
		return nil
	}

	var alerts []models.Alert

	// Memory alerts
	if info.Memory.UsagePercent >= 90 {
		alerts = append(alerts, models.Alert{
			Level:   "critical",
			Type:    "memory",
			Message: "内存使用率过高 (>90%)",
		})
	} else if info.Memory.UsagePercent >= 80 {
		alerts = append(alerts, models.Alert{
			Level:   "warning",
			Type:    "memory",
			Message: "内存使用率较高 (>80%)",
		})
	}

	// CPU alerts
	if info.CPU.UsagePercent >= 90 {
		alerts = append(alerts, models.Alert{
			Level:   "critical",
			Type:    "cpu",
			Message: "CPU 使用率过高 (>90%)",
		})
	} else if info.CPU.UsagePercent >= 80 {
		alerts = append(alerts, models.Alert{
			Level:   "warning",
			Type:    "cpu",
			Message: "CPU 使用率较高 (>80%)",
		})
	}

	// Disk alerts
	if info.Disk.UsagePercent >= 95 {
		alerts = append(alerts, models.Alert{
			Level:   "critical",
			Type:    "disk",
			Message: "磁盘空间严重不足 (>95%)",
		})
	} else if info.Disk.UsagePercent >= 85 {
		alerts = append(alerts, models.Alert{
			Level:   "warning",
			Type:    "disk",
			Message: "磁盘空间不足 (>85%)",
		})
	}

	return alerts
}
