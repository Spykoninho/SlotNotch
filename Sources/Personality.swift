import Foundation

// Langue de l'app : persistée, défaut = langue système
enum Lang: String, CaseIterable {
    case fr, en
    var label: String { self == .fr ? "Français" : "English" }
}

enum L10n {
    static var lang: Lang {
        get {
            if let raw = UserDefaults.standard.string(forKey: "lang"),
               let l = Lang(rawValue: raw) { return l }
            return Locale.preferredLanguages.first?.hasPrefix("fr") == true ? .fr : .en
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "lang") }
    }
}

// La voix de Slotch : narquoise, jamais méchante
enum Personality {
    private static func pick(_ fr: [String], _ en: [String]) -> String {
        (L10n.lang == .fr ? fr : en).randomElement()!
    }
    private static func one(_ fr: String, _ en: String) -> String {
        L10n.lang == .fr ? fr : en
    }

    static var greeting: String {
        pick([
            "Un p'tit tour ?",
            "Clique. Tu sais que tu en as envie.",
            "Slotch t'attendait.",
            "Pssst. Par ici.",
            "Tire sur le levier, on verra bien.",
            "L'encoche cache des trésors.",
            "Ta pause est légitime. Prouve-le.",
        ], [
            "Fancy a spin?",
            "Click. You know you want to.",
            "Slotch was waiting for you.",
            "Psst. Over here.",
            "Pull the lever, see what happens.",
            "The notch hides treasures.",
            "Your break is legit. Prove it.",
        ])
    }

    static var lose: String {
        pick([
            "Encore un p'tit tour ?",
            "La chance tourne. Pas pour toi.",
            "C'était presque bien.",
            "L'encoche te regarde avec pitié.",
            "Retourne bosser. Ou pas.",
            "Statistiquement, ça devait arriver.",
            "Allez, un dernier. Promis ?",
            "Même la pomme a plus de chance.",
        ], [
            "One more spin?",
            "Luck turns. Not for you.",
            "That was almost good.",
            "The notch pities you.",
            "Back to work. Or not.",
            "Statistically, this was bound to happen.",
            "Come on, one last one. Promise?",
            "Even the apple has better odds.",
        ])
    }

    static var nearMiss: String {
        pick([
            "NON MAIS SI PRÈS ?!",
            "Le troisième 7 est en RTT.",
            "J'ai cru. Toi aussi. Aïe.",
            "Deux 7. Le destin est cruel.",
        ], [
            "SO CLOSE?!",
            "The third 7 called in sick.",
            "I believed. So did you. Ouch.",
            "Two 7s. Fate is cruel.",
        ])
    }

    static var pair: String {
        pick([
            "Presque ! Enfin… presque presque.",
            "Deux sur trois. Comme au loto. Non.",
            "Ça chauffe. Tiède, disons.",
            "La paire. Classe, mais sans plus.",
        ], [
            "Almost! Well… almost almost.",
            "Two out of three. Like the lottery. No.",
            "Getting warm. Lukewarm, really.",
            "A pair. Classy, but no.",
        ])
    }

    static func triple(_ s: Int) -> String {
        switch s {
        case 0: return one("PLUIE DE CERISES !", "CHERRY RAIN!")
        case 2: return "DING DING DING !"
        case 3: return one("TRIPLE BAR. Le grand classique.", "TRIPLE BAR. The classic.")
        case 4: return one("DIAMANTS. Quelle classe.", "DIAMONDS. So classy.")
        case 5: return one("FER À CHEVAL. Veinard, va.", "HORSESHOE. Lucky you.")
        default: return one("TRIPLETTE ! L'encoche est fière.", "TRIPLE! The notch is proud.")
        }
    }

    static var jackpot: String { one("JACKPOT. Encadre cet écran.", "JACKPOT. Frame this screen.") }
    static var pity: String { one("Bon. Tiens. Tu me faisais de la peine.", "Fine. Here. You were breaking my heart.") }
    static var welcome: String { one("Cadeau de la maison. Reviens quand tu veux.", "House gift. Come back anytime.") }
    static var houseGift: String { one("La maison régale : +10 crédits.", "The house treats you: +10 credits.") }
    static var spinning: String {
        pick(["…", "ça tourne…", "croise les doigts…"], ["…", "spinning…", "cross your fingers…"])
    }

    // Bannières plein écran
    static var bannerJackpot: String { "JACKPOT" }
    static var bannerBell: String { "DING DING DING" }
    static var bannerBar: String { "BAR BAR BAR" }
    static var bannerDiamond: String { one("DIAMANTS", "DIAMONDS") }
    static var bannerShoe: String { one("VEINARD", "LUCKY YOU") }

    // Menu barre des menus
    static var menuTestSpin: String { one("Tirage d'essai", "Test spin") }
    static var menuMute: String { one("Silencieux", "Mute") }
    static var menuLaunchAtLogin: String { one("Lancer au démarrage", "Launch at login") }
    static var menuReset: String { one("Remettre les compteurs à zéro", "Reset counters") }
    static var menuLanguage: String { one("Langue", "Language") }
    static var menuQuit: String { one("Quitter", "Quit") }

    static func statsLine(spins: Int, triples: Int, jackpots: Int, credits: Int) -> String {
        L10n.lang == .fr
            ? "\(spins) tirages · \(triples) triplettes · \(jackpots) jackpots · \(credits) crédits"
            : "\(spins) spins · \(triples) triples · \(jackpots) jackpots · \(credits) credits"
    }
}
