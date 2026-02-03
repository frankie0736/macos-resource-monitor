import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Create the floating panel
        let contentView = ContentView()
        panel = FloatingPanelController.createPanel(
            content: contentView,
            frame: NSRect(x: 100, y: 100, width: 280, height: 450)
        )

        // Position at bottom-right of built-in screen (MacBook display)
        let screen = NSScreen.screens.first { screen in
            // Find built-in display
            screen.localizedName.contains("Built-in") || screen.localizedName.contains("内置")
        } ?? NSScreen.screens.first ?? NSScreen.main

        if let screen = screen {
            let screenFrame = screen.visibleFrame
            let panelWidth: CGFloat = 280
            let panelHeight: CGFloat = 450
            let padding: CGFloat = 30  // Extra padding to avoid Dock

            let x = screenFrame.maxX - panelWidth - padding
            let y = screenFrame.minY + padding

            panel?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel?.orderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
