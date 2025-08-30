import Foundation

/// Исполнитель, использующий DevTools Protocol для управления Chromium.
/// Ответственен за навигацию по страницам, заполнение форм и выполнение действий в браузере.
final class BrowserExecutor {
    /// Процесс Chromium. Запускается с параметром remote‑debugging‑port.
    private var process: Process?
    /// Задача WebSocket для отправки/получения команд CDP.
    private var webSocketTask: URLSessionWebSocketTask?
    /// Следующий идентификатор сообщения CDP.
    private var messageId: Int = 0

    /// Путь к бинарнику Chromium. Можно настроить через конфигурацию.
    var chromiumPath: String = "/Applications/Chromium.app/Contents/MacOS/Chromium"

    /// Запускает экземпляр Chromium с включённым DevTools Protocol.
    func start(port: Int = 9222) throws {
        guard process == nil else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: chromiumPath)
        proc.arguments = [
            "--remote-debugging-port=\(port)",
            "--user-data-dir=\(NSHomeDirectory())/.brisa/chromium-profile",
            "--no-first-run",
            "--no-default-browser-check"
        ]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        try proc.run()
        self.process = proc
        // Дадим браузеру время поднять сервер
        Thread.sleep(forTimeInterval: 2.0)
        try connect(port: port)
    }

    /// Подключается к первому доступному табу DevTools через WebSocket.
    private func connect(port: Int) throws {
        // Получаем список target‑ов
        let listURL = URL(string: "http://localhost:\(port)/json/list")!
        let data = try Data(contentsOf: listURL)
        guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = arr.first,
              let wsURLString = first["webSocketDebuggerUrl"] as? String,
              let wsURL = URL(string: wsURLString) else {
            throw NSError(domain: "BrowserExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось получить WebSocket URL"])
        }
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: wsURL)
        task.resume()
        self.webSocketTask = task
    }

    /// Открывает указанную страницу в текущей вкладке.
    func open(url: URL) {
        guard let task = webSocketTask else { return }
        messageId += 1
        let payload: [String: Any] = [
            "id": messageId,
            "method": "Page.navigate",
            "params": ["url": url.absoluteString]
        ]
        send(message: payload)
    }

    /// Выполняет JavaScript в текущем контексте страницы.
    private func evaluate(script: String) {
        guard let task = webSocketTask else { return }
        messageId += 1
        let payload: [String: Any] = [
            "id": messageId,
            "method": "Runtime.evaluate",
            "params": ["expression": script]
        ]
        send(message: payload)
    }

    /// Заполняет поле, найденное по CSS‑селектору, указанным текстом.
    func fill(selector: String, with text: String) {
        let js = "document.querySelector(\(escape(js: selector))).value = \(escape(js: text));"
        evaluate(script: js)
    }

    /// Выполняет клик по элементу, найденному по CSS‑селектору.
    func click(selector: String) {
        let js = "document.querySelector(\(escape(js: selector))).click();"
        evaluate(script: js)
    }

    /// Отправляет JSON‑команду по WebSocket.
    private func send(message: [String: Any]) {
        guard let task = webSocketTask,
              let data = try? JSONSerialization.data(withJSONObject: message, options: []) else { return }
        let text = String(data: data, encoding: .utf8) ?? ""
        task.send(.string(text)) { error in
            if let error = error {
                print("BrowserExecutor WebSocket send error: \(error)")
            }
        }
    }

    /// Экранирует строку для использования в JavaScript.
    private func escape(js: String) -> String {
        var result = js.replacingOccurrences(of: "\\", with: "\\\\")
        result = result.replacingOccurrences(of: "\"", with: "\\\"")
        result = result.replacingOccurrences(of: "'", with: "\\'")
        return "'\(result)'"
    }
}