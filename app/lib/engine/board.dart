import 'package:flutter/foundation.dart';

const int boardSize = 7;
const int winCaptures = 4;

enum Player { amber, slate }

Player opponent(Player p) => p == Player.amber ? Player.slate : Player.amber;

class Board {
  final List<List<Player?>> grid;
  final Map<Player, int> captures;

  Board()
      : grid = List.generate(boardSize, (_) => List.filled(boardSize, null)),
        captures = {Player.amber: 0, Player.slate: 0};

  Board._internal(this.grid, this.captures);

  Player? get(int r, int c) => grid[r][c];

  void set(int r, int c, Player? value) => grid[r][c] = value;

  bool onBoard(int r, int c) =>
      r >= 0 && r < boardSize && c >= 0 && c < boardSize;

  List<(int, int)> neighbors(int r, int c) {
    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    return [
      for (final (dr, dc) in dirs)
        if (onBoard(r + dr, c + dc)) (r + dr, c + dc),
    ];
  }

  List<(int, int)> legalMoves() => [
        for (int r = 0; r < boardSize; r++)
          for (int c = 0; c < boardSize; c++)
            if (grid[r][c] == null) (r, c),
      ];

  int stoneCount(Player p) {
    int n = 0;
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (grid[r][c] == p) n++;
      }
    }
    return n;
  }

  bool get isFull {
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (grid[r][c] == null) return false;
      }
    }
    return true;
  }

  Board copy() {
    final newGrid = List.generate(
      boardSize,
      (r) => List<Player?>.from(grid[r]),
    );
    return Board._internal(newGrid, Map.from(captures));
  }

  @override
  bool operator ==(Object other) =>
      other is Board && listEquals(grid.expand((r) => r).toList(), other.grid.expand((r) => r).toList());

  @override
  int get hashCode => Object.hashAll(grid.expand((r) => r));
}
