import AppKit

final class TypeTool {
    func type(text: String) -> Bool {
        // Требуется Accessibility
        guard AXIsProcessTrusted() else {
            BrisaLogger.shared.warn("Typing requires Accessibility permissions")
            return false
        }
        BrisaLogger.shared.info("Type text (len=\(text.count))")
        // Безопасная вставка через буфер обмена (минимум для MVP)
        let pb = NSPasteboard.general
        let old = pb.string(forType: .string)
        pb.clearContents()
        pb.setString(text, forType: .string)

        // Сгенерировать Cmd+V
        let src = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: true) // Cmd
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true) // V
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: false)
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        // Восстановить буфер обмена
        if let old = old {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pb.clearContents()
                pb.setString(old, forType: .string)
            }
        }
        return true
    }
}
