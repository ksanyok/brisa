import Foundation

/// Реалтайм‑движок, отвечающий за подключение к OpenAI Realtime API,
/// потоковую передачу аудио и текста, обработку промежуточных ответов и вызовы функций.
/// Реалтайм‑движок, который общается с моделью OpenAI через HTTP API.
/// На этапе MVP поддерживается отправка текста и получение ответа в виде одной строки.
final class RealtimeEngine {
    private let apiKey: String
    private let model: String
    private let temperature: Double

    /// Массив сообщений для поддержания контекста. Каждый элемент представляет роль и содержимое.
    private var messages: [[String: String]] = []

    init(apiKey: String, model: String = "gpt-4o", temperature: Double = 0.5) {
        self.apiKey = apiKey
        self.model = model
        self.temperature = temperature
        // Приветственное сообщение системы задаёт роль ассистента
        messages.append(["role": "system", "content": "You are Brisa, a helpful macOS assistant."])
    }

    /// Начинает новую сессию, очищая контекст сообщений.
    func startSession() {
        messages.removeAll(keepingCapacity: false)
        messages.append(["role": "system", "content": "You are Brisa, a helpful macOS assistant."])
    }

    /// Отправляет текстовый запрос в модель. Ответ возвращается через коллбек.
    func send(text: String, completion: @escaping (String) -> Void) {
        // Добавляем сообщение пользователя в контекст
        messages.append(["role": "user", "content": text])

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion("")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "temperature": temperature
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion("")
            return
        }

        // Отправляем запрос
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("RealtimeEngine error: \(error)")
                completion("")
                return
            }
            guard let data = data else {
                completion("")
                return
            }
            // Парсим ответ
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                // Добавляем ответ ассистента в историю
                self.messages.append(["role": "assistant", "content": content])
                completion(content)
            } else {
                completion("")
            }
        }
        task.resume()
    }

    /// Завершает текущую сессию.
    func stop() {
        // Для HTTP‑API нет активного соединения, но мы можем очистить контекст
        messages.removeAll(keepingCapacity: false)
    }
}