import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var island: IslandController!
    private var statusItem: NSStatusItem!
    private let statsItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private var muteItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        island = IslandController()
        island.statsChanged = { [weak self] in self?.refreshStats() }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🎰"
        rebuildMenu()
    }

    // Reconstruit tout : appelé au lancement et à chaque changement de langue
    private func rebuildMenu() {
        let menu = NSMenu()
        let header = NSMenuItem(title: "Slotch", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        statsItem.isEnabled = false
        menu.addItem(statsItem)
        menu.addItem(.separator())

        let spin = NSMenuItem(title: Personality.menuTestSpin, action: #selector(testSpin), keyEquivalent: "t")
        spin.target = self
        menu.addItem(spin)

        muteItem = NSMenuItem(title: Personality.menuMute, action: #selector(toggleMute), keyEquivalent: "")
        muteItem.target = self
        menu.addItem(muteItem)

        let reset = NSMenuItem(title: Personality.menuReset, action: #selector(resetStats), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        // Sous-menu langue, coche sur la langue active
        let langMenu = NSMenu()
        for lang in Lang.allCases {
            let item = NSMenuItem(title: lang.label, action: #selector(pickLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = lang.rawValue
            item.state = L10n.lang == lang ? .on : .off
            langMenu.addItem(item)
        }
        let langItem = NSMenuItem(title: Personality.menuLanguage, action: nil, keyEquivalent: "")
        menu.addItem(langItem)
        menu.setSubmenu(langMenu, for: langItem)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: Personality.menuQuit,
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
        refreshStats()
    }

    private func refreshStats() {
        statsItem.title = island.statsLine
        muteItem?.state = SoundBox.muted ? .on : .off
    }

    @objc private func testSpin() { island.spinRequested() }

    @objc private func toggleMute() {
        SoundBox.muted.toggle()
        refreshStats()
    }

    @objc private func resetStats() { island.resetStats() }

    @objc private func pickLanguage(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let lang = Lang(rawValue: raw) else { return }
        L10n.lang = lang
        rebuildMenu()
    }
}
