# 🎰 Slotch

It lives behind your Mac's notch.

Move your cursor to the notch: a slot machine cabinet slides out, Dynamic
Island style. Riveted brass frame, felted burgundy face, ivory reels behind
curved glass, a chrome lever bolted to the right side. Click — the lever
pulls, the reels spin, and depending on the combination, things happen to
your screen.

Everything is hand-drawn in Core Graphics: symbols, coins, gold bars, bulbs,
gold lettering. Zero emoji, zero imported images.

**[Download for macOS](https://github.com/Spykoninho/SlotNotch/releases/latest)** — free, notarized, macOS 12+.

## The combinations

| Reels | Full-screen effect |
|---|---|
| 7 · 7 · 7 | **JACKPOT** — golden explosion, coin rain, marquee-letter banner |
| Cherries ×3 | Cherry rain |
| Bell ×3 | DING DING DING — golden shockwaves + chimes |
| BAR ×3 | A rain of gold bars, heavy as it should be |
| Diamond ×3 | Sparkles + a ray of light sweeping the screen |
| Horseshoe ×3 | The green streak of luck, raining horseshoes |
| Any pair | A burst of sparks under the island |
| 7 · 7 · ✗ | Near-miss. Red flash. Pain. |
| Nothing | A taunt. Sometimes a lone tumbleweed. |

## The cabinet

- **Dot-matrix display** — homemade 5×7 font, amber dots, column-by-column
  stepped scrolling like a real ticker. Accents get dropped at render time,
  just like on real LED boards.
- **7-segment credit counter** — debited on the pull, credited when the reels
  stop. Broke? The house treats you: +10. Like every honest house.
- **Marquee bulbs** — a chase on reveal and on triples, full frenzy on jackpot.
- **Engraved plate, coin slot, jeweled status lamp** — deadpan realism,
  all the way down.

## The personality

- **First spin always wins** — house gift.
- **Built-in mercy** — 25 spins without a triple and the machine cracks before you do.
- **Rigged near-misses** — 25% of losses show 7·7·✗, because drama is life.
- **It talks** — French or English (🎰 menu → Language), taunts on the ticker,
  a mood lamp, a lever that pulls itself.

## Anatomy

```
Sources/
├── main.swift             # 6 lines, as it should be
├── AppDelegate.swift      # the 🎰 menu
├── IslandController.swift # panel glued to the notch, cursor detection, game loop
├── IslandView.swift       # the cabinet: face, reels, lever, bulbs, ticker
├── CasinoArt.swift        # every asset, drawn in Core Graphics
├── DotMatrix.swift        # the 5×7 LED display and its homemade font
├── SlotEngine.swift       # odds rigged with love, credits included
├── Personality.swift      # Slotch's voice, FR/EN
├── EffectsOverlay.swift   # the full-screen effects
└── SoundBox.swift         # system sounds, guilty as charged
tools/                     # icon generator
docs/                      # the landing page (GitHub Pages)
packaging/homebrew/        # the cask, ready for a tap
```
