import Cocoa
import SwiftUI

/// Делегат приложения. Создаёт значок в строке меню и управляет окнами.
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Создаём пункт в строке меню
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Brisa")
        item.button?.image?.isTemplate = true
        item.menu = constructMenu()
        self.statusItem = item

        // При старте приложения пытаемся восстановить ранее сохранённый ключ API и настроить движок.
        if let key = UserDefaults.standard.string(forKey: "OpenAIAPIKey"), !key.isEmpty {
            RealtimeManager.shared.configure(apiKey: key)
        }
    }

    private func constructMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Brisa", action: #selector(openOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Clone View", action: #selector(showCloneView), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Tasks", action: #selector(showTasks), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Pause/Resume", action: #selector(togglePause), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        return menu
    }

    // MARK: Menu Actions

    @objc private func openOverlay() {
        OverlayWindow.shared.show()
    }

    @objc private func showCloneView() {
        CloneWindow.shared.show()
    }

    @objc private func showTasks() {
        // TODO: отображать окно со списком задач
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }

    @objc private func togglePause() {
        // TODO: реализовать приостановку/возобновление агентов
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}