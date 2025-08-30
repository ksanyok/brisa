import Foundation
import Combine

/// Observable manager that wraps `RealtimeEngine` and exposes a list of messages.
/// This class handles configuration of the engine with an API key and provides
/// convenience methods for sending user input and receiving responses. The
/// messages array can be observed by SwiftUI views to render a chat transcript.
final class RealtimeManager: ObservableObject {
    /// Shared singleton instance used throughout the app.
    static let shared = RealtimeManager()

    /// Underlying realtime engine. Optional until configured with an API key.
    private var engine: RealtimeEngine?

    /// Published list of chat messages. Each entry is a string like "User: …" or "Brisa: …".
    @Published var messages: [String] = []

    private init() {}

    /// Configures the realtime engine with an API key. Should be called once when the key becomes available.
    func configure(apiKey: String) {
        // Recreate the engine with the new key and reset the conversation.
        engine = RealtimeEngine(apiKey: apiKey)
        messages.removeAll()
    }

    /// Sends a user message to the engine and appends the assistant's response to the transcript.
    func send(text: String) {
        guard let engine = engine else {
            messages.append("[Error] API key not configured")
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messages.append("Вы: \(trimmed)")
        engine.send(text: trimmed) { [weak self] response in
            DispatchQueue.main.async {
                self?.messages.append("Brisa: \(response)")
            }
        }
    }
}