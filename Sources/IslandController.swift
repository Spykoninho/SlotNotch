import AppKit

// Capte les clics sur la pilule (hors bande barre des menus), avec leur position
final class ClickCatcherView: NSView {
    var onTapAt: ((NSPoint) -> Void)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        onTapAt?(convert(event.locationInWindow, from: nil))
    }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
}

// Pilote l'île : fenêtre collée au notch, détection du curseur, cycle de jeu
final class IslandController {
    private let panel: NSPanel
    private let clickPanel: NSPanel
    private let view: IslandView
    private let engine = SlotEngine()
    private let bj = BlackjackEngine()

    private var expanded = false
    private var spinning = false
    private var bjBusy = false
    private var resultHoldUntil: Date = .distantPast
    private var lastInside: Date = .distantPast
    private var hoverSince: Date?
    private var timer: Timer?

    var gameMode: GameMode {
        GameMode(rawValue: UserDefaults.standard.string(forKey: "game") ?? "") ?? .slots
    }

    var statsChanged: (() -> Void)?

    init() {
        // Mesure l'encoche AVANT de construire la géométrie
        if #available(macOS 12.0, *) {
            IslandGeo.notchInset = IslandController.pickScreen()?.safeAreaInsets.top ?? 0
        }

        let rect = NSRect(x: 0, y: 0, width: IslandGeo.windowW, height: IslandGeo.windowH)
        // Panneau visuel : ne reçoit JAMAIS un clic (assigné une fois, jamais bougé)
        panel = NSPanel(contentRect: rect,
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 3)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        view = IslandView(frame: rect)
        panel.contentView = view

        // Panneau attrape-clics : pilule + débord du levier, ordonné seulement quand déplié
        clickPanel = NSPanel(contentRect: NSRect(x: 0, y: 0,
                                                 width: IslandGeo.pillW + IslandGeo.leverOverhang,
                                                 height: IslandGeo.pillH - IslandGeo.notchInset),
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        clickPanel.level = NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue + 4)
        clickPanel.backgroundColor = .clear
        clickPanel.isOpaque = false
        clickPanel.hasShadow = false
        clickPanel.isMovable = false
        clickPanel.hidesOnDeactivate = false
        clickPanel.ignoresMouseEvents = false
        clickPanel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        let catcher = ClickCatcherView(frame: clickPanel.contentLayoutRect)
        catcher.onTapAt = { [weak self] p in self?.tapped(at: p) }
        clickPanel.contentView = catcher
        view.setMode(gameMode)

        reposition()
        panel.orderFrontRegardless()

        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.reposition()
        }

        // Sondage curseur : aucune permission, quasi gratuit
        timer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer.map { RunLoop.main.add($0, forMode: .common) }

        // Tirage scriptable : `notifyutil -p fr.mathis.slotch.spin`
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterAddObserver(center, observer, { _, obs, _, _, _ in
            guard let obs else { return }
            let me = Unmanaged<IslandController>.fromOpaque(obs).takeUnretainedValue()
            DispatchQueue.main.async { me.spinRequested() }
        }, "fr.mathis.slotch.spin" as CFString, nil, .deliverImmediately)
        CFNotificationCenterAddObserver(center, observer, { _, obs, _, _, _ in
            guard let obs else { return }
            let me = Unmanaged<IslandController>.fromOpaque(obs).takeUnretainedValue()
            DispatchQueue.main.async { me.debugDump() }
        }, "fr.mathis.slotch.dump" as CFString, nil, .deliverImmediately)
        // Pilotage blackjack scriptable, pour le debug
        CFNotificationCenterAddObserver(center, observer, { _, obs, _, _, _ in
            guard let obs else { return }
            let me = Unmanaged<IslandController>.fromOpaque(obs).takeUnretainedValue()
            DispatchQueue.main.async { if me.gameMode == .blackjack, !me.bjBusy { me.bjHit() } }
        }, "fr.mathis.slotch.hit" as CFString, nil, .deliverImmediately)
        CFNotificationCenterAddObserver(center, observer, { _, obs, _, _, _ in
            guard let obs else { return }
            let me = Unmanaged<IslandController>.fromOpaque(obs).takeUnretainedValue()
            DispatchQueue.main.async { if me.gameMode == .blackjack, !me.bjBusy { me.bjStand() } }
        }, "fr.mathis.slotch.stand" as CFString, nil, .deliverImmediately)
    }

    // Autoportrait de l'île dans /tmp/slotch_dump.png : `notifyutil -p fr.mathis.slotch.dump`
    private func debugDump() {
        guard let layer = panel.contentView?.layer,
              let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(IslandGeo.windowW) * 2,
                                         pixelsHigh: Int(IslandGeo.windowH) * 2,
                                         bitsPerSample: 8, samplesPerPixel: 4,
                                         hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB,
                                         bytesPerRow: 0, bitsPerPixel: 0),
              let ctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
        ctx.cgContext.scaleBy(x: 2, y: 2)
        // La couche de présentation capture les animations en vol (défilement LED, levier…)
        (layer.presentation() ?? layer).render(in: ctx.cgContext)
        try? rep.representation(using: .png, properties: [:])?
            .write(to: URL(fileURLWithPath: "/tmp/slotch_dump.png"))
    }

    // Écran avec encoche si présent, sinon écran principal
    static func pickScreen() -> NSScreen? {
        if #available(macOS 12.0, *),
           let notched = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) {
            return notched
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    private var screen: NSScreen? { IslandController.pickScreen() }

    private func reposition() {
        guard let screen else { return }
        let f = screen.frame
        panel.setFrameOrigin(NSPoint(x: f.midX - IslandGeo.windowW / 2,
                                     y: f.maxY - IslandGeo.windowH))
        // La bande barre-des-menus/notch reste hors du cadre : les menus restent cliquables
        clickPanel.setFrame(NSRect(x: f.midX - IslandGeo.pillW / 2,
                                   y: f.maxY - IslandGeo.pillH,
                                   width: IslandGeo.pillW + IslandGeo.leverOverhang,
                                   height: IslandGeo.pillH - IslandGeo.notchInset),
                            display: false)
    }

    // Zone de déclenchement : la bande centrale du haut (l'encoche, ou son fantôme)
    private var triggerZone: NSRect {
        guard let screen else { return .zero }
        let f = screen.frame
        var w: CGFloat = 220
        var h: CGFloat = 30
        if #available(macOS 12.0, *), screen.safeAreaInsets.top > 0 {
            h = screen.safeAreaInsets.top + 4
            if let l = screen.auxiliaryTopLeftArea, let r = screen.auxiliaryTopRightArea {
                w = f.width - l.width - r.width + 24
            }
        }
        // +1.5 seulement : assez pour le curseur plaqué au bord, sans déborder sur un écran au-dessus
        return NSRect(x: f.midX - w / 2, y: f.maxY - h, width: w, height: h + 1.5)
    }

    private var pillScreenRect: NSRect {
        var r = IslandGeo.pillRect
        r.origin.x += panel.frame.origin.x
        r.origin.y += panel.frame.origin.y
        return r
    }

    private func tick() {
        let mouse = NSEvent.mouseLocation
        if !expanded {
            // 2 s de patience sous l'encoche : les passages accidentels ne comptent pas
            if triggerZone.contains(mouse) {
                if hoverSince == nil { hoverSince = Date() }
                else if Date().timeIntervalSince(hoverSince!) >= 2.0 {
                    hoverSince = nil
                    expand()
                }
            } else {
                hoverSince = nil
            }
        } else {
            let keepZone = pillScreenRect.insetBy(dx: -60, dy: -50).union(triggerZone)
            if keepZone.contains(mouse) { lastInside = Date() }
            let idle = Date().timeIntervalSince(lastInside)
            if idle > 0.5, !spinning, Date() > resultHoldUntil { collapse() }
        }
    }

    private func expand() {
        expanded = true
        lastInside = Date()
        panel.orderFrontRegardless()
        clickPanel.orderFrontRegardless()
        view.setCredits(engine.credits)
        view.revealPill()
        view.bulbsChase(rounds: 1)
        SoundBox.play("Pop", volume: 0.25)
        if gameMode == .blackjack {
            bjEnter()
        } else {
            view.setMessage(Personality.greeting)
            view.setLED(.idle)
        }
    }

    private func collapse() {
        expanded = false
        clickPanel.orderOut(nil)
        view.concealPill(animated: true)
    }

    // Action principale : tirage aux rouleaux, ou distribution au blackjack
    func spinRequested() {
        if gameMode == .blackjack {
            if !expanded { expandForced() }
            else if bj.state != .playerTurn { bjDeal() }
            return
        }
        guard !spinning else { return }
        if !expanded { expandForced() }
        spinning = true
        view.setLED(.spin)
        view.setMessage(Personality.spinning)
        SoundBox.play("Pop", volume: 0.4)

        // Débit affiché tout de suite ; le gain n'apparaît qu'à l'arrêt des rouleaux
        let before = engine.credits
        let result = engine.spin()
        view.setCredits(max(0, before - 1))
        view.spinReels(to: result.reels) { [weak self] in
            self?.resolve(result)
        }
    }

    // Ouverture programmée (menu 🎰) même sans passage du curseur
    private func expandForced() {
        expanded = true
        lastInside = Date()
        panel.orderFrontRegardless()
        clickPanel.orderFrontRegardless()
        view.setCredits(engine.credits)
        view.revealPill()
        view.bulbsChase(rounds: 1)
        if gameMode == .blackjack { bjEnter() }
    }

    // MARK: - Blackjack

    private func tapped(at p: NSPoint) {
        guard gameMode == .blackjack else { spinRequested(); return }
        guard !bjBusy else { return }
        if bj.state == .playerTurn {
            // Pendant la main, seuls les boutons comptent : pas de tirage accidentel
            switch view.bjAction(at: p) {
            case .hit: bjHit()
            case .stand: bjStand()
            case nil: break
            }
        } else {
            bjDeal()
        }
    }

    // À l'ouverture : reprend la main en cours, sinon distribue
    private func bjEnter() {
        guard !bjBusy else { return }
        view.setLED(.idle)
        if bj.state == .playerTurn {
            resultHoldUntil = Date().addingTimeInterval(3)
            lastInside = Date()
            view.bjStartHand(player: bj.player, dealer: bj.dealer)
            view.bjSetTotals(player: bj.playerValue,
                             dealer: BlackjackEngine.value([bj.dealer[0]]))
            view.bjButtons(enabled: true)
            view.setMessage(Personality.bjChoice)
        } else {
            bjDeal()
        }
    }

    private func bjDeal() {
        guard !bjBusy else { return }
        bjBusy = true
        resultHoldUntil = Date().addingTimeInterval(3)
        lastInside = Date()
        let refilled = bj.deal()
        view.setCredits(bj.credits)
        statsChanged?()
        view.setLED(.spin)
        view.setMessage(refilled ? Personality.houseGift : Personality.bjDealing)
        view.bjSetTotals(player: nil, dealer: nil)
        view.bjButtons(enabled: false)
        view.bjStartHand(player: bj.player, dealer: bj.dealer)
        for i in 0..<4 { SoundBox.play("Tink", volume: 0.25, after: 0.1 + Double(i) * 0.22) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.bjBusy = false
            self.view.bjSetTotals(player: self.bj.playerValue,
                                  dealer: BlackjackEngine.value([self.bj.dealer[0]]))
            if self.bj.playerHasNatural {
                self.bjStand()   // 21 d'entrée : on règle direct
            } else {
                self.view.setLED(.idle)
                self.view.bjButtons(enabled: true)
                self.view.setMessage(Personality.bjChoice)
                self.lastInside = Date()
                self.resultHoldUntil = Date().addingTimeInterval(3)
            }
        }
    }

    private func bjHit() {
        guard bj.state == .playerTurn else { return }
        let c = bj.hit()
        resultHoldUntil = Date().addingTimeInterval(3)
        SoundBox.play("Tink", volume: 0.3)
        view.bjAddCard(c, dealer: false, index: bj.player.count - 1)
        view.bjSetTotals(player: bj.playerValue,
                         dealer: BlackjackEngine.value([bj.dealer[0]]))
        lastInside = Date()
        if bj.playerValue > 21 {
            bjBusy = true
            view.bjButtons(enabled: false)
            view.bjRevealHole(bj.dealer[1])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.bjFinish() }
        } else if bj.playerValue == 21 {
            bjStand()
        }
    }

    private func bjStand() {
        guard bj.state == .playerTurn else { return }
        bjBusy = true
        view.bjButtons(enabled: false)
        view.setLED(.spin)
        view.bjRevealHole(bj.dealer[1])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self else { return }
            self.view.bjSetTotals(player: self.bj.playerValue,
                                  dealer: BlackjackEngine.value(Array(self.bj.dealer.prefix(2))))
        }

        // Le croupier tire jusqu'à 17, une carte toutes les 0,55 s
        let drawn = bj.dealerPlay()
        for (k, c) in drawn.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75 + Double(k) * 0.55) { [weak self] in
                guard let self else { return }
                self.view.bjAddCard(c, dealer: true, index: 2 + k)
                SoundBox.play("Tink", volume: 0.3)
                self.view.bjSetTotals(player: self.bj.playerValue,
                                      dealer: BlackjackEngine.value(Array(self.bj.dealer.prefix(3 + k))))
            }
        }
        let total = 0.95 + Double(drawn.count) * 0.55
        resultHoldUntil = Date().addingTimeInterval(total + 3.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + total) { [weak self] in self?.bjFinish() }
    }

    private func bjFinish() {
        bjBusy = false
        let r = bj.settle()
        view.setCredits(bj.credits)
        statsChanged?()
        guard gameMode == .blackjack else { return }
        view.bjSetTotals(player: bj.playerValue, dealer: bj.dealerValue)
        view.bjButtons(enabled: false)
        resultHoldUntil = Date().addingTimeInterval(3.2)
        lastInside = Date()

        var msg: String
        var tone: MsgTone = .amber
        switch r.outcome {
        case .win:
            msg = Personality.bjWin
            view.setLED(.win)
            view.sparkleBurst()
            view.bulbsChase(rounds: 2)
            SoundBox.play("Glass", volume: 0.5)
        case .blackjack:
            msg = Personality.bjBlackjack
            tone = .gold
            view.setLED(.jackpot)
            view.goldShimmer()
            view.bulbsFrenzy(duration: 2.5)
            SoundBox.play("Hero", volume: 0.6)
        case .push:
            msg = Personality.bjPush
            view.setLED(.idle)
            SoundBox.play("Purr", volume: 0.4)
        case .lose:
            msg = Personality.bjLose
            tone = .red
            view.setLED(.lose)
            SoundBox.play("Basso", volume: 0.4)
        case .bust:
            msg = Personality.bjBust
            tone = .red
            view.setLED(.lose)
            SoundBox.play("Basso", volume: 0.5)
        }
        if r.houseRefill { msg += " " + Personality.houseGift }
        view.setMessage(msg, tone: tone)
    }

    func setGameMode(_ m: GameMode) {
        let changed = m != gameMode
        UserDefaults.standard.set(m.rawValue, forKey: "game")
        view.setMode(m)   // regrave aussi les libellés (langue)
        if expanded, changed {
            if m == .blackjack {
                bjEnter()
            } else {
                view.setMessage(Personality.greeting)
                view.setLED(.idle)
                view.setCredits(engine.credits)
            }
        }
        statsChanged?()
    }

    private func resolve(_ r: SpinResult) {
        spinning = false
        view.setCredits(engine.credits)
        statsChanged?()
        // Jeu changé pendant la rotation : les gains sont comptés, pas la mise en scène
        guard gameMode == .slots else { return }
        resultHoldUntil = Date().addingTimeInterval(2.6)
        lastInside = Date()

        switch r.outcome {
        case .jackpot:
            view.setLED(.jackpot)
            view.setMessage(r.message, tone: .gold)
            view.goldShimmer()
            view.bulbsFrenzy(duration: 4.5)
            SoundBox.play("Hero", volume: 0.7)
            SoundBox.play("Glass", volume: 0.6, after: 0.5)
            EffectsOverlay.play(.jackpot, on: screen)
            resultHoldUntil = Date().addingTimeInterval(4.5)
        case .triple(let s):
            view.setLED(.win)
            view.setMessage(r.message, tone: .gold)
            view.goldShimmer()
            view.bulbsChase(rounds: 4)
            SoundBox.play("Glass", volume: 0.6)
            EffectsOverlay.play(.triple(s), on: screen)
            resultHoldUntil = Date().addingTimeInterval(3.5)
        case .pair:
            view.setLED(.win)
            view.setMessage(r.message)
            view.sparkleBurst()
            view.bulbsChase(rounds: 1)
            SoundBox.play("Purr", volume: 0.5)
        case .nearMiss:
            view.setLED(.lose)
            view.setMessage(r.message, tone: .red)
            EffectsOverlay.play(.nearMiss, on: screen)
            SoundBox.play("Basso", volume: 0.4)
        case .lose:
            view.setLED(.lose)
            view.setMessage(r.message)
            if Double.random(in: 0..<1) < 0.12 { EffectsOverlay.play(.tumbleweed, on: screen) }
            if Double.random(in: 0..<1) < 0.3 { SoundBox.play("Bottle", volume: 0.3) }
        }
    }

    var statsLine: String {
        Personality.statsLine(spins: engine.spins, triples: engine.triples,
                              jackpots: engine.jackpots, credits: engine.credits)
    }

    func resetStats() { engine.resetStats(); statsChanged?() }
}
