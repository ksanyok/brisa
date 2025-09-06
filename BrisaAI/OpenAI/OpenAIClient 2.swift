import Foundation

struct OpenAIClient {
    private let base = URL(string: "https://api.openai.com/v1")!

    struct TestResponse: Decodable { let id: String? }

    func testAPIKey(apiKey: String, model: String, completion: @escaping (Bool, String) -> Void) {
        // Лёгкий тест через /responses (модальности: только text/audio, без video)
        let url = base.appendingPathComponent("responses")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "input": "ping",
            "modalities": ["text"]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { BrisaLogger.shared.error("OpenAI test error: \(err.localizedDescription)"); completion(false, err.localizedDescription); return }
            guard let http = resp as? HTTPURLResponse else { completion(false, "no response"); return }
            if (200..<300).contains(http.statusCode) {
                completion(true, "connected")
            } else {
                let text = String(data: data ?? Data(), encoding: .utf8) ?? ""
                completion(false, "HTTP \(http.statusCode): \(text)")
            }
        }.resume()
    }

    // STT: частичные чанки PCM16 линейные 16-бит моно, 16/24 кГц
    func transcribeChunk(apiKey: String, pcm16: Data, completion: @escaping (String?) -> Void) {
        // TODO: Реальная интеграция с /audio/transcriptions (Whisper) multipart/form-data
        completion(nil)
    }

    // TTS: OpenAI Audio Speech
    func synthesizeSpeech(apiKey: String, text: String, voice: String, completion: @escaping (Data?) -> Void) {
        let url = base.appendingPathComponent("audio/speech")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": "gpt-4o-mini-tts",
            "input": text,
            "voice": voice,
            "format": "pcm",
            "modalities": ["audio"]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { BrisaLogger.shared.error("TTS error: \(err.localizedDescription)"); completion(nil); return }
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { completion(nil); return }
            completion(data)
        }.resume()
    }
}

