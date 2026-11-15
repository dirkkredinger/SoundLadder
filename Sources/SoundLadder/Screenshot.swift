import AppKit
import ImageIO
import SwiftUI

/// Erzeugt das Werbebild für GitHub.
/// Aufruf: SoundLadder.app/Contents/MacOS/SoundLadder --screenshot <ausgabe.png>
/// Läuft im Demo-Modus mit Beispielgeräten – echte Einstellungen bleiben unberührt.
@MainActor
enum Screenshot {
    nonisolated static var outputPath: String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--screenshot"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    nonisolated static var gifPath: String? {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--gif"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    nonisolated static var isRequested: Bool { outputPath != nil || gifPath != nil }

    static func prepare() {
        NSApp.appearance = NSAppearance(named: .aqua)
    }

    static func captureWhenReady() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let window = NSApp.windows.first(where: { $0.title == "SoundLadder" }) else {
                NSApp.terminate(nil); return
            }
            if let gif = gifPath {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                window.setContentSize(NSSize(width: 520, height: 560))
                recordGIF(window: window, path: gif)
                return
            }
            guard let path = outputPath else { NSApp.terminate(nil); return }
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.setContentSize(NSSize(width: 520, height: 560))
            window.displayIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let windowImage = snapshot(of: window)
                let poster = compose(window: windowImage)
                if let tiff = poster.tiffRepresentation,
                   let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                    try? png.write(to: URL(fileURLWithPath: path))
                }
                NSApp.terminate(nil)
            }
        }
    }

    // MARK: Animiertes GIF

    private struct GIFStep {
        let airPods: Bool
        let time: String
        let caption: String
        let seconds: Double
    }

    private static func recordGIF(window: NSWindow, path: String) {
        let steps = [
            GIFStep(airPods: true, time: "2:32 PM", caption: L("AirPods connected – SoundLadder uses them"), seconds: 2.2),
            GIFStep(airPods: false, time: "2:33 PM", caption: L("AirPods off – the next device takes over"), seconds: 2.6),
            GIFStep(airPods: true, time: "2:34 PM", caption: L("AirPods back – switched back automatically"), seconds: 2.6),
        ]
        var frames: [(CGImage, Double)] = []

        func capture(_ index: Int) {
            guard index < steps.count else {
                writeGIF(frames, to: path)
                NSApp.terminate(nil)
                return
            }
            let step = steps[index]
            PriorityStore.demoInstance?.demoSetAirPods(connected: step.airPods, time: step.time)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                let frame = composeFrame(window: snapshot(of: window), caption: step.caption)
                if let cg = frame.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    frames.append((cg, step.seconds))
                }
                capture(index + 1)
            }
        }
        capture(0)
    }

    private static func composeFrame(window: NSImage, caption: String) -> NSImage {
        let size = NSSize(width: 680, height: 720)
        let image = NSImage(size: size, flipped: true) { rect in
            NSGradient(colors: [
                NSColor(srgbRed: 0.98, green: 0.36, blue: 0.47, alpha: 1),
                NSColor(srgbRed: 0.55, green: 0.27, blue: 0.95, alpha: 1),
                NSColor(srgbRed: 0.16, green: 0.36, blue: 0.98, alpha: 1),
            ])!.draw(in: rect, angle: -35)
            let winRect = NSRect(x: (rect.width - window.size.width) / 2, y: 28,
                                 width: window.size.width, height: window.size.height)
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(roundedRect: winRect, xRadius: 12, yRadius: 12).addClip()
            window.draw(in: winRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            NSGraphicsContext.restoreGraphicsState()
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            let text = NSAttributedString(string: caption, attributes: [
                .font: NSFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: NSColor.white, .paragraphStyle: style])
            text.draw(in: NSRect(x: 20, y: winRect.maxY + 28, width: rect.width - 40, height: 40))
            return true
        }
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        let out = NSImage(size: size)
        out.addRepresentation(rep)
        return out
    }

    private static func writeGIF(_ frames: [(CGImage, Double)], to path: String) {
        guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                         "com.compuserve.gif" as CFString, frames.count, nil) else { return }
        CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
        for (image, seconds) in frames {
            CGImageDestinationAddImage(dest, image, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: seconds]] as CFDictionary)
        }
        CGImageDestinationFinalize(dest)
    }

    /// Fensterinhalt inkl. Titelleiste als Bild.
    private static func snapshot(of window: NSWindow) -> NSImage {
        let view = window.contentView!.superview ?? window.contentView!
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        let image = NSImage(size: view.bounds.size)
        image.addRepresentation(rep)
        return image
    }

    private static func render<V: View>(_ view: V) -> NSImage {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
        renderer.scale = 2
        return renderer.nsImage ?? NSImage()
    }

    // MARK: Komposition

    private static func compose(window: NSImage) -> NSImage {
        let size = NSSize(width: 1200, height: 750)
        let menu = render(MenuMock())
        let title = render(TitleMock())

        let poster = NSImage(size: size, flipped: true) { rect in
            // Hintergrund im Farbverlauf des App-Icons
            NSGradient(colors: [
                NSColor(srgbRed: 0.98, green: 0.36, blue: 0.47, alpha: 1),
                NSColor(srgbRed: 0.55, green: 0.27, blue: 0.95, alpha: 1),
                NSColor(srgbRed: 0.16, green: 0.36, blue: 0.98, alpha: 1),
            ])!.draw(in: rect, angle: -35)

            // Angedeutete Menüleiste
            NSColor.white.withAlphaComponent(0.28).setFill()
            NSRect(x: 0, y: 0, width: rect.width, height: 30).fill()
            let iconX: CGFloat = 820
            NSColor.white.withAlphaComponent(0.45).setFill()
            NSBezierPath(roundedRect: NSRect(x: iconX - 7, y: 3, width: 36, height: 24), xRadius: 5, yRadius: 5).fill()
            MenuBarIcon.image(autoSwitch: true)
                .draw(in: NSRect(x: iconX, y: 6, width: 22, height: 18), from: .zero,
                      operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            let clock = NSAttributedString(string: L("Sat Nov 15  2:32 PM"), attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor: NSColor.black.withAlphaComponent(0.8)])
            clock.draw(at: NSPoint(x: rect.width - 160, y: 6))

            // Fenster mit Schatten und runden Ecken
            let winRect = NSRect(x: 70, y: 90, width: window.size.width, height: window.size.height)
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
            shadow.shadowBlurRadius = 40
            shadow.shadowOffset = NSSize(width: 0, height: -18)
            shadow.set()
            NSColor.white.setFill()
            NSBezierPath(roundedRect: winRect, xRadius: 12, yRadius: 12).fill()
            NSGraphicsContext.restoreGraphicsState()
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(roundedRect: winRect, xRadius: 12, yRadius: 12).addClip()
            window.draw(in: winRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            NSGraphicsContext.restoreGraphicsState()

            // Menü unter dem Symbol
            let menuRect = NSRect(x: iconX - 14, y: 34, width: menu.size.width, height: menu.size.height)
            menu.draw(in: menuRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)

            // Titel
            let titleRect = NSRect(x: 650, y: rect.height - title.size.height - 70,
                                   width: title.size.width, height: title.size.height)
            title.draw(in: titleRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
            return true
        }

        // In doppelter Auflösung rastern
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * 2), pixelsHigh: Int(size.height * 2),
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        rep.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        poster.draw(in: NSRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        let out = NSImage(size: size)
        out.addRepresentation(rep)
        return out
    }
}

// MARK: - Nachgebautes Menü und Titel (nur für das Werbebild)

private struct MenuMock: View {
    private struct Row: Identifiable {
        let id = UUID()
        var title = ""
        var check = false
        var shortcut = ""
        var highlighted = false
        var secondary = false
        var divider = false
    }

    private let rows: [Row] = [
        Row(title: String(format: L("Output: %@"), "AirPods Pro"), secondary: true),
        Row(divider: true),
        Row(title: "AirPods Pro", check: true),
        Row(title: "Studio Display"),
        Row(title: "LG UltraWide"),
        Row(title: L("MacBook Pro Speakers")),
        Row(divider: true),
        Row(title: L("Switch automatically"), check: true),
        Row(title: L("Edit priorities…"), shortcut: "⌘,", highlighted: true),
        Row(divider: true),
        Row(title: L("Support the project ♥")),
        Row(title: L("About SoundLadder")),
        Row(divider: true),
        Row(title: L("Quit"), shortcut: "⌘Q"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rows) { row in
                if row.divider {
                    Rectangle().fill(Color.black.opacity(0.1)).frame(height: 1).padding(.vertical, 5).padding(.horizontal, 10)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .opacity(row.check ? 1 : 0)
                            .frame(width: 14)
                        Text(row.title)
                        Spacer(minLength: 20)
                        Text(row.shortcut).opacity(0.6)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(row.highlighted ? Color.white : (row.secondary ? Color.black.opacity(0.45) : Color.black.opacity(0.88)))
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(RoundedRectangle(cornerRadius: 5).fill(row.highlighted ? Color.accentColor : .clear))
                    .padding(.horizontal, 5)
                }
            }
        }
        .padding(.vertical, 6)
        .frame(width: 270)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.96)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.12), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.3), radius: 18, y: 10)
        .padding(24)
    }
}

private struct TitleMock: View {
    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text("SoundLadder")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                Text("Your audio output,\nalways in the right order.")
                    .font(.system(size: 20, weight: .medium))
                    .opacity(0.9)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
        .padding(10)
    }
}

extension View {
    /// Im Screenshot-Modus: selbst gezeichnete Schalter/Häkchen in Akzentfarbe,
    /// da die AppKit-Steuerelemente beim Abfotografieren grau erscheinen.
    @ViewBuilder func forceActiveAppearance(_ active: Bool) -> some View {
        if active { self.toggleStyle(PosterCheckboxStyle()) } else { self }
    }

    @ViewBuilder func rowSwitchStyle() -> some View {
        if Screenshot.isRequested { self.toggleStyle(PosterSwitchStyle()) } else { self.toggleStyle(.switch) }
    }
}

private struct PosterSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(configuration.isOn ? Color.accentColor : Color.black.opacity(0.1))
            .frame(width: 38, height: 22)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Circle().fill(.white).padding(2).shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
            }
            .onTapGesture { configuration.isOn.toggle() }
    }
}

private struct PosterCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3.5)
                .fill(configuration.isOn ? Color.accentColor : Color.white)
                .overlay(RoundedRectangle(cornerRadius: 3.5).stroke(Color.black.opacity(configuration.isOn ? 0 : 0.25), lineWidth: 0.5))
                .overlay(Image(systemName: "checkmark").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white)
                    .opacity(configuration.isOn ? 1 : 0))
                .frame(width: 14, height: 14)
            configuration.label
        }
        .onTapGesture { configuration.isOn.toggle() }
    }
}
