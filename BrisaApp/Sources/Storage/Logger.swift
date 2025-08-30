import Foundation
import os.log

/// Журналирование и аудит действий агента. Использует `os.log` для системного логирования.
final class Logger {
    static let shared = Logger()

    private let log = OSLog(subsystem: "com.buyreadysite.brisa", category: "Brisa")

    private init() {}

    func info(_ message: String) {
        os_log("%@", log: log, type: .info, message)
    }

    func error(_ message: String) {
        os_log("%@", log: log, type: .error, message)
    }
}