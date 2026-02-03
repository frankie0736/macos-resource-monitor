package handlers

import (
	"net/http"
	"strconv"

	"github.com/fx/resource-monitor/models"
	"github.com/fx/resource-monitor/services"
)

type ProcessHandler struct {
	svc *services.ProcessService
}

func NewProcessHandler(svc *services.ProcessService) *ProcessHandler {
	return &ProcessHandler{svc: svc}
}

// GetProcesses handles GET /api/processes
func (h *ProcessHandler) GetProcesses(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()

	sortBy := query.Get("sort")
	if sortBy == "" {
		sortBy = "cpu"
	}

	limit := 5
	if l := query.Get("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	grouped := query.Get("group") == "true"

	procs, err := h.svc.GetProcesses(sortBy, limit, grouped)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    procs,
	})
}
