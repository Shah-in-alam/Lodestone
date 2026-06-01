import 'dart:math';
import 'game.dart';
import 'board.dart';

const _c = 1.4142135623730951; // sqrt(2)

const Map<String, double> difficultyBudgets = {
  'easy': 0.05,
  'medium': 0.5,
  'hard': 2.0,
  'expert': 5.0,
};

class _Node {
  final Game game;
  final _Node? parent;
  final (int, int)? move;
  final Player? playerWhoMoved;

  final List<_Node> children = [];
  int visits = 0;
  double wins = 0;
  late List<(int, int)> _untried;

  _Node(this.game, {this.parent, this.move, this.playerWhoMoved}) {
    _untried = List.from(game.legalMoves())..shuffle(_rng);
  }

  bool get isFullyExpanded => _untried.isEmpty;
  bool get isTerminal => game.isOver;

  double get ucb1 {
    if (visits == 0) return double.infinity;
    return wins / visits + _c * sqrt(log(parent!.visits) / visits);
  }

  _Node get bestChild => children.reduce((a, b) => a.ucb1 > b.ucb1 ? a : b);
}

final _rng = Random();

(int, int) mctsSearch(Game game, double timeBudget) {
  final root = _Node(game.copy());
  final deadline = DateTime.now().add(
    Duration(milliseconds: (timeBudget * 1000).toInt()),
  );

  while (DateTime.now().isBefore(deadline)) {
    var node = root;

    // Selection
    while (!node.isTerminal && node.isFullyExpanded) {
      node = node.bestChild;
    }

    // Expansion
    if (!node.isTerminal && node._untried.isNotEmpty) {
      final move = node._untried.removeLast();
      final newGame = node.game.copy();
      newGame.applyMove(move.$1, move.$2);
      final child = _Node(
        newGame,
        parent: node,
        move: move,
        playerWhoMoved: node.game.currentPlayer,
      );
      node.children.add(child);
      node = child;
    }

    // Rollout
    final winner = _rollout(node.game);

    // Backpropagation
    _Node? n = node;
    while (n != null) {
      n.visits++;
      if (winner != null && n.playerWhoMoved == winner) n.wins++;
      n = n.parent;
    }
  }

  if (root.children.isEmpty) {
    final moves = game.legalMoves();
    return moves[_rng.nextInt(moves.length)];
  }

  return root.children.reduce((a, b) => a.visits > b.visits ? a : b).move!;
}

Player? _rollout(Game game) {
  final g = game.copy();
  while (!g.isOver) {
    final moves = g.legalMoves();
    if (moves.isEmpty) break;
    final m = moves[_rng.nextInt(moves.length)];
    g.applyMove(m.$1, m.$2);
  }
  return _resultToWinner(g.result);
}

Player? _resultToWinner(GameResult? result) {
  if (result == GameResult.amberWins) return Player.amber;
  if (result == GameResult.slateWins) return Player.slate;
  return null;
}
