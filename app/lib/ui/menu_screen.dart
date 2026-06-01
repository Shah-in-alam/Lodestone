import 'package:flutter/material.dart';
import '../engine/mcts.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _difficulty = 'medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / title
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      colors: [Color(0xFFF7DF88), Color(0xFFC09020)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8C97A).withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'LODESTONE',
                  style: TextStyle(
                    color: Color(0xFFE8C97A),
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A minute to learn.\nA lifetime to master.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6666AA),
                    fontSize: 13,
                    height: 1.7,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 52),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DIFFICULTY',
                    style: TextStyle(
                      color: Color(0xFF555577),
                      fontSize: 11,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _DifficultyPicker(
                  selected: _difficulty,
                  onChanged: (v) => setState(() => _difficulty = v),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameScreen(difficulty: _difficulty),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8C97A),
                      foregroundColor: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const HowToPlayScreen()),
                    ),
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('How to Play'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8888AA),
                      side: const BorderSide(color: Color(0xFF3A3A5A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _DifficultyPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: difficultyBudgets.keys.map((d) {
        final isSelected = d == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE8C97A)
                    : const Color(0xFF1E1E38),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE8C97A)
                      : const Color(0xFF3A3A5A),
                  width: 1.5,
                ),
              ),
              child: Text(
                d[0].toUpperCase() + d.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFF6666AA),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
