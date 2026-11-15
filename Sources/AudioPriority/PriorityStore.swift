import CoreAudio
import Foundation
import ServiceManagement

/// Ein Eintrag in der Prioritätenliste. Wird über die Geräte-UID identifiziert,
/// damit auch aktuell nicht angeschlossene Geräte ihren Platz behalten.
struct PriorityEntry: Identifiable, Codable, Hashable {
    var uid: String
    var name: String
    var enabled: Bool = true
    var transportType: UInt32 = 0
    var id: String { uid }
}

final class PriorityStore: ObservableObject {
    @Published var entries: [PriorityEntry] = [] { didSet { save() } }
    @Published private(set) var connected: [String: AudioDevice] = [:]
    @Published private(set) var currentUID: String?
    @Published private(set) var lastAction: String = ""

    @Published var autoSwitch: Bool { didSet { defaults.set(autoSwitch, forKey: Keys.auto); if autoSwitch { apply() } } }
    @Published var includeSystemOutput: Bool { didSet { defaults.set(includeSystemOutput, forKey: Keys.system); if autoSwitch { apply() } } }
    @Published var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled {
        didSet {
            guard launchAtLogin != (SMAppService.mainApp.status == .enabled) else { return }
            do {
                if launchAtLogin { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            } catch {
                lastAction = "Autostart fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let entries = "priorityEntries"
        static let auto = "autoSwitch"
        static let system = "includeSystemOutput"
    }
    private var pendingRefresh: DispatchWorkItem?

    init() {
        autoSwitch = defaults.object(forKey: Keys.auto) as? Bool ?? true
        includeSystemOutput = defaults.object(forKey: Keys.system) as? Bool ?? true
        if let data = defaults.data(forKey: Keys.entries),
           let saved = try? JSONDecoder().decode([PriorityEntry].self, from: data) {
            entries = saved
            refresh(applyRules: true)
        } else {
            // Erster Start: nichts umschalten, aktuelles Gerät an die Spitze setzen
            refresh(applyRules: false)
            if let uid = currentUID, let i = entries.firstIndex(where: { $0.uid == uid }) {
                entries.insert(entries.remove(at: i), at: 0)
            }
        }

        CoreAudioHelper.observe(kAudioHardwarePropertyDevices) { [weak self] in
            // Kurz warten: frisch verbundene Geräte (v. a. Bluetooth) sind nicht sofort bereit
            // und macOS schaltet ggf. selbst noch um – danach setzen wir unsere Priorität durch.
            self?.scheduleRefresh()
        }
        CoreAudioHelper.observe(kAudioHardwarePropertyDefaultOutputDevice) { [weak self] in
            self?.refresh(applyRules: false)
        }
    }

    // MARK: Abgeleitete Werte

    var currentName: String {
        currentUID.flatMap { uid in entries.first { $0.uid == uid }.map(displayName) ?? connected[uid]?.name } ?? "–"
    }

    func isConnected(_ entry: PriorityEntry) -> Bool { connected[entry.uid] != nil }

    /// Name mit Nummer, falls mehrere Geräte gleich heißen (z. B. zwei Monitor-Ausgänge).
    func displayName(_ entry: PriorityEntry) -> String {
        let same = entries.filter { $0.name == entry.name }.sorted { $0.uid < $1.uid }
        guard same.count > 1, let n = same.firstIndex(where: { $0.uid == entry.uid }) else { return entry.name }
        return "\(entry.name) (\(n + 1))"
    }

    /// Das Gerät, das laut Prioritätenliste gerade aktiv sein sollte.
    var preferred: AudioDevice? {
        entries.lazy.filter(\.enabled).compactMap { self.connected[$0.uid] }.first
    }

    // MARK: Aktionen

    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.refresh(applyRules: true) }
        pendingRefresh = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }

    func refresh(applyRules: Bool) {
        let devices = CoreAudioHelper.outputDevices()
        connected = Dictionary(devices.map { ($0.uid, $0) }, uniquingKeysWith: { a, _ in a })

        // Neue Geräte hinten anhängen, Namen/Typ bekannter Geräte aktualisieren
        var updated = entries
        for device in devices {
            if let i = updated.firstIndex(where: { $0.uid == device.uid }) {
                updated[i].name = device.name
                updated[i].transportType = device.transportType
            } else {
                updated.append(PriorityEntry(uid: device.uid, name: device.name, transportType: device.transportType))
            }
        }
        if updated != entries { entries = updated }

        currentUID = CoreAudioHelper.defaultOutput().flatMap(CoreAudioHelper.uid(of:))
        if applyRules && autoSwitch { apply() }
    }

    /// Wählt das höchstpriorisierte verfügbare Gerät als Ausgabe.
    func apply() {
        guard let target = preferred else {
            lastAction = "Kein aktiviertes Gerät verfügbar"
            return
        }
        select(target, reason: "Automatisch")
    }

    func select(_ device: AudioDevice, reason: String = "Manuell") {
        var ok = true
        if CoreAudioHelper.defaultOutput() != device.id {
            ok = CoreAudioHelper.setDefaultOutput(device.id)
        }
        if includeSystemOutput, CoreAudioHelper.defaultOutput(system: true) != device.id {
            ok = CoreAudioHelper.setDefaultOutput(device.id, system: true) && ok
        }
        currentUID = CoreAudioHelper.defaultOutput().flatMap(CoreAudioHelper.uid(of:))
        let time = Date().formatted(date: .omitted, time: .shortened)
        lastAction = ok ? "\(reason): \(device.name) (\(time))" : "Umschalten auf \(device.name) fehlgeschlagen"
    }

    func move(from source: IndexSet, to destination: Int) {
        entries.move(fromOffsets: source, toOffset: destination)
        if autoSwitch { apply() }
    }

    func setEnabled(_ entry: PriorityEntry, _ enabled: Bool) {
        guard let i = entries.firstIndex(where: { $0.uid == entry.uid }) else { return }
        entries[i].enabled = enabled
        if autoSwitch { apply() }
    }

    func forget(_ entry: PriorityEntry) {
        entries.removeAll { $0.uid == entry.uid }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) { defaults.set(data, forKey: Keys.entries) }
    }
}
