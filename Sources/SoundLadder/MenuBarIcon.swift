import AppKit

/// Menüleisten-Symbol im Stil des App-Icons: Lautsprecher + Rangliste.
/// Als Template-Bild passt es sich automatisch an hellen/dunklen Modus an.
/// Ist das automatische Umschalten aus, werden die Balken blass dargestellt.
enum MenuBarIcon {
    static func image(autoSwitch: Bool) -> NSImage {
        let img = NSImage(size: NSSize(width: 22, height: 18), flipped: true) { _ in
            NSColor.black.setFill()

            // Lautsprecher
            NSBezierPath(roundedRect: NSRect(x: 1, y: 6.5, width: 3.2, height: 5), xRadius: 0.8, yRadius: 0.8).fill()
            let cone = NSBezierPath()
            cone.move(to: NSPoint(x: 3.6, y: 6.8))
            cone.line(to: NSPoint(x: 8.6, y: 2.6))
            cone.line(to: NSPoint(x: 8.6, y: 15.4))
            cone.line(to: NSPoint(x: 3.6, y: 11.2))
            cone.close()
            cone.fill()

            // Rangliste
            let bars: [(y: CGFloat, w: CGFloat, a: CGFloat)] = [(3.2, 10.5, 1), (8, 8, 0.8), (12.8, 5.5, 0.6)]
            for bar in bars {
                NSColor.black.withAlphaComponent(autoSwitch ? bar.a : 0.3).setFill()
                NSBezierPath(roundedRect: NSRect(x: 10.8, y: bar.y, width: bar.w, height: 2.2),
                             xRadius: 1.1, yRadius: 1.1).fill()
            }
            return true
        }
        img.isTemplate = true
        img.accessibilityDescription = "SoundLadder"
        return img
    }
}
