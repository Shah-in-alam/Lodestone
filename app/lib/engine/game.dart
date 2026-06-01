import 'board.dart';
import 'rules.dart';

enum GameResult { amberWins, slateWins, draw }

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

  void applyMove(int row, int col) {
    assert(!isOver, 'Game is already over');
    assert(board.get(row, col) == null, 'Cell is occupied');

    final placer = currentPlayer;
    board.set(row, col, placer);
    resolvePulls(board, row, col, placer);
    resolveCaptures(board, placer);

    result = _checkWinner();
    if (!isOver) currentPlayer = opponent(currentPlayer);
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
