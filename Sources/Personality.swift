import Foundation

// La voix du Bandit : narquoise, jamais méchante
enum Personality {
    static var greeting: String {
        [
            "Un p'tit tour ?",
            "Clique. Tu sais que tu en as envie.",
            "Le Bandit t'attendait.",
            "Pssst. Par ici.",
            "Tire sur le levier, on verra bien.",
            "L'encoche cache des trésors.",
            "Ta pause est légitime. Prouve-le.",
        ].randomElement()!
    }

    static var lose: String {
        [
            "Encore un p'tit tour ?",
            "La chance tourne. Pas pour toi.",
            "C'était presque bien.",
            "L'encoche te regarde avec pitié.",
            "Retourne bosser. Ou pas.",
            "Statistiquement, ça devait arriver.",
            "Allez, un dernier. Promis ?",
            "Même la pomme a plus de chance.",
        ].randomElement()!
    }

    static var nearMiss: String {
        [
            "NON MAIS SI PRÈS ?!",
            "Le troisième 7 est en RTT.",
            "J'ai cru. Toi aussi. Aïe.",
            "Deux 7. Le destin est cruel.",
        ].randomElement()!
    }

    static var pair: String {
        [
            "Presque ! Enfin… presque presque.",
            "Deux sur trois. Comme au loto. Non.",
            "Ça chauffe. Tiède, disons.",
            "La paire. Classe, mais sans plus.",
        ].randomElement()!
    }

    static func triple(_ s: Int) -> String {
        switch s {
        case 0: return "PLUIE DE CERISES !"
        case 2: return "DING DING DING !"
        case 3: return "TRIPLE BAR. Le grand classique."
        case 4: return "DIAMANTS. Quelle classe."
        case 5: return "FER À CHEVAL. Veinard, va."
        default: return "TRIPLETTE ! L'encoche est fière."
        }
    }

    static var jackpot: String { "JACKPOT. Encadre cet écran." }
    static var pity: String { "Bon. Tiens. Tu me faisais de la peine." }
    static var spinning: String { ["…", "ça tourne…", "croise les doigts…"].randomElement()! }
}
