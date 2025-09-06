import SwiftUI
import Combine

struct CommandStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
}

struct ChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
    let time = Date()
}

final class CommandPaletteVM: ObservableObject {
    @Published var input: String = ""
    @Published var steps: [CommandStep] = []
    @Published var isRunningPlan = false
    @Published var confirmRequest: String? = nil
    @Published var micActive = false
    @Published var askPrompt: String? = nil
    @Published var askPlaceholder: String = ""
    @Published var askText: String = ""
    @Published var messages: [ChatMessage] = []

    let orchestrator = Orchestrator()
    private var cancellables = Set<AnyCancellable>()

    init() {
        orchestrator.onStepUpdate = { [weak self] title in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRunningPlan = true
                self.steps.append(CommandStep(title: title))
                if self.steps.count > 3 { self.steps.removeFirst(self.steps.count - 3) }
                // Озвучка статуса (не навязчиво)
                if AppConfig.defaultVoice != "none" {
                    TTSManager.shared.speak(text: title, voice: AppConfig.defaultVoice)
                }
                self.messages.append(ChatMessage(role: .assistant, text: title))
            }
        }
        orchestrator.onPlanFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.isRunningPlan = false
                if AppConfig.defaultVoice != "none" {
                    let t = AppConfig.defaultLanguage == "ru" ? "Готово." : "Done."
                    TTSManager.shared.speak(text: t, voice: AppConfig.defaultVoice)
                }
            }
        }
        orchestrator.onConfirm = { [weak self] prompt, proceed, cancel in
            DispatchQueue.main.async {
                self?.confirmRequest = prompt
            }
        }
        orchestrator.onConfirmResolved = { [weak self] in
            DispatchQueue.main.async { self?.confirmRequest = nil }
        }

        orchestrator.onAskInput = { [weak self] prompt, placeholder in
            DispatchQueue.main.async {
                self?.askPrompt = prompt
                self?.askPlaceholder = placeholder
                self?.askText = ""
            }
        }
        orchestrator.onAskInputResolved = { [weak self] in
            DispatchQueue.main.async { self?.askPrompt = nil; self?.askText = "" }
        }

        // STT hookup
        STTManager.shared.onTranscript = { [weak self] text in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.askPrompt != nil {
                    self.askText += (self.askText.isEmpty ? "" : " ") + text
                } else {
                    self.input += (self.input.isEmpty ? "" : " ") + text
                }
            }
        }
    }

    func runTextCommand() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(role: .user, text: text))
        steps.removeAll()
        BrisaLogger.shared.info("Command: \(text)")
        orchestrator.runTextCommand(text: text)
    }

    func confirmProceed() {
        orchestrator.resolveConfirmation(agree: true)
    }
    func confirmCancel() {
        orchestrator.resolveConfirmation(agree: false)
    }

    func askSubmit() {
        orchestrator.resolveAsk(text: askText)
    }
    func askCancel() {
        orchestrator.resolveAsk(text: nil)
    }
}

struct CommandPaletteWindow: View {
    var onOpenSettings: () -> Void
    var onOpenConsent: () -> Void

    @StateObject private var vm = CommandPaletteVM()

    var body: some View {
        VStack(spacing: 14) {
            // Header badge
            HStack {
                ZStack {
                    Circle().fill(DS.gradient()).frame(width: 30, height: 30).glow()
                    Image(systemName: "waveform").foregroundStyle(.white)
                }
                Text("Brisa Command")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if vm.isRunningPlan { ProgressView().controlSize(.small) }
                Button(action: { vm.micActive.toggle() }) {
                    Image(systemName: vm.micActive ? "mic.fill" : "mic")
                        .foregroundStyle(vm.micActive ? DS.accent : .secondary)
                }.help("Микрофон")
            }

            ChatHistory(messages: vm.messages, steps: vm.steps)
                .frame(minHeight: 180, maxHeight: 220)

            HStack(spacing: 10) {
                TextField("Введите команду…", text: $vm.input, onCommit: { vm.runTextCommand() })
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DS.panel)
                    .cornerRadius(10)
                Button(action: { vm.runTextCommand() }) {
                    HStack { Image(systemName: "paperplane.fill"); Text("Отправить") }
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 8) {
                ForEach(vm.steps) { step in
                    Text(step.title)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(DS.gradient(true))
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                        .glow(DS.accent2)
                }
                Spacer()
            }

            if let confirm = vm.confirmRequest {
                VStack(alignment: .leading, spacing: 8) {
                    Text(confirm)
                    HStack {
                        Button("Подтвердить") { vm.confirmProceed() }.keyboardShortcut(.defaultAction)
                        Button("Отмена") { vm.confirmCancel() }
                    }
                }
                .padding(10)
                .background(Color.yellow.opacity(0.18))
                .cornerRadius(10)
            }

            if let ask = vm.askPrompt {
                VStack(alignment: .leading, spacing: 8) {
                    Text(ask)
                    TextField(vm.askPlaceholder, text: $vm.askText)
                    HStack {
                        Button("Отправить") { vm.askSubmit() }.keyboardShortcut(.defaultAction)
                        Button("Отмена") { vm.askCancel() }
                    }
                }
                .padding(10)
                .background(Color.blue.opacity(0.10))
                .cornerRadius(10)
            }

            HStack {
                Button("Настройки…", action: onOpenSettings)
                Button("Разрешения", action: onOpenConsent)
                Toggle(isOn: $vm.micActive) { Image(systemName: vm.micActive ? "mic.fill" : "mic") }
                    .toggleStyle(.switch)
                    .onChange(of: vm.micActive) { active in
                        if active { STTManager.shared.start() } else { STTManager.shared.stop() }
                    }
                Spacer()
            }
        }
        .padding(14)
        .background(DS.bg)
        .onChange(of: vm.micActive) { active in
            if active { STTManager.shared.start() } else { STTManager.shared.stop() }
        }
    }
}

private struct ChatHistory: View {
    let messages: [ChatMessage]
    let steps: [CommandStep]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(messages) { msg in
                    row(for: msg)
                }
                if !steps.isEmpty {
                    HStack { Text("Шаги плана:").font(.caption); Spacer() }
                    ForEach(steps) { step in
                        HStack { Text("• \(step.title)").font(.caption); Spacer() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for msg: ChatMessage) -> some View {
        HStack {
            if msg.role == .assistant { Spacer() }
            if msg.role == .user {
                Text(msg.text)
                    .padding(8)
                    .background(DS.panel)
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            } else {
                Text(msg.text)
                    .padding(8)
                    .background(DS.gradient(true))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            if msg.role == .user { Spacer() }
        }
    }
}
