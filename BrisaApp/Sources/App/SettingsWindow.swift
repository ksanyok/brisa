import Cocoa
import SwiftUI

/// Окно настроек, открывающее `SettingsView` без использования системы Preferences.
final class SettingsWindow {
    static let shared = SettingsWindow()
    private var window: NSWindow?

    private init() {}

    /// Отображает окно настроек. Если окно ещё не было создано, создаёт его.
    func show() {
        if window == nil {
            let controller = NSHostingController(rootView: SettingsView())
            let w = NSWindow(contentViewController: controller)
            w.title = "Settings"
            w.styleMask = [.titled, .closable, .resizable]
            w.setFrame(NSRect(x: 0, y: 0, width: 500, height: 400), display: false)
            w.isReleasedWhenClosed = false
            self.window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}