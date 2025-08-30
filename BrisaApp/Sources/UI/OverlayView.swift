import SwiftUI

/// Интерфейс для ввода голосовых и текстовых команд.
/// Отображает историю диалога и предоставляет поле ввода с кнопками
/// для отправки текста и (в будущем) голосовых команд.
struct OverlayView: View {
    /// Наблюдаемый менеджер, который отправляет запросы и хранит историю ответов.
    @ObservedObject private var realtimeManager = RealtimeManager.shared
    @State private var inputText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // История сообщений между пользователем и ассистентом
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(realtimeManager.messages.indices, id: \.self) { index in
                        Text(realtimeManager.messages[index])
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(minHeight: 200)

            Divider()

            // Поле ввода команды
            TextField("Введите команду...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    send()
                }
            HStack(spacing: 16) {
                Button(action: send) {
                    Text("Отправить")
                }
                Button(action: talk) {
                    Label("Говорить", systemImage: "mic")
                }
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    /// Отправляет введённый текст в realtime‑движок и очищает поле ввода.
    private func send() {
        realtimeManager.send(text: inputText)
        inputText = ""
    }

    /// Заглушка для голосового ввода; будет реализована в будущем.
    private func talk() {
        // TODO: активировать запись голоса и потоковую отправку
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayView()
    }
}