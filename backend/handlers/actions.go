package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/fx/resource-monitor/models"
	"github.com/fx/resource-monitor/services"
)

type ActionsHandler struct {
	svc *services.ProcessService
}

func NewActionsHandler(svc *services.ProcessService) *ActionsHandler {
	return &ActionsHandler{svc: svc}
}

// KillProcess handles POST /api/process/kill
func (h *ActionsHandler) KillProcess(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, models.APIResponse{
			Success: false,
			Error:   "method not allowed",
		})
		return
	}

	var req models.KillRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "invalid request body",
		})
		return
	}

	if req.PID <= 0 {
		writeJSON(w, http.StatusBadRequest, models.APIResponse{
			Success: false,
			Error:   "invalid PID",
		})
		return
	}

	if err := h.svc.KillProcess(req); err != nil {
		writeJSON(w, http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    map[string]interface{}{"pid": req.PID, "killed": true},
	})
}

// PurgeCache handles POST /api/cache/purge
func (h *ActionsHandler) PurgeCache(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, models.APIResponse{
			Success: false,
			Error:   "method not allowed",
		})
		return
	}

	if err := h.svc.PurgeCache(); err != nil {
		writeJSON(w, http.StatusInternalServerError, models.APIResponse{
			Success: false,
			Error:   err.Error(),
		})
		return
	}

	writeJSON(w, http.StatusOK, models.APIResponse{
		Success: true,
		Data:    map[string]interface{}{"purged": true},
	})
}
