import Foundation
import AVFoundation

final class STTManager: NSObject {
    static let shared = STTManager()
    private let audioEngine = AVAudioEngine()
    private let queue = DispatchQueue(label: "ai.brisa.stt")
    private var bufferData = Data()
    private var sending = false

    var onTranscript: ((String) -> Void)?

    func start() {
        // Автозапрос разрешения на микрофон по требованию
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async { self?.start() }
            }
            return
        default:
            BrisaLogger.shared.warn("Microphone permission denied – cannot start STT")
            return
        }
        // TODO: реализация потоковой передачи фрагментов (0.5–1.0с) в OpenAI Audio Transcriptions
        let input = audioEngine.inputNode
        let format = input.inputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] (buffer, when) in
            guard let self = self else { return }
            self.queue.async {
                if let block = buffer.toPCM16Data() { self.bufferData.append(block) }
                self.flushIfNeeded()
            }
        }
        audioEngine.prepare()
        try? audioEngine.start()
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func flushIfNeeded() {
        guard bufferData.count > 16000, !sending else { return }
        sending = true
        let chunk = bufferData
        bufferData.removeAll(keepingCapacity: true)
        let apiKey = KeychainHelper.shared.getAPIKey() ?? ""
        OpenAIClient().transcribeChunk(apiKey: apiKey, pcm16: chunk) { [weak self] text in
            self?.sending = false
            if let t = text, !t.isEmpty { self?.onTranscript?(t) }
        }
    }
}

private extension AVAudioPCMBuffer {
    func toPCM16Data() -> Data? {
        guard let channelData = self.int16ChannelData else { return nil }
        let channels = UnsafeBufferPointer(start: channelData, count: Int(self.format.channelCount))
        let frameLength = Int(self.frameLength)
        var data = Data(capacity: frameLength * MemoryLayout<Int16>.size)
        for frame in 0..<frameLength {
            for ch in 0..<Int(self.format.channelCount) {
                let sample = channels[ch][frame]
                data.append(UnsafeBufferPointer(start: [sample], count: 1))
            }
        }
        return data
    }
}
