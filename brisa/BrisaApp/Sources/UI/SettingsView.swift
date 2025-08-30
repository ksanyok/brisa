import SwiftUI

/// Вкладка настроек приложения. Содержит базовые параметры, которые можно расширить в будущем.
struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var workspacePath: String = "~/BrisaWorkspace"

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
        }
        .onAppear {
            // Загружаем сохранённый ключ при открытии настроек
            if let storedKey = UserDefaults.standard.string(forKey: "OpenAIAPIKey"), !storedKey.isEmpty {
                apiKey = storedKey
                RealtimeManager.shared.configure(apiKey: storedKey)
            }
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