//
//  GlobalHotKeyManager.swift
//  StealthTab
//
//  Registers app-wide keyboard shortcuts for overlay controls.
//

import Carbon
import Foundation

@MainActor
final class GlobalHotKeyManager {
    private enum HotKey: UInt32 {
        case cycleOpacityWithDownArrow = 1
        case cycleOpacityWithUpArrow = 2
    }

    private static let signature: OSType = 0x53544142
    private static weak var current: GlobalHotKeyManager?
    private static let eventHandler: EventHandlerUPP = { _, event, _ in
        guard let event = event else { return noErr }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else { return status }

        Task { @MainActor in
            GlobalHotKeyManager.current?.handleHotKey(id: hotKeyID.id)
        }

        return noErr
    }

    private let cycleOpacity: () -> Void
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []

    init(cycleOpacity: @escaping () -> Void) {
        self.cycleOpacity = cycleOpacity
    }

    func start() {
        stop()

        Self.current = self

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            Self.eventHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        register(.cycleOpacityWithDownArrow, keyCode: kVK_DownArrow)
        register(.cycleOpacityWithUpArrow, keyCode: kVK_UpArrow)
    }

    func stop() {
        hotKeyRefs.forEach { UnregisterEventHotKey($0) }
        hotKeyRefs.removeAll()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }

        if Self.current === self {
            Self.current = nil
        }
    }

    private func register(_ hotKey: HotKey, keyCode: Int) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: hotKey.rawValue)
        let modifiers = UInt32(cmdKey | optionKey | controlKey)

        let status = RegisterEventHotKey(
            UInt32(keyCode),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else { return }
        hotKeyRefs.append(hotKeyRef)
    }

    private func handleHotKey(id: UInt32) {
        guard HotKey(rawValue: id) != nil else { return }
        cycleOpacity()
    }
}
