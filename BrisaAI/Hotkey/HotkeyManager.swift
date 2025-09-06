import Foundation
import AppKit
import Carbon

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyEventHandler: EventHandlerRef?
    private var handler: (() -> Void)?

    // По умолчанию ⌥Space (Option + Space)
    func registerDefaultHotkey(_ handler: @escaping () -> Void) {
        registerHotkey(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey), handler: handler)
    }

    func registerHotkey(keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        unregister()
        self.handler = handler

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let eventHandler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
            manager.handler?()
            return noErr
        }

        InstallEventHandler(GetEventDispatcherTarget(), eventHandler, 1, &eventType, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), &hotKeyEventHandler)

        var hotKeyID = EventHotKeyID(signature: OSType(UTGetOSTypeFromString("BRSA" as CFString)), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let hk = hotKeyRef { UnregisterEventHotKey(hk) }
        if let h = hotKeyEventHandler { RemoveEventHandler(h) }
        hotKeyRef = nil
        hotKeyEventHandler = nil
    }

    deinit { unregister() }
}
