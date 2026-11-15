import AppKit
import CoreAudio
import SwiftUI

@main
struct AudioPriorityApp: App {
    @StateObject private var store = PriorityStore()

    var body: some Scene {
        Window("Audio-Prioritäten", id: "main") {
            PriorityListView()
                .environmentObject(store)
                .frame(minWidth: 460, minHeight: 380)
                // Solange das Fenster offen ist, erscheint die App im Dock
                .onAppear { NSApp.setActivationPolicy(.regular) }
                .onDisappear { NSApp.setActivationPolicy(.accessory) }
        }
        .windowResizability(.contentMinSize)

        MenuBarExtra {
            MenuContent().environmentObject(store)
        } label: {
            Image(nsImage: MenuBarIcon.image(autoSwitch: store.autoSwitch))
        }
    }
}

// MARK: - Hauptfenster

struct PriorityListView: View {
    @EnvironmentObject var store: PriorityStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ausgabegeräte nach Priorität")
                    .font(.headline)
                Text("Ziehe die Geräte in die gewünschte Reihenfolge. Ist das oberste nicht verfügbar, wird automatisch das nächste gewählt.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()

            List {
                ForEach(Array(store.entries.enumerated()), id: \.element.id) { index, entry in
                    DeviceRow(rank: index + 1, entry: entry)
                }
                .onMove(perform: store.move)
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Automatisch umschalten", isOn: $store.autoSwitch)
                Toggle("Auch Systemtöne (Hinweise, Effekte) umleiten", isOn: $store.includeSystemOutput)
                Toggle("Beim Anmelden starten", isOn: $store.launchAtLogin)
                HStack {
                    Text("Aktuell: \(store.currentName)")
                        .font(.callout)
                    Spacer()
                    Button("Jetzt anwenden") { store.apply() }
                        .keyboardShortcut("r")
                }
                HStack {
                    Text(store.lastAction)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("Gefällt dir die App? Unterstütze sie auf Ko-fi ♥", destination: Links.donate)
                        .font(.caption)
                }
            }
            .padding()
        }
    }
}

struct DeviceRow: View {
    @EnvironmentObject var store: PriorityStore
    let rank: Int
    let entry: PriorityEntry

    var body: some View {
        let connected = store.isConnected(entry)
        let active = store.currentUID == entry.uid

        HStack(spacing: 10) {
            Text("\(rank)")
                .font(.system(.body, design: .rounded).monospacedDigit().bold())
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .trailing)

            Image(systemName: icon(for: entry.transportType))
                .frame(width: 22)
                .foregroundStyle(connected ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.displayName(entry))
                    .strikethrough(!entry.enabled)
                HStack(spacing: 6) {
                    Circle()
                        .fill(connected ? Color.green : Color.gray.opacity(0.5))
                        .frame(width: 7, height: 7)
                    Text(connected ? "Verbunden" : "Nicht verbunden")
                    if active {
                        Text("· Aktive Ausgabe").fontWeight(.semibold)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .opacity(connected ? 1 : 0.6)

            Spacer()

            if !connected {
                Button {
                    store.forget(entry)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Gerät aus der Liste entfernen")
            }

            Toggle("", isOn: Binding(
                get: { entry.enabled },
                set: { store.setEnabled(entry, $0) }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .help("Deaktivierte Geräte werden nie automatisch gewählt")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            if let device = store.connected[entry.uid] {
                Button("Jetzt als Ausgabe verwenden") { store.select(device) }
            }
            Button("Aus Liste entfernen", role: .destructive) { store.forget(entry) }
        }
    }
}

func icon(for transport: UInt32) -> String {
    switch transport {
    case kAudioDeviceTransportTypeBuiltIn: return "laptopcomputer"
    case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return "headphones"
    case kAudioDeviceTransportTypeUSB: return "cable.connector"
    case kAudioDeviceTransportTypeHDMI, kAudioDeviceTransportTypeDisplayPort: return "tv"
    case kAudioDeviceTransportTypeAirPlay: return "airplayaudio"
    case kAudioDeviceTransportTypeThunderbolt: return "bolt"
    case kAudioDeviceTransportTypeVirtual, kAudioDeviceTransportTypeAggregate: return "square.stack.3d.up"
    default: return "hifispeaker"
    }
}

// MARK: - Menüleiste

struct MenuContent: View {
    @EnvironmentObject var store: PriorityStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("Ausgabe: \(store.currentName)")
        Divider()
        ForEach(store.entries.filter { store.isConnected($0) }) { entry in
            if let device = store.connected[entry.uid] {
                Button {
                    store.select(device)
                } label: {
                    if store.currentUID == entry.uid {
                        Label(store.displayName(entry), systemImage: "checkmark")
                    } else {
                        Text(store.displayName(entry))
                    }
                }
            }
        }
        Divider()
        Toggle("Automatisch umschalten", isOn: $store.autoSwitch)
        Button("Prioritäten bearbeiten …") {
            openWindow(id: "main")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")
        Divider()
        Button("Projekt unterstützen ♥") { NSWorkspace.shared.open(Links.donate) }
        Button("Über Audio-Prioritäten") { Links.showAbout() }
        Divider()
        Button("Beenden") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
