import Foundation
import AVFoundation

final class TTSManager {
    static let shared = TTSManager()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var isSetup = false

    func setupIfNeeded() {
        guard !isSetup else { return }
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 24000, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
        isSetup = true
    }

    func speak(text: String, voice: String) {
        // Прерывание: если идёт воспроизведение – останавливаем (barge-in)
        stop()
        guard voice.lowercased() != "none" else { return }
        setupIfNeeded()
        let apiKey = KeychainHelper.shared.getAPIKey() ?? ""
        OpenAIClient().synthesizeSpeech(apiKey: apiKey, text: text, voice: voice) { [weak self] audioData in
            guard let self = self, let audioData = audioData else { return }
            self.play(data: audioData)
        }
    }

    func stop() {
        player.stop()
    }

    private func play(data: Data) {
        // Проще всего: сохранить во временный WAV и воспроизвести через AVAudioFile
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("brisa_tts_\(UUID().uuidString).wav")
        do { try data.write(to: tmp) } catch { return }
        setupIfNeeded()
        do {
            let file = try AVAudioFile(forReading: tmp)
            let format = file.processingFormat
            engine.connect(player, to: engine.mainMixerNode, format: format)
            player.play()
            player.scheduleFile(file, at: nil) {
                try? FileManager.default.removeItem(at: tmp)
            }
        } catch {
            try? FileManager.default.removeItem(at: tmp)
        }
    }
}
