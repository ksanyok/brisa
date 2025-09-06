import SwiftUI

struct SettingsWindow: View {
    @State private var apiKey: String = KeychainHelper.shared.getAPIKey() ?? ""
    @State private var model: String = UserDefaults.standard.string(forKey: "responses_model") ?? "gpt-4o-realtime"
    @State private var language: String = UserDefaults.standard.string(forKey: "language") ?? "ru"
    @State private var voice: String = UserDefaults.standard.string(forKey: "voice") ?? "none"
    @State private var status: String = ""
    @State private var isTesting = false

    // Разрешения
    @State private var micGranted = PermissionsGuide.shared.isMicrophoneGranted
    @State private var screenGranted = PermissionsGuide.shared.isScreenRecordingGranted
    @State private var axGranted = PermissionsGuide.shared.isAccessibilityGranted

    let voices = ["none","alloy","ash","ballad","coral","echo","fable","nova","onyx","sage","shimmer","verse","cedar","marin"]

    var body: some View {
        Form {
            SecureField("OpenAI API Key", text: $apiKey)
            TextField("Модель (Responses/Realtime)", text: $model)
            Picker("Язык", selection: $language) {
                Text("Русский").tag("ru")
                Text("English").tag("en")
            }
            Picker("Голос", selection: $voice) {
                ForEach(voices, id: \.self) { Text($0).tag($0) }
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
                }.disabled(apiKey.isEmpty || isTesting)
                Button("Сохранить") {
                    KeychainHelper.shared.setAPIKey(apiKey)
                    UserDefaults.standard.set(model, forKey: "responses_model")
                    UserDefaults.standard.set(language, forKey: "language")
                    UserDefaults.standard.set(voice, forKey: "voice")
                    status = "Сохранено"
                }
                Spacer()
                Text(status).font(.footnote)
            }

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
        .padding(16)
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
