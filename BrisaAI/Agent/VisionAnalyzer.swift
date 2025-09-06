import Foundation
import Vision
import AppKit

final class VisionAnalyzer {
    static let shared = VisionAnalyzer()
    private init() {}

    struct OCRResult { let text: String; let boxes: [VNRecognizedTextObservation] }

    func ocr(image: NSImage) async -> OCRResult? {
        // TODO: интеграция: вызывать OpenAI Vision для уточнения по обрезку кадра при необходимости
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let cg = rep.cgImage else { return nil }
        let req = VNRecognizeTextRequest()
        req.recognitionLevel = .fast
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        do {
            try handler.perform([req])
            let texts = (req.results ?? []).compactMap { $0.topCandidates(1).first?.string }
            return OCRResult(text: texts.joined(separator: "\n"), boxes: req.results ?? [])
        } catch {
            BrisaLogger.shared.error("Vision OCR error: \(error.localizedDescription)")
            return nil
        }
    }

    func looksLikeLoggedInFacebook(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let loginMarkers = ["log in", "войти", "email", "пароль", "password"]
        let homeMarkers = ["что у вас нового", "what's on your mind", "создать публикацию"]
        let hasHome = homeMarkers.contains { lowered.contains($0) }
        let hasLogin = loginMarkers.contains { lowered.contains($0) }
        return hasHome && !hasLogin
    }
}
