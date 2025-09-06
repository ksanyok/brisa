import Foundation

struct OpenAIClient {
    private let base = URL(string: "https://api.openai.com/v1")!

    struct TestResponse: Decodable { let id: String? }

    // MARK: - Plan generation (Responses)
    func generatePlan(apiKey: String, model: String, temperature: Double, task: String, ocr: String?, conversation: [String] = [], completion: @escaping (ActionPlan?) -> Void) {
        let url = base.appendingPathComponent("responses")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let sys = "You are Brisa desktop agent. Return JSON only with fields: plan_id (uuid) and steps: [{type: one of open_app, click, type, wait_for, navigate_url, create_folder; name?; x?; y?; text?; target?; timeout_ms?; url?}]. No explanations. Use OCR context of the current screen when relevant."
        var prompt = "Task: \(task)."
        if let ocr = ocr, !ocr.isEmpty { prompt += "\nScreen OCR:\n\(ocr.prefix(4000))" }
        if !conversation.isEmpty { prompt += "\nRecent messages:\n\(conversation.joined(separator: "\n"))" }

        var body: [String: Any] = [
            "model": model,
            "input": [
                ["role": "system", "content": sys],
                ["role": "user", "content": prompt]
            ],
            "temperature": temperature,
            "max_output_tokens": 800
        ]
        // Если выбрана realtime-модель — безопасно дергаем через мини-модель для плана
        if AppConfig.isRealtime(model) { body["model"] = "gpt-4o-mini" }

        BrisaLogger.shared.info("Plan request via Responses model=\(body["model"] ?? model)")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { BrisaLogger.shared.error("Plan network error: \(err.localizedDescription)"); completion(nil); return }
            guard let data = data, let http = resp as? HTTPURLResponse else { completion(nil); return }
            let text = String(data: data, encoding: .utf8) ?? ""
            BrisaLogger.shared.info("Plan response: status=\(http.statusCode) len=\(text.count)")
            guard (200..<300).contains(http.statusCode) else { completion(nil); return }
            // Попробуем извлечь JSON из текста ответа (вдруг есть обёртки)
            if let jsonStr = Self.extractJSON(from: text), let planData = jsonStr.data(using: .utf8) {
                let plan = try? JSONDecoder().decode(ActionPlan.self, from: planData)
                completion(plan)
                return
            }
            completion(nil)
        }.resume()
    }

    private static func extractJSON(from text: String) -> String? {
        // Находит первый { ... } на верхнем уровне
        var lvl = 0
        var start: String.Index?
        for i in text.indices {
            let ch = text[i]
            if ch == "{" {
                if lvl == 0 { start = i }
                lvl += 1
            } else if ch == "}" {
                lvl -= 1
                if lvl == 0, let s = start { return String(text[s...i]) }
            }
        }
        return nil
    }

    func testAPIKey(apiKey: String, model: String, completion: @escaping (Bool, String) -> Void) {
        // Если выбран realtime-модель, используем безопасный пинг через /responses с «gpt-4o-mini»
        let effectiveModel = model.contains("realtime") ? "gpt-4o-mini" : model
        let url = base.appendingPathComponent("responses")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Минимальный валидный запрос Responses: только текстовый input
        let body: [String: Any] = [
            "model": effectiveModel,
            "input": "ping",
            "max_output_tokens": 32
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // Логируем факт запроса (без секрета)
        BrisaLogger.shared.info("TestAPIKey: POST /responses model=\(effectiveModel)")
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                BrisaLogger.shared.error("TestAPIKey network error: \(err.localizedDescription)")
                completion(false, err.localizedDescription)
                return
            }
            guard let http = resp as? HTTPURLResponse else { completion(false, "no response"); return }
            let bodyText = String(data: data ?? Data(), encoding: .utf8) ?? ""
            if (200..<300).contains(http.statusCode) {
                BrisaLogger.shared.info("TestAPIKey response: status=\(http.statusCode)")
                completion(true, "connected")
            } else {
                BrisaLogger.shared.error("TestAPIKey response: status=\(http.statusCode) body=\(bodyText.prefix(300))")
                completion(false, "HTTP \(http.statusCode)")
            }
        }.resume()
    }

    // STT: частичные чанки PCM16 линейные 16-бит, N кГц, 1..2 канала
    // Отправляем как WAV через multipart/form-data в /audio/transcriptions (Whisper)
    func transcribeChunk(apiKey: String, pcm16: Data, sampleRate: Double, channels: Int, completion: @escaping (String?) -> Void) {
        let wav = Self.makeWav(pcm16: pcm16, sampleRate: Int(sampleRate), channels: Int16(channels))
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: base.appendingPathComponent("audio/transcriptions"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        func appendFile(name: String, filename: String, mime: String, data: Data) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        appendField(name: "model", value: "whisper-1")
        appendFile(name: "file", filename: "chunk.wav", mime: "audio/wav", data: wav)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { BrisaLogger.shared.error("STT error: \(err.localizedDescription)"); completion(nil); return }
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode), let data = data else {
                let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
                let txt = String(data: data ?? Data(), encoding: .utf8) ?? ""
                BrisaLogger.shared.error("STT bad response: code=\(code) body=\(txt.prefix(200))")
                completion(nil)
                return
            }
            if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let text = obj["text"] as? String {
                completion(text)
            } else {
                completion(nil)
            }
        }.resume()
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
            "format": "wav",
            "modalities": ["audio"]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { BrisaLogger.shared.error("TTS error: \(err.localizedDescription)"); completion(nil); return }
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { completion(nil); return }
            completion(data)
        }.resume()
    }

    // MARK: - WAV helper
    static func makeWav(pcm16: Data, sampleRate: Int, channels: Int16) -> Data {
        // PCM16 LE WAV header (RIFF)
        let byteRate = sampleRate * Int(channels) * 2
        let blockAlign = Int(channels) * 2
        var data = Data()
        func write(_ s: String) { data.append(s.data(using: .ascii)!) }
        func writeUInt32(_ v: UInt32) { var le = v.littleEndian; data.append(Data(bytes: &le, count: 4)) }
        func writeUInt16(_ v: UInt16) { var le = v.littleEndian; data.append(Data(bytes: &le, count: 2)) }
        // RIFF header
        write("RIFF")
        writeUInt32(UInt32(36 + pcm16.count))
        write("WAVE")
        // fmt chunk
        write("fmt ")
        writeUInt32(16) // PCM chunk size
        writeUInt16(1) // PCM format
        writeUInt16(UInt16(channels))
        writeUInt32(UInt32(sampleRate))
        writeUInt32(UInt32(byteRate))
        writeUInt16(UInt16(blockAlign))
        writeUInt16(16) // bits per sample
        // data chunk
        write("data")
        writeUInt32(UInt32(pcm16.count))
        data.append(pcm16)
        return data
    }
}
