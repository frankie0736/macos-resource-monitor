import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType = .buffered, defer flag: Bool = false) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView], backing: backing, defer: flag)

        // Desktop widget properties - sits at desktop level like wallpaper/icons
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        self.isMovableByWindowBackground = true
        self.isMovable = true
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = false

        // Make it semi-transparent with dark background
        self.isOpaque = false
        self.backgroundColor = NSColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 0.9)
        self.alphaValue = 0.92

        // Visual effect (dark frosted glass - Matrix style)
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .dark
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.appearance = NSAppearance(named: .darkAqua)
        visualEffect.frame = NSRect(origin: .zero, size: contentRect.size)
        visualEffect.autoresizingMask = [.width, .height]

        self.contentView = visualEffect

        // Hide window buttons by default
        hideWindowButtons()

        // Track mouse for hover effects
        setupHoverTracking()
    }

    private func hideWindowButtons() {
        standardWindowButton(.closeButton)?.alphaValue = 0
        standardWindowButton(.miniaturizeButton)?.alphaValue = 0
        standardWindowButton(.zoomButton)?.alphaValue = 0
    }

    private func showWindowButtons() {
        standardWindowButton(.closeButton)?.alphaValue = 1
        standardWindowButton(.miniaturizeButton)?.alphaValue = 1
        standardWindowButton(.zoomButton)?.alphaValue = 1
    }

    private func setupHoverTracking() {
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView?.addTrackingArea(trackingArea)
    }

    override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 0.98
        }
        showWindowButtons()
    }

    override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 0.92
        }
        hideWindowButtons()
    }

    // Allow window to become key but not main
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - SwiftUI Bridge
struct FloatingPanelController {
    static func createPanel<Content: View>(content: Content, frame: NSRect = NSRect(x: 100, y: 100, width: 280, height: 450)) -> NSPanel {
        let panel = FloatingPanel(contentRect: frame)

        let hostingView = NSHostingView(rootView: content)
        // Use bounds (origin 0,0) not frame (which includes window position)
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        hostingView.autoresizingMask = [.width, .height]

        if let visualEffectView = panel.contentView as? NSVisualEffectView {
            visualEffectView.addSubview(hostingView)
        }

        return panel
    }
}
