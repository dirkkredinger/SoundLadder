import AppKit

/// Externe Links an einer Stelle.
enum Links {
    static let donate = URL(string: "https://ko-fi.com/mbmf17")!
    static let project = URL(string: "https://github.com/dirkkredinger/SoundLadder")!

    static func showAbout() {
        let credits = NSMutableAttributedString(
            string: L("Automatically picks the available audio output with the highest priority.") + "\n\n",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.labelColor])
        credits.append(NSAttributedString(string: L("Project on GitHub"), attributes: [
            .link: project, .font: NSFont.systemFont(ofSize: 11)]))
        credits.append(NSAttributedString(string: "  ·  ", attributes: [
            .font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]))
        credits.append(NSAttributedString(string: L("Support on Ko-fi ♥"), attributes: [
            .link: donate, .font: NSFont.systemFont(ofSize: 11)]))
        credits.append(NSAttributedString(string: "\n\n" + L("Open source under the MIT License."), attributes: [
            .font: NSFont.systemFont(ofSize: 10), .foregroundColor: NSColor.secondaryLabelColor]))
        let centered = NSMutableParagraphStyle()
        centered.alignment = .center
        credits.addAttribute(.paragraphStyle, value: centered, range: NSRange(location: 0, length: credits.length))

        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}
