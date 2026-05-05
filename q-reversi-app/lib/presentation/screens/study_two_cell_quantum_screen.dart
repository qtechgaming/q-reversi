import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/quantum/qcomplex.dart';
import '../../core/quantum/study_quantum_gauge.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/piece_type.dart';
import '../../domain/entities/position.dart';
import '../widgets/board_widget.dart';
import '../widgets/gate_button.dart';
import '../widgets/study/study_quantum_graph_widgets.dart';
import '../widgets/study/study_text_tutorial_overlay.dart';
import '../../domain/services/study_text_progress_service.dart';

/// スタディ「2マスで学ぶ量子コンピュータ」専用の駒表示。
///
/// 状態ベクトルは [|00⟩,|01⟩,|10⟩,|11⟩] の複素振幅（未正規化でも可）。
///
/// - **Bell 4状態**への忠実度が十分高いとき
///   - \|Φ±⟩ 系（\|00⟩,\|11⟩ 成分が支配的）→ 両マス [PieceType.blackWhite]
///   - \|Ψ±⟩ 系（\|01⟩,\|10⟩ 成分が支配的）→ 両マス [PieceType.whiteBlack]
/// - **積状態**（シュラー行列式 \|ad−bc\| が小さい）→ 各ビットの周辺から
///   P(\|1⟩) と ⟨X⟩ で [white]/[black]/[grayPlus]/[grayMinus]/[grayNeutral]
/// - それ以外のエンタングル → 両マス [PieceType.grayNeutral]（記号なしグレー）
class StudyTwoCellPieceDisplay {
  StudyTwoCellPieceDisplay._();

  static const double _bellFidelityThreshold = 0.82;
  static const double _slaterProductTol = 0.035;
  static const double _p1Edge = 0.05;
  static const double _xThresh = 0.07;

  static StudyTwoCellPieces fromAmplitudes(List<QComplex> amplitudes) {
    final v = _normalize4(amplitudes);
    final a = v[0];
    final b = v[1];
    final c = v[2];
    final d = v[3];

    // F_i = |⟨Bell_i|ψ⟩|²（正規化 |ψ⟩=1）
    final fPhiPlus = 0.5 * (a + d).normSquared();
    final fPhiMinus = 0.5 * (a - d).normSquared();
    final fPsiPlus = 0.5 * (b + c).normSquared();
    final fPsiMinus = 0.5 * (b - c).normSquared();

    final bellPhi = math.max(fPhiPlus, fPhiMinus);
    final bellPsi = math.max(fPsiPlus, fPsiMinus);
    final bestBell = math.max(bellPhi, bellPsi);

    if (bestBell >= _bellFidelityThreshold) {
      final usePhi = bellPhi >= bellPsi;
      final t = usePhi ? PieceType.blackWhite : PieceType.whiteBlack;
      return StudyTwoCellPieces(left: t, right: t);
    }

    final slater = (a * d - b * c).abs();
    if (slater <= _slaterProductTol) {
      final p1Left = c.normSquared() + d.normSquared();
      final zLeft = a.conj() * c + b.conj() * d;
      final xLeft = 2 * zLeft.re;
      final p1Right = b.normSquared() + d.normSquared();
      final zRight = a.conj() * b + c.conj() * d;
      final xRight = 2 * zRight.re;
      return StudyTwoCellPieces(
        left: _singleQubitVisual(p1: p1Left, xExp: xLeft),
        right: _singleQubitVisual(p1: p1Right, xExp: xRight),
      );
    }

    return const StudyTwoCellPieces(
      left: PieceType.grayNeutral,
      right: PieceType.grayNeutral,
    );
  }

  static PieceType _singleQubitVisual({
    required double p1,
    required double xExp,
  }) {
    if (p1 < _p1Edge) return PieceType.white;
    if (p1 > 1.0 - _p1Edge) return PieceType.black;
    if (xExp > _xThresh) return PieceType.grayPlus;
    if (xExp < -_xThresh) return PieceType.grayMinus;
    return PieceType.grayNeutral;
  }

  static List<QComplex> _normalize4(List<QComplex> a) {
    final n = math.sqrt(
      a.fold<double>(0, (s, v) => s + v.normSquared()),
    );
    if (n == 0) {
      return [QComplex.one, QComplex.zero, QComplex.zero, QComplex.zero];
    }
    return a.map((v) => v.scaled(1 / n)).toList();
  }
}

class StudyTwoCellPieces {
  const StudyTwoCellPieces({
    required this.left,
    required this.right,
  });

  final PieceType left;
  final PieceType right;
}

/// スタディ2: 2マスで学ぶ量子コンピュータ
class StudyTwoCellQuantumScreen extends StatefulWidget {
  const StudyTwoCellQuantumScreen({super.key});

  @override
  State<StudyTwoCellQuantumScreen> createState() =>
      _StudyTwoCellQuantumScreenState();
}

class _StudyTwoCellQuantumScreenState extends State<StudyTwoCellQuantumScreen> {
  static const List<String> _basisLabels = ['|00⟩', '|01⟩', '|10⟩', '|11⟩'];

  // 複素振幅の2量子ビット状態ベクトル（順序: |00⟩, |01⟩, |10⟩, |11⟩）
  List<QComplex> _amplitudes = [
    QComplex.one,
    QComplex.zero,
    QComplex.zero,
    QComplex.zero,
  ];
  GateType? _selectedGate;

  List<Position> _selectedPositions = [];
  int? _selectedRow;
  String? _selectedRowDirection;
  String? _entangledErrorMessage;
  final GlobalKey _boardAreaKey = GlobalKey();
  final GlobalKey _upperGraphsAreaKey = GlobalKey();
  final GlobalKey _lowerPlayAreaKey = GlobalKey();
  int? _tutorialStepIndex;

  final List<StudyTextTutorialStep> _tutorialSteps = const [
    StudyTextTutorialStep(
      title: '2マスで学ぶ量子コンピュータ',
      message:
          'このページでは、2量子ビットの状態を確率振幅と存在確率で体験します。',
    ),
    StudyTextTutorialStep(
      title: '2量子ビットの表現',
      message:
          '1量子ビットのときは、|0⟩状態か|1⟩状態かの2択でした。2ビットになると、1番目が|0⟩と|1⟩、2番目が|0⟩と|1⟩でそれぞれ2通りずつあるため、掛け合わせて全部で4パターンの状態ができます。\n「|00⟩」のように | ⟩ の中に2つ数字が入る表記では、左が1ビット目、右が2ビット目を表します。',
    ),
    StudyTextTutorialStep(
      title: '試してみよう',
      message:
          'この2マスの盤面を用いて、ゲートを適用して重ね合わせの状態を作ってみたり、エンタングルをしてみたりして2ビットの状態の変化を体験してみてください',
      nextLabel: '完了',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _showTutorialOnFirstVisit();
  }

  List<double> get _probabilities => _amplitudes
      .map((a) => a.normSquared().clamp(0, 1).toDouble())
      .toList();

  Future<void> _showTutorialOnFirstVisit() async {
    final seen = await StudyTextProgressService.hasSeen('study2');
    if (!mounted || seen) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _tutorialStepIndex = 0;
    });
  }

  void _startTutorial() {
    setState(() {
      _tutorialStepIndex = 0;
    });
  }

  void _advanceTutorial() {
    final index = _tutorialStepIndex;
    if (index == null) return;
    if (index >= _tutorialSteps.length - 1) {
      _closeTutorial(markSeen: true);
      return;
    }
    setState(() {
      _tutorialStepIndex = index + 1;
    });
  }

  void _closeTutorial({bool markSeen = false}) {
    setState(() {
      _tutorialStepIndex = null;
    });
    if (markSeen) {
      StudyTextProgressService.markSeen('study2');
    }
  }

  Board get _displayBoard {
    final base = Board.create1x2();
    final types = StudyTwoCellPieceDisplay.fromAmplitudes(_amplitudes);
    final left = Piece(
      id: 'study2_q0',
      type: types.left,
      position: const Position(0, 0),
    );
    final right = Piece(
      id: 'study2_q1',
      type: types.right,
      position: const Position(0, 1),
    );
    return base.setPiece(0, 0, left).setPiece(0, 1, right);
  }

  void _handleGateSelection(GateType gate) {
    setState(() {
      _selectedGate = gate;
      _entangledErrorMessage = null;
      if (gate.isTwoBitGate) {
        _selectedPositions = [];
        _selectedRow = null;
        _selectedRowDirection = null;
      }
      // 1ビットゲート同士の切り替えでは盤面選択（1マス／行）を維持する
    });
  }

  void _handlePositionTap(Position position) {
    setState(() {
      if (_selectedGate != null && _selectedGate!.isTwoBitGate) {
        _entangledErrorMessage = null;
        if (_selectedPositions.isEmpty) {
          _selectedPositions = [position];
        } else if (_selectedPositions.length == 1) {
          final first = _selectedPositions.first;
          if (position.isAdjacent(first)) {
            _selectedPositions.add(position);
          } else {
            _selectedPositions = [position];
            _entangledErrorMessage = '隣接した駒のみ選択できます';
          }
        } else if (_selectedPositions.length == 2) {
          _selectedPositions = [position];
        }
        _selectedRow = null;
        _selectedRowDirection = null;
      } else {
        _selectedRow = null;
        _selectedRowDirection = null;
        if (_selectedPositions.length == 1 &&
            _selectedPositions.first == position) {
          _selectedPositions = [];
        } else {
          _selectedPositions = [position];
        }
        _entangledErrorMessage = null;
      }
    });
  }

  void _handleRowSelection(int row, String direction) {
    setState(() {
      if (_selectedGate != null && _selectedGate!.isTwoBitGate) return;

      final isSameRow = _selectedRow == row;
      final isSameDirection = _selectedRowDirection == direction;
      final shouldDeselect = isSameRow && isSameDirection;

      _selectedRow = shouldDeselect ? null : row;
      _selectedRowDirection = shouldDeselect ? null : direction;

      if (_selectedRow != null) {
        _selectedPositions = _getRowPositionsAll(_displayBoard, row, direction);
      } else {
        _selectedPositions = [];
      }
      _entangledErrorMessage = null;
    });
  }

  List<Position> _getRowPositionsAll(
    Board board,
    int row,
    String direction,
  ) {
    final positions = <Position>[];
    if (direction == 'left') {
      for (int col = 0; col < board.cols; col++) {
        positions.add(Position(row, col));
      }
    } else {
      for (int col = board.cols - 1; col >= 0; col--) {
        positions.add(Position(row, col));
      }
    }
    return positions;
  }

  List<Position> _getAdjacentPositions(Board board) {
    if (_selectedGate == null || !_selectedGate!.isTwoBitGate) {
      return [];
    }
    if (_selectedPositions.isEmpty) return [];

    final firstPosition = _selectedPositions.first;
    final adjacentPositions = <Position>[];

    for (int rowOffset = -1; rowOffset <= 1; rowOffset++) {
      for (int colOffset = -1; colOffset <= 1; colOffset++) {
        if (rowOffset == 0 && colOffset == 0) continue;

        final newRow = firstPosition.row + rowOffset;
        final newCol = firstPosition.col + colOffset;

        if (board.isValidPosition(newRow, newCol)) {
          final adjacentPos = Position(newRow, newCol);
          if (!_selectedPositions.contains(adjacentPos)) {
            adjacentPositions.add(adjacentPos);
          }
        }
      }
    }

    return adjacentPositions;
  }

  List<Position>? _resolveTargetPositions(Board board) {
    if (_selectedRow != null) {
      final cols = board.cols;
      final isFromRight = _selectedRowDirection == 'right';
      return List.generate(
        cols,
        (i) {
          final col = isFromRight ? (cols - 1 - i) : i;
          return Position(_selectedRow!, col);
        },
      );
    }
    if (_selectedPositions.isEmpty) return null;
    return List<Position>.from(_selectedPositions);
  }

  bool _canApplyGate() {
    final gate = _selectedGate;
    if (gate == null) return false;
    if (gate.isTwoBitGate) {
      return _selectedPositions.length == 2;
    }
    if (_selectedRow != null) {
      return true;
    }
    return _selectedPositions.isNotEmpty;
  }

  void _applyGate() {
    final gate = _selectedGate;
    if (gate == null || !_canApplyGate()) return;

    final board = _displayBoard;
    final targets = _resolveTargetPositions(board);
    if (targets == null || targets.isEmpty) return;

    final next = List<QComplex>.from(_amplitudes);

    if (gate.isOneBitGate) {
      final matrix = _matrixForOneBitGate(gate);
      if (matrix == null) return;
      final cols = targets.map((p) => p.col).toSet().toList()..sort();
      for (final c in cols) {
        _applySingleQubit(next, c, matrix);
      }
    } else {
      if (targets.length != 2) return;
      if (gate == GateType.swap) {
        _applySwap(next);
      } else if (gate == GateType.cnot) {
        final control = targets[0].col;
        _applyCnot(next, control: control);
      }
    }

    setState(() {
      _amplitudes = _normalize(next);
      _selectedGate = null;
      _selectedPositions = [];
      _selectedRow = null;
      _selectedRowDirection = null;
      _entangledErrorMessage = null;
    });
  }

  List<QComplex> _normalize(List<QComplex> values) {
    final norm = math.sqrt(
      values.fold<double>(0, (sum, v) => sum + v.normSquared()),
    );
    if (norm == 0) {
      return [
        QComplex.one,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
      ];
    }
    final inv = 1 / norm;
    return values.map((v) => v.scaled(inv)).toList();
  }

  static const List<List<QComplex>> _xMatrix = [
    [QComplex.zero, QComplex.one],
    [QComplex.one, QComplex.zero],
  ];

  static const List<List<QComplex>> _zMatrix = [
    [QComplex.one, QComplex.zero],
    [QComplex.zero, QComplex(-1, 0)],
  ];

  /// Pauli-Y（虚数成分あり）
  static const List<List<QComplex>> _yMatrix = [
    [QComplex.zero, QComplex(0, -1)],
    [QComplex(0, 1), QComplex.zero],
  ];

  static const double _invSqrt2 = 0.7071067811865475;
  static final List<List<QComplex>> _hMatrix = [
    [QComplex.real(_invSqrt2), QComplex.real(_invSqrt2)],
    [QComplex.real(_invSqrt2), QComplex.real(-_invSqrt2)],
  ];

  List<List<QComplex>>? _matrixForOneBitGate(GateType gate) {
    switch (gate) {
      case GateType.x:
        return _xMatrix;
      case GateType.h:
        return _hMatrix;
      case GateType.y:
        return _yMatrix;
      case GateType.z:
        return _zMatrix;
      default:
        return null;
    }
  }

  void _applySingleQubit(
    List<QComplex> state,
    int targetQubit,
    List<List<QComplex>> matrix,
  ) {
    final mask = targetQubit == 0 ? 2 : 1;
    for (int i = 0; i < 4; i++) {
      if ((i & mask) != 0) continue;
      final j = i | mask;
      final a0 = state[i];
      final a1 = state[j];
      state[i] = matrix[0][0] * a0 + matrix[0][1] * a1;
      state[j] = matrix[1][0] * a0 + matrix[1][1] * a1;
    }
  }

  void _applyCnot(List<QComplex> state, {required int control}) {
    final controlMask = control == 0 ? 2 : 1;
    final targetMask = control == 0 ? 1 : 2;

    for (int i = 0; i < 4; i++) {
      if ((i & controlMask) == 0) continue;
      if ((i & targetMask) != 0) continue;
      final j = i | targetMask;
      final temp = state[i];
      state[i] = state[j];
      state[j] = temp;
    }
  }

  void _applySwap(List<QComplex> state) {
    final temp = state[1];
    state[1] = state[2];
    state[2] = temp;
  }

  void _resetStudyState() {
    setState(() {
      _amplitudes = [
        QComplex.one,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
      ];
      _selectedGate = null;
      _selectedPositions = [];
      _selectedRow = null;
      _selectedRowDirection = null;
      _entangledErrorMessage = null;
    });
  }

  String _gateHintText() {
    final gate = _selectedGate;
    if (gate == null) {
      return 'ゲートを選択し、盤面で適用先を選びます';
    }
    if (gate.isTwoBitGate) {
      return '隣接する2マスを順にタップ（1つ目が制御、2つ目がターゲット）';
    }
    return 'マスをタップ（1マス）または左右の行ボタン（1行まとめて）で対象を選びます';
  }

  @override
  Widget build(BuildContext context) {
    final probs = _probabilities;
    final gaugeAmp = globalPhaseGaugeFirstPositive(_amplitudes);
    final amps = gaugeAmp.map((z) => z.re).toList();
    final board = _displayBoard;

    final step = _tutorialStepIndex == null ? null : _tutorialSteps[_tutorialStepIndex!];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '2マスで学ぶ',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0E27),
                  Color(0xFF1A1F3A),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      key: _upperGraphsAreaKey,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                      child: Column(
                        children: [
                          Expanded(
                            child: StudyQuantumGraphCard(
                              title: '確率振幅（-1 ～ 1）',
                              child: StudyQuantumStateBarChart(
                                values: amps,
                                labels: _basisLabels,
                                minY: -1,
                                maxY: 1,
                                barColor: const Color(0xFF57D6FF),
                                zeroLineColor: const Color(0xFF9AA3C1),
                                valueFormatter: (v) => v.toStringAsFixed(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: StudyQuantumGraphCard(
                              title: '存在確率（0 ～ 1）',
                              child: StudyQuantumStateBarChart(
                                values: probs,
                                labels: _basisLabels,
                                minY: 0,
                                maxY: 1,
                                barColor: const Color(0xFF9C6BFF),
                                zeroLineColor: const Color(0xFF9AA3C1),
                                valueFormatter: (v) => v.toStringAsFixed(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      key: _lowerPlayAreaKey,
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E132B).withValues(alpha: 0.6),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              children: [
                          Row(
                            children: [
                              const Spacer(),
                              OutlinedButton(
                                onPressed: _startTutorial,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text('テキスト'),
                              ),
                            ],
                          ),
                          Text(
                            _gateHintText(),
                            style: const TextStyle(
                              color: Color(0xFFDDE4FF),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_entangledErrorMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _entangledErrorMessage!,
                              style: TextStyle(
                                color: Colors.orange.shade200,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            key: _boardAreaKey,
                            child: Center(
                              child: BoardWidget(
                                board: board,
                                selectedPositions: _selectedPositions,
                                highlightedPositions:
                                    _getAdjacentPositions(board),
                                lastTwoBitGatePositions: const [],
                                enableRowColumnButtons: true,
                                showColumnButtons: false,
                                selectedGate: _selectedGate,
                                selectedRows: _selectedRow != null
                                    ? {_selectedRow!: true}
                                    : null,
                                cellSize: 54,
                                onPositionTap: _handlePositionTap,
                                onRowSelected: _handleRowSelection,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GateType.x,
                              GateType.h,
                              GateType.y,
                              GateType.z
                            ].map((gate) {
                              return SizedBox(
                                width: 74,
                                child: GateButton(
                                  gate: gate,
                                  isEnabled: true,
                                  isSelected: _selectedGate == gate,
                                  centerTwoBitLabel: true,
                                  onTap: () => _handleGateSelection(gate),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [GateType.cnot, GateType.swap].map((gate) {
                              return SizedBox(
                                width: 86,
                                child: GateButton(
                                  gate: gate,
                                  isEnabled: true,
                                  isSelected: _selectedGate == gate,
                                  centerTwoBitLabel: true,
                                  onTap: () => _handleGateSelection(gate),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: _canApplyGate() ? _applyGate : null,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  backgroundColor: !_canApplyGate()
                                      ? Colors.grey.shade700
                                      : const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                  'ゲートを適用',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _resetStudyState,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  backgroundColor: const Color(0xFF607D8B),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text(
                                  'リセット',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (step != null)
            StudyTextTutorialOverlay(
              step: _tutorialStepIndex == 1
                  ? StudyTextTutorialStep(
                      title: step.title,
                      message: step.message,
                      targetKey: _upperGraphsAreaKey,
                      nextLabel: step.nextLabel,
                      showNextButton: step.showNextButton,
                    )
                  : _tutorialStepIndex == 2
                      ? StudyTextTutorialStep(
                          title: step.title,
                          message: step.message,
                          targetKey: _lowerPlayAreaKey,
                          nextLabel: step.nextLabel,
                          showNextButton: step.showNextButton,
                        )
                  : step,
              onNext: _advanceTutorial,
              onClose: () => _closeTutorial(markSeen: true),
            ),
        ],
      ),
    );
  }
}
