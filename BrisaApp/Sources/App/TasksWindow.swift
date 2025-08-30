import Cocoa
import SwiftUI

/// Окно списка задач, отображает очередь планов агента.
final class TasksWindow {
    /// Общий экземпляр для использования во всём приложении.
    static let shared = TasksWindow()
    private var window: NSWindow?

    private init() {}

    /// Показывает окно со списком задач. Создаёт окно при первом вызове.
    func show() {
        // Создаём окно только один раз, затем просто показываем его
        if window == nil {
            let controller = NSHostingController(rootView: TasksView())
            let w = NSWindow(contentViewController: controller)
            w.title = "Tasks"
            w.styleMask = [.titled, .closable, .resizable]
            // Задаём начальный размер окна и запрещаем освобождение после закрытия
            w.setFrame(NSRect(x: 0, y: 0, width: 400, height: 300), display: false)
            w.isReleasedWhenClosed = false
            self.window = w
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}