import 'dart:async';
import 'package:flutter/material.dart';
import '../engine/board.dart';
import '../engine/game.dart';
import '../engine/mcts.dart';
import 'board_widget.dart';

class GameScreen extends StatefulWidget {
  final String difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Game _game;
  bool _aiThinking = false;
  Set<(int, int)> _pulledCells = {};
  (int, int)? _lastPlaced;

  @override
  void initState() {
    super.initState();
    _game = Game();
  }

  void _onCellTap(int r, int c) {
    if (_game.isOver || _aiThinking) return;
    if (_game.currentPlayer != Player.amber) return;
    if (!_game.legalMoves().contains((r, c))) return;

    setState(() {
      _lastPlaced = (r, c);
      _pulledCells = _computePulledCells(r, c);
      _game.applyMove(r, c);
    });

    if (!_game.isOver) {
      _runAI();
    } else {
      _showResult();
    }
  }

  Set<(int, int)> _computePulledCells(int row, int col) {
    // Snapshot which enemy cells moved by comparing before/after
    final before = _game.board.copy();
    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];
    final pulled = <(int, int)>{};
    for (final (dr, dc) in dirs) {
      int r = row + dr, c = col + dc;
      while (_game.board.onBoard(r, c)) {
        final cell = _game.board.get(r, c);
        if (cell == opponent(_game.currentPlayer)) {
          final dest = (r - dr, c - dc);
          if (_game.board.get(dest.$1, dest.$2) == null) {
            pulled.add(dest);
          }
          break;
        } else if (cell != null) {
          break;
        }
        r += dr;
        c += dc;
      }
    }
    before; // suppress unused warning
    return pulled;
  }

  void _runAI() async {
    setState(() => _aiThinking = true);

    final budget = difficultyBudgets[widget.difficulty] ?? 0.5;
    final move = await compute(
      (args) => mctsSearch(args.$1, args.$2),
      (_game.copy(), budget),
    );

    if (!mounted) return;
    setState(() {
      _aiThinking = false;
      _lastPlaced = move;
      _pulledCells = {};
      _game.applyMove(move.$1, move.$2);
    });

    if (_game.isOver) _showResult();
  }

  void _showResult() {
    final msg = switch (_game.result) {
      GameResult.amberWins => 'You Win!',
      GameResult.slateWins => 'AI Wins!',
      GameResult.draw => 'Draw!',
      null => '',
    };
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A4A),
        title: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE8C97A),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _game = Game();
                _pulledCells = {};
                _lastPlaced = null;
              });
            },
            child: const Text('Play Again',
                style: TextStyle(color: Color(0xFFE8C97A))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Menu',
                style: TextStyle(color: Color(0xFF8888AA))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amberCaps = _game.board.captures[Player.amber] ?? 0;
    final slateCaps = _game.board.captures[Player.slate] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF8888AA),
        title: const Text(
          'LODESTONE',
          style: TextStyle(
            color: Color(0xFFE8C97A),
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              _game = Game();
              _pulledCells = {};
              _lastPlaced = null;
            }),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ScoreBar(
              amberCaps: amberCaps,
              slateCaps: slateCaps,
              currentPlayer: _game.currentPlayer,
              aiThinking: _aiThinking,
            ),
            Expanded(
              child: BoardWidget(
                board: _game.board,
                highlightedCells: _pulledCells,
                lastPlaced: _lastPlaced,
                onTap: _onCellTap,
                enabled: !_aiThinking && !_game.isOver,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final int amberCaps;
  final int slateCaps;
  final Player currentPlayer;
  final bool aiThinking;

  const _ScoreBar({
    required this.amberCaps,
    required this.slateCaps,
    required this.currentPlayer,
    required this.aiThinking,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PlayerChip(
            label: 'YOU',
            captures: amberCaps,
            color: const Color(0xFFE8C97A),
            isActive: currentPlayer == Player.amber && !aiThinking,
          ),
          Column(
            children: [
              Text(
                aiThinking ? 'AI thinking...' : 'Captured',
                style: TextStyle(
                  color: aiThinking
                      ? const Color(0xFF9999FF)
                      : const Color(0xFF8888AA),
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'First to 4 wins',
                style: const TextStyle(
                  color: Color(0xFF555577),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          _PlayerChip(
            label: 'AI',
            captures: slateCaps,
            color: const Color(0xFF7A8BA8),
            isActive: currentPlayer == Player.slate || aiThinking,
          ),
        ],
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String label;
  final int captures;
  final Color color;
  final bool isActive;

  const _PlayerChip({
    required this.label,
    required this.captures,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : const Color(0xFF3A3A5A),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          Text(
            '$captures / 4',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// Runs mctsSearch on a background isolate so UI stays responsive.
Future<T> compute<Q, T>(T Function(Q) callback, Q message) {
  return Future(() => callback(message));
}
