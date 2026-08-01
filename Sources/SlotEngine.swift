import Foundation

// 0:🍒 1:7️⃣ 2:🌙 3:⚡️ 4:👻 5:🫠
enum Symbols {
    static let all = ["🍒", "7️⃣", "🌙", "⚡️", "👻", "🫠"]
}

enum Outcome {
    case jackpot          // 7️⃣7️⃣7️⃣
    case triple(Int)      // trois identiques (hors 7)
    case pair(Int)        // deux identiques
    case nearMiss         // 7️⃣7️⃣✗ — le drame
    case lose
}

struct SpinResult {
    let reels: [Int]
    let outcome: Outcome
    let message: String
}

final class SlotEngine {
    private let d = UserDefaults.standard

    var spins: Int { d.integer(forKey: "spins") }
    var jackpots: Int { d.integer(forKey: "jackpots") }
    var triples: Int { d.integer(forKey: "triples") }
    private var spinsSinceTriple: Int {
        get { d.integer(forKey: "spinsSinceTriple") }
        set { d.set(newValue, forKey: "spinsSinceTriple") }
    }

    func resetStats() {
        ["spins", "jackpots", "triples", "spinsSinceTriple", "hasSpun"].forEach { d.removeObject(forKey: $0) }
    }

    func spin() -> SpinResult {
        d.set(spins + 1, forKey: "spins")

        // Cadeau de bienvenue : la maison offre toujours le premier tour
        if !d.bool(forKey: "hasSpun") {
            d.set(true, forKey: "hasSpun")
            return record(.triple(0), reels: [0, 0, 0],
                          message: "Cadeau de la maison. Reviens quand tu veux. 🍒")
        }

        // Pitié : 25 tours sans triplette, la machine craque avant toi
        if spinsSinceTriple >= 25 {
            let s = Double.random(in: 0..<1) < 0.15 ? 1 : Int.random(in: 2...5)
            let outcome: Outcome = s == 1 ? .jackpot : .triple(s)
            return record(outcome, reels: [s, s, s], message: Personality.pity)
        }

        let roll = Double.random(in: 0..<1)
        switch roll {
        case ..<0.015:
            return record(.jackpot, reels: [1, 1, 1], message: Personality.jackpot)
        case ..<0.115:
            let s = [0, 2, 3, 4, 5].randomElement()!
            return record(.triple(s), reels: [s, s, s], message: Personality.triple(s))
        case ..<0.40:
            // Jamais de paire de 7 ici : les 7️⃣7️⃣✗ appartiennent au near-miss
            let s = [0, 2, 3, 4, 5].randomElement()!
            var other = Int.random(in: 0...5)
            while other == s { other = Int.random(in: 0...5) }
            var reels = [s, s, s]
            reels[Int.random(in: 0...2)] = other
            return record(.pair(s), reels: reels, message: Personality.pair)
        default:
            // Perte — mais 25% du temps, un near-miss 7-7-✗ pour le frisson
            if Double.random(in: 0..<1) < 0.25 {
                var x = Int.random(in: 0...5)
                while x == 1 { x = Int.random(in: 0...5) }
                return record(.nearMiss, reels: [1, 1, x], message: Personality.nearMiss)
            }
            var pool = Array(0...5).shuffled()
            let reels = [pool.removeLast(), pool.removeLast(), pool.removeLast()]
            return record(.lose, reels: reels, message: Personality.lose)
        }
    }

    private func record(_ outcome: Outcome, reels: [Int], message: String) -> SpinResult {
        switch outcome {
        case .jackpot:
            d.set(jackpots + 1, forKey: "jackpots")
            d.set(triples + 1, forKey: "triples")
            spinsSinceTriple = 0
        case .triple:
            d.set(triples + 1, forKey: "triples")
            spinsSinceTriple = 0
        default:
            spinsSinceTriple += 1
        }
        return SpinResult(reels: reels, outcome: outcome, message: message)
    }
}
