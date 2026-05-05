import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../../core/quantum/qcomplex.dart';
import '../../core/quantum/study_quantum_gauge.dart';
import '../../domain/entities/gate_type.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/piece_type.dart';
import '../../domain/entities/position.dart';
import '../widgets/board_widget.dart';
import '../widgets/study/study_quantum_graph_widgets.dart';
import '../widgets/study/study_text_tutorial_overlay.dart';
import '../../domain/services/study_text_progress_service.dart';

enum _Study3Gate { h, x, ccz }

class _CircuitStep {
  const _CircuitStep.oneBit(this.gate)
      : isOneBit = true,
        label = gate == _Study3Gate.h ? 'H' : 'X';

  const _CircuitStep.ccz()
      : gate = _Study3Gate.ccz,
        isOneBit = false,
        label = 'CCZ';

  final _Study3Gate gate;
  final bool isOneBit;
  final String label;
}

class StudyThreeCellGroverScreen extends StatefulWidget {
  const StudyThreeCellGroverScreen({super.key});

  @override
  State<StudyThreeCellGroverScreen> createState() =>
      _StudyThreeCellGroverScreenState();
}

class _StudyThreeCellGroverScreenState extends State<StudyThreeCellGroverScreen> {
  static const List<String> _basisLabels = [
    '|000⟩',
    '|001⟩',
    '|010⟩',
    '|011⟩',
    '|100⟩',
    '|101⟩',
    '|110⟩',
    '|111⟩',
  ];

  static const List<_CircuitStep> _groverSteps = [
    _CircuitStep.oneBit(_Study3Gate.h),
    _CircuitStep.ccz(),
    _CircuitStep.oneBit(_Study3Gate.h),
    _CircuitStep.oneBit(_Study3Gate.x),
    _CircuitStep.ccz(),
    _CircuitStep.oneBit(_Study3Gate.x),
    _CircuitStep.oneBit(_Study3Gate.h),
    _CircuitStep.ccz(),
    _CircuitStep.oneBit(_Study3Gate.h),
    _CircuitStep.oneBit(_Study3Gate.x),
    _CircuitStep.ccz(),
    _CircuitStep.oneBit(_Study3Gate.x),
    _CircuitStep.oneBit(_Study3Gate.h),
  ];

  static const double _invSqrt2 = 0.7071067811865475;
  static final List<List<QComplex>> _hMatrix = [
    [QComplex.real(_invSqrt2), QComplex.real(_invSqrt2)],
    [QComplex.real(_invSqrt2), QComplex.real(-_invSqrt2)],
  ];
  static const List<List<QComplex>> _xMatrix = [
    [QComplex.zero, QComplex.one],
    [QComplex.one, QComplex.zero],
  ];

  static const double _p1Edge = 0.05;
  static const double _xThresh = 0.07;
  static const double _superpositionCenterTol = 0.1;
  static const double _pureStateTol = 0.9;

  List<QComplex> _amplitudes = [
    QComplex.one,
    QComplex.zero,
    QComplex.zero,
    QComplex.zero,
    QComplex.zero,
    QComplex.zero,
    QComplex.zero,
    QComplex.zero,
  ];
  _Study3Gate? _selectedGate;
  List<Position> _selectedPositions = [];

  int _stepIndex = 0;
  final Set<int> _currentStepAppliedQubits = <int>{};
  bool _sequenceFailed = false;
  bool _measured = false;
  String? _message;
  final ScrollController _circuitScrollController = ScrollController();
  bool _autoCircuitScrollEnabled = true;
  final GlobalKey _boardAreaKey = GlobalKey();
  final GlobalKey _upperGraphsAreaKey = GlobalKey();
  final GlobalKey _amplitude111AreaKey = GlobalKey();
  final GlobalKey _probability111AreaKey = GlobalKey();
  final GlobalKey _cczGateButtonKey = GlobalKey();
  final GlobalKey _measurementResultKey = GlobalKey();
  int? _tutorialStepIndex;
  bool _advancedFlowEnabled = false;
  bool _waitingStep8ByCcz = false;
  bool _waitingStep9AfterStep8 = false;
  bool _waitingStep10AfterStep9 = false;
  bool _waitingStep11AfterStep10 = false;
  bool _shownStep7 = false;
  bool _shownStep8 = false;
  bool _shownStep9 = false;
  bool _shownStep10 = false;
  bool _shownStep11 = false;

  final List<StudyTextTutorialStep> _tutorialSteps = const [
    StudyTextTutorialStep(
      title: '3マスで学ぶグローバーのアルゴリズム',
      message:
          'このページでは、量子コンピュータ特有のアルゴリズムの一つである"グローバーのアルゴリズム"を、3マス盤面と3つのゲートを用いて体験します。',
    ),
    StudyTextTutorialStep(
      title: 'グローバーのアルゴリズムとは',
      message:
          'グローバーのアルゴリズムとは、たくさんの要素を持つデータベースの中から、指定された値を検索する「探索問題」を高速に解くための量子コンピュータのアルゴリズムで、大量のデータの中から、ある一つの値を検索したいときに効果を発揮します。',
    ),
    StudyTextTutorialStep(
      title: '状態の数',
      message:
          '今回は3マス＝3量子ビットにこのアルゴリズムを適用してみます。3量子ビットになると、2の3乗で8個の組み合わせの量子状態ができます。',
    ),
    StudyTextTutorialStep(
      title: '探し出す答え',
      message:
          '今回は、8個のパラメータの中から、|111⟩状態を探し出す、という問題を解くこととします。',
    ),
    StudyTextTutorialStep(
      title: '新たなゲート(CCZ)',
      message:
          '|111⟩を探し出すにあたり、一つ新たなゲートが必要になります。今回CCZ(Control-Control-Z）を使います。これは、CNOT(Control-X)と同じ考え方で、1ビット目、2ビット目が黒|1⟩の時にのみ、3ビット目にZを適用する操作になります。',
    ),
    StudyTextTutorialStep(
      title: '量子回路',
      message:
          'さて、では早速このアルゴリズムを演算していきましょう。こちらの量子回路に従って、盤面にゲートを適用させてください。',
      nextLabel: '次へ',
    ),
    StudyTextTutorialStep(
      title: '重ね合わせの状態',
      message:
          '全体にHを適用することで、盤面の量子状態を重ね合わせの状態にします。',
    ),
    StudyTextTutorialStep(
      title: '印をつける',
      message:
          'CCZによって、量子回路から探したい数字に印(確率振幅の符号反転)をつけます。',
    ),
    StudyTextTutorialStep(
      title: 'アルゴリズム1回分適用完了',
      message:
          'グローバーのアルゴリズムを1回適用しました。この時点で、|111⟩の存在確率が78%まで上がっています。もう1周アルゴリズムを適用すると、取り出したい状態の存在確率が最大化します。続けて、アルゴリズムを適用しましょう。',
    ),
    StudyTextTutorialStep(
      title: 'アルゴリズム2周完了',
      message:
          'グローバーのアルゴリズムを2回分適用することで、存在確率を95%まで上げることができました。最後に測定をして、探したい状態を取り出しましょう。',
    ),
    StudyTextTutorialStep(
      title: '測定完了',
      message:
          '8個の候補から、目標の|111⟩を取り出せました。\n量子コンピュータは測定するまで内部状態を見ることはできません。このように、アルゴリズムで目標状態の確率を高め、最後に測定することで目的の状態を得ることができるのです。',
    ),
    StudyTextTutorialStep(
      title: 'グローバーのアルゴリズム',
      message:
          '今回は、3ビットかつ目標状態を指定して、グローバーのアルゴリズムを体験しました。ビット数を増やし、目標状態に印をつける回路を設計すれば、より多くの候補の中から目的の状態を効率よく見つけられます。\n「なぜ速く探せるのか」が気になった方は、ぜひ調べて学んでみてください。',
      nextLabel: '完了',
    ),
  ];
  @override
  void initState() {
    super.initState();
    _circuitScrollController.addListener(_handleCircuitScroll);
    _showTutorialOnFirstVisit();
  }

  @override
  void dispose() {
    _circuitScrollController.removeListener(_handleCircuitScroll);
    _circuitScrollController.dispose();
    super.dispose();
  }

  List<double> get _probabilities => _amplitudes
      .map((a) => a.normSquared().clamp(0, 1).toDouble())
      .toList();

  Future<void> _showTutorialOnFirstVisit() async {
    final seen = await StudyTextProgressService.hasSeen('study3');
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
    if (index == 5) {
      _advancedFlowEnabled = true;
      _closeTutorial(markSeen: true);
      _maybeShowAdvancedTutorialByProgress();
      return;
    }
    if (index == 6) {
      _waitingStep8ByCcz = true;
      _closeTutorial(markSeen: true);
      return;
    }
    if (index == 7) {
      _waitingStep9AfterStep8 = true;
      _closeTutorial(markSeen: true);
      return;
    }
    if (index == 8) {
      _waitingStep10AfterStep9 = true;
      _closeTutorial(markSeen: true);
      return;
    }
    if (index == 9) {
      _waitingStep11AfterStep10 = true;
      _closeTutorial(markSeen: true);
      return;
    }
    if (index == 10) {
      setState(() {
        _tutorialStepIndex = 11;
      });
      return;
    }
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
      StudyTextProgressService.markSeen('study3');
    }
  }

  void _maybeShowAdvancedTutorialByProgress() {
    if (_tutorialStepIndex != null) return;
    if (!_advancedFlowEnabled) {
      // 最初のHを3マス適用して step が進んだ時点で後半フローを自動有効化
      if (_stepIndex >= 1 || _sequenceCompleted || _measured) {
        _advancedFlowEnabled = true;
      } else {
        return;
      }
    }

    if (!_shownStep7 && _stepIndex >= 1) {
      _shownStep7 = true;
      setState(() => _tutorialStepIndex = 6);
      return;
    }
    if (!_shownStep8 && _stepIndex >= 2) {
      if (_waitingStep8ByCcz) {
        _waitingStep8ByCcz = false;
      } else {
        return;
      }
      _shownStep8 = true;
      setState(() => _tutorialStepIndex = 7);
      return;
    }
    if (!_shownStep9 && _stepIndex >= 7) {
      if (_waitingStep9AfterStep8) {
        _waitingStep9AfterStep8 = false;
      } else {
        return;
      }
      _shownStep9 = true;
      setState(() => _tutorialStepIndex = 8);
      return;
    }
    if (!_shownStep10 && _sequenceCompleted) {
      if (_waitingStep10AfterStep9) {
        _waitingStep10AfterStep9 = false;
      } else {
        return;
      }
      _shownStep10 = true;
      setState(() => _tutorialStepIndex = 9);
      return;
    }
  }

  Board get _displayBoard {
    final base = Board.create1x3();
    final p0 = Piece(
      id: 'study3_q0',
      type: _pieceForQubit(0),
      position: const Position(0, 0),
    );
    final p1 = Piece(
      id: 'study3_q1',
      type: _pieceForQubit(1),
      position: const Position(0, 1),
    );
    final p2 = Piece(
      id: 'study3_q2',
      type: _pieceForQubit(2),
      position: const Position(0, 2),
    );
    return base.setPiece(0, 0, p0).setPiece(0, 1, p1).setPiece(0, 2, p2);
  }

  bool get _sequenceCompleted => !_sequenceFailed && _stepIndex >= _groverSteps.length;

  bool get _canApplyGate {
    if (_selectedGate == null || _sequenceFailed || _measured || _sequenceCompleted) {
      return false;
    }
    return _selectedPositions.length == 3;
  }

  String _gateLabel(_Study3Gate gate) {
    switch (gate) {
      case _Study3Gate.h:
        return 'H';
      case _Study3Gate.x:
        return 'X';
      case _Study3Gate.ccz:
        return 'CCZ';
    }
  }

  /// 盤面（行ボタンの2ビット時スタイル等）用。CCZ は [GateType.cnot] 相当として [isTwoBitGate] を満たす。
  GateType? _gateTypeForBoard() {
    switch (_selectedGate) {
      case _Study3Gate.h:
        return GateType.h;
      case _Study3Gate.x:
        return GateType.x;
      case _Study3Gate.ccz:
        return GateType.cnot;
      case null:
        return null;
    }
  }

  void _selectGate(_Study3Gate gate) {
    if (_sequenceFailed || _measured || _sequenceCompleted) return;
    final board = _displayBoard;
    final all = List<Position>.generate(board.cols, (c) => Position(0, c));
    setState(() {
      _selectedGate = gate;
      _message = null;
      _selectedPositions = all;
    });
    _maybeShowAdvancedTutorialByProgress();
  }

  void _handleRowSelection(int _, String __) {
    // 3マススタディでは行/列ボタンを使わず、ゲート選択時に全マス自動選択する。
  }

  List<Position> _getHighlightedPositions(Board board) {
    if (_selectedGate != _Study3Gate.ccz || _selectedPositions.length >= 3) {
      return const [];
    }
    if (_selectedPositions.isEmpty) {
      // 2マス画面の2ビットゲートと同様に、選択前は盤面ハイライトを出さない。
      return const [];
    }
    if (_selectedPositions.length == 1) {
      final first = _selectedPositions.first;
      final candidates = <Position>[];
      for (final col in [first.col - 1, first.col + 1]) {
        if (board.isValidPosition(0, col)) {
          candidates.add(Position(0, col));
        }
      }
      return candidates;
    }
    final used = _selectedPositions.map((e) => e.col).toSet();
    return List.generate(board.cols, (c) => Position(0, c))
        .where((p) => !used.contains(p.col))
        .toList();
  }

  void _handlePositionTap(Position position) {
    // 3マススタディではマスタップで対象を選ばない（ゲート選択で全マス自動選択）。
  }

  void _applyGate() {
    if (!_canApplyGate) return;
    final gate = _selectedGate!;
    final next = List<QComplex>.from(_amplitudes);
    final cols = _selectedPositions.map((p) => p.col).toSet().toList()..sort();
    final ops = <Map<String, dynamic>>[];

    if (gate == _Study3Gate.h || gate == _Study3Gate.x) {
      final matrix = gate == _Study3Gate.h ? _hMatrix : _xMatrix;
      for (final c in cols) {
        _applySingleQubit(next, c, matrix);
        ops.add({'gate': gate, 'qubit': c});
      }
    } else {
      if (cols.length != 3) return;
      _applyCcz(next);
      ops.add({'gate': _Study3Gate.ccz});
    }

    final valid = _consumeOpsAndValidate(ops);
    setState(() {
      _amplitudes = _normalize(next);
      _selectedGate = null;
      _selectedPositions = [];
      if (!valid) {
        _sequenceFailed = true;
        _message = '手順が違います。リセットで最初からやり直してください。';
      } else if (_sequenceCompleted) {
        _message = '回路をすべて消費しました。測定して状態を確定できます。';
      } else {
        _message = null;
      }
    });
    _maybeShowAdvancedTutorialByProgress();
  }

  bool _consumeOpsAndValidate(List<Map<String, dynamic>> ops) {
    if (_sequenceCompleted || _sequenceFailed) return false;
    final step = _groverSteps[_stepIndex];

    if (step.isOneBit) {
      for (final op in ops) {
        final gate = op['gate'];
        final qubit = op['qubit'];
        if (gate is! _Study3Gate || qubit is! int) {
          return false;
        }
        if (gate != step.gate || _currentStepAppliedQubits.contains(qubit)) {
          return false;
        }
        _currentStepAppliedQubits.add(qubit);
      }
      if (_currentStepAppliedQubits.length == 3) {
        _currentStepAppliedQubits.clear();
        _stepIndex += 1;
        _autoScrollToNextStep();
      }
      return true;
    }

    if (ops.length != 1 || ops.first['gate'] != _Study3Gate.ccz) {
      return false;
    }
    _stepIndex += 1;
    _autoScrollToNextStep();
    return true;
  }

  void _handleCircuitScroll() {
    if (!_circuitScrollController.hasClients || !_autoCircuitScrollEnabled) {
      return;
    }
    final position = _circuitScrollController.position;
    if (!position.hasPixels) return;
    final reachedRightEnd =
        position.pixels >= position.maxScrollExtent - 1.0;
    if (reachedRightEnd) {
      _autoCircuitScrollEnabled = false;
    }
  }

  void _autoScrollToNextStep() {
    if (!_autoCircuitScrollEnabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_circuitScrollController.hasClients) return;
      final position = _circuitScrollController.position;
      final target = (_stepIndex * 52.0).clamp(
        0.0,
        position.maxScrollExtent,
      );
      _circuitScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _applySingleQubit(
    List<QComplex> state,
    int targetQubit,
    List<List<QComplex>> matrix,
  ) {
    final mask = 1 << (2 - targetQubit);
    for (int i = 0; i < 8; i++) {
      if ((i & mask) != 0) continue;
      final j = i | mask;
      final a0 = state[i];
      final a1 = state[j];
      state[i] = matrix[0][0] * a0 + matrix[0][1] * a1;
      state[j] = matrix[1][0] * a0 + matrix[1][1] * a1;
    }
  }

  void _applyCcz(List<QComplex> state) {
    state[7] = state[7].scaled(-1.0);
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
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
      ];
    }
    final inv = 1 / norm;
    return values.map((v) => v.scaled(inv)).toList();
  }

  /// その量子ビットが |1⟩ 側にいる存在確率 P(|1⟩)
  double _p1ForQubit(int qubit) {
    final mask = 1 << (2 - qubit);
    var p1 = 0.0;
    for (int i = 0; i < 8; i++) {
      if ((i & mask) != 0) {
        p1 += _amplitudes[i].normSquared();
      }
    }
    return p1.clamp(0.0, 1.0);
  }

  PieceType _pieceForQubit(int qubit) {
    if (_measured) {
      final idx = _amplitudes.indexWhere((a) => a.abs() > 0.99);
      if (idx >= 0) {
        final bit = (idx >> (2 - qubit)) & 1;
        return bit == 0 ? PieceType.white : PieceType.black;
      }
    }

    double p1 = 0;
    final mask = 1 << (2 - qubit);
    for (int i = 0; i < 8; i++) {
      if ((i & mask) != 0) {
        p1 += _amplitudes[i].normSquared();
      }
    }

    double xExp = 0;
    for (int i = 0; i < 8; i++) {
      if ((i & mask) != 0) continue;
      final j = i | mask;
      final prod = _amplitudes[i].conj() * _amplitudes[j];
      xExp += 2 * prod.re;
    }
    final zExp = 1.0 - 2.0 * p1;
    final blochLengthSq = xExp * xExp + zExp * zExp;
    final isPureLike = blochLengthSq >= _pureStateTol;
    final isBalanced = (p1 - 0.5).abs() <= _superpositionCenterTol;

    if (p1 < _p1Edge) return PieceType.white;
    if (p1 > 1.0 - _p1Edge) return PieceType.black;
    // |+⟩ / |-⟩ は、ほぼ純粋状態かつ P(|0⟩) ≈ P(|1⟩) のときだけ表示する。
    // これにより、エンタングル後の混合状態を grayNeutral と区別できる。
    if (isPureLike && isBalanced && xExp > _xThresh) return PieceType.grayPlus;
    if (isPureLike && isBalanced && xExp < -_xThresh) return PieceType.grayMinus;
    return PieceType.grayNeutral;
  }

  void _measure() {
    if (!_sequenceCompleted || _measured) return;
    final probs = _probabilities;
    final r = math.Random().nextDouble();
    double acc = 0;
    int picked = 0;
    for (int i = 0; i < probs.length; i++) {
      acc += probs[i];
      if (r <= acc) {
        picked = i;
        break;
      }
    }

    setState(() {
      _amplitudes = List<QComplex>.generate(
        8,
        (i) => i == picked ? QComplex.one : QComplex.zero,
      );
      _measured = true;
      _message = '測定結果: ${_basisLabels[picked]}';
    });
    if (_advancedFlowEnabled && !_shownStep11 && _waitingStep11AfterStep10) {
      _shownStep11 = true;
      _waitingStep11AfterStep10 = false;
      setState(() {
        _tutorialStepIndex = 10;
      });
    }
  }

  void _resetAll() {
    setState(() {
      _amplitudes = [
        QComplex.one,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
        QComplex.zero,
      ];
      _selectedGate = null;
      _selectedPositions = [];
      _stepIndex = 0;
      _currentStepAppliedQubits.clear();
      _sequenceFailed = false;
      _measured = false;
      _message = null;
      _autoCircuitScrollEnabled = true;
      _advancedFlowEnabled = false;
      _waitingStep8ByCcz = false;
      _waitingStep9AfterStep8 = false;
      _waitingStep10AfterStep9 = false;
      _waitingStep11AfterStep10 = false;
      _shownStep7 = false;
      _shownStep8 = false;
      _shownStep9 = false;
      _shownStep10 = false;
      _shownStep11 = false;
    });
    if (_circuitScrollController.hasClients) {
      _circuitScrollController.jumpTo(0);
    }
  }

  String _hintText() {
    if (_sequenceFailed) {
      return '手順が崩れました。リセットで最初からやり直してください。';
    }
    if (_sequenceCompleted) {
      return '回路の適用が完了しました。測定を押すと状態が確定します。';
    }
    if (_selectedGate == null) {
      return 'H / X / CCZ のいずれかを選んでください。';
    }
    return '「ゲートを適用」を押してください。';
  }

  Widget _buildStudyGroverPiece(
    Piece piece,
    double size, {
    required bool isSelected,
    required bool isHighlighted,
  }) {
    final qubit = piece.position.col;
    final p1 = _p1ForQubit(qubit);

    Color fill;
    switch (piece.type) {
      case PieceType.white:
        fill = Colors.white;
        break;
      case PieceType.black:
        fill = Colors.black;
        break;
      case PieceType.grayPlus:
      case PieceType.grayMinus:
        // 他画面の [PieceWidget] グレープラス／マイナスと同じベース色
        fill = Colors.grey.shade600;
        break;
      case PieceType.grayNeutral:
        // 一般の重ね合わせ: P(|1⟩) をグレーの濃さに反映
        fill = Color.lerp(
          const Color(0xFFE8E9EF),
          const Color(0xFF2F3238),
          p1,
        )!;
        break;
      case PieceType.blackWhite:
      case PieceType.whiteBlack:
        fill = Colors.grey.shade600;
        break;
    }

    Color borderColor;
    if (isSelected) {
      borderColor = const Color(GameConstants.cyan);
    } else if (isHighlighted) {
      borderColor = const Color(GameConstants.neonBlue);
    } else if (piece.type.isEntangled) {
      borderColor = const Color(0xFFE879A9);
    } else {
      borderColor = Colors.grey.shade700;
    }

    Widget? symbol;
    if (piece.type == PieceType.grayPlus) {
      symbol = Center(
        child: Text(
          '+',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );
    } else if (piece.type == PieceType.grayMinus) {
      symbol = Center(
        child: Text(
          '−',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.8),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(
          color: borderColor,
          width: isSelected ? 3 : (isHighlighted ? 2 : 1),
        ),
        boxShadow: isSelected || isHighlighted
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.45),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: symbol,
    );
  }

  Widget _buildCircuitView() {
    const colW = 52.0;
    const circuitH = 108.0;

    return Opacity(
      opacity: _sequenceFailed ? 0.35 : 1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF121733),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: SizedBox(
          height: circuitH,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _circuitScrollController,
            child: SingleChildScrollView(
              controller: _circuitScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ...List.generate(_groverSteps.length, (i) {
                    final step = _groverSteps[i];
                    final consumed = i < _stepIndex;
                    final active =
                        i == _stepIndex && !_sequenceCompleted && !_sequenceFailed;
                    return SizedBox(
                      width: colW,
                      height: circuitH,
                      child: CustomPaint(
                        painter: _GroverCircuitColumnPainter(
                          step: step,
                          isConsumed: consumed,
                          isActive: active,
                          isFailed: _sequenceFailed,
                          activeAppliedQubits: active && step.isOneBit
                              ? Set<int>.from(_currentStepAppliedQubits)
                              : const <int>{},
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: 64,
                    height: circuitH,
                    child: _GroverMeasureColumn(
                      isReady: _sequenceCompleted && !_sequenceFailed,
                      isDone: _measured,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGateButton(_Study3Gate gate) {
    final selected = _selectedGate == gate;
    return SizedBox(
      key: gate == _Study3Gate.ccz ? _cczGateButtonKey : null,
      width: 88,
      child: ElevatedButton(
        onPressed: (_sequenceFailed || _measured || _sequenceCompleted)
            ? null
            : () => _selectGate(gate),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFF6B46C1) : const Color(0xFF2F3D72),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          _gateLabel(gate),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
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
          '3マスで学ぶ',
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final graphAreaHeight = math.max(
                    250.0,
                    constraints.maxHeight * 0.45,
                  );
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        children: [
                          SizedBox(
                            height: graphAreaHeight,
                            child: Padding(
                              key: _upperGraphsAreaKey,
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        StudyQuantumGraphCard(
                                          title: '確率振幅（-1 ～ 1）',
                                          child: StudyQuantumStateBarChart(
                                            values: amps,
                                            labels: _basisLabels,
                                            minY: -1,
                                            maxY: 1,
                                            barColor: const Color(0xFF57D6FF),
                                            zeroLineColor:
                                                const Color(0xFF9AA3C1),
                                            valueFormatter: (v) =>
                                                v.toStringAsFixed(2),
                                          ),
                                        ),
                                        Positioned(
                                                left: 0,
                                                right: 0,
                                                top: 0,
                                                bottom: 0,
                                                child: LayoutBuilder(
                                                  builder:
                                                      (context, constraints) {
                                                    const leftPad = 34.0;
                                                    const rightPad = 10.0;
                                                    const topPad = 10.0;
                                                    const bottomPad = 24.0;
                                                    const barWidthRatio =
                                                        0.52;
                                                    const count = 8.0;
                                                    const horizontalExpandFactor =
                                                        2.0;
                                                    const verticalNudge =
                                                        12.0; // 約1文字分下へ

                                                    final totalW =
                                                        constraints.maxWidth;
                                                    final chartW = (totalW -
                                                            leftPad -
                                                            rightPad)
                                                        .clamp(0.0, totalW);
                                                    final sectionW =
                                                        chartW / count;
                                                    final barW = sectionW *
                                                        barWidthRatio;
                                                    final lastBarLeft =
                                                        leftPad +
                                                            sectionW * 7 +
                                                            (sectionW - barW) /
                                                                2;
                                                    final expandedW = barW *
                                                        horizontalExpandFactor;
                                                    final expandedLeft =
                                                        (lastBarLeft -
                                                                barW *
                                                                    (horizontalExpandFactor -
                                                                        1))
                                                            .clamp(
                                                              leftPad,
                                                              leftPad +
                                                                  chartW -
                                                                  expandedW,
                                                            )
                                                            .toDouble();
                                                    final highlightTop =
                                                        topPad + verticalNudge;
                                                    final highlightBottom =
                                                        (bottomPad -
                                                                verticalNudge)
                                                            .clamp(
                                                              0.0,
                                                              constraints
                                                                  .maxHeight,
                                                            )
                                                            .toDouble();
                                                    return Stack(
                                                      children: [
                                                        Positioned(
                                                          left: expandedLeft,
                                                          width: expandedW,
                                                          top: highlightTop,
                                                          bottom:
                                                              highlightBottom,
                                                          child: Container(
                                                            key:
                                                                _amplitude111AreaKey,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: Stack(
                              children: [
                                StudyQuantumGraphCard(
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
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      // StudyQuantumStateBarChart の描画ロジックと同じ値
                                      const leftPad = 34.0;
                                      const rightPad = 10.0;
                                      const topPad = 10.0;
                                      const bottomPad = 24.0;
                                      const barWidthRatio = 0.52; // section * 0.52
                                      const count = 8.0;
                                      const horizontalExpandFactor = 2.0;
                                      const verticalNudge = 12.0; // 約1文字分下へ

                                      final totalW = constraints.maxWidth;
                                      final chartW = (totalW - leftPad - rightPad)
                                          .clamp(0.0, totalW);
                                      final sectionW = chartW / count;
                                      final barW = sectionW * barWidthRatio;
                                      final lastBarLeft =
                                          leftPad + sectionW * 7 + (sectionW - barW) / 2;
                                      final expandedW = barW * horizontalExpandFactor;
                                      final expandedLeft = (lastBarLeft -
                                              barW * (horizontalExpandFactor - 1))
                                          .clamp(leftPad, leftPad + chartW - expandedW)
                                          .toDouble();
                                      final highlightTop = topPad + verticalNudge;
                                      final highlightBottom = (bottomPad - verticalNudge)
                                          .clamp(0.0, constraints.maxHeight)
                                          .toDouble();

                                      return Stack(
                                        children: [
                                          Positioned(
                                            left: expandedLeft,
                                            width: expandedW,
                                            top: highlightTop,
                                            bottom: highlightBottom,
                                            child: Container(key: _probability111AreaKey),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
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
                                if (!_sequenceFailed && !_sequenceCompleted)
                                  Text(
                                    _hintText(),
                                    style: const TextStyle(color: Color(0xFFDDE4FF), fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                if (_message != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    key: _measurementResultKey,
                                    child: Text(
                                      _message!,
                                      style: TextStyle(
                                        color: _sequenceFailed
                                            ? Colors.orange.shade200
                                            : Colors.greenAccent.shade100,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Container(
                                  key: _boardAreaKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: BoardWidget(
                                          board: board,
                                          selectedPositions: _selectedPositions,
                                          highlightedPositions: _getHighlightedPositions(board),
                                          lastTwoBitGatePositions: const [],
                                          enableRowColumnButtons: false,
                                          showRowButtons: false,
                                          showColumnButtons: false,
                                          selectedGate: _gateTypeForBoard(),
                                          selectedRows: null,
                                          cellSize: 50,
                                          pieceBuilder: _buildStudyGroverPiece,
                                          onPositionTap: _handlePositionTap,
                                          onRowSelected: _handleRowSelection,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCircuitView(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildGateButton(_Study3Gate.h),
                                    const SizedBox(width: 8),
                                    _buildGateButton(_Study3Gate.x),
                                    const SizedBox(width: 8),
                                    _buildGateButton(_Study3Gate.ccz),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: _sequenceCompleted ? _measure : (_canApplyGate ? _applyGate : null),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        backgroundColor: _sequenceCompleted
                                            ? const Color(0xFF00A86B)
                                            : const Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                        _sequenceCompleted ? '測定' : 'ゲートを適用',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: _resetAll,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        backgroundColor: const Color(0xFF607D8B),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        'リセット',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (step != null)
            StudyTextTutorialOverlay(
              step: _tutorialStepIndex == 2
                  ? StudyTextTutorialStep(
                      title: step.title,
                      message: step.message,
                      targetKey: _upperGraphsAreaKey,
                      nextLabel: step.nextLabel,
                      showNextButton: step.showNextButton,
                    )
                  : _tutorialStepIndex == 3
                      ? StudyTextTutorialStep(
                          title: step.title,
                          message: step.message,
                          targetKey: _probability111AreaKey,
                          nextLabel: step.nextLabel,
                          showNextButton: step.showNextButton,
                        )
                      : _tutorialStepIndex == 4
                          ? StudyTextTutorialStep(
                              title: step.title,
                              message: step.message,
                              targetKey: _cczGateButtonKey,
                              nextLabel: step.nextLabel,
                              showNextButton: step.showNextButton,
                            )
                          : _tutorialStepIndex == 5
                              ? StudyTextTutorialStep(
                                  title: step.title,
                                  message: step.message,
                                  targetKey: _boardAreaKey,
                                  nextLabel: step.nextLabel,
                                  showNextButton: step.showNextButton,
                                )
                              : _tutorialStepIndex == 6
                                  ? StudyTextTutorialStep(
                                      title: step.title,
                                      message: step.message,
                                      targetKey: _upperGraphsAreaKey,
                                      nextLabel: step.nextLabel,
                                      showNextButton: step.showNextButton,
                                    )
                                  : _tutorialStepIndex == 7
                                      ? StudyTextTutorialStep(
                                          title: step.title,
                                          message: step.message,
                                          targetKey: _amplitude111AreaKey,
                                          nextLabel: step.nextLabel,
                                          showNextButton: step.showNextButton,
                                        )
                                      : _tutorialStepIndex == 8
                                          ? StudyTextTutorialStep(
                                              title: step.title,
                                              message: step.message,
                                              targetKey: _probability111AreaKey,
                                              nextLabel: step.nextLabel,
                                              showNextButton: step.showNextButton,
                                            )
                                          : _tutorialStepIndex == 9
                                              ? StudyTextTutorialStep(
                                                  title: step.title,
                                                  message: step.message,
                                                  targetKey: _probability111AreaKey,
                                                  nextLabel: step.nextLabel,
                                                  showNextButton: step.showNextButton,
                                                )
                                          : _tutorialStepIndex == 10
                                              ? StudyTextTutorialStep(
                                                  title: step.title,
                                                  message: step.message,
                                                  targetKey: _measurementResultKey,
                                                  nextLabel: step.nextLabel,
                                                  showNextButton: step.showNextButton,
                                                  highlightExpandX: 14,
                                                  highlightExpandY: 8,
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

/// 1タイムステップ分の量子回路列（上から q0, q1, q2）
class _GroverCircuitColumnPainter extends CustomPainter {
  _GroverCircuitColumnPainter({
    required this.step,
    required this.isConsumed,
    required this.isActive,
    required this.isFailed,
    required this.activeAppliedQubits,
  });

  final _CircuitStep step;
  final bool isConsumed;
  final bool isActive;
  final bool isFailed;
  final Set<int> activeAppliedQubits;

  static const List<double> _wireYs = [18.0, 44.0, 70.0];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final linePaint = Paint()
      ..color = const Color(0xFF8A93B0)
      ..strokeWidth = 1.6;

    for (final y in _wireYs) {
      canvas.drawLine(Offset(2, y), Offset(w - 2, y), linePaint);
    }

    if (step.isOneBit) {
      for (var i = 0; i < 3; i++) {
        final y = _wireYs[i];
        final isAppliedThisStep = isActive && activeAppliedQubits.contains(i);
        Color fill;
        Color border;
        if (isFailed) {
          fill = const Color(0xFF2A2F40);
          border = const Color(0xFF4A4F60);
        } else if (isConsumed || isAppliedThisStep) {
          fill = const Color(0xFF1E3D32);
          border = const Color(0xFF2FA572);
        } else if (isActive) {
          fill = const Color(0xFF2E3F78);
          border = const Color(0xFF8EB7FF);
        } else {
          fill = const Color(0xFF252D48);
          border = const Color(0xFF3D4A66);
        }
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w / 2, y), width: 30, height: 22),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = fill
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = border
            ..style = PaintingStyle.stroke
            ..strokeWidth = isActive ? 2 : 1.2,
        );
        _drawLabel(canvas, step.label, Offset(w / 2, y), 11);
      }
    } else {
      Color fill;
      Color border;
      if (isFailed) {
        fill = const Color(0xFF2A2F40);
        border = const Color(0xFF4A4F60);
      } else if (isConsumed) {
        fill = const Color(0xFF1E3D32);
        border = const Color(0xFF2FA572);
      } else if (isActive) {
        fill = const Color(0xFF2E3F78);
        border = const Color(0xFF8EB7FF);
      } else {
        fill = const Color(0xFF252D48);
        border = const Color(0xFF3D4A66);
      }
      // CCZ: 3本線にまたがるボックス＋接続
      final topY = _wireYs.first - 10;
      final bottomY = _wireYs.last + 10;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w / 2, (topY + bottomY) / 2),
          width: 34,
          height: bottomY - topY,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = isActive ? 2 : 1.2,
      );
      final cx = w / 2;
      final dotPaint = Paint()..color = const Color(0xFFEAF0FF);
      for (final y in _wireYs) {
        canvas.drawCircle(Offset(cx, y), 3.2, dotPaint);
      }
      // ラベルは3本線の外（下側）に置き、ドットと重ならないようにする
      _drawLabel(canvas, 'CCZ', Offset(cx, _wireYs.last + 24), 10);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GroverCircuitColumnPainter oldDelegate) {
    return oldDelegate.step != step ||
        oldDelegate.isConsumed != isConsumed ||
        oldDelegate.isActive != isActive ||
        oldDelegate.isFailed != isFailed ||
        oldDelegate.activeAppliedQubits.length != activeAppliedQubits.length ||
        !oldDelegate.activeAppliedQubits.containsAll(activeAppliedQubits);
  }
}

/// 測定列（3ビット）
class _GroverMeasureColumnPainter extends CustomPainter {
  _GroverMeasureColumnPainter({
    required this.isReady,
    required this.isDone,
  });

  final bool isReady;
  final bool isDone;

  static const List<double> _wireYs = [18.0, 44.0, 70.0];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final linePaint = Paint()
      ..color = const Color(0xFF8A93B0)
      ..strokeWidth = 1.6;
    for (final y in _wireYs) {
      canvas.drawLine(Offset(2, y), Offset(w - 2, y), linePaint);
    }

    Color fill;
    Color border;
    if (isDone) {
      fill = const Color(0xFF1E4A38);
      border = const Color(0xFF3DDC97);
    } else if (isReady) {
      fill = const Color(0xFF3A3520);
      border = const Color(0xFFFFC857);
    } else {
      fill = const Color(0xFF2A2F40);
      border = const Color(0xFF4A5568);
    }

    for (final y in _wireYs) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w / 2, y), width: 26, height: 20),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = fill..style = PaintingStyle.fill);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = isReady || isDone ? 1.8 : 1,
      );
    }

    final cap = TextPainter(
      text: TextSpan(
        text: '測定',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // 「測定」ラベルは3bit目（3本目）の下側に配置
    cap.paint(canvas, Offset(w / 2 - cap.width / 2, _wireYs.last + 20));
  }

  @override
  bool shouldRepaint(covariant _GroverMeasureColumnPainter oldDelegate) {
    return oldDelegate.isReady != isReady || oldDelegate.isDone != isDone;
  }
}

class _GroverMeasureColumn extends StatelessWidget {
  const _GroverMeasureColumn({
    required this.isReady,
    required this.isDone,
  });

  final bool isReady;
  final bool isDone;

  static const List<double> _wireYs = [18.0, 44.0, 70.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 108,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GroverMeasureColumnPainter(
                isReady: isReady,
                isDone: isDone,
              ),
            ),
          ),
          ..._wireYs.map(
            (y) => Positioned(
              left: 20.3,
              top: y - 9.0,
              width: 23.4,
              height: 18.0,
              child: Image.asset(
                'assets/mesurement_t.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
