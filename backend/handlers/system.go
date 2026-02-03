package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/fx/resource-monitor/models"
	"github.com/fx/resource-monitor/services"
)

type SystemHandler struct {
	monitor *services.Monitor
}

func NewSystemHandler(monitor *services.Monitor) *SystemHandler {
	return &SystemHandler{monitor: monitor}
}

// GetSystemInfo handles GET /api/system
func (h *SystemHandler) GetSystemInfo(w http.ResponseWriter, r *http.Request) {
	info, err := h.monitor.GetSystemInfo()
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    info,
	})
}

// GetAlerts handles GET /api/alerts
func (h *SystemHandler) GetAlerts(w http.ResponseWriter, r *http.Request) {
	alerts := h.monitor.GetAlerts()

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    alerts,
	})
}

func writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
