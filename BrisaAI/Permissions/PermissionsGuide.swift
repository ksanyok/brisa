import Foundation
import AppKit
import AVFoundation
import CoreGraphics

final class PermissionsGuide {
    static let shared = PermissionsGuide()
    private init() {}

    var hasCompletedConsent: Bool {
        get { UserDefaults.standard.bool(forKey: "consent_done") }
        set { UserDefaults.standard.set(newValue, forKey: "consent_done") }
    }

    var isMicrophoneGranted: Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return true
        default: return false
        }
    }

    var isScreenRecordingGranted: Bool {
        if #available(macOS 10.15, *) {
            return CGPreflightScreenCaptureAccess()
        } else {
            return true
        }
    }

    var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    func requestMicrophone(_ completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenRecording") {
            NSWorkspace.shared.open(url)
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func requestScreenRecording(_ completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            var granted = true
            if #available(macOS 10.15, *) {
                granted = CGRequestScreenCaptureAccess()
            }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func requestAccessibilityPrompt() {
        let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
