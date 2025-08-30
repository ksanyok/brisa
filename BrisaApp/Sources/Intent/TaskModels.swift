import Foundation

/// Возможные действия шага. Используются для планирования, классификации рисков и выполнения.
public enum StepAction {
    case openURL(URL)
    case prepareDraft
    case navigateToPublish
    case fillForm
    case send
    /// Открыть приложение по названию. Например, "Telegram"
    case openApp(String)
    case custom(String)
}

/// Структура, представляющая один шаг плана.
public struct TaskStep {
    public let description: String
    public let action: StepAction
    public init(description: String, action: StepAction) {
        self.description = description
        self.action = action
    }
}