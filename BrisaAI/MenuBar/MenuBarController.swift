import AppKit

final class MenuBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onOpenBrisa: () -> Void
    private let onOpenSettings: () -> Void
    private let onOpenLogs: () -> Void
    private let onClearLogs: () -> Void
    private let onQuit: () -> Void

    // Индикатор активности
    private var isActive = false { didSet { updateIcon() } }

    init(onOpenBrisa: @escaping () -> Void,
         onOpenSettings: @escaping () -> Void,
         onOpenLogs: @escaping () -> Void,
         onClearLogs: @escaping () -> Void,
         onQuit: @escaping () -> Void) {
        self.onOpenBrisa = onOpenBrisa
        self.onOpenSettings = onOpenSettings
        self.onOpenLogs = onOpenLogs
        self.onClearLogs = onClearLogs
        self.onQuit = onQuit
        configure()
    }

    private func configure() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Brisa AI")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.addItem(withTitle: "Открыть Brisa", action: #selector(openBrisa), keyEquivalent: "")
        menu.addItem(withTitle: "Настройки…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Открыть логи", action: #selector(openLogs), keyEquivalent: "l")
        menu.addItem(withTitle: "Очистить логи", action: #selector(clearLogs), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Выйти", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    func setActive(_ active: Bool) {
        isActive = active
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let base = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Brisa AI")
        base?.isTemplate = true
        if isActive, let overlay = NSImage(systemSymbolName: "smallcircle.fill.circle", accessibilityDescription: nil) {
            let composed = NSImage(size: NSSize(width: 18, height: 18))
            composed.lockFocus()
            base?.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18))
            overlay.draw(in: NSRect(x: 12, y: 0, width: 6, height: 6))
            composed.unlockFocus()
            button.image = composed
        } else {
            button.image = base
        }
    }

    @objc private func openBrisa() { onOpenBrisa() }
    @objc private func openSettings() { onOpenSettings() }
    @objc private func openLogs() { onOpenLogs() }
    @objc private func clearLogs() { onClearLogs() }
    @objc private func quit() { onQuit() }
}

