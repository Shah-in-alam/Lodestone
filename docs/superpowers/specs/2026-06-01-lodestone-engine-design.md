# Lodestone Engine Design — Phase A (Python Prototype)

**Date:** 2026-06-01  
**Scope:** Python engine prototype only (board, rules, MCTS AI, CLI runner, tests). No mobile app.

---

## 1. Goal

Produce a fully playable terminal game with a competent AI opponent. Proves the rules are consistent and fun before any mobile work begins.

---

## 2. Architecture

```
engine-prototype/
  lodestone/
    __init__.py
    board.py      # Board dataclass + low-level grid helpers
    rules.py      # resolve_pulls(), resolve_captures()
    game.py       # Game class — turn loop, win detection
    mcts.py       # MCTSNode, mcts_search()
  tests/
    test_rules.py # pull + capture edge cases
    test_mcts.py  # MCTS sanity checks
  play_cli.py     # Human vs AI in the terminal
```

Each module has one clear purpose. No module imports from one above it in the list (board ← rules ← game ← mcts).

---

## 3. Data model

```python
from enum import Enum

class Player(Enum):
    AMBER = 1   # human
    SLATE = 2   # AI

BOARD_SIZE = 7
WIN_CAPTURES = 4
```

**Board** is a `7×7` list-of-lists holding `Player | None`.  
A `Board` object also carries `captures: dict[Player, int]` (stones removed so far).

`Move` is a plain `(row: int, col: int)` tuple — the only action a player takes.

---

## 4. Rules (fully resolved)

### 4.1 Legal moves
Any cell currently `None` (empty). If no empty cell exists, the board is full → check win by stone count.

### 4.2 Pull resolution

After placing a stone at `(r, c)` for `placer`:

1. Scan outward in each of the four orthogonal directions.  
2. In each direction, walk cell-by-cell until:
   - An **enemy** stone is found → record `(source, dest)` where `dest` is one step back toward `(r, c)`.
   - A **friendly** stone (or board edge with no enemy found) → no pull in this direction.
3. Collect all `dest` cells across all four directions.  
4. **Collision rule:** if two directions target the same `dest`, both are discarded.  
5. For each surviving `(source, dest)`:
   - If `dest` is empty → move the enemy stone there.
   - If `dest` is occupied (edge case: already filled by another resolved pull) → pull is blocked silently.

Pulls resolve **simultaneously** (compute all first, apply non-conflicting ones together).

### 4.3 Capture resolution

After all pulls are applied:

1. Identify every stone on the board that is **surrounded**: all of its on-board orthogonal neighbors are held by the opposing player.
   - Center: 4 neighbors all enemy.
   - Edge (non-corner): 3 neighbors all enemy (board edge counts as "wall", not a neighbor).
   - Corner: 2 neighbors all enemy.
2. Collect **enemy** stones of the active player first (enemy_captures list).  
3. Collect **own** stones of the active player (self_captures list).  
4. Remove all collected stones; increment `captures` accordingly.

Self-capture is allowed. Both lists are evaluated after the same single snapshot of the board (no re-evaluation between enemy and own removal).

### 4.4 Win conditions (checked after each turn)

1. If `captures[AMBER] >= WIN_CAPTURES` → **Slate wins** (Amber lost 4 stones).  
2. If `captures[SLATE] >= WIN_CAPTURES` → **Amber wins**.  
3. If the board is full and neither threshold reached → compare stone counts on board; more stones wins. Equal → **draw**.

---

## 5. MCTS engine

**Node state:** `move`, `player_who_moved`, `visits`, `wins`, `children`, `parent`, `untried_moves`.

**Selection:** UCB1 with `C = √2`:
```
score = wins/visits + C * sqrt(ln(parent.visits) / visits)
```
Pick the child with the highest score; unvisited children have infinite priority.

**Expansion:** Pick one random untried move, create a child node.

**Rollout:** From the expanded node, play random legal moves (uniform random) to terminal state.

**Backpropagation:** Walk back to root, incrementing `visits` on every node; increment `wins` on nodes belonging to the winner.

**Budget:** Time-based (`itertools`-free loop checking `time.time()`). Default 1.0 s (tunable).

**Difficulty presets:**

| Level  | Time budget |
|--------|-------------|
| Easy   | 0.05 s      |
| Medium | 0.5 s       |
| Hard   | 2.0 s       |
| Expert | 5.0 s       |

---

## 6. CLI interface (`play_cli.py`)

- Prints the board after each move with row/column labels (A-G for columns, 1-7 for rows).
- Human enters a move as e.g. `d4` or `4d` (case-insensitive).
- Shows captured stone count for both players after each turn.
- Announces winner or draw at game end.
- Accepts `--difficulty easy|medium|hard|expert` flag (default: medium).

---

## 7. Testing

**test_rules.py** covers:
- Basic pull (one enemy stone pulled).
- Pull blocked by own stone in path.
- Pull blocked because destination is occupied.
- Collision: two pulls targeting same cell → both cancel.
- Corner capture (2 neighbors).
- Edge capture (3 neighbors).
- Center capture (4 neighbors).
- Self-capture after a pull.
- Win by 4 captures.
- Win by stone count when board is full.

**test_mcts.py** covers:
- MCTS returns a valid legal move.
- MCTS finds an immediate win in one move (trivial forced win board).
- Rollout always reaches a terminal state.

---

## 8. Out of scope for Phase A

- Flutter/Dart port (Phase B).
- Neural-network policy guidance (AlphaZero style).
- Networked multiplayer.
- Sound, animations, cosmetics.
