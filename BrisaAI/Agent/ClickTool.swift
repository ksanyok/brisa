import AppKit

final class ClickTool {
    func click(at point: CGPoint) -> Bool {
        // Требуется Accessibility
        guard AXIsProcessTrusted() else {
            BrisaLogger.shared.warn("Click requires Accessibility permissions")
            return false
        }
        BrisaLogger.shared.info("Click at: (\(Int(point.x)), \(Int(point.y)))")
        let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
        let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        return true
    }
}

