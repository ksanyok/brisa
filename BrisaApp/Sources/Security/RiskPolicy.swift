import Foundation

/// Категория риска для операции.
public enum RiskCategory {
    case low
    case medium
    case high
}

/// Компонент, который классифицирует действия и определяет необходимость подтверждения.
public struct RiskPolicy {
    /// Определяет категорию риска для переданного шага на основе его действия.
    public func category(for step: TaskStep) -> RiskCategory {
        switch step.action {
        case .send:
            // Отправка контента во внешний мир — высокий риск
            return .high
        case .navigateToPublish, .fillForm:
            // Заполнение форм и переход к публикации — средний риск
            return .medium
        case .openURL(_):
            // Простая навигация — низкий риск
            return .low
        case .openApp(_):
            // Открытие локального приложения — низкий риск
            return .low
        case .prepareDraft:
            return .low
        case .custom(let desc):
            // Простейшая эвристика: если строка содержит опасные слова, повышаем риск
            let lowered = desc.lowercased()
            if lowered.contains("delete") || lowered.contains("удалить") || lowered.contains("pay") || lowered.contains("купить") {
                return .high
            } else if lowered.contains("update") || lowered.contains("изменить") {
                return .medium
            }
            return .low
        }
    }

    /// Требуется ли подтверждение для шага с учётом политики.
    public func requiresConfirmation(for step: TaskStep) -> Bool {
        switch category(for: step) {
        case .low:
            return false
        case .medium, .high:
            return true
        }
    }
}