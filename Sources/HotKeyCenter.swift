import Carbon
import Foundation

final class HotKeyCenter {
    static let shared = HotKeyCenter()
    private var hotKeyRef: EventHotKeyRef?
    var onCapture: (() -> Void)?

    func register() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x414E4348), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_J), UInt32(cmdKey | optionKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            if hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    HotKeyCenter.shared.onCapture?()
                }
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }
}
