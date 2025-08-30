import Foundation

/// Категория риска для операции.
public enum RiskCategory {
    case low
    case medium
    case high
}

/// Компонент, который классифицирует действия и определяет необходимость подтверждения.
public struct RiskPolicy {
    /// Определяет категорию риска для переданного шага.
    public func category(for action: TaskStep) -> RiskCategory {
        // TODO: анализировать описание шага и возвращать категорию риска
        return .low
    }

    /// Требуется ли подтверждение для шага с учётом политики.
    public func requiresConfirmation(for action: TaskStep) -> Bool {
        switch category(for: action) {
        case .low:
            return false
        case .medium, .high:
            return true
        }
    }
}