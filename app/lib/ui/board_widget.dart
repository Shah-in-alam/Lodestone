import 'package:flutter/material.dart';
import '../engine/board.dart';

const _colLabels = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];

class BoardWidget extends StatelessWidget {
  final Board board;
  final Set<(int, int)> pulledCells;
  final Map<(int, int), Player> capturedStones;
  final (int, int)? lastPlaced;
  final bool showHints;
  final void Function(int row, int col)? onTap;
  final bool enabled;

  const BoardWidget({
    super.key,
    required this.board,
    this.pulledCells = const {},
    this.capturedStones = const {},
    this.lastPlaced,
    this.showHints = false,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Column labels
          Row(
            children: [
              const SizedBox(width: 20),
              ...List.generate(
                boardSize,
                (c) => Expanded(
                  child: Center(
                    child: Text(
                      _colLabels[c],
                      style: const TextStyle(
                        color: Color(0xFF4A4A6A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row labels
                Column(
                  children: List.generate(
                    boardSize,
                    (r) => Expanded(
                      child: Center(
                        child: Text(
                          '${r + 1}',
                          style: const TextStyle(
                            color: Color(0xFF4A4A6A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Grid
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E38),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2E2E50),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: List.generate(
                          boardSize,
                          (r) => Expanded(
                            child: Row(
                              children: List.generate(boardSize, (c) {
                                final pos = (r, c);
                                final displayPlayer =
                                    capturedStones[pos] ?? board.get(r, c);
                                final isCaptured =
                                    capturedStones.containsKey(pos);
                                final isPulled = pulledCells.contains(pos);
                                final isLastPlaced = lastPlaced == pos;
                                final isHint =
                                    showHints && displayPlayer == null;

                                return Expanded(
                                  child: _Cell(
                                    player: displayPlayer,
                                    isCaptured: isCaptured,
                                    isPulled: isPulled,
                                    isLastPlaced: isLastPlaced,
                                    isHint: isHint,
                                    onTap: enabled && displayPlayer == null
                                        ? () => onTap?.call(r, c)
                                        : null,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Player? player;
  final bool isCaptured;
  final bool isPulled;
  final bool isLastPlaced;
  final bool isHint;
  final VoidCallback? onTap;

  const _Cell({
    this.player,
    this.isCaptured = false,
    this.isPulled = false,
    this.isLastPlaced = false,
    this.isHint = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isCaptured
        ? const Color(0xFFFF4444)
        : isPulled
            ? const Color(0xFF5588FF)
            : isLastPlaced
                ? const Color(0xAAFFFFFF)
                : const Color(0xFF2E2E50);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isCaptured
              ? const Color(0xFF3A1A1A)
              : isPulled
                  ? const Color(0xFF1A2040)
                  : const Color(0xFF242440),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: player != null
            ? TweenAnimationBuilder<double>(
                key: ValueKey(player!.name),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: _Stone(
                  player: player!,
                  isCaptured: isCaptured,
                  isPulled: isPulled,
                  isLastPlaced: isLastPlaced,
                ),
              )
            : isHint
                ? Center(
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  )
                : null,
      ),
    );
  }
}

class _Stone extends StatelessWidget {
  final Player player;
  final bool isCaptured;
  final bool isPulled;
  final bool isLastPlaced;

  const _Stone({
    required this.player,
    this.isCaptured = false,
    this.isPulled = false,
    this.isLastPlaced = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAmber = player == Player.amber;

    final List<Color> gradientColors;
    if (isCaptured) {
      gradientColors = [const Color(0xFFFF6666), const Color(0xFF990000)];
    } else if (isAmber) {
      gradientColors = [const Color(0xFFF7DF88), const Color(0xFFC09020)];
    } else {
      gradientColors = [const Color(0xFF9AAFC8), const Color(0xFF3A4F6A)];
    }

    Color glowColor = Colors.transparent;
    double glowBlur = 0;
    if (isCaptured) {
      glowColor = const Color(0xFFFF4444);
      glowBlur = 14;
    } else if (isPulled) {
      glowColor = const Color(0xFF5588FF);
      glowBlur = 12;
    } else if (isLastPlaced) {
      glowColor =
          isAmber ? const Color(0xFFE8C97A) : const Color(0xFF7A8BA8);
      glowBlur = 10;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.85,
          colors: gradientColors,
        ),
        boxShadow: glowColor != Colors.transparent
            ? [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.65),
                  blurRadius: glowBlur,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
