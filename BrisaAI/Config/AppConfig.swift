import Foundation
import SwiftUI

enum AppConfig {
    static var defaultLanguage: String { UserDefaults.standard.string(forKey: "language") ?? "ru" }
    static var defaultVoice: String { UserDefaults.standard.string(forKey: "voice") ?? "none" }
    // Доступные модели для выбора в настройках.
    // Если в списке <= 1, селектор модели скрывается.
    static let availableModels: [String] = [
        "gpt-4o-mini",        // responses
        "gpt-4o-realtime",    // realtime (no video)
        "gpt-5"               // next-gen responses model
    ]
    static var defaultModel: String {
        UserDefaults.standard.string(forKey: "responses_model") ?? (availableModels.first ?? "gpt-4o-mini")
    }

    // Parameters per model
    static func isRealtime(_ model: String) -> Bool {
        model.lowercased().contains("realtime")
    }
    static func supportsTemperature(_ model: String) -> Bool {
        !isRealtime(model) // in our app, temperature only for responses-like models
    }

    static var defaultTemperature: Double { UserDefaults.standard.object(forKey: "temperature") as? Double ?? 0.7 }
}

// Мини-дизайн-система для современного вида окон
enum DS {
    static let accent = Color(red: 0.38, green: 0.72, blue: 1.0)
    static let accent2 = Color(red: 0.66, green: 0.46, blue: 1.0)
    static let bg = Color(nsColor: .windowBackgroundColor)
    static let panel = Color.black.opacity(0.06)
    static let panel2 = Color.black.opacity(0.12)

    static func gradient(_ reverse: Bool = false) -> LinearGradient {
        LinearGradient(colors: reverse ? [accent2, accent] : [accent, accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct Glow: ViewModifier {
    var color: Color = DS.accent
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.45), radius: 12, x: 0, y: 0)
            .shadow(color: color.opacity(0.25), radius: 24, x: 0, y: 0)
    }
}

extension View {
    func glow(_ color: Color = DS.accent) -> some View { modifier(Glow(color: color)) }
}
