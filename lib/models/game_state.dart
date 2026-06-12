import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int gridSize = 11;
const int centerRow = 5;
const int centerCol = 5;

enum CellState { empty, fence, cat }

enum GamePhase { playerTurn, cpuTurn, gameOver }

enum GameResult { none, catEscaped, catTrapped }

class HexCoord {
  final int row;
  final int col;

  const HexCoord(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is HexCoord && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'HexCoord($row, $col)';
}

class GameState extends ChangeNotifier {
  late List<List<CellState>> board;
  late HexCoord catPos;
  GamePhase phase = GamePhase.playerTurn;
  GameResult result = GameResult.none;
  int scorePlayer = 0;
  int scoreCPU = 0;
  int roundNumber = 1;

  static const _keyPlayer = 'score_player';
  static const _keyCPU = 'score_cpu';
  static const _keyRound = 'round_number';

  GameState() {
    _loadScores();
    _initBoard();
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    scorePlayer = prefs.getInt(_keyPlayer) ?? 0;
    scoreCPU = prefs.getInt(_keyCPU) ?? 0;
    roundNumber = prefs.getInt(_keyRound) ?? 1;
    notifyListeners();
  }

  Future<void> _saveScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPlayer, scorePlayer);
    await prefs.setInt(_keyCPU, scoreCPU);
    await prefs.setInt(_keyRound, roundNumber);
  }



  void _initBoard() {
    board = List.generate(
      gridSize,
      (_) => List.filled(gridSize, CellState.empty),
    );

    catPos = const HexCoord(centerRow, centerCol);
    board[centerRow][centerCol] = CellState.cat;

    final fenceCount = 9 + (DateTime.now().millisecondsSinceEpoch % 7);
    final placed = <HexCoord>{};
    final rand = DateTime.now().millisecondsSinceEpoch;
    var seed = rand;

    while (placed.length < fenceCount) {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      final r = (seed >> 16) % gridSize;
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      final c = (seed >> 16) % gridSize;
      final coord = HexCoord(r, c);
      if (coord == catPos) continue;
      if (placed.contains(coord)) continue;
      placed.add(coord);
      board[r][c] = CellState.fence;
    }

    phase = GamePhase.playerTurn;
    result = GameResult.none;
    notifyListeners();
  }

  void newGame() {
    roundNumber++;
    _saveScores();
    _initBoard();
  }

  bool isOnBorder(HexCoord coord) {
    return coord.row == 0 ||
        coord.row == gridSize - 1 ||
        coord.col == 0 ||
        coord.col == gridSize - 1;
  }

  List<HexCoord> getNeighbors(HexCoord coord) {
    final r = coord.row;
    final c = coord.col;
    final bool oddRow = r % 2 == 1;

    final List<HexCoord> candidates = oddRow
        ? [
            HexCoord(r - 1, c),
            HexCoord(r - 1, c + 1),
            HexCoord(r, c - 1),
            HexCoord(r, c + 1),
            HexCoord(r + 1, c),
            HexCoord(r + 1, c + 1),
          ]
        : [
            HexCoord(r - 1, c - 1),
            HexCoord(r - 1, c),
            HexCoord(r, c - 1),
            HexCoord(r, c + 1),
            HexCoord(r + 1, c - 1),
            HexCoord(r + 1, c),
          ];

    return candidates
        .where((h) =>
            h.row >= 0 && h.row < gridSize && h.col >= 0 && h.col < gridSize)
        .toList();
  }

  bool isCatTrapped() {
    return findEscapePath(catPos) == null;
  }

  List<HexCoord>? findEscapePath(HexCoord from) {
    if (isOnBorder(from)) return [from];

    final queue = <List<HexCoord>>[];
    final visited = <HexCoord>{};
    queue.add([from]);
    visited.add(from);

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      for (final neighbor in getNeighbors(current)) {
        if (visited.contains(neighbor)) continue;
        if (board[neighbor.row][neighbor.col] == CellState.fence) continue;
        final newPath = [...path, neighbor];
        if (isOnBorder(neighbor)) return newPath;
        visited.add(neighbor);
        queue.add(newPath);
      }
    }
    return null;
  }

  bool tryMoveCat(HexCoord target) {
    if (phase != GamePhase.playerTurn) return false;
    if (board[target.row][target.col] != CellState.empty) return false;

    final neighbors = getNeighbors(catPos);
    if (!neighbors.contains(target)) return false;

    board[catPos.row][catPos.col] = CellState.empty;
    catPos = target;
    board[target.row][target.col] = CellState.cat;

    if (isOnBorder(target)) {
      result = GameResult.catEscaped;
      phase = GamePhase.gameOver;
      scorePlayer++;
      _saveScores();
      notifyListeners();
      return true;
    }

    if (isCatTrapped()) {
      result = GameResult.catTrapped;
      phase = GamePhase.gameOver;
      scoreCPU++;
      _saveScores();
      notifyListeners();
      return true;
    }

    phase = GamePhase.cpuTurn;
    notifyListeners();
    return true;
  }

  HexCoord? computeCpuMove() {
    final path = findEscapePath(catPos);

    if (path != null && path.length > 1) {
      for (int i = 1; i < path.length; i++) {
        final cell = path[i];
        if (board[cell.row][cell.col] == CellState.empty &&
            cell != catPos) {
          return cell;
        }
      }
    }

    final emptyCells = <HexCoord>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (board[r][c] == CellState.empty) {
          emptyCells.add(HexCoord(r, c));
        }
      }
    }

    if (emptyCells.isEmpty) return null;
    final idx = DateTime.now().millisecondsSinceEpoch % emptyCells.length;
    return emptyCells[idx];
  }

  void applyCpuMove(HexCoord cell) {
    board[cell.row][cell.col] = CellState.fence;

    if (isCatTrapped()) {
      result = GameResult.catTrapped;
      phase = GamePhase.gameOver;
      scoreCPU++;
      _saveScores();
    } else {
      phase = GamePhase.playerTurn;
    }
    notifyListeners();
  }
}
