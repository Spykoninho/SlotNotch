import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var island: IslandController!
    private var statusItem: NSStatusItem!
    private let statsItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let muteItem = NSMenuItem(title: "Silencieux", action: #selector(toggleMute), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        island = IslandController()
        island.statsChanged = { [weak self] in self?.refreshStats() }
        buildStatusItem()
    }

    private func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🎰"

        let menu = NSMenu()
        let header = NSMenuItem(title: "Le Bandit à Encoche", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        statsItem.isEnabled = false
        menu.addItem(statsItem)
        menu.addItem(.separator())

        let spin = NSMenuItem(title: "Tirage d'essai", action: #selector(testSpin), keyEquivalent: "t")
        spin.target = self
        menu.addItem(spin)

        muteItem.target = self
        menu.addItem(muteItem)

        let reset = NSMenuItem(title: "Remettre les compteurs à zéro", action: #selector(resetStats), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quitter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        statusItem.menu = menu
        refreshStats()
    }

    private func refreshStats() {
        statsItem.title = island.statsLine
        muteItem.state = SoundBox.muted ? .on : .off
    }

    @objc private func testSpin() { island.spinRequested() }

    @objc private func toggleMute() {
        SoundBox.muted.toggle()
        refreshStats()
    }

    @objc private func resetStats() { island.resetStats() }
}
