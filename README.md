# Lodestone

**A minute to learn, a lifetime to master.** Lodestone is an original two-player strategy board game for mobile, built around one simple idea: every stone you place is a magnet that *pulls* your opponent's stones toward it. Use those pulls to drag enemy stones into traps and surround them.

The opponent AI is powered by a custom **Monte Carlo Tree Search (MCTS)** engine, so it can play a game that has never existed before — no pre-built chess-style engine required.

---

## Table of contents

- [Why this project](#why-this-project)
- [The game](#the-game)
- [How the AI works](#how-the-ai-works)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Roadmap](#roadmap)
- [Difficulty levels](#difficulty-levels)
- [Monetization](#monetization)
- [Risks and open questions](#risks-and-open-questions)
- [License](#license)

---

## Why this project

Most game-AI projects reuse an existing engine (Stockfish for chess, etc.). Because Lodestone is a brand-new game, no such engine exists — which is exactly why it's a good project. A single general-purpose algorithm (MCTS) can play *any* turn-based, perfect-information, deterministic game given only its rules. Build the rules once, plug MCTS in, and you instantly have a competent, scalable AI opponent.

The game is designed from the start to fit that algorithm: small board, simple rules, no hidden information, no dice.

---

## The game

> ⚠️ These are **v1 rules** — a sensible starting point, not a finished design. Expect to playtest and rewrite them. Most invented games are not fun on the first try; that's normal.

### Setup

- A **7×7** grid, starting empty.
- Two players: **Amber** (the human) and **Slate** (the AI).
- Amber moves first; players then alternate.

### A turn

On your turn, place **one stone of your color** on any empty cell. Two things then resolve automatically, in this order:

**1. The pull.**
The stone you just placed acts as a magnet. Look outward from it in each of the four orthogonal directions (up, down, left, right). In each direction, find the **nearest enemy stone** in that line. That stone slides **one cell toward** your new stone — but only if the cell it would move into is empty. A single placement can trigger up to four pulls at once, creating chain reactions.

**2. Captures.**
After all pulls resolve, any stone whose **every on-board orthogonal neighbor is an enemy stone** is captured and removed.
- A **center** stone needs all 4 sides surrounded.
- An **edge** stone needs 3 (the board edge protects it).
- A **corner** stone needs only 2.

This makes edges and corners safer, which gives the board real positional strategy. Enemy stones are checked for capture first, then your own.

### Winning

- **First to capture 4 enemy stones wins**, or
- If the board fills first, the player with **more stones on the board** wins.

### Why it's interesting

The pull means you rarely place a stone just to occupy a cell — you place it to *move* the opponent. A single well-placed stone can yank an enemy piece out of safety and straight into a surround. That "drag them into the trap" feeling is the game's hook and is easy to show on a phone with a single tap.

---

## How the AI works

The opponent uses **Monte Carlo Tree Search (MCTS)**. In plain terms, on each turn the AI:

1. **Selects** a promising line of play it has already started exploring.
2. **Expands** by trying a new candidate move from there.
3. **Simulates** the rest of the game with fast semi-random moves to the end ("rollout").
4. **Backpropagates** the win/loss result up the tree so good moves accumulate value.

It repeats this loop as many times as its time budget allows, then plays the move that came out best. The beauty of MCTS: it needs **only the rules of the game** (legal moves, and who won at the end). It never needs a hand-written "this position is good because…" evaluation, which is hard to write for a brand-new game.

**Tuning difficulty is trivial:** give MCTS more thinking time / more simulations → stronger play; less → weaker. That single dial drives all your difficulty levels.

*(Optional later upgrade: once the game is proven fun, you can train a small neural network to guide the search — the AlphaZero approach — but that is well beyond v1 and not needed to ship.)*

---

## Tech stack

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | **Flutter 3.44+** | Single codebase → iOS + Android. |
| Language | **Dart** | UI and MCTS engine in one language, no native bridge. |
| State | **setState** (v1) → Riverpod (if complexity grows) | Keep it simple first. |
| Local storage | **shared_preferences** | Save settings and stats. |
| AI | **Custom MCTS** (pure Dart) | ~200 lines; no dependencies; tunable by time budget. |

---

## Project structure

```
lodestone/
├── README.md
└── app/                         # Flutter app — iOS + Android
    ├── lib/
    │   ├── engine/
    │   │   ├── board.dart        # Board state, Player enum, helpers
    │   │   ├── rules.dart        # Pull resolution + capture logic
    │   │   ├── game.dart         # Turn loop, win conditions
    │   │   └── mcts.dart         # MCTS AI engine
    │   ├── ui/
    │   │   ├── game_screen.dart  # Main game screen
    │   │   ├── board_widget.dart # Interactive 7×7 grid
    │   │   └── menu_screen.dart  # Difficulty picker + start screen
    │   └── main.dart
    ├── assets/
    └── pubspec.yaml
```

---

## Getting started

```bash
cd app
flutter pub get
flutter run                      # runs on a connected device or emulator
```

---

## Roadmap

**Milestone 1 — Core engine (Dart).** Board, pull resolution, capture logic, win detection — all rule edge cases locked in and unit tested.

**Milestone 2 — MCTS AI.** UCB1 search with time-based difficulty budget. Target: a move in under 1 second on mid-range hardware.

**Milestone 3 — Playable Flutter UI.** Tap to place, animate pulls and captures, show captured counts, game-over screen.

**Milestone 4 — Playtest & polish.** Difficulty picker, sound, tutorial, onboarding. Then publish to App Store and Google Play.

---

## Difficulty levels

All driven by the MCTS time/simulation budget — no separate AI code needed:

| Level | MCTS simulations per move | Feel |
|-------|---------------------------|------|
| Easy | very few (or random) | Beatable by a beginner |
| Medium | moderate | A fair fight |
| Hard | high | Punishes mistakes |
| Expert | maximum the device allows | For mastered players |

---

## Monetization

(You flagged this as a startup idea, so a few realistic options.)

- **Free with ads** between matches — lowest friction for installs.
- **One-time unlock** to remove ads and unlock Expert difficulty / extra board sizes.
- **Cosmetics** — stone skins, board themes (no pay-to-win; keep the game fair).

Ship a genuinely fun free core first. Distinctive gameplay drives word-of-mouth far more than any pricing trick.

---

## Risks and open questions

- **Game design is the hard part, not the code.** The MCTS engine is well-understood; making the *game* fun is the real challenge. Budget time to iterate.
- **Balance.** Does Amber's first-move advantage decide games? You may need a rule tweak (e.g. a "pie rule" where the second player can swap sides after move one).
- **Performance on phones.** Pure-Dart MCTS must stay fast. If it's slow, reduce the simulation count or optimize the rollout.
- **Rule ambiguities.** Simultaneous pulls and chain captures need crisp, deterministic ordering — define these before coding.

---

## License

TBD — choose before publishing (e.g. MIT for open code, or keep it proprietary if you plan to monetize).
