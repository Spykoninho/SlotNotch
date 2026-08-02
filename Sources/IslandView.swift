import AppKit
import QuartzCore

// Géométrie partagée fenêtre/pilule
enum IslandGeo {
    static let windowW: CGFloat = 560
    static let windowH: CGFloat = 300
    static let pillW: CGFloat = 344
    // Largeur du levier qui dépasse du flanc droit (zone cliquable comprise)
    static let leverOverhang: CGFloat = 48
    // Hauteur de l'encoche physique : le haut de la pilule vit derrière, invisible
    static var notchInset: CGFloat = 0
    // 128 px de contenu toujours visibles SOUS le notch
    static var pillH: CGFloat { 128 + notchInset }
    static var pillRect: CGRect {
        CGRect(x: (windowW - pillW) / 2, y: windowH - pillH, width: pillW, height: pillH)
    }
}

enum LEDState { case idle, spin, win, jackpot, lose }
enum MsgTone { case amber, gold, red }

final class IslandView: NSView {
    private let pillContainer = CALayer()
    private let pillBody = CALayer()
    private let jewel = CALayer()
    private let leverArm = CALayer()
    private let dotText = CALayer()
    private let creditsLayer = CALayer()
    private var strips: [CALayer] = []
    private var bulbs: [CALayer] = []
    private var currentIndices = [0, 1, 2]

    private let cellH: CGFloat = 58
    private let reelW: CGFloat = 68
    private let reelH: CGFloat = 58
    private let repeats = 8
    private var stripH: CGFloat { cellH * CGFloat(6 * repeats) }

    // Panneau LED : pas de la grille et zone utile
    private let dotPitch: CGFloat = 2.25
    private let dotSize: CGFloat = 1.65
    private let dotPanelFrame = CGRect(x: 16, y: 10, width: 224, height: 22)
    private var dotInnerW: CGFloat { 216 }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = true
        buildPill()
        buildFaceplate()
        buildReels()
        buildMarquee()
        buildDotPanel()
        buildCredits()
        buildLever()
        concealPill(animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Construction

    private func buildPill() {
        pillContainer.frame = IslandGeo.pillRect
        pillContainer.shadowColor = NSColor.black.cgColor
        pillContainer.shadowOpacity = 0.55
        pillContainer.shadowRadius = 18
        pillContainer.shadowOffset = CGSize(width: 0, height: -8)
        layer?.addSublayer(pillContainer)

        // Dépasse de 30px au-dessus de l'écran : les coins hauts sont tranchés net par le bord
        pillBody.frame = CGRect(x: 0, y: 0, width: IslandGeo.pillW, height: IslandGeo.pillH + 30)
        pillBody.backgroundColor = NSColor.black.cgColor
        pillBody.cornerRadius = 26
        pillBody.cornerCurve = .continuous
        pillBody.masksToBounds = true
        pillBody.borderWidth = 0.5
        pillBody.borderColor = NSColor(white: 1, alpha: 0.08).cgColor
        pillContainer.addSublayer(pillBody)
    }

    private func buildFaceplate() {
        // Façade bordeaux feutrée, vignettée, encadrée de laiton
        let face = CALayer()
        face.frame = CGRect(x: 5, y: 5, width: 334, height: 118)
        face.backgroundColor = CasinoArt.burgundy.cgColor
        face.cornerRadius = 12
        face.masksToBounds = true
        pillBody.addSublayer(face)

        let noise = CALayer()
        noise.frame = face.bounds
        noise.contents = CasinoArt.noise(334, 118)
        noise.opacity = 0.55
        face.addSublayer(noise)

        let vignette = CAGradientLayer()
        vignette.type = .radial
        vignette.frame = face.bounds
        vignette.colors = [NSColor.clear.cgColor, NSColor.clear.cgColor,
                           NSColor(calibratedWhite: 0, alpha: 0.42).cgColor]
        vignette.locations = [0, 0.55, 1]
        vignette.startPoint = CGPoint(x: 0.5, y: 0.55)
        vignette.endPoint = CGPoint(x: 1.0, y: 1.05)
        face.addSublayer(vignette)

        let frame = CALayer()
        frame.frame = face.frame
        frame.contents = CasinoArt.framePlate(334, 118)
        pillBody.addSublayer(frame)

        // Rivets aux quatre coins
        for (x, y) in [(13.5, 13.5), (325.5, 13.5), (13.5, 109.5), (325.5, 109.5)] {
            let r = CALayer()
            r.frame = CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)
            r.contents = CasinoArt.rivet(5)
            pillBody.addSublayer(r)
        }

        // Ampoules de marquise, trois par flanc
        for x: CGFloat in [17, 327] {
            for y: CGFloat in [47, 72, 97] {
                let off = CALayer()
                off.frame = CGRect(x: x - 6.5, y: y - 6.5, width: 13, height: 13)
                off.contents = CasinoArt.bulbOff(13)
                pillBody.addSublayer(off)
                let lit = CALayer()
                lit.frame = CGRect(x: x - 13, y: y - 13, width: 26, height: 26)
                lit.contents = CasinoArt.bulbLit(26)
                lit.opacity = 0
                pillBody.addSublayer(lit)
                bulbs.append(lit)
            }
        }
    }

    private func buildMarquee() {
        // Plaque laiton gravée
        let plaque = CAGradientLayer()
        plaque.frame = CGRect(x: 87, y: 100, width: 170, height: 16)
        plaque.colors = [CasinoArt.brassDark.cgColor, CasinoArt.brass.cgColor,
                         CasinoArt.brassLight.cgColor, CasinoArt.brass.cgColor]
        plaque.locations = [0, 0.45, 0.75, 1]
        plaque.startPoint = CGPoint(x: 0.5, y: 0)
        plaque.endPoint = CGPoint(x: 0.5, y: 1)
        plaque.cornerRadius = 3.5
        plaque.borderWidth = 1
        plaque.borderColor = CasinoArt.brassDark.cgColor
        pillBody.addSublayer(plaque)

        let font = NSFont(name: "Copperplate-Bold", size: 10) ?? NSFont.boldSystemFont(ofSize: 10)
        func plaqueText(_ color: NSColor, dy: CGFloat) {
            let t = CATextLayer()
            t.string = NSAttributedString(string: "· SLOTCH ·", attributes: [
                .font: font, .foregroundColor: color, .kern: 3.5,
            ])
            t.alignmentMode = .center
            t.contentsScale = 2
            t.frame = CGRect(x: 87, y: 102 + dy, width: 170, height: 13)
            pillBody.addSublayer(t)
        }
        // Gravure : filet clair dessous, creux sombre dessus
        plaqueText(NSColor(calibratedWhite: 1, alpha: 0.30), dy: -0.9)
        plaqueText(NSColor(calibratedRed: 0.20, green: 0.11, blue: 0.03, alpha: 0.95), dy: 0)

        // Fente à pièce décorative, à gauche de la plaque
        let slotPlate = CAGradientLayer()
        slotPlate.frame = CGRect(x: 64, y: 100.5, width: 14, height: 15)
        slotPlate.colors = [CasinoArt.brassDark.cgColor, CasinoArt.brassLight.cgColor]
        slotPlate.cornerRadius = 2.5
        slotPlate.borderWidth = 0.8
        slotPlate.borderColor = CasinoArt.brassDark.cgColor
        pillBody.addSublayer(slotPlate)
        let slot = CALayer()
        slot.frame = CGRect(x: 69.5, y: 103.5, width: 3, height: 9)
        slot.backgroundColor = NSColor(calibratedWhite: 0.02, alpha: 1).cgColor
        slot.cornerRadius = 1.5
        pillBody.addSublayer(slot)

        // Lampe témoin sertie, à droite de la plaque
        let ring = CALayer()
        ring.frame = CGRect(x: 265, y: 101, width: 14, height: 14)
        ring.cornerRadius = 7
        ring.backgroundColor = NSColor(calibratedRed: 0.08, green: 0.04, blue: 0.02, alpha: 1).cgColor
        ring.borderWidth = 1.8
        ring.borderColor = CasinoArt.brass.cgColor
        pillBody.addSublayer(ring)
        jewel.frame = CGRect(x: 268.5, y: 104.5, width: 7, height: 7)
        jewel.cornerRadius = 3.5
        pillBody.addSublayer(jewel)
        setLED(.idle)
    }

    private func buildReels() {
        for i in 0..<3 {
            let winFrame = CGRect(x: 62 + CGFloat(i) * (reelW + 8), y: 38, width: reelW, height: reelH)

            let bezel = CAGradientLayer()
            bezel.frame = winFrame.insetBy(dx: -3, dy: -3)
            bezel.colors = [CasinoArt.brassDark.cgColor, CasinoArt.brassLight.cgColor,
                            CasinoArt.brass.cgColor, CasinoArt.brassDark.cgColor]
            bezel.locations = [0, 0.55, 0.8, 1]
            bezel.startPoint = CGPoint(x: 0.5, y: 0)
            bezel.endPoint = CGPoint(x: 0.5, y: 1)
            bezel.cornerRadius = 8
            bezel.borderWidth = 0.8
            bezel.borderColor = NSColor(calibratedWhite: 0, alpha: 0.6).cgColor
            pillBody.addSublayer(bezel)

            let win = CALayer()
            win.frame = winFrame
            win.backgroundColor = CasinoArt.ivory.cgColor
            win.cornerRadius = 5
            win.masksToBounds = true
            win.borderWidth = 1.2
            win.borderColor = NSColor(calibratedRed: 0.16, green: 0.09, blue: 0.03, alpha: 0.85).cgColor
            pillBody.addSublayer(win)

            let strip = CALayer()
            strip.anchorPoint = .zero
            strip.frame = CGRect(x: 0, y: 0, width: reelW, height: stripH)
            for c in 0..<(6 * repeats) {
                let cellY = stripH - CGFloat(c + 1) * cellH
                let cell = CALayer()
                cell.frame = CGRect(x: 10, y: cellY + 5, width: reelW - 20, height: cellH - 10)
                cell.contents = CasinoArt.symbol(c % 6, size: 48)
                cell.contentsGravity = .resizeAspect
                strip.addSublayer(cell)
                // Filet rouge entre les cases, comme sur une vraie bande de rouleau
                let sep = CALayer()
                sep.frame = CGRect(x: 0, y: cellY + cellH - 0.75, width: reelW, height: 1.5)
                sep.backgroundColor = NSColor(calibratedRed: 0.70, green: 0.20, blue: 0.16, alpha: 0.75).cgColor
                strip.addSublayer(sep)
            }
            win.addSublayer(strip)
            strips.append(strip)
            setStrip(i, toCell: 42 + i)
            currentIndices[i] = i

            // Courbure du tambour : ombres haut/bas
            let shade = CAGradientLayer()
            shade.frame = win.bounds
            shade.colors = [NSColor(calibratedWhite: 0, alpha: 0.38).cgColor, NSColor.clear.cgColor,
                            NSColor.clear.cgColor, NSColor(calibratedWhite: 0, alpha: 0.34).cgColor]
            shade.locations = [0, 0.26, 0.74, 1]
            shade.startPoint = CGPoint(x: 0.5, y: 0)
            shade.endPoint = CGPoint(x: 0.5, y: 1)
            win.addSublayer(shade)

            // Reflet du verre
            let glass = CAGradientLayer()
            glass.frame = win.bounds
            glass.colors = [NSColor.clear.cgColor, NSColor(calibratedWhite: 1, alpha: 0.13).cgColor,
                            NSColor.clear.cgColor]
            glass.locations = [0.15, 0.42, 0.7]
            glass.startPoint = CGPoint(x: 0, y: 0)
            glass.endPoint = CGPoint(x: 0.85, y: 1)
            win.addSublayer(glass)
        }
    }

    private func buildDotPanel() {
        let panel = CALayer()
        panel.frame = dotPanelFrame
        panel.backgroundColor = NSColor(calibratedRed: 0.07, green: 0.04, blue: 0.015, alpha: 1).cgColor
        panel.cornerRadius = 3
        panel.borderWidth = 1
        panel.borderColor = NSColor(calibratedRed: 0.42, green: 0.32, blue: 0.14, alpha: 0.7).cgColor
        panel.masksToBounds = true
        pillBody.addSublayer(panel)

        let grid = CALayer()
        grid.frame = CGRect(x: 4, y: 3.1, width: dotInnerW, height: 7 * dotPitch)
        grid.contents = DotMatrix.grid(cols: Int(dotInnerW / dotPitch), rows: 7,
                                       pitch: dotPitch, dot: dotSize,
                                       color: NSColor(calibratedRed: 0.20, green: 0.11, blue: 0.04, alpha: 1))
        panel.addSublayer(grid)

        dotText.anchorPoint = CGPoint(x: 0, y: 0.5)
        dotText.frame = CGRect(x: 4, y: 3.1, width: 10, height: 7 * dotPitch)
        panel.addSublayer(dotText)
        setMessage(Personality.greeting)
    }

    private func buildCredits() {
        let panel = CALayer()
        panel.frame = CGRect(x: 248, y: 10, width: 80, height: 22)
        panel.backgroundColor = NSColor(calibratedRed: 0.07, green: 0.04, blue: 0.015, alpha: 1).cgColor
        panel.cornerRadius = 3
        panel.borderWidth = 1
        panel.borderColor = NSColor(calibratedRed: 0.42, green: 0.32, blue: 0.14, alpha: 0.7).cgColor
        pillBody.addSublayer(panel)

        creditsLayer.frame = CGRect(x: 248 + 24, y: 14, width: 32, height: 14)
        creditsLayer.contentsGravity = .resizeAspect
        pillBody.addSublayer(creditsLayer)

        // Micro-gravure « CREDITS » à gauche des digits
        let label = CATextLayer()
        label.string = NSAttributedString(string: "CR", attributes: [
            .font: NSFont(name: "Copperplate-Bold", size: 6) ?? NSFont.boldSystemFont(ofSize: 6),
            .foregroundColor: NSColor(calibratedRed: 0.62, green: 0.48, blue: 0.22, alpha: 0.8),
            .kern: 0.5,
        ])
        label.contentsScale = 2
        label.frame = CGRect(x: 255, y: 17, width: 18, height: 8)
        pillBody.addSublayer(label)
        setCredits(0)
    }

    private func buildLever() {
        // Monté SUR le flanc droit du cabinet, hors de la pilule — pillContainer ne masque pas
        let bracket = CAGradientLayer()
        bracket.frame = CGRect(x: 336, y: 52, width: 26, height: 16)
        bracket.colors = [NSColor(calibratedWhite: 0.30, alpha: 1).cgColor,
                          NSColor(calibratedWhite: 0.78, alpha: 1).cgColor,
                          NSColor(calibratedWhite: 0.42, alpha: 1).cgColor]
        bracket.startPoint = CGPoint(x: 0.5, y: 0)
        bracket.endPoint = CGPoint(x: 0.5, y: 1)
        bracket.cornerRadius = 4
        bracket.borderWidth = 0.6
        bracket.borderColor = NSColor(calibratedWhite: 0.12, alpha: 1).cgColor
        pillContainer.addSublayer(bracket)

        for x: CGFloat in [340.5, 355.5] {
            let screw = CALayer()
            screw.frame = CGRect(x: x, y: 58, width: 3.5, height: 3.5)
            screw.cornerRadius = 1.75
            screw.backgroundColor = NSColor(calibratedWhite: 0.16, alpha: 1).cgColor
            pillContainer.addSublayer(screw)
        }

        leverArm.bounds = CGRect(x: 0, y: 0, width: 20, height: 56)
        leverArm.anchorPoint = CGPoint(x: 0.5, y: 0.1)
        leverArm.position = CGPoint(x: 349, y: 61)

        let shaft = CAGradientLayer()
        shaft.frame = CGRect(x: 7.5, y: 4, width: 5, height: 36)
        shaft.colors = [NSColor(calibratedWhite: 0.35, alpha: 1).cgColor,
                        NSColor(calibratedWhite: 0.92, alpha: 1).cgColor,
                        NSColor(calibratedWhite: 0.45, alpha: 1).cgColor]
        shaft.startPoint = CGPoint(x: 0, y: 0.5)
        shaft.endPoint = CGPoint(x: 1, y: 0.5)
        shaft.cornerRadius = 2.5
        leverArm.addSublayer(shaft)

        let ball = CALayer()
        ball.frame = CGRect(x: 1, y: 37, width: 18, height: 18)
        ball.contents = CasinoArt.redBall(18)
        leverArm.addSublayer(ball)

        pillContainer.addSublayer(leverArm)
    }

    // MARK: - État

    func setMessage(_ s: String, tone: MsgTone = .amber) {
        let color: NSColor
        switch tone {
        case .amber: color = CasinoArt.amber
        case .gold: color = NSColor(calibratedRed: 1.0, green: 0.87, blue: 0.32, alpha: 1)
        case .red: color = NSColor(calibratedRed: 1.0, green: 0.30, blue: 0.22, alpha: 1)
        }
        let norm = DotMatrix.normalize(s)
        let w = DotMatrix.textWidth(norm, pitch: dotPitch)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        dotText.removeAnimation(forKey: "scroll")
        dotText.contents = DotMatrix.image(norm, pitch: dotPitch, dot: dotSize, color: color)
        dotText.bounds = CGRect(x: 0, y: 0, width: w, height: 7 * dotPitch)
        let midY = 3.1 + 7 * dotPitch / 2

        if w <= dotInnerW {
            // Centré, calé sur la grille de pastilles
            let x = 4 + (dotInnerW - w) / 2
            dotText.position = CGPoint(x: 4 + (x - 4).rounded(toMultipleOf: dotPitch), y: midY)
        } else {
            // Défilement cranté colonne par colonne, calé sur la grille — comme un vrai ticker
            let step = dotPitch
            let start = 4 + ((dotPanelFrame.width - 4) / step).rounded(.up) * step
            dotText.position = CGPoint(x: start, y: midY)
            let steps = Int(ceil((start + w) / step))
            let anim = CAKeyframeAnimation(keyPath: "position.x")
            anim.values = (0...steps).map { start - CGFloat($0) * step }
            anim.calculationMode = .discrete
            anim.duration = Double(steps) * 0.048
            anim.repeatCount = .infinity
            dotText.add(anim, forKey: "scroll")
        }
        CATransaction.commit()
    }

    func setCredits(_ n: Int) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        creditsLayer.contents = CasinoArt.sevenSegment(n, digits: 3, height: 14)
        CATransaction.commit()
    }

    func setLED(_ state: LEDState) {
        jewel.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        switch state {
        case .idle: jewel.backgroundColor = CasinoArt.amber.cgColor
        case .spin: jewel.backgroundColor = NSColor.systemYellow.cgColor
        case .win: jewel.backgroundColor = NSColor.systemGreen.cgColor
        case .jackpot: jewel.backgroundColor = NSColor.systemYellow.cgColor
        case .lose: jewel.backgroundColor = NSColor.systemRed.cgColor
        }
        jewel.shadowColor = jewel.backgroundColor
        jewel.shadowOpacity = 0.9
        jewel.shadowRadius = 4
        jewel.shadowOffset = .zero
        CATransaction.commit()

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1
        pulse.toValue = 0.3
        pulse.duration = state == .spin ? 0.25 : 1.4
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        jewel.add(pulse, forKey: "pulse")

        if state == .jackpot {
            let hue = CAKeyframeAnimation(keyPath: "backgroundColor")
            hue.values = stride(from: 0.0, through: 1.0, by: 0.15).map {
                NSColor(calibratedHue: $0, saturation: 0.9, brightness: 1, alpha: 1).cgColor
            }
            hue.duration = 1.2
            hue.repeatCount = .infinity
            jewel.add(hue, forKey: "rainbow")
        }
    }

    // MARK: - Ampoules de marquise

    /// Chenillard : chaque ampoule clignote en décalé, un tour par `rounds`
    func bulbsChase(rounds: Float) {
        let order = [0, 1, 2, 5, 4, 3]  // gauche montante puis droite descendante
        for (rank, idx) in order.enumerated() {
            let blink = CAKeyframeAnimation(keyPath: "opacity")
            blink.values = [0, 1, 0]
            blink.keyTimes = [0, 0.3, 1]
            blink.duration = 0.55
            blink.beginTime = CACurrentMediaTime() + Double(rank) * 0.09
            blink.repeatCount = rounds
            bulbs[idx].add(blink, forKey: "chase")
        }
    }

    /// Frénésie jackpot : tout clignote vite, en désordre
    func bulbsFrenzy(duration: Double) {
        for b in bulbs {
            let blink = CABasicAnimation(keyPath: "opacity")
            blink.fromValue = 0
            blink.toValue = 1
            blink.duration = Double.random(in: 0.09...0.16)
            blink.autoreverses = true
            blink.repeatCount = Float(duration / (blink.duration * 2))
            blink.beginTime = CACurrentMediaTime() + Double.random(in: 0...0.2)
            b.add(blink, forKey: "frenzy")
        }
    }

    // MARK: - Apparition / disparition

    func revealPill() {
        spring(to: 0)
    }

    func concealPill(animated: Bool) {
        if animated { spring(to: IslandGeo.pillH + 40) }
        else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            pillContainer.transform = CATransform3DMakeTranslation(0, IslandGeo.pillH + 40, 0)
            CATransaction.commit()
        }
    }

    private func spring(to ty: CGFloat) {
        let from = (pillContainer.presentation() ?? pillContainer).value(forKeyPath: "transform.translation.y")
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pillContainer.transform = CATransform3DMakeTranslation(0, ty, 0)
        CATransaction.commit()
        let anim = CASpringAnimation(keyPath: "transform.translation.y")
        anim.fromValue = from
        anim.toValue = ty
        anim.damping = 17
        anim.stiffness = 230
        anim.mass = 1
        anim.duration = anim.settlingDuration
        pillContainer.add(anim, forKey: "slide")
    }

    // MARK: - Rouleaux

    private func stripY(forCell k: Int) -> CGFloat {
        CGFloat(k + 1) * cellH - stripH
    }

    private func setStrip(_ i: Int, toCell k: Int) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        strips[i].position = CGPoint(x: 0, y: stripY(forCell: k))
        CATransaction.commit()
    }

    func pullLever() {
        let pull = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        pull.values = [0, -2.3, -2.3, 0.18, 0]
        pull.keyTimes = [0, 0.22, 0.42, 0.78, 1]
        pull.duration = 0.85
        pull.timingFunctions = [CAMediaTimingFunction(name: .easeIn),
                                CAMediaTimingFunction(name: .linear),
                                CAMediaTimingFunction(name: .easeOut),
                                CAMediaTimingFunction(name: .easeInEaseOut)]
        leverArm.add(pull, forKey: "pull")
    }

    /// Anime les 3 rouleaux vers `finals`, arrêts décalés, tic sonore à chaque arrêt
    func spinReels(to finals: [Int], completion: @escaping () -> Void) {
        pullLever()
        let durations: [CFTimeInterval] = [1.1, 1.5, 1.9]
        for i in 0..<3 {
            let startCell = 42 + currentIndices[i]
            let endCell = (3 - i) * 6 + finals[i]
            setStrip(i, toCell: startCell)

            let anim = CABasicAnimation(keyPath: "position.y")
            anim.fromValue = stripY(forCell: startCell)
            anim.toValue = stripY(forCell: endCell)
            anim.duration = durations[i]
            anim.timingFunction = CAMediaTimingFunction(controlPoints: 0.18, 0.7, 0.25, 1)

            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                guard let self else { return }
                self.setStrip(i, toCell: 42 + finals[i])
                self.currentIndices[i] = finals[i]
                SoundBox.play("Tink", volume: 0.35)
                if i == 2 { DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: completion) }
            }
            CATransaction.setDisableActions(true)
            strips[i].position = CGPoint(x: 0, y: stripY(forCell: endCell))
            strips[i].add(anim, forKey: "spin")
            CATransaction.commit()
        }
    }

    // MARK: - Petits effets locaux

    func sparkleBurst() {
        guard let img = CasinoArt.glint(26) else { return }
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: IslandGeo.windowW / 2, y: IslandGeo.pillRect.minY + 4)
        emitter.emitterShape = .point
        let cell = CAEmitterCell()
        cell.contents = img
        cell.birthRate = 80
        cell.lifetime = 1.6
        cell.velocity = 190
        cell.velocityRange = 70
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = 1.1
        cell.yAcceleration = -320
        cell.scale = 0.5
        cell.scaleRange = 0.3
        // Fondu complet avant le bord de fenêtre, sinon les étincelles « poppent »
        cell.alphaSpeed = -2.0
        cell.spin = 3
        emitter.emitterCells = [cell]
        layer?.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { emitter.birthRate = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { emitter.removeFromSuperlayer() }
    }

    func goldShimmer() {
        let g = CAGradientLayer()
        g.frame = CGRect(x: 20, y: 33, width: IslandGeo.pillW - 40, height: 2)
        g.startPoint = CGPoint(x: 0, y: 0.5)
        g.endPoint = CGPoint(x: 1, y: 0.5)
        let gold = NSColor(calibratedRed: 1, green: 0.83, blue: 0.3, alpha: 1).cgColor
        let clear = NSColor.clear.cgColor
        g.colors = [clear, gold, clear]
        g.locations = [-0.4, -0.2, 0]
        pillBody.addSublayer(g)
        let sweep = CABasicAnimation(keyPath: "locations")
        sweep.fromValue = [-0.4, -0.2, 0]
        sweep.toValue = [1, 1.2, 1.4]
        sweep.duration = 1.1
        sweep.repeatCount = 3
        g.add(sweep, forKey: "sweep")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { g.removeFromSuperlayer() }
    }
}

private extension CGFloat {
    func rounded(toMultipleOf m: CGFloat) -> CGFloat { (self / m).rounded() * m }
}
