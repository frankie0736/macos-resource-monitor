package main

import (
	"log"

	"github.com/fx/resource-monitor/api"
)

const defaultPort = 19527

func main() {
	server := api.NewServer(defaultPort)
	if err := server.Start(); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
