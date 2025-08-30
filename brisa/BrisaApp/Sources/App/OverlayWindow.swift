import Cocoa
import SwiftUI

/// Окно диалога Brisa Overlay.
final class OverlayWindow {
    static let shared = OverlayWindow()
    private var window: NSWindow?

    private init() {}

    /// Показывает окно поверх всех приложений.
    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: OverlayView())
            let w = NSWindow(contentViewController: controller)
            w.title = "Brisa"
            w.styleMask = [.titled, .closable]
            w.level = .floating
            w.isReleasedWhenClosed = false
            self.window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}