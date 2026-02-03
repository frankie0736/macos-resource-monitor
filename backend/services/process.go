package services

import (
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"syscall"

	"github.com/fx/resource-monitor/models"
	"github.com/shirou/gopsutil/v4/process"
)

// Version pattern to detect if name looks like a version number
var versionPattern = regexp.MustCompile(`^\d+\.\d+(\.\d+)?$`)

type ProcessService struct{}

func NewProcessService() *ProcessService {
	return &ProcessService{}
}

// GetProcesses returns top N processes, optionally grouped by application
func (s *ProcessService) GetProcesses(sortBy string, limit int, grouped bool) ([]models.ProcessInfo, error) {
	procs, err := process.Processes()
	if err != nil {
		return nil, err
	}

	var procInfos []models.ProcessInfo

	for _, p := range procs {
		name := s.getProcessName(p)
		if name == "" {
			continue
		}

		cpuPercent, _ := p.CPUPercent()
		memInfo, err := p.MemoryInfo()
		if err != nil {
			continue
		}

		memMB := float64(memInfo.RSS) / (1024 * 1024)

		procInfos = append(procInfos, models.ProcessInfo{
			PID:        p.Pid,
			Name:       name,
			CPUPercent: cpuPercent,
			MemoryMB:   memMB,
		})
	}

	if grouped {
		procInfos = s.groupByApplication(procInfos)
	}

	// Sort
	switch sortBy {
	case "memory", "mem":
		sort.Slice(procInfos, func(i, j int) bool {
			return procInfos[i].MemoryMB > procInfos[j].MemoryMB
		})
	default: // "cpu" or default
		sort.Slice(procInfos, func(i, j int) bool {
			return procInfos[i].CPUPercent > procInfos[j].CPUPercent
		})
	}

	// Limit
	if limit > 0 && limit < len(procInfos) {
		procInfos = procInfos[:limit]
	}

	return procInfos, nil
}

// groupByApplication merges processes belonging to the same application
func (s *ProcessService) groupByApplication(procs []models.ProcessInfo) []models.ProcessInfo {
	groups := make(map[string]*models.ProcessInfo)

	for _, p := range procs {
		appName := s.normalizeAppName(p.Name)

		if existing, ok := groups[appName]; ok {
			existing.CPUPercent += p.CPUPercent
			existing.MemoryMB += p.MemoryMB
			existing.ChildCount++
			existing.ChildPIDs = append(existing.ChildPIDs, p.PID)
		} else {
			newProc := models.ProcessInfo{
				PID:        p.PID,
				Name:       appName,
				CPUPercent: p.CPUPercent,
				MemoryMB:   p.MemoryMB,
				ChildCount: 1,
				ChildPIDs:  []int32{p.PID},
				IsGrouped:  true,
			}
			groups[appName] = &newProc
		}
	}

	result := make([]models.ProcessInfo, 0, len(groups))
	for _, g := range groups {
		result = append(result, *g)
	}

	return result
}

// getProcessName gets a reliable process name, falling back to exe path if Name() returns garbage
func (s *ProcessService) getProcessName(p *process.Process) string {
	name, _ := p.Name()

	// If name looks like a version number (e.g., "2.1.17"), try to get real name
	if name == "" || versionPattern.MatchString(name) {
		// Try executable path
		if exe, err := p.Exe(); err == nil && exe != "" {
			name = filepath.Base(exe)
		}
	}

	// Still looks like version? Try cmdline
	if versionPattern.MatchString(name) {
		if cmdline, err := p.Cmdline(); err == nil && cmdline != "" {
			parts := strings.Fields(cmdline)
			if len(parts) > 0 {
				name = filepath.Base(parts[0])
			}
		}
	}

	return name
}

// normalizeAppName extracts the main application name from process names
func (s *ProcessService) normalizeAppName(name string) string {
	// Handle common helper process patterns
	patterns := map[string]string{
		"Google Chrome Helper": "Chrome",
		"Google Chrome":        "Chrome",
		"Chrome Helper":        "Chrome",
		"Safari Web Content":   "Safari",
		"Safari Networking":    "Safari",
		"Code Helper":          "VS Code",
		"Electron Helper":      "Electron",
		"Firefox Content":      "Firefox",
		"plugin-container":     "Firefox",
	}

	for pattern, normalized := range patterns {
		if strings.Contains(name, pattern) {
			return normalized
		}
	}

	// Remove common suffixes
	suffixes := []string{" Helper", " Agent", " Renderer", " GPU", " Utility"}
	for _, suffix := range suffixes {
		if strings.HasSuffix(name, suffix) {
			return strings.TrimSuffix(name, suffix)
		}
	}

	return name
}

// KillProcess kills a process by PID
func (s *ProcessService) KillProcess(req models.KillRequest) error {
	signal := syscall.SIGTERM
	if req.Force {
		signal = syscall.SIGKILL
	}

	if req.IncludeChildren {
		// Kill children first
		procs, _ := process.Processes()
		for _, p := range procs {
			ppid, err := p.Ppid()
			if err == nil && ppid == req.PID {
				syscall.Kill(int(p.Pid), signal)
			}
		}
	}

	return syscall.Kill(int(req.PID), signal)
}

// PurgeCache runs the macOS purge command with admin privileges
func (s *ProcessService) PurgeCache() error {
	cmd := exec.Command("osascript", "-e",
		`do shell script "purge" with administrator privileges`)
	return cmd.Run()
}
