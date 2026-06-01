import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF8888AA),
        elevation: 0,
        title: const Text(
          'HOW TO PLAY',
          style: TextStyle(
            color: Color(0xFFE8C97A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 4,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: const [
          _RuleCard(
            icon: Icons.grid_on,
            title: 'The Board',
            color: Color(0xFF8888CC),
            body:
                'A 7×7 grid, starting empty. You are Amber ●, the AI is Slate ●. Amber always goes first.',
          ),
          _RuleCard(
            icon: Icons.touch_app,
            title: 'Your Turn',
            color: Color(0xFFE8C97A),
            body:
                'Tap any empty cell to place one of your stones. Two things happen automatically after you place.',
          ),
          _RuleCard(
            icon: Icons.adjust,
            title: '1 — The Pull',
            color: Color(0xFF5588FF),
            body:
                'Your new stone acts as a magnet. It pulls the nearest enemy stone in each of the 4 directions (up, down, left, right) one cell toward it — but only if that cell is empty.\n\nA single placement can pull up to 4 enemy stones at once.',
          ),
          _RuleCard(
            icon: Icons.highlight_off,
            title: '2 — Captures',
            color: Color(0xFFFF6666),
            body:
                'After pulls resolve, any stone completely surrounded by enemies on all its on-board sides is captured and removed.\n\n• Corner stone: 2 enemy neighbors needed\n• Edge stone: 3 enemy neighbors needed\n• Center stone: 4 enemy neighbors needed\n\nEnemy captures are checked first, then your own.',
          ),
          _RuleCard(
            icon: Icons.emoji_events,
            title: 'Winning',
            color: Color(0xFFE8C97A),
            body:
                'First player to capture 4 enemy stones wins.\n\nIf the board fills completely before that, the player with more stones on the board wins. Equal stones = draw.',
          ),
          _RuleCard(
            icon: Icons.lightbulb_outline,
            title: 'Strategy Tips',
            color: Color(0xFF66CC88),
            body:
                '• Corners and edges are safer — they need fewer surrounding stones to capture.\n\n• Use pulls to drag enemy stones out of safe positions into traps.\n\n• Watch out — you can accidentally capture your own stones too!',
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String body;

  const _RuleCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF9999BB),
                    fontSize: 13,
                    height: 1.6,
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
