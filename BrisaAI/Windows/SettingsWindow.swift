import SwiftUI

struct SettingsWindow: View {
    @State private var apiKey: String = KeychainHelper.shared.getAPIKey() ?? ""
    @State private var model: String = UserDefaults.standard.string(forKey: "responses_model") ?? AppConfig.defaultModel
    @State private var language: String = UserDefaults.standard.string(forKey: "language") ?? "ru"
    @State private var voice: String = UserDefaults.standard.string(forKey: "voice") ?? "none"
    @State private var status: String = ""
    @State private var isTesting = false

    // Разрешения
    @State private var micGranted = PermissionsGuide.shared.isMicrophoneGranted
    @State private var screenGranted = PermissionsGuide.shared.isScreenRecordingGranted
    @State private var axGranted = PermissionsGuide.shared.isAccessibilityGranted

    @State private var tab: Int = 0 // 0=Общее, 1=Разрешения

    let voices = ["none","alloy","ash","ballad","coral","echo","fable","nova","onyx","sage","shimmer","verse","cedar","marin"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                ZStack {
                    Circle().fill(DS.gradient()).frame(width: 36, height: 36).glow()
                    Image(systemName: "sparkles").foregroundStyle(.white)
                }
                Text("Brisa AI – Настройки")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            .padding(.bottom, 2)

            TabView(selection: $tab) {
                // TAB 1: General
                VStack(alignment: .leading, spacing: 10) {
                    GroupBox(label: Text("OpenAI")) {
                        VStack(alignment: .leading, spacing: 10) {
                            SecureField("OpenAI API Key", text: $apiKey)
                            if AppConfig.availableModels.count > 1 {
                                Picker("Модель", selection: $model) {
                                    ForEach(AppConfig.availableModels, id: \.self) { Text($0).tag($0) }
                                }
                            }
                            Picker("Язык", selection: $language) {
                                Text("Русский").tag("ru")
                                Text("English").tag("en")
                            }
                            Picker("Голос", selection: $voice) {
                                ForEach(voices, id: \.self) { Text($0).tag($0) }
                            }
                            if AppConfig.supportsTemperature(model) {
                                HStack {
                                    Text("Температура")
                                    Slider(value: Binding(
                                        get: { UserDefaults.standard.object(forKey: "temperature") as? Double ?? 0.7 },
                                        set: { UserDefaults.standard.set($0, forKey: "temperature") }
                                    ), in: 0...1, step: 0.05)
                                    Text(String(format: "%.2f", UserDefaults.standard.object(forKey: "temperature") as? Double ?? 0.7))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                            }
                            HStack {
                                Button("Проверить ключ") {
                                    isTesting = true
                                    status = "Проверка…"
                                    let client = OpenAIClient()
                                    client.testAPIKey(apiKey: apiKey, model: model) { ok, message in
                                        DispatchQueue.main.async {
                                            isTesting = false
                                            status = ok ? "ОК: \(message)" : "Ошибка: \(message)"
                                        }
                                    }
                                }.buttonStyle(.borderedProminent)
                                 .disabled(apiKey.isEmpty || isTesting)
                                Button("Сохранить") {
                                    KeychainHelper.shared.setAPIKey(apiKey)
                                    UserDefaults.standard.set(model, forKey: "responses_model")
                                    UserDefaults.standard.set(language, forKey: "language")
                                    UserDefaults.standard.set(voice, forKey: "voice")
                                    status = "Сохранено"
                                }
                                Button("Прослушать голос") {
                                    guard voice != "none" else { return }
                                    let text = language == "ru" ? "Это демонстрация голоса Brisa." : "This is a Brisa voice preview."
                                    let apiKey = KeychainHelper.shared.getAPIKey() ?? ""
                                    TTSManager.shared.speak(text: text, voice: voice)
                                }
                                Spacer()
                                Text(status).font(.footnote)
                            }
                        }
                    }
                }
                .padding(4)
                .tabItem { Label("Общее", systemImage: "slider.horizontal.3") }
                .tag(0)

                // TAB 2: Permissions
                VStack(alignment: .leading, spacing: 10) {
                    GroupBox(label: Text("Разрешения")) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                statusDot(micGranted)
                                Text("Микрофон: \(micGranted ? "разрешен" : "не разрешен")")
                                Spacer()
                                Button(micGranted ? "ОК" : "Запросить") {
                                    PermissionsGuide.shared.requestMicrophone { granted in
                                        micGranted = granted
                                    }
                                }.disabled(micGranted)
                            }
                            HStack(alignment: .center) {
                                statusDot(screenGranted)
                                Text("Запись экрана: \(screenGranted ? "разрешена" : "не разрешена")")
                                Spacer()
                                Button(screenGranted ? "ОК" : "Запросить") {
                                    PermissionsGuide.shared.requestScreenRecording { granted in
                                        screenGranted = granted
                                    }
                                }.disabled(screenGranted)
                                Button("Открыть настройки") { PermissionsGuide.shared.openScreenRecordingSettings() }
                            }
                            Text("После выдачи доступа к записи экрана может потребоваться перезапуск приложения.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            HStack {
                                statusDot(axGranted)
                                Text("Accessibility: \(axGranted ? "разрешен" : "не разрешен")")
                                Spacer()
                                Button(axGranted ? "ОК" : "Запросить") {
                                    PermissionsGuide.shared.requestAccessibilityPrompt()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        axGranted = PermissionsGuide.shared.isAccessibilityGranted
                                    }
                                }.disabled(axGranted)
                                Button("Открыть настройки") { PermissionsGuide.shared.openAccessibilitySettings() }
                            }
                            HStack {
                                Button("Обновить статусы") { reloadPermissions() }
                                Spacer()
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(4)
                .tabItem { Label("Разрешения", systemImage: "lock.shield") }
                .tag(1)
            }
            .tabViewStyle(.automatic)
        }
        .padding(16)
        .background(DS.bg)
        .onAppear { reloadPermissions() }
    }
}

private extension SettingsWindow {
    func statusDot(_ ok: Bool) -> some View {
        Circle()
            .fill(ok ? Color.green : Color.red)
            .frame(width: 10, height: 10)
            .padding(.trailing, 4)
    }

    func reloadPermissions() {
        micGranted = PermissionsGuide.shared.isMicrophoneGranted
        screenGranted = PermissionsGuide.shared.isScreenRecordingGranted
        axGranted = PermissionsGuide.shared.isAccessibilityGranted
    }
}
