import AppKit

// Une seule instance : si Slotch tourne déjà, on s'efface sans bruit
let bundleID = Bundle.main.bundleIdentifier ?? "fr.mathis.slotch"
let already = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
if already { exit(0) }

// Point d'entrée : app "accessory", vit derrière l'encoche, pas de Dock
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
