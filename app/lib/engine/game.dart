import 'board.dart';
import 'rules.dart';

enum GameResult { amberWins, slateWins, draw }

class MoveResult {
  final List<((int, int), (int, int))> pulls; // (from, to) pairs
  final Map<(int, int), Player> capturedStones; // pos → whose stone was removed

  const MoveResult({required this.pulls, required this.capturedStones});

  bool get hasPulls => pulls.isNotEmpty;
  bool get hasCaptures => capturedStones.isNotEmpty;

  Set<(int, int)> get pullDests => pulls.map((p) => p.$2).toSet();
}

class Game {
  final Board board;
  Player currentPlayer;
  GameResult? result;

  Game()
      : board = Board(),
        currentPlayer = Player.amber;

  Game._internal(this.board, this.currentPlayer, this.result);

  bool get isOver => result != null;

  List<(int, int)> legalMoves() => isOver ? [] : board.legalMoves();

  MoveResult applyMove(int row, int col) {
    assert(!isOver, 'Game is already over');
    assert(board.get(row, col) == null, 'Cell is occupied');

    final placer = currentPlayer;
    board.set(row, col, placer);
    final pullMoves = resolvePulls(board, row, col, placer);
    final (enemyCaps, selfCaps) = resolveCaptures(board, placer);

    final capturedStones = <(int, int), Player>{
      for (final pos in enemyCaps) pos: opponent(placer),
      for (final pos in selfCaps) pos: placer,
    };

    result = _checkWinner();
    if (!isOver) currentPlayer = opponent(currentPlayer);

    return MoveResult(pulls: pullMoves, capturedStones: capturedStones);
  }

  GameResult? _checkWinner() {
    final amberCaps = board.captures[Player.amber] ?? 0;
    final slateCaps = board.captures[Player.slate] ?? 0;
    if (amberCaps >= winCaptures) return GameResult.amberWins;
    if (slateCaps >= winCaptures) return GameResult.slateWins;
    if (board.isFull) {
      final a = board.stoneCount(Player.amber);
      final s = board.stoneCount(Player.slate);
      if (a > s) return GameResult.amberWins;
      if (s > a) return GameResult.slateWins;
      return GameResult.draw;
    }
    return null;
  }

  Game copy() => Game._internal(board.copy(), currentPlayer, result);
}
