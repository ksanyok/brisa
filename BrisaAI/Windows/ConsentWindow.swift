import SwiftUI
import AVFoundation

struct ConsentWindow: View {
    var onDone: () -> Void
    @State private var micGranted = PermissionsGuide.shared.isMicrophoneGranted
    @State private var screenGranted = PermissionsGuide.shared.isScreenRecordingGranted
    @State private var axGranted = PermissionsGuide.shared.isAccessibilityGranted

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Первичная настройка разрешений").font(.title3).bold()
            Text("Для работы Brisa нужны разрешения: микрофон, запись экрана и доступность (Accessibility).")
            GroupBox(label: Text("Микрофон: \(micGranted ? "разрешен" : "не разрешен")")) {
                HStack {
                    Button("Запросить") { PermissionsGuide.shared.requestMicrophone { micGranted = $0 } }
                    Spacer()
                }
            }
            GroupBox(label: Text("Запись экрана: \(screenGranted ? "разрешена" : "не разрешена")")) {
                HStack {
                    Button("Открыть настройки") { PermissionsGuide.shared.openScreenRecordingSettings() }
                    Spacer()
                }
            }
            GroupBox(label: Text("Accessibility: \(axGranted ? "разрешен" : "не разрешен")")) {
                HStack {
                    Button("Открыть настройки") { PermissionsGuide.shared.openAccessibilitySettings() }
                    Spacer()
                }
            }
            HStack {
                Button("Готово") {
                    PermissionsGuide.shared.hasCompletedConsent = true
                    onDone()
                }
                .disabled(!(micGranted && axGranted))
                Spacer()
            }
        }
        .padding(16)
        .onAppear {
            micGranted = PermissionsGuide.shared.isMicrophoneGranted
            screenGranted = PermissionsGuide.shared.isScreenRecordingGranted
            axGranted = PermissionsGuide.shared.isAccessibilityGranted
        }
    }
}

