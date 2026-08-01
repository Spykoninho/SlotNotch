# 🎰 Le Bandit à Encoche

> Il vit derrière le notch de ton Mac. Il attend. Il te nargue.

Approche ton curseur de l'encoche : une machine à sous glisse hors du notch,
façon Dynamic Island. Clique, le levier se tire, les rouleaux tournent —
et selon la combinaison, ton écran vit des choses.

## Les combinaisons

| Rouleaux | Effet plein écran |
|---|---|
| 7️⃣ 7️⃣ 7️⃣ | **JACKPOT** — explosion dorée, pluie de pièces, flash |
| 🍒 🍒 🍒 | Pluie de cerises |
| 🌙 🌙 🌙 | La nuit tombe sur ton écran, la lune se lève |
| ⚡️ ⚡️ ⚡️ | Orage : flashs, barres de glitch néon, foudre |
| 👻 👻 👻 | Un fantôme traverse l'écran. BOUH. |
| 🫠 🫠 🫠 | L'écran fond en coulées pastel |
| Deux identiques | Gerbe d'étincelles sous l'île |
| 7️⃣ 7️⃣ ✗ | Near-miss. Flash rouge. Douleur. |
| Rien | Une taquinerie. Parfois une feuille morte, seule. |

## Le caractère

- **Premier tirage toujours gagnant** — cadeau de la maison. 🍒
- **Pitié intégrée** — 25 tours sans triplette et la machine craque avant toi.
- **Near-miss truqués** — 25 % des pertes affichent 7️⃣7️⃣✗, parce que le drame, c'est la vie.
- **Elle parle** — taquineries françaises sous les rouleaux, LED d'humeur, levier qui se tire tout seul.

## Construire & lancer

```bash
./build.sh --run
```

C'est tout. Pas d'Xcode, pas de dépendances, pas de permissions système.
`swiftc` + AppKit + Core Animation, ~1 200 lignes.

- L'app vit dans la barre des menus : **🎰** (stats, tirage d'essai, mode silencieux, quitter).
- Pas d'icône Dock, pas de vol de focus : la fenêtre est un panneau non-activant,
  transparent aux clics quand l'île est repliée.
- Sans encoche ? Ça marche aussi — l'île sort du haut-centre de l'écran,
  là où l'encoche aurait dû être. Le Bandit ne juge pas ton matériel.

## Anatomie

```
Sources/
├── main.swift             # 6 lignes, comme il se doit
├── AppDelegate.swift      # le menu 🎰
├── IslandController.swift # panneau collé au notch, détection du curseur, cycle de jeu
├── IslandView.swift       # la pilule noire : rouleaux, levier, LED, messages
├── SlotEngine.swift       # probabilités truquées avec amour
├── Personality.swift      # la voix du Bandit
├── EffectsOverlay.swift   # les effets plein écran
├── EmojiArt.swift         # emoji → CGImage
└── SoundBox.swift         # sons système, coupables
```

*Aucune productivité n'a été épargnée pendant le développement de cette application.*
