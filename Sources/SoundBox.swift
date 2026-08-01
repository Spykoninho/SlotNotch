import AppKit

// Petits sons système, coupables via le menu 🎰
enum SoundBox {
    static var muted: Bool {
        get { UserDefaults.standard.bool(forKey: "muted") }
        set { UserDefaults.standard.set(newValue, forKey: "muted") }
    }

    static func play(_ name: String, volume: Float = 0.6, after delay: Double = 0) {
        guard !muted else { return }
        let fire = {
            guard let s = NSSound(named: NSSound.Name(name))?.copy() as? NSSound else { return }
            s.volume = volume
            s.play()
        }
        if delay <= 0 { fire() }
        else { DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: fire) }
    }
}
