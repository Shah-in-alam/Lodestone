import 'board.dart';

const _dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

void resolvePulls(Board board, int row, int col, Player placer) {
  final enemy = opponent(placer);
  final targets = <(int, int), (int, int)>{};
  final conflicts = <(int, int)>{};

  for (final (dr, dc) in _dirs) {
    int r = row + dr, c = col + dc;
    while (board.onBoard(r, c)) {
      final cell = board.get(r, c);
      if (cell == enemy) {
        final dest = (r - dr, c - dc);
        if (targets.containsKey(dest)) {
          conflicts.add(dest);
        } else {
          targets[dest] = (r, c);
        }
        break;
      } else if (cell != null) {
        break; // friendly stone blocks scan
      }
      r += dr;
      c += dc;
    }
  }

  for (final entry in targets.entries) {
    final dest = entry.key;
    final src = entry.value;
    if (!conflicts.contains(dest) && board.get(dest.$1, dest.$2) == null) {
      board.set(dest.$1, dest.$2, enemy);
      board.set(src.$1, src.$2, null);
    }
  }
}

/// Returns (enemyCaptured, selfCaptured).
(int, int) resolveCaptures(Board board, Player activePl) {
  final enemy = opponent(activePl);

  // Evaluate both lists against the same snapshot before removing anything.
  final enemyList = [
    for (int r = 0; r < boardSize; r++)
      for (int c = 0; c < boardSize; c++)
        if (board.get(r, c) == enemy && _isSurrounded(board, r, c, activePl))
          (r, c),
  ];
  final selfList = [
    for (int r = 0; r < boardSize; r++)
      for (int c = 0; c < boardSize; c++)
        if (board.get(r, c) == activePl && _isSurrounded(board, r, c, enemy))
          (r, c),
  ];

  for (final (r, c) in enemyList) { board.set(r, c, null); }
  for (final (r, c) in selfList) { board.set(r, c, null); }

  board.captures[activePl] = (board.captures[activePl] ?? 0) + enemyList.length;
  board.captures[enemy] = (board.captures[enemy] ?? 0) + selfList.length;

  return (enemyList.length, selfList.length);
}

bool _isSurrounded(Board board, int r, int c, Player byPlayer) =>
    board.neighbors(r, c).every((n) => board.get(n.$1, n.$2) == byPlayer);
