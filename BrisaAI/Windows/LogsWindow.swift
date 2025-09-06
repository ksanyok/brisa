import SwiftUI
import Combine

struct LogsWindow: View {
    @State private var content: String = ""
    @State private var timer: AnyCancellable?
    let reloadPublisher = PassthroughSubject<Void, Never>()

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button("Очистить") { BrisaLogger.shared.truncate(); reload() }
                Button("Скопировать всё") { copyAll() }
                Button("Показать в Finder") { revealInFinder() }
                Spacer()
            }
            .padding(.bottom, 4)

            // Вывод логов: выделяемый текст (копируемый)
            ScrollViewReader { proxy in
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .id("bottom")
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: content) { _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
        .padding(12)
        .onAppear {
            startAutoRefresh()
            reload()
        }
        .onDisappear { timer?.cancel() }
        .onReceive(reloadPublisher) { _ in reload() }
    }

    private func startAutoRefresh() {
        timer?.cancel()
        timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink { _ in
            reload()
        }
    }

    private func reload() {
        content = (try? String(contentsOf: BrisaLogger.shared.logFileURL)) ?? ""
    }

    private func copyAll() {
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(content, forType: .string)
    }

    private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([BrisaLogger.shared.logFileURL])
    }
}
