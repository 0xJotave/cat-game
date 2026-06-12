import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../widgets/hex_grid_painter.dart';
import '../widgets/score_board.dart';
import '../widgets/status_bar.dart';
import 'splash_screen.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameState _gameState;
  HexCoord? _hoveredCell;
  List<HexCoord> _validMoves = [];
  bool _cpuThinking = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _gameState.addListener(_onStateChanged);
    _updateValidMoves();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gameState.removeListener(_onStateChanged);
    _gameState.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    _updateValidMoves();
    setState(() {});

    if (_gameState.phase == GamePhase.cpuTurn && !_cpuThinking) {
      _doCpuTurn();
    }

    if (_gameState.phase == GamePhase.gameOver) {
      _showResultDialog();
    }
  }

  void _updateValidMoves() {
    if (_gameState.phase == GamePhase.playerTurn) {
      _validMoves = _gameState
          .getNeighbors(_gameState.catPos)
          .where((h) =>
              _gameState.board[h.row][h.col] == CellState.empty)
          .toList();
    } else {
      _validMoves = [];
    }
  }

  Future<void> _doCpuTurn() async {
    _cpuThinking = true;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final move = _gameState.computeCpuMove();
    if (move != null) {
      _gameState.applyCpuMove(move);
    } else {
      _gameState.phase = GamePhase.playerTurn;
    }
    _cpuThinking = false;
  }

  void _handleTap(Offset localPos) {
    if (_gameState.phase != GamePhase.playerTurn) return;
    final coord = pixelToHex(localPos);
    if (coord == null) return;
    _gameState.tryMoveCat(coord);
  }

  void _handleHover(Offset localPos) {
    final coord = pixelToHex(localPos);
    setState(() => _hoveredCell = coord);
  }

  Future<void> _showResultDialog() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: ResultScreen(
            result: _gameState.result,
            scorePlayer: _gameState.scorePlayer,
            scoreCPU: _gameState.scoreCPU,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    if (!mounted) return;
    if (result == true) {
      _gameState.newGame();
      _updateValidMoves();
      setState(() {});
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, anim, _) => const SplashScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canvasSize = hexGridCanvasSize();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF050E1A), Color(0xFF071422)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              ScoreBoard(
                playerScore: _gameState.scorePlayer,
                cpuScore: _gameState.scoreCPU,
                round: _gameState.roundNumber,
              ),
              StatusBar(
                phase: _gameState.phase,
                result: _gameState.result,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox.fromSize(
                        size: canvasSize,
                        child: GestureDetector(
                          onTapDown: (d) {
                            _handleTap(d.localPosition);
                          },
                          onPanUpdate: (d) {
                            _handleHover(d.localPosition);
                          },
                          child: CustomPaint(
                            painter: HexGridPainter(
                              gameState: _gameState,
                              hoveredCell: _hoveredCell,
                              validMoves: _validMoves,
                              escapePath: _gameState.phase == GamePhase.playerTurn
                                  ? _gameState.findEscapePath(_gameState.catPos)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildLegend(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white54, size: 20),
            onPressed: () => Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, anim, _) => const SplashScreen(),
                transitionsBuilder: (_, anim, _, child) =>
                    FadeTransition(opacity: anim, child: child),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🐱 ', style: TextStyle(fontSize: 20)),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF4FC3F7)],
                  ).createShader(bounds),
                  child: const Text(
                    'Pegue o Gato',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white54, size: 22),
            tooltip: 'Novo jogo',
            onPressed: () {
              _gameState.newGame();
              _updateValidMoves();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(
            color: const Color(0xFF00E5FF),
            label: 'Gato',
            icon: '🐱',
          ),
          const SizedBox(width: 24),
          _LegendItem(
            color: const Color(0xFFFF8A65),
            label: 'Cerca',
            icon: '🟤',
          ),
          const SizedBox(width: 24),
          _LegendItem(
            color: const Color(0xFF4CAF50),
            label: 'Válido',
            dot: true,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String? icon;
  final bool dot;

  const _LegendItem({
    required this.color,
    required this.label,
    this.icon,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Text(icon!, style: const TextStyle(fontSize: 14))
        else
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
