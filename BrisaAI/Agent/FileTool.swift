import Foundation

final class FileTool {
    func createFolderOnDesktop(name: String) -> Bool {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let url = desktop.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
            BrisaLogger.shared.info("Folder created: \(url.path)")
            return true
        } catch {
            BrisaLogger.shared.error("Create folder failed: \(error.localizedDescription)")
            return false
        }
    }
}

