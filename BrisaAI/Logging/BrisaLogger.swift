import Foundation

final class BrisaLogger {
    static let shared = BrisaLogger()
    let logFileURL: URL
    private let queue = DispatchQueue(label: "ai.brisa.logger")
    private let maxBytes: Int = 5 * 1024 * 1024 // 5 MB

    private init() {
        let logDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Logs/BrisaAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        logFileURL = logDir.appendingPathComponent("log.txt")
        if !FileManager.default.fileExists(atPath: logFileURL.path) { FileManager.default.createFile(atPath: logFileURL.path, contents: nil) }
    }

    func info(_ msg: String) { write("INFO", msg) }
    func warn(_ msg: String) { write("WARN", msg) }
    func error(_ msg: String) { write("ERROR", msg) }

    func truncate() {
        queue.async {
            try? "".data(using: .utf8)?.write(to: self.logFileURL)
        }
    }

    private func write(_ level: String, _ msg: String) {
        queue.async {
            let masked = self.maskSecrets(in: msg)
            let line = "\(self.timestamp()) [\(level)] \(masked)\n"
            guard let data = line.data(using: .utf8) else { return }

            // rotate if exceeded
            if let sizeNum = try? FileManager.default.attributesOfItem(atPath: self.logFileURL.path)[.size] as? NSNumber,
               sizeNum.intValue > self.maxBytes {
                let rotated = self.logFileURL.deletingLastPathComponent().appendingPathComponent("log.txt.1")
                // remove previous rotated
                try? FileManager.default.removeItem(at: rotated)
                // move current to rotated
                try? FileManager.default.moveItem(at: self.logFileURL, to: rotated)
                // recreate empty
                FileManager.default.createFile(atPath: self.logFileURL.path, contents: nil)
            }

            if let fh = try? FileHandle(forWritingTo: self.logFileURL) {
                defer { try? fh.close() }
                do { try fh.seekToEnd() } catch {}
                try? fh.write(contentsOf: data)
            } else {
                try? data.write(to: self.logFileURL, options: .atomic)
            }
        }
    }

    private func timestamp() -> String {
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return df.string(from: Date())
    }

    func maskSecrets(in text: String) -> String {
        var t = text
        // Маскируем ключи вида sk-...
        t = t.replacingOccurrences(of: #"sk-[A-Za-z0-9_\-]{10,}"#, with: "sk-****", options: .regularExpression)
        // Примитивное маскирование паролей в строках query
        t = t.replacingOccurrences(of: #"(?i)(password|pwd|pass)[=:][^\s&]+"#, with: "$1=****", options: .regularExpression)
        return t
    }
}
