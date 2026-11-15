import CoreAudio
import Foundation

/// Ein aktuell angeschlossenes Audio-Ausgabegerät.
struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let transportType: UInt32
}

/// Dünne Hülle um die CoreAudio-HAL-API.
enum CoreAudioHelper {
    private static let systemObject = AudioObjectID(kAudioObjectSystemObject)

    private static func address(_ selector: AudioObjectPropertySelector,
                                scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    // MARK: Geräte auflisten

    static func outputDevices() -> [AudioDevice] {
        allDeviceIDs().compactMap { id in
            guard hasOutputStreams(id), let uid = uid(of: id) else { return nil }
            // Geräte, die nicht als Standardausgabe gewählt werden können, ausblenden
            guard canBeDefaultOutput(id) else { return nil }
            return AudioDevice(id: id, uid: uid, name: name(of: id) ?? uid, transportType: transportType(of: id))
        }
    }

    private static func allDeviceIDs() -> [AudioDeviceID] {
        var addr = address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(systemObject, &addr, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(systemObject, &addr, 0, nil, &size, &ids) == noErr else { return [] }
        return ids
    }

    private static func hasOutputStreams(_ id: AudioDeviceID) -> Bool {
        var addr = address(kAudioDevicePropertyStreams, scope: kAudioObjectPropertyScopeOutput)
        var size: UInt32 = 0
        return AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr && size > 0
    }

    private static func canBeDefaultOutput(_ id: AudioDeviceID) -> Bool {
        var addr = address(kAudioDevicePropertyDeviceCanBeDefaultDevice, scope: kAudioObjectPropertyScopeOutput)
        var value: UInt32 = 1
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &value) == noErr else { return true }
        return value != 0
    }

    private static func string(_ id: AudioObjectID, _ selector: AudioObjectPropertySelector) -> String? {
        var addr = address(selector)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &value) == noErr,
              let str = value?.takeRetainedValue() else { return nil }
        return str as String
    }

    static func uid(of id: AudioDeviceID) -> String? { string(id, kAudioDevicePropertyDeviceUID) }
    static func name(of id: AudioDeviceID) -> String? { string(id, kAudioObjectPropertyName) }

    private static func transportType(of id: AudioDeviceID) -> UInt32 {
        var addr = address(kAudioDevicePropertyTransportType)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &value)
        return value
    }

    // MARK: Standardausgabe

    static func defaultOutput(system: Bool = false) -> AudioDeviceID? {
        var addr = address(system ? kAudioHardwarePropertyDefaultSystemOutputDevice : kAudioHardwarePropertyDefaultOutputDevice)
        var id = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(systemObject, &addr, 0, nil, &size, &id) == noErr, id != 0 else { return nil }
        return id
    }

    @discardableResult
    static func setDefaultOutput(_ id: AudioDeviceID, system: Bool = false) -> Bool {
        var addr = address(system ? kAudioHardwarePropertyDefaultSystemOutputDevice : kAudioHardwarePropertyDefaultOutputDevice)
        var value = id
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        return AudioObjectSetPropertyData(systemObject, &addr, 0, nil, size, &value) == noErr
    }

    // MARK: Änderungen beobachten

    /// Registriert einen Listener auf dem Systemobjekt. Der Block läuft auf der Main-Queue.
    static func observe(_ selector: AudioObjectPropertySelector, _ handler: @escaping () -> Void) {
        var addr = address(selector)
        AudioObjectAddPropertyListenerBlock(systemObject, &addr, DispatchQueue.main) { _, _ in handler() }
    }
}
