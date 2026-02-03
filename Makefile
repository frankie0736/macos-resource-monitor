.PHONY: all backend frontend run-backend run-frontend clean check-xcode run pkg

# Default target
all: backend frontend

# Check Xcode installation
check-xcode:
	@xcode-select -p > /dev/null 2>&1 || (echo "Error: Xcode not found. Run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" && exit 1)
	@echo "Xcode found at: $$(xcode-select -p)"

# Build Go backend
backend:
	cd backend && go build -o resource-monitor .

# Build Swift frontend
frontend: check-xcode
	cd frontend/ResourceMonitor && xcodebuild -project ResourceMonitor.xcodeproj -scheme ResourceMonitor -configuration Release build SYMROOT=build

# Run Go backend
run-backend: backend
	cd backend && ./resource-monitor

# Run Swift frontend (after building)
run-frontend:
	open frontend/ResourceMonitor/build/Release/ResourceMonitor.app

# Run both (backend in background, frontend in foreground)
run: backend frontend
	@echo "Starting backend..."
	cd backend && ./resource-monitor &
	@sleep 1
	@echo "Starting frontend..."
	open frontend/ResourceMonitor/build/Release/ResourceMonitor.app

# Clean build artifacts
clean:
	rm -f backend/resource-monitor
	rm -rf frontend/ResourceMonitor/build
	rm -rf frontend/ResourceMonitor/DerivedData

# Development: run backend with auto-rebuild
dev-backend:
	cd backend && go run main.go

# Test API
test-api:
	@echo "Testing /api/system..."
	curl -s http://127.0.0.1:19527/api/system | jq .
	@echo "\nTesting /api/processes..."
	curl -s "http://127.0.0.1:19527/api/processes?sort=cpu&limit=5&group=true" | jq .
	@echo "\nTesting /api/alerts..."
	curl -s http://127.0.0.1:19527/api/alerts | jq .

# Stop backend
stop:
	@pkill -f resource-monitor 2>/dev/null || true
	@echo "Backend stopped"

# Install (copy binaries and setup auto-start)
install: all
	@echo "Installing backend to /usr/local/bin..."
	cp backend/resource-monitor /usr/local/bin/
	@echo "Installing app to /Applications..."
	cp -r frontend/ResourceMonitor/build/Release/ResourceMonitor.app /Applications/
	@echo "Installing LaunchAgent for auto-start..."
	cp com.fx.resource-monitor.plist ~/Library/LaunchAgents/
	launchctl load ~/Library/LaunchAgents/com.fx.resource-monitor.plist
	@echo "Adding app to Login Items..."
	osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/ResourceMonitor.app", hidden:false}'
	@echo "Installation complete! Backend will start on boot, app added to Login Items."

# Build PKG installer
pkg: all
	@echo "Preparing installer payload..."
	rm -rf installer/payload installer/*.pkg ResourceMonitor-1.0.0.pkg
	mkdir -p installer/payload/Applications
	mkdir -p installer/payload/usr/local/bin
	mkdir -p installer/payload/Library/LaunchAgents
	cp -R frontend/ResourceMonitor/build/Release/ResourceMonitor.app installer/payload/Applications/
	cp backend/resource-monitor installer/payload/usr/local/bin/
	cp com.fx.resource-monitor.plist installer/payload/Library/LaunchAgents/
	@echo "Building package..."
	pkgbuild --root installer/payload \
		--scripts installer/scripts \
		--identifier com.fx.resource-monitor \
		--version 1.0.0 \
		--install-location / \
		--ownership recommended \
		--component-plist installer/component.plist \
		ResourceMonitor-1.0.0.pkg
	@echo "Cleaning build directory to prevent relocation on install..."
	rm -rf frontend/ResourceMonitor/build
	@echo "✅ PKG installer created: ResourceMonitor-1.0.0.pkg"

# Uninstall
uninstall:
	@echo "Stopping services..."
	-launchctl unload ~/Library/LaunchAgents/com.fx.resource-monitor.plist 2>/dev/null
	-pkill -f resource-monitor 2>/dev/null
	-pkill -f ResourceMonitor 2>/dev/null
	@echo "Removing files..."
	rm -f /usr/local/bin/resource-monitor
	rm -f ~/Library/LaunchAgents/com.fx.resource-monitor.plist
	rm -rf /Applications/ResourceMonitor.app
	osascript -e 'tell application "System Events" to delete login item "ResourceMonitor"' 2>/dev/null || true
	@echo "Uninstall complete."

# Help
help:
	@echo "Available targets:"
	@echo "  all          - Build both backend and frontend"
	@echo "  backend      - Build Go backend"
	@echo "  frontend     - Build Swift frontend (requires Xcode)"
	@echo "  run          - Build and run both backend and frontend"
	@echo "  run-backend  - Build and run Go backend"
	@echo "  run-frontend - Run Swift frontend app"
	@echo "  dev-backend  - Run backend in development mode"
	@echo "  test-api     - Test API endpoints (requires backend running)"
	@echo "  stop         - Stop backend process"
	@echo "  clean        - Remove build artifacts"
	@echo "  check-xcode  - Verify Xcode installation"
	@echo "  install      - Install app and setup auto-start on boot"
	@echo "  uninstall    - Remove app and auto-start config"
