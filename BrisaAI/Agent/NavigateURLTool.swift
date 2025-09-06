import AppKit

final class NavigateURLTool {
    func open(urlString: String) -> Bool {
        BrisaLogger.shared.info("Open URL: \(urlString)")
        guard let url = URL(string: urlString) else { return false }
        return NSWorkspace.shared.open(url)
    }
}

