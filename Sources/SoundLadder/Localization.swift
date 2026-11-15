import Foundation

/// Übersetzt einen englischen Text (Schlüssel) über Resources/<sprache>.lproj/Localizable.strings.
/// SwiftUI-Texte mit festen Zeichenketten werden automatisch übersetzt; L() ist für alles andere.
func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
