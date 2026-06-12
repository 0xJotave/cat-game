import 'package:flutter/material.dart';

class ScoreBoard extends StatelessWidget {
  final int playerScore;
  final int cpuScore;
  final int round;

  const ScoreBoard({
    super.key,
    required this.playerScore,
    required this.cpuScore,
    required this.round,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1929), Color(0xFF0D2137)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _ScoreItem(
            emoji: '🐱',
            label: 'Gato (Você)',
            score: playerScore,
            color: const Color(0xFF00E5FF),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rodada $round',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _ScoreItem(
            emoji: '🟤',
            label: 'Cerca (CPU)',
            score: cpuScore,
            color: const Color(0xFFFF8A65),
            reversed: true,
          ),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String emoji;
  final String label;
  final int score;
  final Color color;
  final bool reversed;

  const _ScoreItem({
    required this.emoji,
    required this.label,
    required this.score,
    required this.color,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Text(
        emoji,
        style: const TextStyle(fontSize: 26),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment:
            reversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$score',
              key: ValueKey(score),
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reversed ? content.reversed.toList() : content,
    );
  }
}
