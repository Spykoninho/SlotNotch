# 🎰 Slotch

> *Le Bandit à Encoche.*

Il vit derrière le notch de ton Mac. Il attend. Il te nargue.

Approche ton curseur de l'encoche : un cabinet de machine à sous glisse hors du
notch, façon Dynamic Island. Cadre laiton riveté, façade bordeaux feutrée,
rouleaux ivoire sous verre bombé, levier chromé monté sur le flanc droit.
Clique, le levier se tire, les rouleaux tournent — et selon la combinaison,
ton écran vit des choses.

Tout est dessiné à la main en Core Graphics : symboles, pièces, lingots,
ampoules, lettrage doré. Zéro emoji, zéro image importée.

## Les combinaisons

| Rouleaux | Effet plein écran |
|---|---|
| 7 · 7 · 7 | **JACKPOT** — explosion dorée, pluie de pièces, bannière en lettres de marquise |
| Cerises ×3 | Pluie de cerises |
| Cloche ×3 | DING DING DING — ondes dorées + carillon |
| BAR ×3 | Pluie de lingots, lourde comme il se doit |
| Diamant ×3 | Scintillements + rai de lumière qui balaie l'écran |
| Fer à cheval ×3 | La veine verte, pluie de fers |
| Deux identiques | Gerbe d'étincelles sous l'île |
| 7 · 7 · ✗ | Near-miss. Flash rouge. Douleur. |
| Rien | Une taquinerie. Parfois un virevoltant, seul. |

## Le cabinet

- **Afficheur à matrice de points** — fonte 5×7 maison, pastilles ambrées,
  défilement cranté colonne par colonne comme un vrai ticker. Les accents
  sautent au rendu, comme sur les vrais panneaux.
- **Compteur de crédits 7 segments** — débité au tirage, crédité à l'arrêt des
  rouleaux. Fauché ? La maison régale : +10. Comme toutes les maisons honnêtes.
- **Ampoules de marquise** — chenillard à l'ouverture et sur triplette,
  frénésie complète au jackpot.
- **Plaque gravée, fente à pièce, lampe témoin sertie** — le premier degré
  jusqu'au bout.

## Le caractère

- **Premier tirage toujours gagnant** — cadeau de la maison.
- **Pitié intégrée** — 25 tours sans triplette et la machine craque avant toi.
- **Near-miss truqués** — 25 % des pertes affichent 7·7·✗, parce que le drame, c'est la vie.
- **Elle parle** — français ou anglais (menu 🎰 → Langue), taquineries sur le ticker, lampe d'humeur, levier qui se tire tout seul.

## Construire & lancer

```bash
./build.sh --run
```

C'est tout. Pas d'Xcode, pas de dépendances, pas de permissions système.
`swiftc` + AppKit + Core Animation, ~2 000 lignes.

- L'app vit dans la barre des menus : **🎰** (stats, tirage d'essai, langue,
  lancement au démarrage, mode silencieux, quitter).
- Pas d'icône Dock, pas de vol de focus : la fenêtre est un panneau non-activant,
  transparent aux clics quand l'île est repliée.
- Sans encoche ? Ça marche aussi — l'île sort du haut-centre de l'écran,
  là où l'encoche aurait dû être. Le Bandit ne juge pas ton matériel.

## Publier

```bash
./tools/make_icon.sh   # régénère l'icône depuis le code (CasinoArt → .icns)
./release.sh 1.0       # build signé Developer ID + notarisation + DMG
```

`release.sh` exige un certificat « Developer ID Application » et un profil
notarytool (`xcrun notarytool store-credentials slotch-notary …`, voir l'en-tête
du script). Il imprime le sha256 à reporter dans
[packaging/homebrew/slotch.rb](packaging/homebrew/slotch.rb) pour le cask.
La page vitrine vit dans [docs/](docs/) — prête pour GitHub Pages.

## Anatomie

```
Sources/
├── main.swift             # 6 lignes, comme il se doit
├── AppDelegate.swift      # le menu 🎰
├── IslandController.swift # panneau collé au notch, détection du curseur, cycle de jeu
├── IslandView.swift       # le cabinet : façade, rouleaux, levier, ampoules, ticker
├── CasinoArt.swift        # tous les assets, dessinés en Core Graphics
├── DotMatrix.swift        # l'afficheur LED 5×7 et sa fonte maison
├── SlotEngine.swift       # probabilités truquées avec amour, crédits compris
├── Personality.swift      # la voix du Bandit
├── EffectsOverlay.swift   # les effets plein écran
└── SoundBox.swift         # sons système, coupables
tools/                     # générateur d'icône
docs/                      # la page vitrine (GitHub Pages)
packaging/homebrew/        # le cask, prêt à copier dans un tap
```

*Aucune productivité n'a été épargnée pendant le développement de cette application.*
