import SwiftUI
import AppKit

/// Главная точка входа приложения Brisa.
@main
struct BrisaApp: App {
    /// Делегат приложения, отвечающий за создание пункта в строке меню и управление жизненным циклом.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Пустая группа окон. Не отображается, но необходима для поддержки окна настроек.
        WindowGroup {
            EmptyView()
        }
        // Используем сцены настроек для показа окна Preferences по ⌘, и пункту меню Settings.
        Settings {
            SettingsView()
        }
    }
}