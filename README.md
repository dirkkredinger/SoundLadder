# Audio-Prioritäten

macOS-Menüleisten-App, die die Audioausgabe nach einer festen Prioritätenliste wählt.
Ist das bevorzugte Gerät nicht angeschlossen, wird automatisch das nächste in der Liste verwendet.

## Funktionen
- Erkannte Ausgabegeräte per Drag & Drop sortieren (auch nicht verbundene behalten ihren Platz)
- Automatisches Umschalten beim An-/Abstecken von Geräten
- Geräte einzeln von der Automatik ausschließen
- Optional auch Systemtöne umleiten, Start bei Anmeldung
- Manuelle Auswahl über das Menüleisten-Symbol

## Bauen
Voraussetzung: Xcode Command Line Tools (Swift 5.9+), macOS 13+.

```bash
./build.sh                               # -> build/AudioPriority.app
VERSION=1.2 Installer/make_installer.sh  # -> dist/AudioPriority-1.2.pkg
Installer/uninstall.sh                   # App vollständig entfernen
```

## Aufbau
- `Sources/AudioPriority/CoreAudioHelper.swift` – Zugriff auf CoreAudio (Geräte, Standardausgabe, Listener)
- `Sources/AudioPriority/PriorityStore.swift` – Prioritätenliste, Persistenz, Umschaltlogik
- `Sources/AudioPriority/AudioPriorityApp.swift` – SwiftUI-Fenster und Menüleisten-Menü
- `Sources/AudioPriority/MenuBarIcon.swift` – Menüleisten-Symbol
- `Tools/make_icon.swift` – erzeugt `Resources/AppIcon.icns`
- `Installer/` – pkg-Installer (Skripte, Begrüßungs-/Abschlussseiten)
