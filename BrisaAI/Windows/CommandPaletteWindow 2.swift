import SwiftUI
import Combine

struct CommandStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
}

final class CommandPaletteVM: ObservableObject {
    @Published var input: String = ""
    @Published var steps: [CommandStep] = []
    @Published var isRunningPlan = false
    @Published var confirmRequest: String? = nil
    @Published var micActive = false

    let orchestrator = Orchestrator()
    private var cancellables = Set<AnyCancellable>()

    init() {
        orchestrator.onStepUpdate = { [weak self] title in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isRunningPlan = true
                self.steps.append(CommandStep(title: title))
                if self.steps.count > 3 { self.steps.removeFirst(self.steps.count - 3) }
            }
        }
        orchestrator.onPlanFinished = { [weak self] in
            DispatchQueue.main.async { self?.isRunningPlan = false }
        }
        orchestrator.onConfirm = { [weak self] prompt, proceed, cancel in
            DispatchQueue.main.async {
                self?.confirmRequest = prompt
            }
        }
        orchestrator.onConfirmResolved = { [weak self] in
            DispatchQueue.main.async { self?.confirmRequest = nil }
        }
    }

    func runTextCommand() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
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
}

struct CommandPaletteWindow: View {
    var onOpenSettings: () -> Void
    var onOpenConsent: () -> Void

    @StateObject private var vm = CommandPaletteVM()

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Введите команду…", text: $vm.input, onCommit: { vm.runTextCommand() })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: { vm.runTextCommand() }) {
                    Text("Отправить")
                }
                Button(action: { /* TODO: STT start/stop */ vm.micActive.toggle() }) {
                    Image(systemName: vm.micActive ? "mic.fill" : "mic")
                }.help("Микрофон")
            }

            HStack {
                Text("Шаги:")
                Spacer()
                if vm.isRunningPlan { ProgressView() }
            }
            .font(.caption)

            HStack(spacing: 8) {
                ForEach(vm.steps) { step in
                    Text(step.title)
                        .font(.caption)
                        .padding(6)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
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
                .padding(8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
            }

            HStack {
                Button("Настройки…", action: onOpenSettings)
                Button("Разрешения", action: onOpenConsent)
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(12)
    }
}

