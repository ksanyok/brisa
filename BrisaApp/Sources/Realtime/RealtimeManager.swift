import Foundation
import Combine

/// Observable manager that wraps `RealtimeEngine` and exposes a list of messages.
/// This class handles configuration of the engine with an API key and provides
/// convenience methods for sending user input and receiving responses. The
/// messages array can be observed by SwiftUI views to render a chat transcript.
final class RealtimeManager: ObservableObject {
    /// Shared singleton instance used throughout the app.
    static let shared = RealtimeManager()

    /// Underlying realtime engine. Optional until configured with an API key.
    private var engine: RealtimeEngine?

    /// Компоненты для разбора намерений и выполнения шагов
    private let intentParser = IntentParser()
    private let appOpener = AppOpener()

    /// Chat message model with role and content. Each message has a unique identifier for SwiftUI lists.
    struct ChatMessage: Identifiable {
        enum Role {
            case user
            case assistant
            case system
            case error
        }
        let id = UUID()
        let role: Role
        let content: String

        /// Возвращает true, если сообщение отправлено пользователем. Удобно для UI.
        var isUser: Bool { role == .user }
    }

    /// Published list of chat messages used to render the dialogue in the UI.
    @Published var messages: [ChatMessage] = []

    private init() {}

    /// Configures the realtime engine with an API key. Should be called once when the key becomes available.
    func configure(apiKey: String) {
        // Recreate the engine with the new key and reset the conversation.
        engine = RealtimeEngine(apiKey: apiKey)
        messages.removeAll()
    }

    /// Sends a user message to the engine and appends the assistant's response to the transcript.
    func send(text: String) {
        guard let engine = engine else {
            messages.append(ChatMessage(role: .error, content: "API key not configured"))
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // Append the user's message to the conversation
        messages.append(ChatMessage(role: .user, content: trimmed))

        // Парсим намерение и выполняем найденные шаги. Выполнение происходит асинхронно,
        // чтобы не блокировать UI. В будущем здесь будет согласование с политикой риска
        // и подтверждениями.
        let steps = intentParser.parse(command: trimmed)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            steps.forEach { step in
                self?.execute(step: step)
            }
        }
        engine.send(text: trimmed) { [weak self] response in
            DispatchQueue.main.async {
                self?.messages.append(ChatMessage(role: .assistant, content: response))
            }
        }
    }

    /// Выполняет один шаг плана, используя соответствующие исполнители.
    private func execute(step: TaskStep) {
        switch step.action {
        case .openApp(let appName):
            appOpener.open(appName: appName)
        case .openURL(_):
            // TODO: делегировать BrowserExecutor
            break
        case .prepareDraft, .navigateToPublish, .fillForm, .send, .custom:
            // TODO: реализовать остальные действия
            break
        }
    }
}