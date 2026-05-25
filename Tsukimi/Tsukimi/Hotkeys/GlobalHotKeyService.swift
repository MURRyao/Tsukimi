import Carbon
import Foundation

enum TsukimiShortcut: CaseIterable, Identifiable {
    case captureArea
    case toggleShelf

    var id: UInt32 {
        switch self {
        case .captureArea:
            return 1
        case .toggleShelf:
            return 2
        }
    }

    var title: String {
        switch self {
        case .captureArea:
            return "Capture Area"
        case .toggleShelf:
            return "Show or Hide Shelf"
        }
    }

    var displayName: String {
        switch self {
        case .captureArea:
            return "Control Option S"
        case .toggleShelf:
            return "Control Option B"
        }
    }

    var symbolicDisplayName: String {
        switch self {
        case .captureArea:
            return "⌃⌥S"
        case .toggleShelf:
            return "⌃⌥B"
        }
    }

    fileprivate var keyCode: UInt32 {
        switch self {
        case .captureArea:
            return UInt32(kVK_ANSI_S)
        case .toggleShelf:
            return UInt32(kVK_ANSI_B)
        }
    }

    fileprivate var modifiers: UInt32 {
        UInt32(controlKey | optionKey)
    }
}

struct GlobalHotKeyRegistration {
    let shortcut: TsukimiShortcut
    let action: () -> Void
}

enum GlobalHotKeyError: Error {
    case handlerInstallFailed(OSStatus)
    case registrationFailed(TsukimiShortcut, OSStatus)
}

final class GlobalHotKeyService {
    private static let signature = fourCharCode("TSKM")

    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var actions: [UInt32: () -> Void] = [:]

    private let eventHandler: EventHandlerUPP = { _, eventRef, userData in
        guard let eventRef, let userData else { return noErr }
        let service = Unmanaged<GlobalHotKeyService>.fromOpaque(userData).takeUnretainedValue()
        return service.handleHotKeyEvent(eventRef)
    }

    deinit {
        stop()
    }

    func start(registrations: [GlobalHotKeyRegistration]) throws {
        stop()

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandler,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            throw GlobalHotKeyError.handlerInstallFailed(handlerStatus)
        }

        do {
            for registration in registrations {
                try register(registration)
            }
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        for ref in hotKeyRefs.values {
            UnregisterEventHotKey(ref)
        }

        hotKeyRefs.removeAll()
        actions.removeAll()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func register(_ registration: GlobalHotKeyRegistration) throws {
        let shortcut = registration.shortcut
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: shortcut.id)
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            throw GlobalHotKeyError.registrationFailed(shortcut, status)
        }

        hotKeyRefs[shortcut.id] = hotKeyRef
        actions[shortcut.id] = registration.action
    }

    private func handleHotKeyEvent(_ eventRef: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else { return status }
        guard let action = actions[hotKeyID.id] else { return OSStatus(eventNotHandledErr) }

        DispatchQueue.main.async(execute: action)
        return noErr
    }
}

private func fourCharCode(_ value: String) -> OSType {
    precondition(value.utf8.count == 4)

    return value.utf8.reduce(0) { result, character in
        (result << 8) + OSType(character)
    }
}
