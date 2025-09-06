import Foundation
import AppKit

struct ActionPlan: Codable {
    let plan_id: String
    var steps: [PlanStep]
}

enum StepType: String, Codable {
    case open_app
    case click
    case type
    case wait_for
    case navigate_url
    case create_folder
}

struct PlanStep: Codable {
    let type: StepType
    var name: String?
    var x: Double?
    var y: Double?
    var text: String?
    var target: String?
    var timeout_ms: Int?
    var url: String?
}

final class Orchestrator {
    // Коллбеки в UI
    var onStepUpdate: ((String) -> Void)?
    var onPlanFinished: (() -> Void)?
    var onConfirm: ((_ prompt: String, _ proceed: @escaping () -> Void, _ cancel: @escaping () -> Void) -> Void)?
    var onConfirmResolved: (() -> Void)?
    var onAskInput: ((_ prompt: String, _ placeholder: String) -> Void)?
    var onAskInputResolved: (() -> Void)?

    private let openApp = OpenAppTool()
    private let click = ClickTool()
    private let typer = TypeTool()
    private let waitFor = WaitFor()
    private let nav = NavigateURLTool()
    private let fileTool = FileTool()

    private var pendingConfirm: ((Bool) -> Void)?
    private var pendingAsk: ((String?) -> Void)?
    static let busyChanged = Notification.Name("brisa.orchestrator.busy")

    // Мини-демо: простое правило для команды «открой телеграм и напиши “Привет”»
    func runTextCommand(text: String) {
        // 1) Собираем наблюдения: OCR экрана
        Task { [weak self] in
            guard let self = self else { return }
            var ocrText: String? = nil
            if let img = ScreenCapture.shared.snapshotActiveScreen() {
                if let ocr = await VisionAnalyzer.shared.ocr(image: img) {
                    ocrText = ocr.text
                    BrisaLogger.shared.info("OCR collected (len=\(ocr.text.count))")
                }
            }

            // 2) Пытаемся построить план через OpenAI
            let temperature = UserDefaults.standard.object(forKey: "temperature") as? Double ?? 0.7
            let apiKey = KeychainHelper.shared.getAPIKey() ?? ""
            let model = AppConfig.defaultModel
            OpenAIClient().generatePlan(apiKey: apiKey, model: model, temperature: temperature, task: text, ocr: ocrText, conversation: []) { plan in
                if let plan = plan {
                    DispatchQueue.main.async { self.execute(plan: plan) }
                } else {
                    // 3) Fallback эвристики
                    let lower = text.lowercased()
                    var fbPlan: ActionPlan
                    if lower.contains("создай папку") || lower.contains("создать папку") {
                        // Выделить имя (последнее слово/кавычки)
                        let name = lower.replacingOccurrences(of: "создай папку", with: "").replacingOccurrences(of: "создать папку", with: "").trimmingCharacters(in: .whitespaces)
                        fbPlan = ActionPlan(plan_id: UUID().uuidString, steps: [ PlanStep(type: .create_folder, name: name, x: nil, y: nil, text: nil, target: nil, timeout_ms: nil, url: nil) ])
                    } else if lower.contains("телеграм") || lower.contains("telegram") {
                        fbPlan = ActionPlan(plan_id: UUID().uuidString, steps: [ PlanStep(type: .open_app, name: "Telegram", x: nil, y: nil, text: nil, target: nil, timeout_ms: nil, url: nil) ])
                    } else if lower.contains("facebook") {
                        fbPlan = ActionPlan(plan_id: UUID().uuidString, steps: [ PlanStep(type: .navigate_url, name: nil, x: nil, y: nil, text: nil, target: nil, timeout_ms: nil, url: "https://www.facebook.com") ])
                    } else {
                        let name = lower.replacingOccurrences(of: "открой ", with: "").trimmingCharacters(in: .whitespaces)
                        fbPlan = ActionPlan(plan_id: UUID().uuidString, steps: [ PlanStep(type: .open_app, name: name, x: nil, y: nil, text: nil, target: nil, timeout_ms: nil, url: nil) ])
                    }
                    DispatchQueue.main.async { self.execute(plan: fbPlan) }
                }
            }
        }
    }

    func execute(plan: ActionPlan) {
        BrisaLogger.shared.info("Plan started: \(plan.plan_id)")
        NotificationCenter.default.post(name: Self.busyChanged, object: nil, userInfo: ["active": true])
        Task { [weak self] in
            guard let self = self else { return }
            for step in plan.steps {
                let title = self.describe(step: step)
                self.onStepUpdate?(title)
                let ok = await self.perform(step: step)
                if !ok {
                    BrisaLogger.shared.error("Step failed: \(title)")
                    break
                }
            }
            self.onPlanFinished?()
            BrisaLogger.shared.info("Plan finished: \(plan.plan_id)")
            NotificationCenter.default.post(name: Self.busyChanged, object: nil, userInfo: ["active": false])
        }
    }

    private func describe(step: PlanStep) -> String {
        switch step.type {
        case .open_app: return "Открыть приложение: \(step.name ?? "?")"
        case .click: return "Клик по координатам: (\(Int(step.x ?? 0)), \(Int(step.y ?? 0)))"
        case .type: return "Ввод текста"
        case .wait_for: return "Ожидание: \(step.target ?? "?")"
        case .navigate_url: return "Открыть URL: \(step.url ?? "?")"
        case .create_folder: return "Создать папку: \(step.name ?? step.text ?? "NewFolder")"
        }
    }

    private func perform(step: PlanStep) async -> Bool {
        switch step.type {
        case .open_app:
            guard let name = step.name else { return false }
            return openApp.open(appName: name)
        case .click:
            guard let x = step.x, let y = step.y else { return false }
            // Проверка актуальности кадра и доступности — TODO: интеграция со ScreenCapture/Vision
            return click.click(at: CGPoint(x: x, y: y))
        case .type:
            guard let text = step.text else { return false }
            // Самопроверка/подтверждение на крит. действия (пример: публикации/пароли)
            if needsConfirm(for: text) {
                let proceed = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                    self.pendingConfirm = { agree in
                        continuation.resume(returning: agree)
                    }
                    self.onConfirm?("Подтвердить ввод текста?", { self.resolveConfirmation(agree: true) }, { self.resolveConfirmation(agree: false) })
                }
                self.onConfirmResolved?()
                guard proceed else { return false }
            }
            return typer.type(text: text)
        case .wait_for:
            let timeout = (step.timeout_ms ?? 1000)
            return await waitFor.wait(timeoutMs: timeout)
        case .navigate_url:
            guard let url = step.url else { return false }
            if needsConfirm(for: url) {
                let proceed = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                    self.pendingConfirm = { agree in
                        continuation.resume(returning: agree)
                    }
                    self.onConfirm?("Открыть URL?", { self.resolveConfirmation(agree: true) }, { self.resolveConfirmation(agree: false) })
                }
                self.onConfirmResolved?()
                guard proceed else { return false }
            }
            return nav.open(urlString: url)
        case .create_folder:
            let name = step.name ?? step.text ?? "NewFolder"
            return fileTool.createFolderOnDesktop(name: name)
        }
    }

    private func needsConfirm(for text: String) -> Bool {
        let risky = ["парол", "password", "публикац", "опубликовать", "submit", "authorize", "авториза"]
        return risky.contains { text.lowercased().contains($0) }
    }

    func resolveConfirmation(agree: Bool) {
        let p = pendingConfirm
        pendingConfirm = nil
        p?(agree)
    }

    func resolveAsk(text: String?) {
        let p = pendingAsk
        pendingAsk = nil
        onAskInputResolved?()
        p?(text)
    }

    private func askText(prompt: String, placeholder: String = "") async -> String? {
        await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            self.pendingAsk = { txt in continuation.resume(returning: txt) }
            self.onAskInput?(prompt, placeholder)
        }
    }

    // Facebook post flow (упрощённый MVP с уточнениями)
    private func flowFacebookPost() async {
        let planId = UUID().uuidString
        BrisaLogger.shared.info("FB flow start: \(planId)")
        self.onStepUpdate?("Открыть Facebook")
        _ = await self.perform(step: PlanStep(type: .navigate_url, name: nil, x: nil, y: nil, text: nil, target: nil, timeout_ms: 0, url: "https://www.facebook.com"))
        self.onStepUpdate?("Ожидание загрузки страницы")
        _ = await self.perform(step: PlanStep(type: .wait_for, name: nil, x: nil, y: nil, text: nil, target: "facebook home", timeout_ms: 5000, url: nil))

        // Проверяем по OCR: если видно домашнюю ленту, пропускаем логин
        var needsLogin = true
        if let img = ScreenCapture.shared.snapshotActiveScreen(), let ocr = await VisionAnalyzer.shared.ocr(image: img) {
            needsLogin = !VisionAnalyzer.shared.looksLikeLoggedInFacebook(ocr.text)
            BrisaLogger.shared.info("FB login needed=\(needsLogin)")
        }
        if needsLogin {
            let proceedLogin = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                self.pendingConfirm = { agree in continuation.resume(returning: agree) }
                self.onConfirm?("Если требуется, авторизуйтесь в Facebook и нажмите 'Подтвердить'", { self.resolveConfirmation(agree: true) }, { self.resolveConfirmation(agree: false) })
            }
            self.onConfirmResolved?()
            guard proceedLogin else { self.onPlanFinished?(); return }
        }

        // Уточнить цель публикации
        let target = (await askText(prompt: "Куда опубликовать пост? (Профиль/Страница/Группа)", placeholder: "например, Профиль")) ?? "Профиль"
        BrisaLogger.shared.info("FB target: \(target)")
        // Уточнить текст
        guard let message = await askText(prompt: "Текст поста?", placeholder: "Введите текст") else { self.onPlanFinished?(); return }
        BrisaLogger.shared.info("FB message len=\(message.count)")

        self.onStepUpdate?("Подготовка поля ввода")
        let proceedFocus = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            self.pendingConfirm = { agree in continuation.resume(returning: agree) }
            self.onConfirm?("Нажмите в поле 'Создать публикацию' и подтвердите", { self.resolveConfirmation(agree: true) }, { self.resolveConfirmation(agree: false) })
        }
        self.onConfirmResolved?()
        guard proceedFocus else { self.onPlanFinished?(); return }

        self.onStepUpdate?("Ввод текста")
        _ = await self.perform(step: PlanStep(type: .type, name: nil, x: nil, y: nil, text: message, target: nil, timeout_ms: 0, url: nil))

        self.onStepUpdate?("Проверка/публикация")
        let proceedPublish = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            self.pendingConfirm = { agree in continuation.resume(returning: agree) }
            self.onConfirm?("Готово публиковать? Браузер: нажмите кнопку 'Опубликовать' и подтвердите.", { self.resolveConfirmation(agree: true) }, { self.resolveConfirmation(agree: false) })
        }
        self.onConfirmResolved?()
        if proceedPublish {
            self.onStepUpdate?("Публикация отправлена")
        }
        self.onPlanFinished?()
        BrisaLogger.shared.info("FB flow finished: \(planId)")
    }
}
