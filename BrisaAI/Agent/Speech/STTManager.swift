import Foundation
import AVFoundation

final class STTManager: NSObject {
    static let shared = STTManager()
    private let audioEngine = AVAudioEngine()
    private let queue = DispatchQueue(label: "ai.brisa.stt")
    private var bufferData = Data()
    private var sending = false
    private var bytesPerSecond: Int = 32000 // default guard
    private var currentSampleRate: Double = 16000
    private var currentChannels: Int = 1

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
        let input = audioEngine.inputNode
        let format = input.inputFormat(forBus: 0)
        currentSampleRate = format.sampleRate
        currentChannels = Int(format.channelCount)
        bytesPerSecond = Int(currentSampleRate) * 2 * currentChannels
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] (buffer, when) in
            guard let self = self else { return }
            self.queue.async {
                if let block = buffer.toPCM16Data() { self.bufferData.append(block) }
                self.flushIfNeeded()
            }
        }
        audioEngine.prepare()
        try? audioEngine.start()
        BrisaLogger.shared.info("STT started: sr=\(Int(currentSampleRate)) ch=\(currentChannels)")
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }

    private func flushIfNeeded() {
        // Отправляем каждые ~0.6 сек звука
        guard bufferData.count > Int(Double(bytesPerSecond) * 0.6), !sending else { return }
        sending = true
        let chunk = bufferData
        bufferData.removeAll(keepingCapacity: true)
        let apiKey = KeychainHelper.shared.getAPIKey() ?? ""
        BrisaLogger.shared.info("STT send chunk bytes=\(chunk.count)")
        OpenAIClient().transcribeChunk(apiKey: apiKey, pcm16: chunk, sampleRate: currentSampleRate, channels: currentChannels) { [weak self] text in
            self?.sending = false
            if let t = text, !t.isEmpty {
                BrisaLogger.shared.info("STT text=\(t)")
                self?.onTranscript?(t)
            }
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
                var s = sample
                withUnsafeBytes(of: &s) { raw in
                    data.append(raw.bindMemory(to: UInt8.self))
                }
            }
        }
        return data
    }
}
