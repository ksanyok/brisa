import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!
    private var hotkeyManager = HotkeyManager()

    // Окна
    private var commandPaletteWC: NSWindowController?
    private var settingsWC: NSWindowController?
    private var logsWC: NSWindowController?
    private var consentWC: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        BrisaLogger.shared.info("App launched")

        // Меню бар
        menuBarController = MenuBarController(
            onOpenBrisa: { [weak self] in self?.showCommandPalette() },
            onOpenSettings: { [weak self] in self?.showSettings() },
            onOpenLogs: { [weak self] in self?.showLogs() },
            onClearLogs: { [weak self] in self?.clearLogs() },
            onQuit: { NSApp.terminate(nil) }
        )

        // Глобальный хоткей: ⌥Space по умолчанию
        hotkeyManager.registerDefaultHotkey { [weak self] in
            self?.showCommandPalette()
        }

        // Не показываем мастер разрешений автоматически.
        // Разрешения настраиваются через окно настроек.

        // Индикатор активности в трее
        NotificationCenter.default.addObserver(forName: Orchestrator.busyChanged, object: nil, queue: .main) { [weak self] note in
            let active = (note.userInfo?["active"] as? Bool) ?? false
            self?.menuBarController.setActive(active)
        }
    }

    private func makeWindow<V: View>(title: String, view: V, size: NSSize = NSSize(width: 520, height: 360)) -> NSWindowController {
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = title
        window.setContentSize(size)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        let wc = NSWindowController(window: window)
        return wc
    }

    func showCommandPalette() {
        if let wc = commandPaletteWC { wc.showWindow(nil); wc.window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let view = CommandPaletteWindow(
            onOpenSettings: { [weak self] in self?.showSettings() },
            // Кнопка «Разрешения» ведет в Настройки, где раздел Разрешений.
            onOpenConsent: { [weak self] in self?.showSettings() }
        )
        let wc = makeWindow(title: "Brisa – Команда", view: view, size: NSSize(width: 640, height: 360))
        commandPaletteWC = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSettings() {
        if let wc = settingsWC { wc.showWindow(nil); NSApp.activate(ignoringOtherApps: true); return }
        let view = SettingsWindow()
        let wc = makeWindow(title: "Brisa – Настройки", view: view)
        settingsWC = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showLogs() {
        if let wc = logsWC { wc.showWindow(nil); NSApp.activate(ignoringOtherApps: true); return }
        let view = LogsWindow()
        let wc = makeWindow(title: "Brisa – Логи", view: view, size: NSSize(width: 720, height: 480))
        logsWC = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func clearLogs() {
        BrisaLogger.shared.truncate()
        if let wc = logsWC, let hosting = wc.contentViewController as? NSHostingController<LogsWindow> {
            hosting.rootView.reloadPublisher.send()
        }
    }

    func showConsent() {
        if let wc = consentWC { wc.showWindow(nil); NSApp.activate(ignoringOtherApps: true); return }
        let view = ConsentWindow(onDone: { [weak self] in
            self?.consentWC?.close();
            self?.consentWC = nil
        })
        let wc = makeWindow(title: "Brisa – Разрешения", view: view)
        consentWC = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
