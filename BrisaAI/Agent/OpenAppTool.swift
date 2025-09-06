import AppKit

final class OpenAppTool {
    func open(appName: String) -> Bool {
        var name = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { return false }
        // Простейшие синонимы
        let lower = name.lowercased()
        if lower.contains("телеграм") { name = "Telegram" }
        if lower.contains("whatsapp") { name = "WhatsApp" }
        if lower.contains("браузер") || lower.contains("safari") { name = "Safari" }

        BrisaLogger.shared.info("OpenApp: \(name)")
        let ok = NSWorkspace.shared.launchApplication(name)
        // Верификация активного приложения
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let front = NSWorkspace.shared.frontmostApplication {
                BrisaLogger.shared.info("Frontmost app: \(front.localizedName ?? front.bundleIdentifier ?? "?")")
            }
        }
        if !ok { BrisaLogger.shared.warn("OpenApp failed (may need consent)") }
        return ok
    }
}
