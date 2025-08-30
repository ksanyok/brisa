import SwiftUI
import AppKit

/// Главная точка входа приложения Brisa.
@main
struct BrisaApp: App {
    /// Делегат приложения, отвечающий за создание пункта в строке меню и управление жизненным циклом.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Используем только окно настроек в разделе «Settings». Остальные окна управляются вручную через AppDelegate.
        Settings {
            SettingsView()
        }
    }
}