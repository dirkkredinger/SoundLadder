// Zeichnet das App-Icon und erzeugt Resources/AppIcon.icns
// Aufruf: swift Tools/make_icon.swift <Ausgabeordner>
import AppKit

func drawIcon(size s: CGFloat) -> NSImage {
    NSImage(size: NSSize(width: s, height: s), flipped: false) { _ in
        let ctx = NSGraphicsContext.current!.cgContext
        let u = s / 1024 // Einheit

        // Grundform im macOS-Stil (abgerundetes Quadrat mit Rand)
        let tile = CGRect(x: 100 * u, y: 100 * u, width: 824 * u, height: 824 * u)
        let tilePath = CGPath(roundedRect: tile, cornerWidth: 185 * u, cornerHeight: 185 * u, transform: nil)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -12 * u), blur: 28 * u,
                      color: NSColor.black.withAlphaComponent(0.35).cgColor)
        ctx.addPath(tilePath); ctx.setFillColor(NSColor.black.cgColor); ctx.fillPath()
        ctx.restoreGState()

        ctx.saveGState()
        ctx.addPath(tilePath); ctx.clip()
        let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
            NSColor(srgbRed: 0.98, green: 0.36, blue: 0.47, alpha: 1).cgColor,
            NSColor(srgbRed: 0.55, green: 0.27, blue: 0.95, alpha: 1).cgColor,
            NSColor(srgbRed: 0.16, green: 0.36, blue: 0.98, alpha: 1).cgColor,
        ] as CFArray, locations: [0, 0.55, 1])!
        ctx.drawLinearGradient(bg, start: CGPoint(x: tile.minX, y: tile.maxY),
                               end: CGPoint(x: tile.maxX, y: tile.minY), options: [])
        // Glanz oben
        let gloss = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [
            NSColor.white.withAlphaComponent(0.22).cgColor, NSColor.white.withAlphaComponent(0).cgColor,
        ] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(gloss, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.midY), options: [])
        ctx.restoreGState()

        // Lautsprecher (weiß, mit leichtem Schatten)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -6 * u), blur: 14 * u,
                      color: NSColor.black.withAlphaComponent(0.25).cgColor)
        ctx.setFillColor(NSColor.white.cgColor)
        let body = CGPath(roundedRect: CGRect(x: 215 * u, y: 420 * u, width: 105 * u, height: 184 * u),
                          cornerWidth: 22 * u, cornerHeight: 22 * u, transform: nil)
        ctx.addPath(body)
        let cone = CGMutablePath()
        cone.move(to: CGPoint(x: 300 * u, y: 430 * u))
        cone.addLine(to: CGPoint(x: 460 * u, y: 295 * u))
        cone.addQuadCurve(to: CGPoint(x: 490 * u, y: 320 * u), control: CGPoint(x: 490 * u, y: 285 * u))
        cone.addLine(to: CGPoint(x: 490 * u, y: 704 * u))
        cone.addQuadCurve(to: CGPoint(x: 460 * u, y: 729 * u), control: CGPoint(x: 490 * u, y: 739 * u))
        cone.addLine(to: CGPoint(x: 300 * u, y: 594 * u))
        cone.closeSubpath()
        ctx.addPath(cone)
        ctx.fillPath()

        // Rangliste: drei Balken mit Ziffern, oberster am hellsten
        let bars: [(y: CGFloat, w: CGFloat, a: CGFloat)] = [(640, 250, 1.0), (488, 195, 0.75), (336, 140, 0.5)]
        for (i, bar) in bars.enumerated() {
            let r = CGRect(x: 560 * u, y: bar.y * u, width: bar.w * u, height: 64 * u)
            ctx.setFillColor(NSColor.white.withAlphaComponent(bar.a).cgColor)
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 32 * u, cornerHeight: 32 * u, transform: nil))
            ctx.fillPath()
            // Ziffer am Balkenanfang in dunklem Violett
            let dot = CGRect(x: r.minX + 8 * u, y: r.minY + 6 * u, width: 52 * u, height: 52 * u)
            let font = NSFont.systemFont(ofSize: 46 * u, weight: .black)
            let str = NSAttributedString(string: "\(i + 1)", attributes: [
                .font: font, .foregroundColor: NSColor(srgbRed: 0.33, green: 0.18, blue: 0.78, alpha: 1),
            ])
            let sz = str.size()
            ctx.setShadow(offset: .zero, blur: 0, color: nil)
            str.draw(at: CGPoint(x: dot.midX - sz.width / 2, y: dot.midY - sz.height / 2 + 2 * u))
        }
        ctx.restoreGState()
        return true
    }
}

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let iconset = out.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = base * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                                   samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                   colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        drawIcon(size: CGFloat(px)).draw(in: NSRect(x: 0, y: 0, width: px, height: px))
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! rep.representation(using: .png, properties: [:])!.write(to: iconset.appendingPathComponent(name))
    }
}
print(iconset.path)
