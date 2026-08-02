import AppKit

// Génère AppIcon.iconset — le cabinet Slotch en squircle : notch, laiton, 7-7-7
@main
struct IconGen {
    static func main() {
        let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources"
        let master = draw()
        let setURL = URL(fileURLWithPath: outDir).appendingPathComponent("AppIcon.iconset")
        try? FileManager.default.createDirectory(at: setURL, withIntermediateDirectories: true)
        let sizes: [(Int, String)] = [
            (16, "icon_16x16"), (32, "icon_16x16@2x"),
            (32, "icon_32x32"), (64, "icon_32x32@2x"),
            (128, "icon_128x128"), (256, "icon_128x128@2x"),
            (256, "icon_256x256"), (512, "icon_256x256@2x"),
            (512, "icon_512x512"), (1024, "icon_512x512@2x"),
        ]
        for (px, name) in sizes {
            writePNG(master, px: px, to: setURL.appendingPathComponent("\(name).png"))
        }
        print("iconset ok → \(setURL.path)")
    }

    static func draw() -> NSImage {
        let S: CGFloat = 1024
        let img = NSImage(size: NSSize(width: S, height: S))
        img.lockFocus()

        // Squircle Apple : 832 pt centré, ombre portée
        let sq = NSRect(x: 96, y: 96, width: 832, height: 832)
        let squircle = NSBezierPath(roundedRect: sq, xRadius: 187, yRadius: 187)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.35)
        shadow.shadowBlurRadius = 26
        shadow.shadowOffset = NSSize(width: 0, height: -14)
        shadow.set()
        NSColor.black.setFill()
        squircle.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        squircle.addClip()

        // Façade bordeaux vignettée
        NSGradient(colors: [
            NSColor(calibratedRed: 0.16, green: 0.03, blue: 0.05, alpha: 1),
            NSColor(calibratedRed: 0.27, green: 0.06, blue: 0.10, alpha: 1),
        ])!.draw(in: sq, angle: 90)
        NSGradient(colors: [NSColor.clear,
                            NSColor(calibratedWhite: 0, alpha: 0.40)])!
            .draw(in: squircle, relativeCenterPosition: NSPoint(x: 0, y: 0.1))

        // Cadre laiton biseauté
        let frame = NSBezierPath(roundedRect: sq.insetBy(dx: 34, dy: 34), xRadius: 155, yRadius: 155)
        CasinoArt.brassDark.setStroke(); frame.lineWidth = 34; frame.stroke()
        CasinoArt.brass.setStroke(); frame.lineWidth = 20; frame.stroke()
        CasinoArt.brassLight.setStroke(); frame.lineWidth = 7; frame.stroke()
        let filet = NSBezierPath(roundedRect: sq.insetBy(dx: 56, dy: 56), xRadius: 136, yRadius: 136)
        NSColor(calibratedWhite: 0, alpha: 0.5).setStroke(); filet.lineWidth = 5; filet.stroke()

        // Le notch mord sur le cadre, coins bas arrondis
        let notch = NSBezierPath(roundedRect: NSRect(x: 512 - 165, y: sq.maxY - 96, width: 330, height: 150),
                                 xRadius: 34, yRadius: 34)
        NSColor.black.setFill()
        notch.fill()

        NSGraphicsContext.restoreGraphicsState()

        // Rouleaux 7·7·7
        let winW: CGFloat = 190, winH: CGFloat = 188, gap: CGFloat = 26
        let x0 = (S - 3 * winW - 2 * gap) / 2
        for i in 0..<3 {
            let win = NSRect(x: x0 + CGFloat(i) * (winW + gap), y: 352, width: winW, height: winH)
            let bezel = NSBezierPath(roundedRect: win.insetBy(dx: -13, dy: -13), xRadius: 34, yRadius: 34)
            NSGradient(colors: [CasinoArt.brassDark, CasinoArt.brass, CasinoArt.brassLight, CasinoArt.brassDark],
                       atLocations: [0, 0.35, 0.75, 1], colorSpace: .deviceRGB)!
                .draw(in: bezel, angle: 90)
            NSColor(calibratedWhite: 0, alpha: 0.6).setStroke()
            bezel.lineWidth = 3
            bezel.stroke()

            let window = NSBezierPath(roundedRect: win, xRadius: 22, yRadius: 22)
            CasinoArt.ivory.setFill()
            window.fill()

            if let seven = CasinoArt.symbol(1, size: 150) {
                NSImage(cgImage: seven, size: NSSize(width: 150, height: 150))
                    .draw(in: NSRect(x: win.midX - 75, y: win.midY - 75, width: 150, height: 150))
            }
            // Courbure du tambour
            NSGradient(colors: [NSColor(calibratedWhite: 0, alpha: 0.38), NSColor.clear,
                                NSColor.clear, NSColor(calibratedWhite: 0, alpha: 0.34)],
                       atLocations: [0, 0.28, 0.72, 1], colorSpace: .deviceRGB)!
                .draw(in: window, angle: 90)
        }

        // Rangée d'ampoules de marquise sous les rouleaux
        if let lit = CasinoArt.bulbLit(64) {
            let n = 6
            let span: CGFloat = 500
            for i in 0..<n {
                let x = 512 - span / 2 + span * CGFloat(i) / CGFloat(n - 1)
                NSImage(cgImage: lit, size: NSSize(width: 64, height: 64))
                    .draw(in: NSRect(x: x - 32, y: 218, width: 64, height: 64))
            }
        }

        // Rivets
        if let rivet = CasinoArt.rivet(40) {
            for (x, y) in [(206.0, 206.0), (818.0, 206.0), (206.0, 818.0), (818.0, 818.0)] {
                NSImage(cgImage: rivet, size: NSSize(width: 40, height: 40))
                    .draw(in: NSRect(x: x - 20, y: y - 20, width: 40, height: 40))
            }
        }

        img.unlockFocus()
        return img
    }

    static func writePNG(_ image: NSImage, px: Int, to url: URL) {
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                         isPlanar: false, colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0),
              let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        ctx.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: CGFloat(px), height: CGFloat(px)),
                   from: .zero, operation: .copy, fraction: 1)
        NSGraphicsContext.restoreGraphicsState()
        try? rep.representation(using: .png, properties: [:])?.write(to: url)
    }
}
