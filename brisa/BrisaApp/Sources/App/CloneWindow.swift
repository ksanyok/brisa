import Cocoa
import SwiftUI

/// Окно «клон» отображает поток из Agent Space и текущий шаг.
final class CloneWindow {
    static let shared = CloneWindow()
    private var window: NSWindow?

    private init() {}

    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: CloneView())
            let w = NSWindow(contentViewController: controller)
            w.title = "Clone View"
            w.styleMask = [.titled, .closable, .resizable]
            w.setFrame(NSRect(x: 0, y: 0, width: 800, height: 600), display: false)
            w.isReleasedWhenClosed = false
            self.window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}