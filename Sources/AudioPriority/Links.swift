import AppKit

/// Externe Links an einer Stelle – vor der Veröffentlichung hier anpassen.
enum Links {
    // TODO: echten Ko-fi-Namen eintragen
    static let donate = URL(string: "https://ko-fi.com/DEIN_KOFI_NAME")!
    // TODO: echte GitHub-Adresse eintragen
    static let project = URL(string: "https://github.com/DEIN_GITHUB_NAME/AudioPriority")!

    static func showAbout() {
        let credits = NSMutableAttributedString(
            string: "Wählt automatisch das verfügbare Audio-Ausgabegerät mit der höchsten Priorität.\n\n",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.labelColor])
        credits.append(NSAttributedString(string: "Projekt auf GitHub", attributes: [
            .link: project, .font: NSFont.systemFont(ofSize: 11)]))
        credits.append(NSAttributedString(string: "  ·  ", attributes: [
            .font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]))
        credits.append(NSAttributedString(string: "Auf Ko-fi unterstützen ♥", attributes: [
            .link: donate, .font: NSFont.systemFont(ofSize: 11)]))
        credits.append(NSAttributedString(string: "\n\nOpen Source unter der MIT-Lizenz.", attributes: [
            .font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.secondaryLabelColor]))
        let centered = NSMutableParagraphStyle()
        centered.alignment = .center
        credits.addAttribute(.paragraphStyle, value: centered, range: NSRange(location: 0, length: credits.length))

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}
