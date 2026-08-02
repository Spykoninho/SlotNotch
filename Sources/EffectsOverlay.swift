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
            case 2: bells(screen)
            case 3: bars(screen)
            case 4: diamonds(screen)
            case 5: horseshoes(screen)
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

    // Bannière en lettrage doré biseauté, dessiné maison
    private static func banner(_ text: String, in root: CALayer, size: CGFloat,
                               delay: Double = 0.1, hold: Double = 2.2) {
        guard let img = CasinoArt.goldText(text, fontSize: size) else { return }
        let pt = CasinoArt.goldTextSize(text, fontSize: size)
        let t = CALayer()
        t.contents = img
        t.bounds = CGRect(origin: .zero, size: pt)
        t.position = CGPoint(x: root.bounds.midX, y: root.bounds.midY)
        t.opacity = 0
        t.shadowColor = NSColor.black.cgColor
        t.shadowOpacity = 0.55
        t.shadowRadius = 14
        t.shadowOffset = CGSize(width: 0, height: -6)
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

    private static func assetCell(_ img: CGImage?, lifetime: Float = 7) -> CAEmitterCell {
        let c = CAEmitterCell()
        c.contents = img
        c.lifetime = lifetime
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
        let c = assetCell(CasinoArt.symbol(0, size: 56))
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

        // Explosion centrale : pièces, éclats, lingots
        let boom = CAEmitterLayer()
        boom.emitterPosition = CGPoint(x: root.bounds.midX, y: root.bounds.midY)
        boom.emitterShape = .point
        var cells: [CAEmitterCell] = []
        for img in [CasinoArt.coin(46), CasinoArt.glint(38), CasinoArt.ingot(46)] {
            let c = assetCell(img)
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
            c.contents = CasinoArt.colorRect(NSColor(calibratedHue: hue, saturation: 0.85, brightness: 1, alpha: 1),
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
        let coin = assetCell(CasinoArt.coin(44))
        coin.birthRate = 14
        coin.velocity = -80
        coin.velocityRange = 60
        coin.emissionLongitude = .pi / 2
        coin.yAcceleration = -300
        coin.scale = 0.7
        coin.scaleRange = 0.3
        coin.spin = 3
        _ = rain(root, cells: [coin], birthDuration: 4)

        banner(Personality.bannerJackpot, in: root, size: 120, hold: 3)
    }

    // Triple cloche : ondes sonores dorées + carillon
    private static func bells(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 7)
        let center = CGPoint(x: root.bounds.midX, y: root.bounds.midY)

        for i in 0..<3 {
            let ring = CAShapeLayer()
            ring.path = CGPath(ellipseIn: CGRect(x: -70, y: -70, width: 140, height: 140), transform: nil)
            ring.position = center
            ring.fillColor = nil
            ring.strokeColor = NSColor(calibratedRed: 1, green: 0.8, blue: 0.3, alpha: 1).cgColor
            ring.lineWidth = 7
            ring.opacity = 0
            root.addSublayer(ring)

            let t0 = CACurrentMediaTime() + Double(i) * 0.3
            let grow = CABasicAnimation(keyPath: "transform.scale")
            grow.fromValue = 0.25
            grow.toValue = 7
            grow.duration = 1.5
            grow.beginTime = t0
            grow.timingFunction = CAMediaTimingFunction(name: .easeOut)
            ring.add(grow, forKey: "grow")

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 0.9, 0]
            fade.keyTimes = [0, 0.12, 1]
            fade.duration = 1.5
            fade.beginTime = t0
            ring.add(fade, forKey: "fade")

            SoundBox.play("Glass", volume: 0.55, after: Double(i) * 0.3)
        }

        let bell = assetCell(CasinoArt.symbol(2, size: 50))
        bell.birthRate = 10
        bell.velocity = -50
        bell.velocityRange = 35
        bell.emissionLongitude = .pi / 2
        bell.yAcceleration = -220
        bell.scale = 0.7
        bell.scaleRange = 0.3
        bell.spin = 1
        bell.spinRange = 2
        _ = rain(root, cells: [bell], birthDuration: 2.6)

        banner(Personality.bannerBell, in: root, size: 72, delay: 0.3, hold: 2)
    }

    // Triple BAR : la fortune tombe du ciel, lourde
    private static func bars(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 8)
        let ingot = assetCell(CasinoArt.ingot(64))
        ingot.birthRate = 14
        ingot.velocity = -160
        ingot.velocityRange = 80
        ingot.emissionLongitude = .pi / 2
        ingot.yAcceleration = -520
        ingot.scale = 0.75
        ingot.scaleRange = 0.35
        ingot.spin = 0.6
        ingot.spinRange = 1.4
        _ = rain(root, cells: [ingot], birthDuration: 3)

        let sym = assetCell(CasinoArt.symbol(3, size: 56))
        sym.birthRate = 6
        sym.velocity = -120
        sym.velocityRange = 60
        sym.emissionLongitude = .pi / 2
        sym.yAcceleration = -420
        sym.scale = 0.8
        sym.scaleRange = 0.3
        _ = rain(root, cells: [sym], birthDuration: 3)

        banner(Personality.bannerBar, in: root, size: 84, delay: 0.2, hold: 2.2)
    }

    // Triple diamant : scintillements et balayage lumineux
    private static func diamonds(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 6.5)

        for _ in 0..<26 {
            let g = CALayer()
            let s = CGFloat.random(in: 18...52)
            g.contents = CasinoArt.glint(40)
            g.frame = CGRect(x: CGFloat.random(in: 0...root.bounds.width - s),
                             y: CGFloat.random(in: 0...root.bounds.height - s),
                             width: s, height: s)
            g.opacity = 0
            root.addSublayer(g)

            let t0 = CACurrentMediaTime() + Double.random(in: 0...3)
            let dur = Double.random(in: 0.7...1.4)
            let twinkle = CAKeyframeAnimation(keyPath: "opacity")
            twinkle.values = [0, 1, 0]
            twinkle.duration = dur
            twinkle.beginTime = t0
            g.add(twinkle, forKey: "twinkle")
            let scale = CAKeyframeAnimation(keyPath: "transform.scale")
            scale.values = [0.3, 1.1, 0.3]
            scale.duration = dur
            scale.beginTime = t0
            g.add(scale, forKey: "scale")
            let turn = CABasicAnimation(keyPath: "transform.rotation.z")
            turn.fromValue = 0
            turn.toValue = CGFloat.random(in: -0.9...0.9)
            turn.duration = dur
            turn.beginTime = t0
            g.add(turn, forKey: "turn")
        }

        // Rai de lumière qui traverse l'écran
        let ray = CAGradientLayer()
        ray.frame = CGRect(x: 0, y: 0, width: 160, height: root.bounds.height * 1.6)
        ray.colors = [NSColor.clear.cgColor,
                      NSColor(calibratedWhite: 1, alpha: 0.30).cgColor,
                      NSColor.clear.cgColor]
        ray.startPoint = CGPoint(x: 0, y: 0.5)
        ray.endPoint = CGPoint(x: 1, y: 0.5)
        ray.position = CGPoint(x: -200, y: root.bounds.midY)
        ray.transform = CATransform3DMakeRotation(0.32, 0, 0, 1)
        root.addSublayer(ray)
        let sweep = CABasicAnimation(keyPath: "position.x")
        sweep.fromValue = -200
        sweep.toValue = root.bounds.width + 200
        sweep.duration = 1.6
        sweep.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        ray.add(sweep, forKey: "sweep")

        banner(Personality.bannerDiamond, in: root, size: 84, delay: 0.5, hold: 1.8)
    }

    // Triple fer à cheval : la veine verte
    private static func horseshoes(_ screen: NSScreen) {
        let root = makeWindow(screen, lifetime: 8)

        let tint = CALayer()
        tint.frame = root.bounds
        tint.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.65, blue: 0.25, alpha: 1).cgColor
        tint.opacity = 0
        root.addSublayer(tint)
        let tk = CAKeyframeAnimation(keyPath: "opacity")
        tk.values = [0, 0.16, 0.16, 0]
        tk.keyTimes = [0, 0.15, 0.7, 1]
        tk.duration = 3.5
        tint.add(tk, forKey: "tint")

        let shoe = assetCell(CasinoArt.symbol(5, size: 56))
        shoe.birthRate = 12
        shoe.velocity = -70
        shoe.velocityRange = 50
        shoe.emissionLongitude = .pi / 2
        shoe.yAcceleration = -260
        shoe.scale = 0.75
        shoe.scaleRange = 0.35
        shoe.spin = 2
        shoe.spinRange = 3
        _ = rain(root, cells: [shoe], birthDuration: 3)

        banner(Personality.bannerShoe, in: root, size: 90, delay: 0.3, hold: 2)
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
        let weed = CALayer()
        weed.contents = CasinoArt.tumbleweed(50)
        weed.frame = CGRect(x: -60, y: 90, width: 50, height: 50)
        root.addSublayer(weed)

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
        weed.add(roll, forKey: "roll")

        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = -Double.pi * 10
        spin.duration = 6.5
        weed.add(spin, forKey: "spin")
    }
}
