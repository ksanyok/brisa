import SwiftUI

/// Вкладка настроек приложения. Содержит базовые параметры, которые можно расширить в будущем.
struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var workspacePath: String = "~/BrisaWorkspace"
    // Горячие клавиши для различных действий. В будущем планируется использование глобальных хоткеев.
    @State private var overlayHotkey: String = ""
    @State private var talkHotkey: String = ""
    @State private var cloneHotkey: String = ""
    @State private var agentSpaceHotkey: String = ""
    @State private var pauseHotkey: String = ""

    var body: some View {
        Form {
            Section(header: Text("OpenAI")) {
                SecureField("API Key", text: $apiKey)
                Button("Сохранить ключ") {
                    // Сохраняем ключ в UserDefaults для MVP и настраиваем RealtimeManager
                    UserDefaults.standard.set(apiKey, forKey: "OpenAIAPIKey")
                    RealtimeManager.shared.configure(apiKey: apiKey)
                }
                Text("Ваш ключ сохраняется локально и используется для запросов к OpenAI.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Section(header: Text("Рабочая папка")) {
                TextField("Путь", text: $workspacePath)
                Text("Папка для временных файлов и артефактов Brisa.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Section(header: Text("Безопасность")) {
                Text("Политика подтверждений настраивается через RiskPolicy и будет интегрирована в будущих версиях.")
                    .font(.footnote)
            }
            Section(header: Text("Горячие клавиши")) {
                TextField("Открыть Overlay", text: $overlayHotkey)
                    .onChange(of: overlayHotkey) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "HotkeyOverlay")
                    }
                TextField("Push-to-talk", text: $talkHotkey)
                    .onChange(of: talkHotkey) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "HotkeyTalk")
                    }
                TextField("Показать Clone View", text: $cloneHotkey)
                    .onChange(of: cloneHotkey) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "HotkeyClone")
                    }
                TextField("Перейти к Agent Space", text: $agentSpaceHotkey)
                    .onChange(of: agentSpaceHotkey) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "HotkeyAgentSpace")
                    }
                TextField("Пауза/Возобновить", text: $pauseHotkey)
                    .onChange(of: pauseHotkey) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "HotkeyPause")
                    }
                Text("Укажите желаемые сочетания клавиш. Реализация глобальных хоткеев появится в следующих версиях.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Загружаем сохранённый ключ при открытии настроек
            if let storedKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey"), !storedKey.isEmpty {
                apiKey = storedKey
                RealtimeManager.shared.configure(apiKey: storedKey)
            }
            // Загружаем сохранённые горячие клавиши
            overlayHotkey = UserDefaults.standard.string(forKey: "HotkeyOverlay") ?? overlayHotkey
            talkHotkey = UserDefaults.standard.string(forKey: "HotkeyTalk") ?? talkHotkey
            cloneHotkey = UserDefaults.standard.string(forKey: "HotkeyClone") ?? cloneHotkey
            agentSpaceHotkey = UserDefaults.standard.string(forKey: "HotkeyAgentSpace") ?? agentSpaceHotkey
            pauseHotkey = UserDefaults.standard.string(forKey: "HotkeyPause") ?? pauseHotkey
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}