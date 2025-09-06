import Foundation

enum AppConfig {
    static var defaultLanguage: String { UserDefaults.standard.string(forKey: "language") ?? "ru" }
    static var defaultVoice: String { UserDefaults.standard.string(forKey: "voice") ?? "none" }
    static var defaultModel: String { UserDefaults.standard.string(forKey: "responses_model") ?? "gpt-4o-realtime" }
}

