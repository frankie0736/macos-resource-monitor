package api

import (
	"fmt"
	"log"
	"net/http"

	"github.com/fx/resource-monitor/handlers"
	"github.com/fx/resource-monitor/services"
)

type Server struct {
	port           int
	monitor        *services.Monitor
	processService *services.ProcessService
}

func NewServer(port int) *Server {
	return &Server{
		port:           port,
		monitor:        services.NewMonitor(),
		processService: services.NewProcessService(),
	}
}

func (s *Server) Start() error {
	mux := http.NewServeMux()

	// Initialize handlers
	systemHandler := handlers.NewSystemHandler(s.monitor)
	processHandler := handlers.NewProcessHandler(s.processService)
	actionsHandler := handlers.NewActionsHandler(s.processService)

	// Routes
	mux.HandleFunc("/api/system", cors(systemHandler.GetSystemInfo))
	mux.HandleFunc("/api/alerts", cors(systemHandler.GetAlerts))
	mux.HandleFunc("/api/processes", cors(processHandler.GetProcesses))
	mux.HandleFunc("/api/process/kill", cors(actionsHandler.KillProcess))
	mux.HandleFunc("/api/cache/purge", cors(actionsHandler.PurgeCache))

	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	addr := fmt.Sprintf("127.0.0.1:%d", s.port)
	log.Printf("Starting server on %s", addr)

	return http.ListenAndServe(addr, mux)
}

// cors wraps a handler with CORS headers for local development
func cors(handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		handler(w, r)
	}
}
