import 'package:flutter/material.dart';
import '../engine/board.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final Set<(int, int)> highlightedCells; // last pulled stones
  final (int, int)? lastPlaced;
  final void Function(int row, int col)? onTap;
  final bool enabled;

  const BoardWidget({
    super.key,
    required this.board,
    this.highlightedCells = const {},
    this.lastPlaced,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: List.generate(boardSize, (r) {
            return Expanded(
              child: Row(
                children: List.generate(boardSize, (c) {
                  return Expanded(child: _Cell(
                    player: board.get(r, c),
                    isLastPlaced: lastPlaced == (r, c),
                    isPulled: highlightedCells.contains((r, c)),
                    onTap: enabled ? () => onTap?.call(r, c) : null,
                  ));
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Player? player;
  final bool isLastPlaced;
  final bool isPulled;
  final VoidCallback? onTap;

  const _Cell({
    required this.player,
    required this.isLastPlaced,
    required this.isPulled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: player == null ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _bgColor(),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLastPlaced
                ? const Color(0xFFFFFFCC)
                : isPulled
                    ? const Color(0xFF9999FF)
                    : const Color(0xFF3A3A5A),
            width: isLastPlaced || isPulled ? 2 : 1,
          ),
        ),
        child: player != null
            ? Center(child: _Stone(player: player!, isPulled: isPulled))
            : null,
      ),
    );
  }

  Color _bgColor() {
    if (player == null) return const Color(0xFF2A2A4A);
    return const Color(0xFF1E1E38);
  }
}

class _Stone extends StatelessWidget {
  final Player player;
  final bool isPulled;

  const _Stone({required this.player, required this.isPulled});

  @override
  Widget build(BuildContext context) {
    final isAmber = player == Player.amber;
    return AnimatedScale(
      scale: isPulled ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAmber ? const Color(0xFFE8C97A) : const Color(0xFF7A8BA8),
          boxShadow: [
            BoxShadow(
              color: isAmber
                  ? const Color(0xFFE8C97A).withValues(alpha: 0.4)
                  : const Color(0xFF7A8BA8).withValues(alpha: 0.4),
              blurRadius: isPulled ? 10 : 4,
              spreadRadius: isPulled ? 2 : 0,
            ),
          ],
        ),
      ),
    );
  }
}
