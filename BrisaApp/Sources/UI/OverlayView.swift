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
            // История сообщений. Используем MessageBubble для стилизованных пузырей.
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(realtimeManager.messages) { message in
                        MessageBubble(text: message.content, isUser: message.isUser)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.windowBackgroundColor))
                    .opacity(0.2)
            )

            Divider()

            // Поле ввода команды с футуристическим стилем
            HStack(spacing: 8) {
                TextField(
                    "Введите команду...",
                    text: $inputText,
                    prompt: Text("Запрос или команда")
                )
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Color.accentColor.opacity(0.5))
                )
                .onSubmit {
                    send()
                }

                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.accentColor)
                }
                Button(action: talk) {
                    Image(systemName: "mic.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(20)
        .frame(width: 420)
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

/// Вспомогательное представление для одного сообщения чата. Стиль различается для
/// пользователя и ассистента: сообщения пользователя выравниваются вправо и имеют
/// акцентный цвет, сообщения ассистента — влево с более приглушенным фоном.
fileprivate struct MessageBubble: View {
    let text: String
    let isUser: Bool

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 30) }
            Text(text)
                .padding(10)
                .foregroundColor(isUser ? .white : .primary)
                .background(isUser ? Color.accentColor : Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            if !isUser { Spacer(minLength: 30) }
        }
    }
}