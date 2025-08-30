import Foundation

/// Исполнитель для вызова командной строки. Позволяет запускать системные утилиты
/// и скрипты, которые лучше выполнять без использования UI или браузера.
final class ShellExecutor {
    /// Выполняет заданную команду с аргументами. Возвращает вывод stdout и stderr.
    @discardableResult
    func run(_ command: String, arguments: [String] = []) throws -> (stdout: String, stderr: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(decoding: outData, as: UTF8.self)
        let stderr = String(decoding: errData, as: UTF8.self)
        return (stdout: stdout, stderr: stderr)
    }
}