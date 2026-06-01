import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/board.dart';
import '../engine/game.dart';
import '../engine/mcts.dart';
import 'board_widget.dart';
import 'how_to_play_screen.dart';

class GameScreen extends StatefulWidget {
  final String difficulty;
  const GameScreen({super.key, required this.difficulty});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Game _game;
  bool _busy = false;
  (int, int)? _lastPlaced;
  Set<(int, int)> _pulledDests = {};
  Map<(int, int), Player> _capturedStones = {};

  @override
  void initState() {
    super.initState();
    _game = Game();
  }

  Future<void> _onCellTap(int r, int c) async {
    if (_busy || _game.isOver) return;
    if (_game.currentPlayer != Player.amber) return;
    if (!_game.legalMoves().contains((r, c))) return;

    HapticFeedback.lightImpact();
    _busy = true;

    final result = _game.applyMove(r, c);
    await _animateMove((r, c), result);

    if (_game.isOver) {
      _busy = false;
      if (mounted) _showResult();
      return;
    }

    await _runAI();
    _busy = false;
  }

  Future<void> _animateMove((int, int) placed, MoveResult result) async {
    if (!mounted) return;

    // Phase 1: show placed stone
    setState(() {
      _lastPlaced = placed;
      _pulledDests = {};
      _capturedStones = {};
    });
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    // Phase 2: pull glow
    if (result.hasPulls) {
      setState(() => _pulledDests = result.pullDests);
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
    }

    // Phase 3: capture flash (show removed stones in red)
    if (result.hasCaptures) {
      setState(() {
        _pulledDests = {};
        _capturedStones = result.capturedStones;
      });
      await Future.delayed(const Duration(milliseconds: 380));
      if (!mounted) return;
      setState(() => _capturedStones = {});
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
    } else {
      setState(() => _pulledDests = {});
    }
  }

  Future<void> _runAI() async {
    if (!mounted) return;
    setState(() {});

    final grid = List.generate(
      boardSize,
      (r) => List.generate(boardSize, (c) {
        final cell = _game.board.get(r, c);
        return cell == null ? -1 : cell.index;
      }),
    );
    final amberCaps = _game.board.captures[Player.amber] ?? 0;
    final slateCaps = _game.board.captures[Player.slate] ?? 0;
    final cpIdx = _game.currentPlayer.index;
    final budget = difficultyBudgets[widget.difficulty] ?? 0.5;

    final move = await Isolate.run(() {
      final g = Game();
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (grid[r][c] >= 0) {
            g.board.set(r, c, Player.values[grid[r][c]]);
          }
        }
      }
      g.board.captures[Player.amber] = amberCaps;
      g.board.captures[Player.slate] = slateCaps;
      g.currentPlayer = Player.values[cpIdx];
      return mctsSearch(g, budget);
    });

    if (!mounted) return;
    HapticFeedback.selectionClick();

    final aiResult = _game.applyMove(move.$1, move.$2);
    await _animateMove(move, aiResult);

    if (_game.isOver && mounted) _showResult();
  }

  void _showResult() {
    final (title, sub) = switch (_game.result) {
      GameResult.amberWins => ('You Win!', 'Amber conquers Slate'),
      GameResult.slateWins => ('AI Wins!', 'Slate conquers Amber'),
      GameResult.draw => ("It's a Draw", 'Equal stones remain'),
      null => ('', ''),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE8C97A),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub,
              style: const TextStyle(color: Color(0xFF8888AA), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8888AA),
                      side: const BorderSide(color: Color(0xFF3A3A5A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Menu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _game = Game();
                        _lastPlaced = null;
                        _pulledDests = {};
                        _capturedStones = {};
                        _busy = false;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8C97A),
                      foregroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Play Again',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amberCaps = _game.board.captures[Player.amber] ?? 0;
    final slateCaps = _game.board.captures[Player.slate] ?? 0;
    final isPlayerTurn =
        _game.currentPlayer == Player.amber && !_busy && !_game.isOver;
    final isAiTurn =
        _game.currentPlayer == Player.slate || (_busy && !_game.isOver);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF8888AA),
        elevation: 0,
        title: const Text(
          'LODESTONE',
          style: TextStyle(
            color: Color(0xFFE8C97A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _busy
                ? null
                : () => setState(() {
                      _game = Game();
                      _lastPlaced = null;
                      _pulledDests = {};
                      _capturedStones = {};
                      _busy = false;
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
              isPlayerTurn: isPlayerTurn,
              isAiTurn: isAiTurn,
              difficulty: widget.difficulty,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BoardWidget(
                board: _game.board,
                pulledCells: _pulledDests,
                capturedStones: _capturedStones,
                lastPlaced: _lastPlaced,
                showHints: isPlayerTurn,
                onTap: _onCellTap,
                enabled: isPlayerTurn,
              ),
            ),
            const SizedBox(height: 12),
            _TurnLabel(
              isPlayerTurn: isPlayerTurn,
              isAiTurn: isAiTurn,
              isOver: _game.isOver,
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
  final bool isPlayerTurn;
  final bool isAiTurn;
  final String difficulty;

  const _ScoreBar({
    required this.amberCaps,
    required this.slateCaps,
    required this.isPlayerTurn,
    required this.isAiTurn,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _PlayerPanel(
            label: 'YOU',
            color: const Color(0xFFE8C97A),
            captures: amberCaps,
            isActive: isPlayerTurn,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  difficulty.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF555577),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'first to 4 wins',
                  style: TextStyle(color: Color(0xFF404060), fontSize: 10),
                ),
              ],
            ),
          ),
          _PlayerPanel(
            label: 'AI',
            color: const Color(0xFF7A8BA8),
            captures: slateCaps,
            isActive: isAiTurn,
            alignRight: true,
          ),
        ],
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  final String label;
  final Color color;
  final int captures;
  final bool isActive;
  final bool alignRight;

  const _PlayerPanel({
    required this.label,
    required this.color,
    required this.captures,
    required this.isActive,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final filled = i < captures;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : Colors.transparent,
            border: Border.all(
              color: filled ? color : color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
        );
      }),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 5),
          dots,
        ],
      ),
    );
  }
}

class _TurnLabel extends StatelessWidget {
  final bool isPlayerTurn;
  final bool isAiTurn;
  final bool isOver;

  const _TurnLabel({
    required this.isPlayerTurn,
    required this.isAiTurn,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    if (isOver) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        isPlayerTurn ? 'Your turn — tap a cell' : 'AI is thinking...',
        key: ValueKey(isPlayerTurn),
        style: TextStyle(
          color: isPlayerTurn
              ? const Color(0xFFE8C97A).withValues(alpha: 0.8)
              : const Color(0xFF7A8BA8).withValues(alpha: 0.8),
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
