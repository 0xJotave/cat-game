import 'package:flutter/material.dart';
import '../models/game_state.dart';

class StatusBar extends StatelessWidget {
  final GamePhase phase;
  final GameResult result;

  const StatusBar({
    super.key,
    required this.phase,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final (String text, Color color, String icon) = switch (phase) {
      GamePhase.playerTurn => (
          'Sua vez — Mova o gato!',
          const Color(0xFF00E5FF),
          '🐱',
        ),
      GamePhase.cpuTurn => (
          'CPU está pensando...',
          const Color(0xFFFF8A65),
          '🤔',
        ),
      GamePhase.gameOver => result == GameResult.catEscaped
          ? ('🎉 Você escapou!', const Color(0xFF69F0AE), '🏆')
          : ('😿 O gato foi preso!', const Color(0xFFFF5252), '💀'),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
