import AppKit

// Tous les assets dessinés à la main : zéro emoji, zéro image importée
enum CasinoArt {
    // Palette cabinet
    static let burgundy = NSColor(calibratedRed: 0.23, green: 0.05, blue: 0.08, alpha: 1)
    static let brass = NSColor(calibratedRed: 0.72, green: 0.55, blue: 0.24, alpha: 1)
    static let brassLight = NSColor(calibratedRed: 0.95, green: 0.82, blue: 0.45, alpha: 1)
    static let brassDark = NSColor(calibratedRed: 0.42, green: 0.30, blue: 0.10, alpha: 1)
    static let ivory = NSColor(calibratedRed: 0.95, green: 0.91, blue: 0.81, alpha: 1)
    static let amber = NSColor(calibratedRed: 1.0, green: 0.69, blue: 0.21, alpha: 1)

    private static var cache: [String: CGImage] = [:]

    private static func cg(_ key: String, _ size: NSSize, _ draw: () -> Void) -> CGImage? {
        if let hit = cache[key] { return hit }
        let img = NSImage(size: size)
        img.lockFocus()
        draw()
        img.unlockFocus()
        var r = CGRect(origin: .zero, size: size)
        let out = img.cgImage(forProposedRect: &r, context: nil, hints: nil)
        if let out { cache[key] = out }
        return out
    }

    private static func goldGradient() -> NSGradient {
        NSGradient(colors: [
            NSColor(calibratedRed: 0.52, green: 0.36, blue: 0.10, alpha: 1),
            NSColor(calibratedRed: 0.98, green: 0.80, blue: 0.30, alpha: 1),
            NSColor(calibratedRed: 1.00, green: 0.94, blue: 0.62, alpha: 1),
        ])!
    }

    // MARK: - Symboles des rouleaux

    static func symbol(_ index: Int, size s: CGFloat) -> CGImage? {
        cg("sym\(index)-\(Int(s))", NSSize(width: s, height: s)) {
            switch index {
            case 0: drawCherries(s)
            case 1: drawSeven(s)
            case 2: drawBell(s)
            case 3: drawBar(s)
            case 4: drawDiamond(s)
            default: drawHorseshoe(s)
            }
        }
    }

    private static func drawCherries(_ s: CGFloat) {
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
        let stem = NSBezierPath()
        stem.move(to: p(0.30, 0.50))
        stem.curve(to: p(0.50, 0.88), controlPoint1: p(0.29, 0.72), controlPoint2: p(0.38, 0.84))
        stem.move(to: p(0.68, 0.44))
        stem.curve(to: p(0.50, 0.88), controlPoint1: p(0.70, 0.68), controlPoint2: p(0.60, 0.84))
        NSColor(calibratedRed: 0.36, green: 0.24, blue: 0.10, alpha: 1).setStroke()
        stem.lineWidth = s * 0.05
        stem.lineCapStyle = .round
        stem.stroke()

        let leaf = NSBezierPath(ovalIn: NSRect(x: 0.50 * s, y: 0.76 * s, width: 0.26 * s, height: 0.13 * s))
        NSGradient(colors: [NSColor(calibratedRed: 0.18, green: 0.42, blue: 0.12, alpha: 1),
                            NSColor(calibratedRed: 0.42, green: 0.68, blue: 0.22, alpha: 1)])!
            .draw(in: leaf, angle: 90)

        for (cx, cy) in [(0.29, 0.30), (0.68, 0.24)] {
            let r = 0.195 * s
            let ball = NSBezierPath(ovalIn: NSRect(x: CGFloat(cx) * s - r, y: CGFloat(cy) * s - r,
                                                   width: r * 2, height: r * 2))
            NSGradient(colors: [NSColor(calibratedRed: 1.0, green: 0.30, blue: 0.24, alpha: 1),
                                NSColor(calibratedRed: 0.55, green: 0.02, blue: 0.05, alpha: 1)])!
                .draw(in: ball, relativeCenterPosition: NSPoint(x: -0.35, y: 0.40))
            NSColor(calibratedWhite: 1, alpha: 0.55).setFill()
            NSBezierPath(ovalIn: NSRect(x: (CGFloat(cx) - 0.10) * s, y: (CGFloat(cy) + 0.05) * s,
                                        width: 0.08 * s, height: 0.055 * s)).fill()
        }
    }

    private static func drawSeven(_ s: CGFloat) {
        func pts(_ dx: CGFloat, _ dy: CGFloat) -> NSBezierPath {
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: (x + dx) * s, y: (y + dy) * s) }
            let path = NSBezierPath()
            path.move(to: p(0.14, 0.92))
            path.line(to: p(0.88, 0.92))
            path.line(to: p(0.60, 0.06))
            path.line(to: p(0.33, 0.06))
            path.line(to: p(0.59, 0.73))
            path.line(to: p(0.14, 0.73))
            path.close()
            return path
        }
        NSColor(calibratedRed: 0.30, green: 0.02, blue: 0.02, alpha: 0.9).setFill()
        pts(0.03, -0.035).fill()
        let main = pts(0, 0)
        NSGradient(colors: [NSColor(calibratedRed: 0.62, green: 0.04, blue: 0.06, alpha: 1),
                            NSColor(calibratedRed: 0.98, green: 0.22, blue: 0.16, alpha: 1)])!
            .draw(in: main, angle: 90)
        brassLight.setStroke()
        main.lineWidth = s * 0.032
        main.stroke()
    }

    private static func drawBell(_ s: CGFloat) {
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
        let body = NSBezierPath()
        body.move(to: p(0.16, 0.36))
        body.curve(to: p(0.34, 0.80), controlPoint1: p(0.16, 0.58), controlPoint2: p(0.22, 0.74))
        body.curve(to: p(0.66, 0.80), controlPoint1: p(0.42, 0.93), controlPoint2: p(0.58, 0.93))
        body.curve(to: p(0.84, 0.36), controlPoint1: p(0.78, 0.74), controlPoint2: p(0.84, 0.58))
        body.close()
        goldGradient().draw(in: body, angle: 90)
        brassDark.setStroke()
        body.lineWidth = s * 0.02
        body.stroke()

        let lip = NSBezierPath(roundedRect: NSRect(x: 0.10 * s, y: 0.26 * s, width: 0.80 * s, height: 0.105 * s),
                               xRadius: 0.05 * s, yRadius: 0.05 * s)
        goldGradient().draw(in: lip, angle: 90)
        brassDark.setStroke()
        lip.lineWidth = s * 0.015
        lip.stroke()

        brassDark.setFill()
        NSBezierPath(ovalIn: NSRect(x: 0.43 * s, y: 0.10 * s, width: 0.14 * s, height: 0.14 * s)).fill()
        NSBezierPath(ovalIn: NSRect(x: 0.45 * s, y: 0.80 * s, width: 0.10 * s, height: 0.09 * s)).fill()

        NSColor(calibratedWhite: 1, alpha: 0.40).setFill()
        NSBezierPath(ovalIn: NSRect(x: 0.28 * s, y: 0.60 * s, width: 0.10 * s, height: 0.16 * s)).fill()
    }

    private static func drawBar(_ s: CGFloat) {
        let box = NSBezierPath(roundedRect: NSRect(x: 0.05 * s, y: 0.30 * s, width: 0.90 * s, height: 0.40 * s),
                               xRadius: 0.09 * s, yRadius: 0.09 * s)
        NSGradient(colors: [NSColor(calibratedWhite: 0.04, alpha: 1),
                            NSColor(calibratedWhite: 0.22, alpha: 1)])!
            .draw(in: box, angle: 90)
        brass.setStroke()
        box.lineWidth = s * 0.035
        box.stroke()

        let font = NSFont(name: "Copperplate-Bold", size: 0.28 * s) ?? NSFont.boldSystemFont(ofSize: 0.28 * s)
        let attr = NSAttributedString(string: "BAR", attributes: [
            .font: font,
            .foregroundColor: brassLight,
            .kern: 0.02 * s,
        ])
        let b = attr.boundingRect(with: NSSize(width: s, height: s), options: [.usesLineFragmentOrigin])
        attr.draw(at: NSPoint(x: (s - b.width) / 2, y: (s - b.height) / 2 + 0.008 * s))
    }

    private static func drawDiamond(_ s: CGFloat) {
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
        let outline = NSBezierPath()
        outline.move(to: p(0.50, 0.08))
        outline.line(to: p(0.12, 0.58))
        outline.line(to: p(0.30, 0.86))
        outline.line(to: p(0.70, 0.86))
        outline.line(to: p(0.88, 0.58))
        outline.close()
        NSGradient(colors: [NSColor(calibratedRed: 0.25, green: 0.55, blue: 0.85, alpha: 1),
                            NSColor(calibratedRed: 0.72, green: 0.93, blue: 1.0, alpha: 1)])!
            .draw(in: outline, angle: 90)

        let facets = NSBezierPath()
        facets.move(to: p(0.12, 0.58)); facets.line(to: p(0.88, 0.58))
        facets.move(to: p(0.50, 0.08)); facets.line(to: p(0.33, 0.58))
        facets.move(to: p(0.50, 0.08)); facets.line(to: p(0.67, 0.58))
        facets.move(to: p(0.30, 0.86)); facets.line(to: p(0.50, 0.58))
        facets.move(to: p(0.70, 0.86)); facets.line(to: p(0.50, 0.58))
        NSColor(calibratedWhite: 1, alpha: 0.75).setStroke()
        facets.lineWidth = s * 0.016
        facets.stroke()

        NSColor(calibratedRed: 0.15, green: 0.38, blue: 0.65, alpha: 1).setStroke()
        outline.lineWidth = s * 0.02
        outline.stroke()
    }

    private static func drawHorseshoe(_ s: CGFloat) {
        let center = NSPoint(x: 0.5 * s, y: 0.52 * s)
        let radius = 0.30 * s
        // Ouverture en haut (60°→120°), le fer couvre 300° — porte-bonheur, donc ouvert vers le ciel
        let a0: CGFloat = 120, a1: CGFloat = 420

        let arc = NSBezierPath()
        arc.appendArc(withCenter: center, radius: radius, startAngle: a0, endAngle: a1, clockwise: false)
        brassDark.setStroke()
        arc.lineWidth = s * 0.15
        arc.stroke()

        let arcMid = NSBezierPath()
        arcMid.appendArc(withCenter: center, radius: radius, startAngle: a0, endAngle: a1, clockwise: false)
        brass.setStroke()
        arcMid.lineWidth = s * 0.095
        arcMid.stroke()

        let arcHi = NSBezierPath()
        arcHi.appendArc(withCenter: center, radius: radius + 0.026 * s, startAngle: 140, endAngle: 400, clockwise: false)
        brassLight.setStroke()
        arcHi.lineWidth = s * 0.03
        arcHi.stroke()

        // Plaquettes d'embout aux deux pointes
        for deg in [120.0, 60.0] {
            let a = deg * .pi / 180
            let x = center.x + radius * CGFloat(cos(a))
            let y = center.y + radius * CGFloat(sin(a))
            let cap = NSBezierPath(roundedRect: NSRect(x: x - 0.085 * s, y: y - 0.008 * s,
                                                       width: 0.17 * s, height: 0.075 * s),
                                   xRadius: 0.02 * s, yRadius: 0.02 * s)
            brassLight.setFill()
            cap.fill()
            brassDark.setStroke()
            cap.lineWidth = s * 0.012
            cap.stroke()
        }

        // Trous de clous le long du fer
        NSColor(calibratedRed: 0.25, green: 0.17, blue: 0.05, alpha: 1).setFill()
        for deg in [145.0, 195.0, 245.0, 295.0, 345.0, 35.0] {
            let a = deg * .pi / 180
            let x = center.x + radius * CGFloat(cos(a))
            let y = center.y + radius * CGFloat(sin(a))
            NSBezierPath(ovalIn: NSRect(x: x - 0.024 * s, y: y - 0.024 * s,
                                        width: 0.048 * s, height: 0.048 * s)).fill()
        }
    }

    // MARK: - Accessoires d'effets

    static func coin(_ s: CGFloat) -> CGImage? {
        cg("coin-\(Int(s))", NSSize(width: s, height: s)) {
            let outer = NSBezierPath(ovalIn: NSRect(x: 0.05 * s, y: 0.05 * s, width: 0.90 * s, height: 0.90 * s))
            NSGradient(colors: [NSColor(calibratedRed: 0.55, green: 0.38, blue: 0.08, alpha: 1),
                                NSColor(calibratedRed: 1.0, green: 0.85, blue: 0.35, alpha: 1)])!
                .draw(in: outer, relativeCenterPosition: NSPoint(x: -0.25, y: 0.35))
            brassDark.setStroke()
            let ring = NSBezierPath(ovalIn: NSRect(x: 0.14 * s, y: 0.14 * s, width: 0.72 * s, height: 0.72 * s))
            ring.lineWidth = s * 0.025
            ring.stroke()
            // Losange embossé au centre
            let gem = NSBezierPath()
            gem.move(to: NSPoint(x: 0.5 * s, y: 0.68 * s))
            gem.line(to: NSPoint(x: 0.64 * s, y: 0.5 * s))
            gem.line(to: NSPoint(x: 0.5 * s, y: 0.32 * s))
            gem.line(to: NSPoint(x: 0.36 * s, y: 0.5 * s))
            gem.close()
            NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.65, alpha: 0.9).setFill()
            gem.fill()
        }
    }

    static func ingot(_ s: CGFloat) -> CGImage? {
        cg("ingot-\(Int(s))", NSSize(width: s, height: s)) {
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
            let front = NSBezierPath()
            front.move(to: p(0.06, 0.18)); front.line(to: p(0.94, 0.18))
            front.line(to: p(0.80, 0.52)); front.line(to: p(0.20, 0.52)); front.close()
            goldGradient().draw(in: front, angle: 90)
            let top = NSBezierPath()
            top.move(to: p(0.20, 0.52)); top.line(to: p(0.80, 0.52))
            top.line(to: p(0.70, 0.72)); top.line(to: p(0.30, 0.72)); top.close()
            NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.55, alpha: 1).setFill()
            top.fill()
            brassDark.setStroke()
            front.lineWidth = s * 0.02; front.stroke()
            top.lineWidth = s * 0.02; top.stroke()
        }
    }

    static func glint(_ s: CGFloat) -> CGImage? {
        cg("glint-\(Int(s))", NSSize(width: s, height: s)) {
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
            let star = NSBezierPath()
            star.move(to: p(0.50, 0.98))
            star.line(to: p(0.60, 0.60)); star.line(to: p(0.98, 0.50))
            star.line(to: p(0.60, 0.40)); star.line(to: p(0.50, 0.02))
            star.line(to: p(0.40, 0.40)); star.line(to: p(0.02, 0.50))
            star.line(to: p(0.40, 0.60)); star.close()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor(calibratedRed: 0.5, green: 0.9, blue: 1.0, alpha: 0.9)
            shadow.shadowBlurRadius = s * 0.12
            shadow.set()
            NSColor.white.setFill()
            star.fill()
        }
    }

    static func tumbleweed(_ s: CGFloat) -> CGImage? {
        cg("weed-\(Int(s))", NSSize(width: s, height: s)) {
            for i in 0..<16 {
                let path = NSBezierPath()
                let cx = CGFloat.random(in: 0.35...0.65) * s
                let cy = CGFloat.random(in: 0.35...0.65) * s
                let r = CGFloat.random(in: 0.12...0.42) * s
                let a0 = CGFloat.random(in: 0...360)
                path.appendArc(withCenter: NSPoint(x: cx, y: cy), radius: r,
                               startAngle: a0, endAngle: a0 + CGFloat.random(in: 120...300))
                NSColor(calibratedRed: 0.55, green: 0.42, blue: 0.22,
                        alpha: CGFloat.random(in: 0.35...0.8)).setStroke()
                path.lineWidth = s * (i % 3 == 0 ? 0.03 : 0.018)
                path.stroke()
            }
        }
    }

    static func bulbOff(_ s: CGFloat) -> CGImage? {
        cg("bulb0-\(Int(s))", NSSize(width: s, height: s)) {
            let glass = NSBezierPath(ovalIn: NSRect(x: 0.18 * s, y: 0.18 * s, width: 0.64 * s, height: 0.64 * s))
            NSGradient(colors: [NSColor(calibratedRed: 0.22, green: 0.15, blue: 0.08, alpha: 1),
                                NSColor(calibratedRed: 0.38, green: 0.27, blue: 0.13, alpha: 1)])!
                .draw(in: glass, relativeCenterPosition: NSPoint(x: -0.2, y: 0.3))
            brassDark.setStroke()
            glass.lineWidth = s * 0.05
            glass.stroke()
            NSColor(calibratedWhite: 1, alpha: 0.14).setFill()
            NSBezierPath(ovalIn: NSRect(x: 0.30 * s, y: 0.52 * s, width: 0.14 * s, height: 0.10 * s)).fill()
        }
    }

    static func bulbLit(_ s: CGFloat) -> CGImage? {
        cg("bulb1-\(Int(s))", NSSize(width: s, height: s)) {
            let halo = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: s, height: s))
            NSGradient(colors: [NSColor(calibratedRed: 1.0, green: 0.92, blue: 0.62, alpha: 0.95),
                                NSColor(calibratedRed: 1.0, green: 0.75, blue: 0.25, alpha: 0.55),
                                NSColor(calibratedRed: 1.0, green: 0.70, blue: 0.20, alpha: 0.0)])!
                .draw(in: halo, relativeCenterPosition: .zero)
            let core = NSBezierPath(ovalIn: NSRect(x: 0.32 * s, y: 0.32 * s, width: 0.36 * s, height: 0.36 * s))
            NSGradient(colors: [NSColor.white, NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.35, alpha: 1)])!
                .draw(in: core, relativeCenterPosition: .zero)
        }
    }

    static func redBall(_ s: CGFloat) -> CGImage? {
        cg("ball-\(Int(s))", NSSize(width: s, height: s)) {
            let ball = NSBezierPath(ovalIn: NSRect(x: 0.04 * s, y: 0.04 * s, width: 0.92 * s, height: 0.92 * s))
            NSGradient(colors: [NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.34, alpha: 1),
                                NSColor(calibratedRed: 0.72, green: 0.07, blue: 0.05, alpha: 1),
                                NSColor(calibratedRed: 0.42, green: 0.03, blue: 0.03, alpha: 1)])!
                .draw(in: ball, relativeCenterPosition: NSPoint(x: -0.30, y: 0.35))
            NSColor(calibratedWhite: 1, alpha: 0.55).setFill()
            NSBezierPath(ovalIn: NSRect(x: 0.24 * s, y: 0.58 * s, width: 0.22 * s, height: 0.15 * s)).fill()
        }
    }

    static func noise(_ w: CGFloat, _ h: CGFloat) -> CGImage? {
        cg("noise-\(Int(w))x\(Int(h))", NSSize(width: w, height: h)) {
            for _ in 0..<1400 {
                let bright = Bool.random()
                NSColor(calibratedWhite: bright ? 1 : 0, alpha: CGFloat.random(in: 0.02...0.06)).setFill()
                NSRect(x: CGFloat.random(in: 0..<w), y: CGFloat.random(in: 0..<h),
                       width: 1, height: 1).fill()
            }
        }
    }

    // MARK: - Quincaillerie du cabinet

    // Cadre laiton biseauté : trois passes de trait concentriques = relief
    static func framePlate(_ w: CGFloat, _ h: CGFloat) -> CGImage? {
        cg("frame-\(Int(w))x\(Int(h))", NSSize(width: w, height: h)) {
            let r = NSRect(x: 3, y: 3, width: w - 6, height: h - 6)
            let path = NSBezierPath(roundedRect: r, xRadius: 11, yRadius: 11)
            brassDark.setStroke(); path.lineWidth = 6; path.stroke()
            brass.setStroke(); path.lineWidth = 3.6; path.stroke()
            brassLight.setStroke(); path.lineWidth = 1.4; path.stroke()
            let inner = NSBezierPath(roundedRect: r.insetBy(dx: 3.2, dy: 3.2), xRadius: 8, yRadius: 8)
            NSColor(calibratedWhite: 0, alpha: 0.5).setStroke()
            inner.lineWidth = 1
            inner.stroke()
        }
    }

    static func rivet(_ s: CGFloat) -> CGImage? {
        cg("rivet-\(Int(s))", NSSize(width: s, height: s)) {
            let dome = NSBezierPath(ovalIn: NSRect(x: 0.08 * s, y: 0.08 * s, width: 0.84 * s, height: 0.84 * s))
            NSGradient(colors: [brassLight, brassDark])!
                .draw(in: dome, relativeCenterPosition: NSPoint(x: -0.3, y: 0.35))
            NSColor(calibratedWhite: 0, alpha: 0.55).setStroke()
            dome.lineWidth = max(0.5, s * 0.08)
            dome.stroke()
        }
    }

    static func colorRect(_ color: NSColor, size: NSSize) -> CGImage? {
        cg("rect-\(color.description)-\(Int(size.width))x\(Int(size.height))", size) {
            color.setFill()
            NSRect(origin: .zero, size: size).fill()
        }
    }

    // MARK: - Texte doré biseauté (Phosphate = lettrage de marquise)

    static func goldText(_ text: String, fontSize: CGFloat) -> CGImage? {
        cg("gold-\(text)-\(Int(fontSize))", goldTextSize(text, fontSize: fontSize)) {
            let font = NSFont(name: "Phosphate-Inline", size: fontSize)
                ?? NSFont(name: "Copperplate-Bold", size: fontSize)
                ?? NSFont.systemFont(ofSize: fontSize, weight: .black)
            let m = fontSize * 0.12 + 4
            let size = goldTextSize(text, fontSize: fontSize)

            // Masque blanc → dégradé or découpé dedans
            let attr = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: NSColor.white])
            let mask = NSImage(size: size)
            mask.lockFocus()
            attr.draw(at: NSPoint(x: m, y: m))
            mask.unlockFocus()

            let gold = NSImage(size: size)
            gold.lockFocus()
            goldGradient().draw(in: NSRect(origin: .zero, size: size), angle: 90)
            mask.draw(at: .zero, from: NSRect(origin: .zero, size: size),
                      operation: .destinationIn, fraction: 1)
            gold.unlockFocus()

            // Extrusion sombre puis face dorée
            let dark = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: NSColor(calibratedRed: 0.24, green: 0.12, blue: 0.02, alpha: 1),
            ])
            let depth = max(2, Int(fontSize * 0.05))
            for i in 1...depth {
                dark.draw(at: NSPoint(x: m + CGFloat(i) * 0.5, y: m - CGFloat(i)))
            }
            gold.draw(at: .zero, from: NSRect(origin: .zero, size: size),
                      operation: .sourceOver, fraction: 1)
        }
    }

    static func goldTextSize(_ text: String, fontSize: CGFloat) -> NSSize {
        let font = NSFont(name: "Phosphate-Inline", size: fontSize)
            ?? NSFont(name: "Copperplate-Bold", size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize, weight: .black)
        let attr = NSAttributedString(string: text, attributes: [.font: font])
        let b = attr.boundingRect(with: NSSize(width: 4000, height: 500), options: [.usesLineFragmentOrigin])
        let m = fontSize * 0.12 + 4
        return NSSize(width: ceil(b.width) + m * 2, height: ceil(b.height) + m * 2)
    }

    // MARK: - Afficheur 7 segments (compteur de crédits)

    static func sevenSegment(_ value: Int, digits: Int, height: CGFloat) -> CGImage? {
        let v = max(0, min(value, Int(pow(10.0, Double(digits))) - 1))
        let digitW = height * 0.62
        let spacing = height * 0.16
        let width = CGFloat(digits) * digitW + CGFloat(digits - 1) * spacing
        return cg("7seg-\(v)-\(digits)-\(Int(height))", NSSize(width: width, height: height)) {
            let segMap: [String] = ["ABCDEF", "BC", "ABGED", "ABGCD", "FGBC",
                                    "AFGCD", "AFGEDC", "ABC", "ABCDEFG", "ABCDFG"]
            let text = String(format: "%0\(digits)d", v)
            let t = height * 0.13
            for (i, ch) in text.enumerated() {
                let x0 = CGFloat(i) * (digitW + spacing)
                let lit = segMap[Int(String(ch))!]
                let segs: [(Character, NSRect)] = [
                    ("A", NSRect(x: x0 + t * 0.8, y: height - t, width: digitW - t * 1.6, height: t)),
                    ("G", NSRect(x: x0 + t * 0.8, y: (height - t) / 2, width: digitW - t * 1.6, height: t)),
                    ("D", NSRect(x: x0 + t * 0.8, y: 0, width: digitW - t * 1.6, height: t)),
                    ("F", NSRect(x: x0, y: height / 2 + t * 0.3, width: t, height: height / 2 - t * 1.1)),
                    ("B", NSRect(x: x0 + digitW - t, y: height / 2 + t * 0.3, width: t, height: height / 2 - t * 1.1)),
                    ("E", NSRect(x: x0, y: t * 0.8, width: t, height: height / 2 - t * 1.1)),
                    ("C", NSRect(x: x0 + digitW - t, y: t * 0.8, width: t, height: height / 2 - t * 1.1)),
                ]
                for (name, rect) in segs {
                    let on = lit.contains(name)
                    if on {
                        NSColor(calibratedRed: 1.0, green: 0.16, blue: 0.10, alpha: 0.35).setFill()
                        NSBezierPath(roundedRect: rect.insetBy(dx: -1.2, dy: -1.2),
                                     xRadius: t / 2, yRadius: t / 2).fill()
                    }
                    (on ? NSColor(calibratedRed: 1.0, green: 0.23, blue: 0.15, alpha: 1)
                        : NSColor(calibratedRed: 0.22, green: 0.06, blue: 0.05, alpha: 1)).setFill()
                    NSBezierPath(roundedRect: rect, xRadius: t / 2, yRadius: t / 2).fill()
                }
            }
        }
    }
}
