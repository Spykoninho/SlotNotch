import AppKit
import QuartzCore

// Effets plein écran : fenêtre transparente au-dessus de tout, transparente aux clics
enum EffectsOverlay {
    enum Effect {
        case jackpot, nearMiss, tumbleweed
        case triple(Int)
    }

    private static var active: [NSWindow] = []

    static func play(_ effect: Effect, on screen: NSScreen?) {
        guard let screen else { return }
        switch effect {
        case .jackpot: jackpot(screen)
        case .nearMiss: nearMiss(screen)
        case .tumbleweed: tumbleweed(screen)
        case .triple(let s):
            switch s {
            case 0: cherries(screen)
            case 2: night(screen)
            case 3: storm(screen)
            case 4: ghost(screen)
            case 5: melt(screen)
            default: jackpot(screen)
            }
        }
    }

    // MARK: - Plomberie

    private static func makeWindow(_ screen: NSScreen, lifetime: Double) -> CALayer {
        let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        w.isReleasedWhenClosed = false
        w.backgroundColor = .clear
        w.isOpaque = false
        w.hasShadow = false
        w.ignoresMouseEvents = true
        w.level = .screenSaver
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        let v = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
        v.wantsLayer = true
        w.contentView = v
        w.orderFrontRegardless()
        active.append(w)
        DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
            w.orderOut(nil)
            active.removeAll { $0 === w }
        }
        return v.layer!
    }

    private static func banner(_ text: String, in root: CALayer, size: CGFloat,
                               color: NSColor, delay: Double = 0.1, hold: Double = 2.2) {
        let t = CATextLayer()
        t.string = NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: .black),
            .foregroundColor: color,
        ])
        t.alignmentMode = .center
        t.contentsScale = 2
        t.frame = CGRect(x: 0, y: root.bounds.midY - size * 0.7,
                         width: root.bounds.width, height: size * 1.5)
        t.opacity = 0
        t.shadowColor = NSColor.black.cgColor
        t.shadowOpacity = 0.6
        t.shadowRadius = 12
        t.shadowOffset = .zero
        root.addSublayer(t)

        let pop = CASpringAnimation(keyPath: "transform.scale")
        pop.fromValue = 0.2
        pop.toValue = 1
        pop.damping = 12
        pop.stiffness = 180
        pop.beginTime = CACurrentMediaTime() + delay
        pop.duration = pop.settlingDuration
        pop.fillMode = .backwards
        t.add(pop, forKey: "pop")

        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 1, 1, 0]
        fade.keyTimes = [0, 0.08, 0.85, 1]
        fade.duration = hold + 0.8
        fade.beginTime = CACurrentMediaTime() + delay
        t.add(fade, forKey: "fade")
    }

    private static func emojiCell(_ emoji: String, size: CGFloat) -> CAEmitterCell {
        let c = CAEmitterCell()
        c.contents = EmojiArt.image(emoji, size: size)
        c.lifetime = 7
        return c
    }

    // Pluie depuis le haut de l'écran
    private static func rain(_ root: CALayer, cells: [CAEmitterCell],
                             birthDuration: Double) -> CAEmitterLayer {
        let e = CAEmitterLayer()
        e.emitterPosition = CGPoint(x: root.bounds.midX, y: root.bounds.height + 60)
        e.emitterSize = CGSize(width: root.bounds.width, height: 10)
        e.emitterShape = .line
        e.emitterCells = cells
        root.addSublayer(e)
        DispatchQueue.main.asyncAfter(deadline: .now() + birthDuration) { e.birthRate = 0 }
        return e
    }

    // MARK: - Effets

    private static func cherries(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 8)
        let c = emojiCell("🍒", size: 56)
        c.birthRate = 16
        c.velocity = -60
        c.velocityRange = 40
        c.emissionLongitude = .pi / 2
        c.yAcceleration = -240
        c.scale = 0.7
        c.scaleRange = 0.4
        c.spin = 1.5
        c.spinRange = 3
        _ = rain(root, cells: [c], birthDuration: 3.2)
    }

    private static func jackpot(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 9)

        // Éclair doré
        let flash = CALayer()
        flash.frame = root.bounds
        flash.backgroundColor = NSColor(calibratedRed: 1, green: 0.85, blue: 0.4, alpha: 1).cgColor
        flash.opacity = 0
        root.addSublayer(flash)
        let fk = CAKeyframeAnimation(keyPath: "opacity")
        fk.values = [0, 0.75, 0, 0.4, 0]
        fk.duration = 0.9
        flash.add(fk, forKey: "flash")

        // Explosion centrale
        let boom = CAEmitterLayer()
        boom.emitterPosition = CGPoint(x: root.bounds.midX, y: root.bounds.midY)
        boom.emitterShape = .point
        var cells: [CAEmitterCell] = []
        for e in ["🪙", "✨", "💰", "🎉"] {
            let c = emojiCell(e, size: 46)
            c.birthRate = 30
            c.velocity = 480
            c.velocityRange = 220
            c.emissionRange = .pi * 2
            c.yAcceleration = -420
            c.scale = 0.6
            c.scaleRange = 0.35
            c.spin = 4
            c.spinRange = 4
            c.alphaSpeed = -0.18
            cells.append(c)
        }
        // Confettis colorés
        for hue in stride(from: 0.0, to: 1.0, by: 0.2) {
            let c = CAEmitterCell()
            c.contents = EmojiArt.colorRect(NSColor(calibratedHue: hue, saturation: 0.85, brightness: 1, alpha: 1),
                                            size: NSSize(width: 10, height: 16))
            c.birthRate = 40
            c.lifetime = 6
            c.velocity = 420
            c.velocityRange = 260
            c.emissionRange = .pi * 2
            c.yAcceleration = -380
            c.spin = 6
            c.spinRange = 6
            c.alphaSpeed = -0.16
            cells.append(c)
        }
        boom.emitterCells = cells
        root.addSublayer(boom)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { boom.birthRate = 0 }

        // Pluie de pièces prolongée
        let coin = emojiCell("🪙", size: 44)
        coin.birthRate = 14
        coin.velocity = -80
        coin.velocityRange = 60
        coin.emissionLongitude = .pi / 2
        coin.yAcceleration = -300
        coin.scale = 0.7
        coin.scaleRange = 0.3
        coin.spin = 3
        _ = rain(root, cells: [coin], birthDuration: 4)

        banner("JACKPOT", in: root, size: 130,
               color: NSColor(calibratedRed: 1, green: 0.83, blue: 0.25, alpha: 1), hold: 3)
    }

    private static func night(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 7.5)
        let dark = CALayer()
        dark.frame = root.bounds
        dark.backgroundColor = NSColor(calibratedRed: 0.01, green: 0.015, blue: 0.09, alpha: 1).cgColor
        dark.opacity = 0
        root.addSublayer(dark)
        let dim = CAKeyframeAnimation(keyPath: "opacity")
        dim.values = [0, 0.62, 0.62, 0]
        dim.keyTimes = [0, 0.18, 0.8, 1]
        dim.duration = 7
        dim.fillMode = .forwards
        dim.isRemovedOnCompletion = false
        dark.add(dim, forKey: "dim")

        // Étoiles qui scintillent
        let star = emojiCell("✦", size: 22)
        star.contents = EmojiArt.image("✨", size: 26)
        star.birthRate = 9
        star.lifetime = 2.4
        star.velocity = 6
        star.emissionRange = .pi * 2
        star.scale = 0.35
        star.scaleRange = 0.35
        star.alphaSpeed = -0.4
        let sky = CAEmitterLayer()
        sky.emitterPosition = CGPoint(x: root.bounds.midX, y: root.bounds.height * 0.66)
        sky.emitterSize = CGSize(width: root.bounds.width, height: root.bounds.height * 0.6)
        sky.emitterShape = .rectangle
        sky.emitterCells = [star]
        root.addSublayer(sky)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.2) { sky.birthRate = 0 }

        // La lune se lève
        let moon = CALayer()
        moon.contents = EmojiArt.image("🌙", size: 120)
        moon.frame = CGRect(x: root.bounds.width * 0.72, y: -140, width: 130, height: 130)
        root.addSublayer(moon)
        let rise = CABasicAnimation(keyPath: "position.y")
        rise.fromValue = -140
        rise.toValue = root.bounds.height * 0.7
        rise.duration = 4.5
        rise.timingFunction = CAMediaTimingFunction(name: .easeOut)
        rise.fillMode = .forwards
        rise.isRemovedOnCompletion = false
        moon.add(rise, forKey: "rise")
        let moonFade = CABasicAnimation(keyPath: "opacity")
        moonFade.fromValue = 1
        moonFade.toValue = 0
        moonFade.beginTime = CACurrentMediaTime() + 5.6
        moonFade.duration = 1.2
        moonFade.fillMode = .forwards
        moonFade.isRemovedOnCompletion = false
        moon.add(moonFade, forKey: "fade")

        banner("BONNE NUIT", in: root, size: 64,
               color: NSColor(calibratedWhite: 0.9, alpha: 0.9), delay: 1.2, hold: 2.4)
    }

    private static func storm(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 3.5)

        // Flashs blancs
        let flash = CALayer()
        flash.frame = root.bounds
        flash.backgroundColor = NSColor.white.cgColor
        flash.opacity = 0
        root.addSublayer(flash)
        let fk = CAKeyframeAnimation(keyPath: "opacity")
        fk.values = [0, 0.85, 0, 0, 0.6, 0, 0.35, 0]
        fk.keyTimes = [0, 0.05, 0.12, 0.3, 0.36, 0.45, 0.5, 0.6]
        fk.duration = 1.6
        flash.add(fk, forKey: "flash")

        // Barres de glitch néon
        for _ in 0..<26 {
            let bar = CALayer()
            let h = CGFloat.random(in: 6...36)
            bar.frame = CGRect(x: 0, y: CGFloat.random(in: 0...root.bounds.height - h),
                               width: root.bounds.width, height: h)
            bar.backgroundColor = NSColor(calibratedHue: CGFloat.random(in: 0...1),
                                          saturation: 1, brightness: 1, alpha: 1).cgColor
            bar.opacity = 0
            bar.compositingFilter = "differenceBlendMode"
            root.addSublayer(bar)
            let blink = CAKeyframeAnimation(keyPath: "opacity")
            blink.values = [0, 0.9, 0, 0.7, 0]
            blink.duration = Double.random(in: 0.12...0.4)
            blink.beginTime = CACurrentMediaTime() + Double.random(in: 0...1.4)
            bar.add(blink, forKey: "blink")
        }

        // Éclairs qui tombent
        let bolt = emojiCell("⚡️", size: 60)
        bolt.birthRate = 10
        bolt.velocity = -500
        bolt.velocityRange = 150
        bolt.emissionLongitude = .pi / 2
        bolt.scale = 0.8
        bolt.scaleRange = 0.4
        bolt.alphaSpeed = -0.5
        _ = rain(root, cells: [bolt], birthDuration: 1.6)
    }

    private static func ghost(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 6)

        // Voile bleuté spectral
        let tint = CALayer()
        tint.frame = root.bounds
        tint.backgroundColor = NSColor(calibratedRed: 0.3, green: 0.5, blue: 1, alpha: 1).cgColor
        tint.opacity = 0
        root.addSublayer(tint)
        let tk = CAKeyframeAnimation(keyPath: "opacity")
        tk.values = [0, 0.14, 0.14, 0]
        tk.keyTimes = [0, 0.15, 0.8, 1]
        tk.duration = 5
        tint.add(tk, forKey: "tint")

        // Le fantôme traverse en ondulant
        let g = CALayer()
        g.contents = EmojiArt.image("👻", size: 150)
        g.frame = CGRect(x: -170, y: root.bounds.midY, width: 160, height: 160)
        root.addSublayer(g)
        let path = CAKeyframeAnimation(keyPath: "position")
        var pts: [CGPoint] = []
        let n = 40
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let x = -170 + t * (root.bounds.width + 340)
            let y = root.bounds.midY + sin(t * .pi * 4) * 90
            pts.append(CGPoint(x: x, y: y))
        }
        path.values = pts.map { NSValue(point: $0) }
        path.duration = 4.5
        path.calculationMode = .cubic
        path.fillMode = .forwards
        path.isRemovedOnCompletion = false
        g.add(path, forKey: "float")

        // Traînée de mini-fantômes
        let trail = emojiCell("👻", size: 30)
        trail.birthRate = 8
        trail.lifetime = 1.2
        trail.velocity = 20
        trail.emissionRange = .pi * 2
        trail.scale = 0.5
        trail.alphaSpeed = -0.85
        let te = CAEmitterLayer()
        te.emitterShape = .point
        te.emitterPosition = pts[0]
        te.emitterCells = [trail]
        root.addSublayer(te)
        // La traînée suit le même chemin
        let tp = CAKeyframeAnimation(keyPath: "emitterPosition")
        tp.values = pts.map { NSValue(point: $0) }
        tp.duration = 4.5
        tp.calculationMode = .cubic
        te.add(tp, forKey: "follow")
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { te.birthRate = 0 }

        banner("BOUH", in: root, size: 90,
               color: NSColor(calibratedWhite: 0.95, alpha: 0.95), delay: 1.6, hold: 1.2)
    }

    private static func melt(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 6)
        let count = 16
        let w = root.bounds.width / CGFloat(count)
        for i in 0..<count {
            let drip = CALayer()
            drip.backgroundColor = NSColor(calibratedHue: CGFloat.random(in: 0...1),
                                           saturation: 0.55, brightness: 0.98, alpha: 0.85).cgColor
            drip.anchorPoint = CGPoint(x: 0.5, y: 1)
            drip.position = CGPoint(x: (CGFloat(i) + 0.5) * w, y: root.bounds.height)
            drip.bounds = CGRect(x: 0, y: 0, width: w * 0.72, height: 0)
            drip.cornerRadius = w * 0.36
            root.addSublayer(drip)

            let grow = CABasicAnimation(keyPath: "bounds.size.height")
            grow.fromValue = 0
            grow.toValue = CGFloat.random(in: root.bounds.height * 0.25...root.bounds.height * 0.75)
            grow.duration = Double.random(in: 1.8...3.2)
            grow.beginTime = CACurrentMediaTime() + Double.random(in: 0...0.7)
            grow.timingFunction = CAMediaTimingFunction(name: .easeIn)
            grow.fillMode = .forwards
            grow.isRemovedOnCompletion = false
            drip.add(grow, forKey: "grow")

            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            fade.beginTime = CACurrentMediaTime() + 4.2
            fade.duration = 1.2
            fade.fillMode = .forwards
            fade.isRemovedOnCompletion = false
            drip.add(fade, forKey: "fade")
        }
        banner("ÇA FOND", in: root, size: 70,
               color: NSColor(calibratedWhite: 1, alpha: 0.9), delay: 1.4, hold: 1.6)
    }

    private static func nearMiss(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 1.5)
        let flash = CALayer()
        flash.frame = root.bounds
        flash.backgroundColor = NSColor.systemRed.cgColor
        flash.opacity = 0
        root.addSublayer(flash)
        let fk = CAKeyframeAnimation(keyPath: "opacity")
        fk.values = [0, 0.22, 0, 0.12, 0]
        fk.duration = 1
        flash.add(fk, forKey: "tease")
    }

    private static func tumbleweed(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 7)
        let leaf = CALayer()
        leaf.contents = EmojiArt.image("🍂", size: 50)
        leaf.frame = CGRect(x: -60, y: 90, width: 50, height: 50)
        root.addSublayer(leaf)

        let roll = CAKeyframeAnimation(keyPath: "position")
        var pts: [CGPoint] = []
        let n = 30
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let x = -60 + t * (root.bounds.width + 120)
            let y = 60 + abs(sin(t * .pi * 6)) * 55
            pts.append(CGPoint(x: x, y: y))
        }
        roll.values = pts.map { NSValue(point: $0) }
        roll.duration = 6.5
        roll.calculationMode = .cubic
        roll.fillMode = .forwards
        roll.isRemovedOnCompletion = false
        leaf.add(roll, forKey: "roll")

        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = -Double.pi * 10
        spin.duration = 6.5
        leaf.add(spin, forKey: "spin")
    }
}
