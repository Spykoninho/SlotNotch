import Foundation

struct PlayingCard {
    let rank: Int   // 1 (as) ... 13 (roi)
    let suit: Int   // 0:♠ 1:♥ 2:♦ 3:♣
}

enum BJState { case idle, playerTurn, settled }
enum BJOutcome { case win, lose, bust, push, blackjack }

struct BJResult {
    let outcome: BJOutcome
    let houseRefill: Bool
}

// Blackjack de comptoir : mise fixe, cagnotte partagée avec la machine à sous
final class BlackjackEngine {
    private let d = UserDefaults.standard
    private var deck: [PlayingCard] = []

    private(set) var player: [PlayingCard] = []
    private(set) var dealer: [PlayingCard] = []
    private(set) var state: BJState = .idle

    let bet = 2
    var credits: Int { d.integer(forKey: "credits") }

    // As = 11 tant que ça passe, sinon 1
    static func value(_ hand: [PlayingCard]) -> Int {
        var total = 0, aces = 0
        for c in hand {
            if c.rank == 1 { aces += 1; total += 11 }
            else { total += min(c.rank, 10) }
        }
        while total > 21 && aces > 0 { total -= 10; aces -= 1 }
        return total
    }

    var playerValue: Int { Self.value(player) }
    var dealerValue: Int { Self.value(dealer) }
    var playerHasNatural: Bool { player.count == 2 && playerValue == 21 }

    /// Nouvelle main : débite la mise, distribue 2+2
    func deal() {
        deck = (0..<52).map { PlayingCard(rank: $0 % 13 + 1, suit: $0 / 13) }.shuffled()
        d.set(max(0, credits - bet), forKey: "credits")
        player = [deck.removeLast(), deck.removeLast()]
        dealer = [deck.removeLast(), deck.removeLast()]
        state = .playerTurn
    }

    /// Tire une carte pour le joueur
    func hit() -> PlayingCard {
        let c = deck.removeLast()
        player.append(c)
        return c
    }

    /// Le croupier tire jusqu'à 17 ; renvoie ses nouvelles cartes
    func dealerPlay() -> [PlayingCard] {
        var drawn: [PlayingCard] = []
        while Self.value(dealer) < 17 {
            let c = deck.removeLast()
            dealer.append(c)
            drawn.append(c)
        }
        return drawn
    }

    /// Compare, paie, et régale si banqueroute — appelable une seule fois par main
    func settle() -> BJResult {
        guard state != .settled else { return BJResult(outcome: .push, houseRefill: false) }
        state = .settled

        let p = playerValue, dl = dealerValue
        let outcome: BJOutcome
        if p > 21 { outcome = .bust }
        else if playerHasNatural { outcome = dealer.count == 2 && dl == 21 ? .push : .blackjack }
        else if dl > 21 || p > dl { outcome = .win }
        else if p == dl { outcome = .push }
        else { outcome = .lose }

        switch outcome {
        case .win: d.set(credits + bet * 2, forKey: "credits")
        case .blackjack: d.set(credits + bet * 2 + 1, forKey: "credits")
        case .push: d.set(credits + bet, forKey: "credits")
        case .lose, .bust: break
        }

        var refill = false
        if credits <= 0 {
            d.set(10, forKey: "credits")
            refill = true
        }
        return BJResult(outcome: outcome, houseRefill: refill)
    }
}
