import Foundation

final class WaitFor {
    // Заглушка ожидания/поиска по OCR/селектору
    func wait(timeoutMs: Int) async -> Bool {
        // TODO: интеграция с VisionAnalyzer/VNRecognizeText + проверка target
        let seconds = Double(timeoutMs) / 1000.0
        BrisaLogger.shared.info("Wait ~\(String(format: "%.1f", seconds))s")
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        return true
    }
}
