import AppKit

// Point d'entrée : app "accessory", vit derrière l'encoche, pas de Dock
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
