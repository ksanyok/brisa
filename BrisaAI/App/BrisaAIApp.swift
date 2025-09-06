import SwiftUI
import AppKit

@main
struct BrisaAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Используем собственные окна, системное Settings скрываем.
        Settings { EmptyView() }
    }
}

