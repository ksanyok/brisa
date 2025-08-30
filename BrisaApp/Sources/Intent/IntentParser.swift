import Foundation


/// Модуль NLU и планировщика.
/// Принимает текстовое намерение и формирует упорядоченный список шагов, которые затем
/// будут исполнены соответствующими компонентами.
struct IntentParser {
    /// Простая эвристическая обработка, которая ищет известные шаблоны в тексте команды и
    /// возвращает соответствующие шаги. В будущем будет заменена на вызов LLM.
    func parse(command: String) -> [TaskStep] {
        var steps: [TaskStep] = []
        let lowercased = command.lowercased()

        // Попытка извлечь название приложения для команды "открыть/открой/open"
        let words = lowercased.split(separator: " ")
        if let idx = words.firstIndex(where: { $0 == "открыть" || $0 == "открой" || $0 == "open" }), idx + 1 < words.count {
            let appNameWord = String(words[idx + 1])
            let appName = appNameWord.capitalized
            steps.append(TaskStep(description: "Открыть приложение \(appName)", action: .openApp(appName)))
        }

        // Если встречается URL, открываем его
        if let url = extractURL(from: command) {
            steps.append(TaskStep(description: "Открыть страницу \(url)", action: .openURL(url)))
        }

        // Если нужно написать пост, готовим черновик
        if lowercased.contains("пост") || lowercased.contains("опубликовать") {
            steps.append(TaskStep(description: "Подготовить черновик поста", action: .prepareDraft))
            steps.append(TaskStep(description: "Открыть форму публикации", action: .navigateToPublish))
            steps.append(TaskStep(description: "Заполнить форму", action: .fillForm))
            steps.append(TaskStep(description: "Отправить пост", action: .send))
        }

        return steps
    }

    /// Пытается извлечь URL из строки. Возвращает nil, если ничего не найдено.
    private func extractURL(from text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let firstMatch = detector?.firstMatch(in: text, options: [], range: range)
        if let match = firstMatch, let url = match.url {
            return url
        }
        return nil
    }
    }