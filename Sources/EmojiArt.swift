import AppKit

// Rendu d'emoji en CGImage (cache) : fiable partout, CATextLayer étant capricieux
enum EmojiArt {
    private static var cache: [String: CGImage] = [:]

    static func image(_ emoji: String, size: CGFloat) -> CGImage? {
        let key = "\(emoji)-\(Int(size))"
        if let hit = cache[key] { return hit }
        let str = NSAttributedString(string: emoji, attributes: [.font: NSFont.systemFont(ofSize: size)])
        var rect = str.boundingRect(with: NSSize(width: 2000, height: 2000), options: [.usesLineFragmentOrigin])
        rect.size.width = ceil(rect.width) + 4
        rect.size.height = ceil(rect.height) + 4
        guard rect.width > 4, rect.height > 4 else { return nil }
        let img = NSImage(size: rect.size)
        img.lockFocus()
        str.draw(at: NSPoint(x: 2, y: 2))
        img.unlockFocus()
        var proposed = CGRect(origin: .zero, size: img.size)
        let cg = img.cgImage(forProposedRect: &proposed, context: nil, hints: nil)
        if let cg { cache[key] = cg }
        return cg
    }

    static func colorRect(_ color: NSColor, size: NSSize) -> CGImage? {
        let img = NSImage(size: size)
        img.lockFocus()
        color.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 2, yRadius: 2).fill()
        img.unlockFocus()
        var proposed = CGRect(origin: .zero, size: size)
        return img.cgImage(forProposedRect: &proposed, context: nil, hints: nil)
    }
}
