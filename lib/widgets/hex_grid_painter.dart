import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_state.dart';

const double hexSize = 22.0;
final double hexW = math.sqrt(3) * hexSize;
const double hexH = hexSize * 2;

Offset hexToPixel(int row, int col) {
  final double x = (col + (row % 2 == 1 ? 0.5 : 0.0)) * hexW + hexW / 2;
  final double y = row * (hexH * 0.75) + hexH / 2;
  return Offset(x, y);
}

Size hexGridCanvasSize() {
  final maxX = (gridSize + 0.5) * hexW;
  final maxY = (gridSize - 1) * (hexH * 0.75) + hexH;
  return Size(maxX, maxY);
}

class HexGridPainter extends CustomPainter {
  final GameState gameState;
  final HexCoord? hoveredCell;
  final List<HexCoord> validMoves;
  final List<HexCoord>? escapePath;

  HexGridPainter({
    required this.gameState,
    this.hoveredCell,
    required this.validMoves,
    this.escapePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final center = hexToPixel(r, c);
        final coord = HexCoord(r, c);
        final state = gameState.board[r][c];
        _drawHex(canvas, center, coord, state);
      }
    }
  }

  void _drawHex(
      Canvas canvas, Offset center, HexCoord coord, CellState state) {
    final path = _hexPath(center);
    final isOnBorder = gameState.isOnBorder(coord);
    final isHovered = hoveredCell == coord;
    final isValidMove = validMoves.contains(coord);

    Color fillColor;
    if (state == CellState.cat) {
      fillColor = const Color(0xFF00E5FF);
    } else if (state == CellState.fence) {
      fillColor = const Color(0xFF8D6E63);
    } else if (isHovered && isValidMove) {
      fillColor = const Color(0xFF4CAF50).withValues(alpha: 0.7);
    } else if (isValidMove) {
      fillColor = const Color(0xFF1B5E20).withValues(alpha: 0.5);
    } else if (isOnBorder) {
      fillColor = const Color(0xFF1A3A5C).withValues(alpha: 0.9);
    } else {
      fillColor = const Color(0xFF0D2137);
    }

    final paint = Paint()..color = fillColor;
    canvas.drawPath(path, paint);

    final strokeColor = isOnBorder
        ? const Color(0xFF4FC3F7).withValues(alpha: 0.5)
        : const Color(0xFF1565C0).withValues(alpha: 0.4);
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isOnBorder ? 1.5 : 0.8;
    canvas.drawPath(path, strokePaint);

    if (isValidMove && state == CellState.empty) {
      final glowPaint = Paint()
        ..color = const Color(0xFF4CAF50).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowPaint);
    }

    if (state == CellState.cat) {
      _drawEmoji(canvas, center, '🐱', 20);
    }

    if (state == CellState.fence) {
      final fencePaint = Paint()
        ..color = const Color(0xFFFFCC80)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 6, fencePaint);
      final innerPaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 4, innerPaint);
    }
  }

  void _drawEmoji(Canvas canvas, Offset center, String emoji, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  Path _hexPath(Offset center) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = center.dx + hexSize * math.cos(angle);
      final y = center.dy + hexSize * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(HexGridPainter oldDelegate) {
    return true;
  }
}

HexCoord? pixelToHex(Offset pos) {
  HexCoord? closest;
  double minDist = double.infinity;

  for (int r = 0; r < gridSize; r++) {
    for (int c = 0; c < gridSize; c++) {
      final center = hexToPixel(r, c);
      final dist = (pos - center).distance;
      if (dist < hexSize * 1.5 && dist < minDist) {
        minDist = dist;
        closest = HexCoord(r, c);
      }
    }
  }
  return closest;
}
