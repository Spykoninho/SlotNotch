import AppKit
import QuartzCore

// Géométrie partagée fenêtre/pilule
enum IslandGeo {
    static let windowW: CGFloat = 560
    static let windowH: CGFloat = 300
    static let pillW: CGFloat = 344
    // Hauteur de l'encoche physique : le haut de la pilule vit derrière, invisible
    static var notchInset: CGFloat = 0
    // 128 px de contenu toujours visibles SOUS le notch
    static var pillH: CGFloat { 128 + notchInset }
    static var pillRect: CGRect {
        CGRect(x: (windowW - pillW) / 2, y: windowH - pillH, width: pillW, height: pillH)
    }
}

enum LEDState { case idle, spin, win, jackpot, lose }

final class IslandView: NSView {
    private let pillContainer = CALayer()
    private let pillBody = CALayer()
    private let titleLayer = CATextLayer()
    private let messageLayer = CATextLayer()
    private let led = CALayer()
    private let leverArm = CALayer()
    private var strips: [CALayer] = []
    private var currentIndices = [0, 1, 2]

    private let cellH: CGFloat = 54
    private let reelW: CGFloat = 64
    private let reelH: CGFloat = 54
    private let repeats = 8
    private var stripH: CGFloat { cellH * CGFloat(6 * repeats) }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = true
        buildPill()
        buildReels()
        buildLever()
        buildTexts()
        buildLED()
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

    private func buildReels() {
        for i in 0..<3 {
            let win = CALayer()
            win.frame = CGRect(x: 52 + CGFloat(i) * (reelW + 10), y: 44, width: reelW, height: reelH)
            win.backgroundColor = NSColor(white: 1, alpha: 0.07).cgColor
            win.cornerRadius = 12
            win.cornerCurve = .continuous
            win.masksToBounds = true
            win.borderWidth = 0.5
            win.borderColor = NSColor(white: 1, alpha: 0.10).cgColor
            pillBody.addSublayer(win)

            let strip = CALayer()
            strip.anchorPoint = .zero
            strip.frame = CGRect(x: 0, y: 0, width: reelW, height: stripH)
            for c in 0..<(6 * repeats) {
                let cell = CALayer()
                cell.frame = CGRect(x: 0, y: stripH - CGFloat(c + 1) * cellH, width: reelW, height: cellH)
                cell.contents = EmojiArt.image(Symbols.all[c % 6], size: 68)
                cell.contentsGravity = .resizeAspect
                cell.frame = cell.frame.insetBy(dx: 12, dy: 9)
                strip.addSublayer(cell)
            }
            win.addSublayer(strip)
            strips.append(strip)
            setStrip(i, toCell: 42 + i)
            currentIndices[i] = i
        }
    }

    private func buildLever() {
        // Socle du levier
        let base = CALayer()
        base.frame = CGRect(x: 299, y: 61, width: 14, height: 14)
        base.cornerRadius = 7
        base.backgroundColor = NSColor(white: 0.22, alpha: 1).cgColor
        pillBody.addSublayer(base)

        leverArm.bounds = CGRect(x: 0, y: 0, width: 14, height: 46)
        leverArm.anchorPoint = CGPoint(x: 0.5, y: 0.09)
        leverArm.position = CGPoint(x: 306, y: 68)

        let stick = CAShapeLayer()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 7, y: 4))
        path.addLine(to: CGPoint(x: 7, y: 34))
        stick.path = path
        stick.strokeColor = NSColor(white: 0.62, alpha: 1).cgColor
        stick.lineWidth = 4
        stick.lineCap = .round
        leverArm.addSublayer(stick)

        let ball = CALayer()
        ball.frame = CGRect(x: 0, y: 31, width: 14, height: 14)
        ball.cornerRadius = 7
        ball.backgroundColor = NSColor.systemRed.cgColor
        leverArm.addSublayer(ball)

        pillBody.addSublayer(leverArm)
    }

    private func buildTexts() {
        titleLayer.frame = CGRect(x: 0, y: 104, width: IslandGeo.pillW, height: 16)
        titleLayer.alignmentMode = .center
        titleLayer.contentsScale = 2
        titleLayer.string = attributed("LE BANDIT À ENCOCHE", size: 9, weight: .semibold,
                                       color: NSColor(white: 1, alpha: 0.38), kern: 3)
        pillBody.addSublayer(titleLayer)

        messageLayer.frame = CGRect(x: 10, y: 13, width: IslandGeo.pillW - 20, height: 18)
        messageLayer.alignmentMode = .center
        messageLayer.contentsScale = 2
        pillBody.addSublayer(messageLayer)
        setMessage(Personality.greeting)
    }

    private func buildLED() {
        led.frame = CGRect(x: 322, y: 108, width: 7, height: 7)
        led.cornerRadius = 3.5
        pillBody.addSublayer(led)
        setLED(.idle)
    }

    private func attributed(_ s: String, size: CGFloat, weight: NSFont.Weight,
                            color: NSColor, kern: CGFloat = 0) -> NSAttributedString {
        NSAttributedString(string: s, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .kern: kern,
        ])
    }

    // MARK: - État

    func setMessage(_ s: String, color: NSColor = NSColor(white: 1, alpha: 0.55)) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        messageLayer.string = attributed(s, size: 11, weight: .medium, color: color)
        CATransaction.commit()
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0
        fade.toValue = 1
        fade.duration = 0.3
        messageLayer.add(fade, forKey: "fade")
    }

    func setLED(_ state: LEDState) {
        led.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        switch state {
        case .idle: led.backgroundColor = NSColor(calibratedHue: 0.1, saturation: 0.3, brightness: 1, alpha: 1).cgColor
        case .spin: led.backgroundColor = NSColor.systemYellow.cgColor
        case .win: led.backgroundColor = NSColor.systemGreen.cgColor
        case .jackpot: led.backgroundColor = NSColor.systemYellow.cgColor
        case .lose: led.backgroundColor = NSColor.systemRed.cgColor
        }
        led.shadowColor = led.backgroundColor
        led.shadowOpacity = 0.9
        led.shadowRadius = 4
        led.shadowOffset = .zero
        CATransaction.commit()

        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 1
        pulse.toValue = 0.3
        pulse.duration = state == .spin ? 0.25 : 1.4
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        led.add(pulse, forKey: "pulse")

        if state == .jackpot {
            let hue = CAKeyframeAnimation(keyPath: "backgroundColor")
            hue.values = stride(from: 0.0, through: 1.0, by: 0.15).map {
                NSColor(calibratedHue: $0, saturation: 0.9, brightness: 1, alpha: 1).cgColor
            }
            hue.duration = 1.2
            hue.repeatCount = .infinity
            led.add(hue, forKey: "rainbow")
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
        guard let img = EmojiArt.image("✨", size: 26) else { return }
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
        g.frame = CGRect(x: 20, y: 2, width: IslandGeo.pillW - 40, height: 2.5)
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
