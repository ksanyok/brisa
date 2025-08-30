import SwiftUI

/// Интерфейс для ввода голосовых и текстовых команд.
struct OverlayView: View {
    @State private var inputText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Введите команду...", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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

    private func send() {
        // TODO: передать текст в RealtimeEngine и очистить поле ввода
        inputText = ""
    }

    private func talk() {
        // TODO: активировать запись голоса и потоковую отправку
    }
}

struct OverlayView_Previews: PreviewProvider {
    static var previews: some View {
        OverlayView()
    }
}