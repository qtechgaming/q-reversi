import '../entities/tutorial_content.dart';
import '../entities/gate_type.dart';
import '../entities/challenge_level.dart';

/// チュートリアルサービス
class TutorialService {
  /// レベル1のチュートリアルコンテンツを取得
  static List<TutorialContent> getLevel1Tutorial() {
    return [
      // ① チャレンジモードの概念説明
      const TutorialContent(
        id: 'level1_concept',
        title: '量子の世界へようこそ',
        description: 'このゲームでは、コンピュータの量子を利用し、その量子でするリバーシゲームです。量子動作の特徴を活用し、原理を理解して量子世界を楽しもう',
        type: TutorialType.concept,
      ),
      
      // ② Xゲートの説明
      const TutorialContent(
        id: 'level1_xgate',
        title: 'Xゲート',
        description: 'Xゲートは白と黒の駒を入れ替えます',
        type: TutorialType.gateExplain,
        gate: GateType.x,
        bulletPoints: [
          '白 → 黒',
          '黒 → 白',
        ],
      ),
      
      // ③ 操作説明（アニメーション付き）
      const TutorialContent(
        id: 'level1_operation',
        title: '操作方法',
        description: 'ゲートを選択して、盤面を選択し、適用ボタンを押します',
        type: TutorialType.operation,
        animation: TutorialAnimation(
          type: AnimationType.operationDemo,
          duration: Duration(seconds: 5),
        ),
      ),
    ];
  }

  /// 新しいゲートが登場するレベルのチュートリアルを取得
  static List<TutorialContent>? getNewGateTutorial(
    int level,
    ChallengeLevel currentLevel,
    List<ChallengeLevel> allLevels,
  ) {
    // 前のレベルで使用可能だったゲートを取得
    final previousGates = _getGatesUpToLevel(level - 1, allLevels);
    final currentGates = currentLevel.availableGates;
    
    // 新しいゲートを検出
    final newGates = currentGates.where((gate) => !previousGates.contains(gate)).toList();
    
    if (newGates.isEmpty) return null;
    
    // 最初の新しいゲートについて説明
    final newGate = newGates.first;
    return [
      TutorialContent(
        id: 'new_gate_${newGate.name}',
        title: '新しいゲート: ${_getGateName(newGate)}',
        description: _getGateDescription(newGate),
        type: TutorialType.gateExplain,
        gate: newGate,
        bulletPoints: _getGateBulletPoints(newGate),
      ),
    ];
  }

  /// レベルまでのゲートを取得
  static List<GateType> _getGatesUpToLevel(int level, List<ChallengeLevel> allLevels) {
    final gates = <GateType>{};
    for (final l in allLevels) {
      if (l.level <= level) {
        gates.addAll(l.availableGates);
      }
    }
    return gates.toList();
  }

  /// ゲート名を取得
  static String _getGateName(GateType gate) {
    switch (gate) {
      case GateType.x:
        return 'Xゲート';
      case GateType.h:
        return 'Hゲート';
      case GateType.y:
        return 'Yゲート';
      case GateType.z:
        return 'Zゲート';
      case GateType.cnot:
        return 'CNOTゲート';
      case GateType.swap:
        return 'SWAPゲート';
    }
  }

  /// ゲートの説明を取得
  static String _getGateDescription(GateType gate) {
    switch (gate) {
      case GateType.x:
        return 'Xゲートは白と黒の駒を入れ替えます';
      case GateType.h:
        return 'Hゲートは重ね合わせ状態を作り出します';
      case GateType.y:
        return 'Yゲートは複数の変化を同時に行います';
      case GateType.z:
        return 'Zゲートは位相を反転させます';
      case GateType.cnot:
        return 'CNOTゲートは制御ビットに応じてターゲットビットを反転させます';
      case GateType.swap:
        return 'SWAPゲートは2つの駒の状態を入れ替えます';
    }
  }

  /// ゲートの箇条書きを取得
  static List<String> _getGateBulletPoints(GateType gate) {
    switch (gate) {
      case GateType.x:
        return ['白 → 黒', '黒 → 白'];
      case GateType.h:
        return ['白 → グレープラス', '黒 → グレーマイナス', 'グレープラス → 白', 'グレーマイナス → 黒'];
      case GateType.y:
        return ['白 → グレーマイナス', '黒 → グレープラス', 'グレープラス → グレーマイナス', 'グレーマイナス → グレープラス'];
      case GateType.z:
        return ['グレープラス → グレーマイナス', 'グレーマイナス → グレープラス', '白・黒は変化なし'];
      case GateType.cnot:
        return ['制御ビットが黒の場合、ターゲットビットを反転', '制御ビットが白の場合は変化なし'];
      case GateType.swap:
        return ['2つの駒の状態を完全に入れ替え'];
    }
  }

  /// 全画面チュートリアルの全ページを取得（スライド制を廃止し、すべてのスライドを独立したページとして返す）
  static List<TutorialPage> getFullTutorial() {
    final originalPages = _getOriginalTutorialPages();

    // 指定されたページのみを残す
    const selectedSlideIds = [
      'welcome-1', // はじめに
      'operation-1', // ゲーム概要
      'piece_types-1', // 駒の種類
      'gate_about-1', // ゲートについて
      'gate_x-1', // Xゲート
      'gate_h-1', // Hゲート
      'gate_z-1', // Zゲート
      'gate_y-1', // Yゲート
      'gate_swap-1', // SWAPゲート
      'gate_cnot_1-1', // CNOTゲート
      'gate_mastery_complete-1', // ゲート習得完了
    ];
    const selectedTitles = [
      'はじめに',
      'ゲーム概要',
      '駒の種類',
      'ゲートについて',
      'Xゲート',
      'Hゲート',
      'Zゲート',
      'Yゲート',
      'SWAPゲート',
      'CNOTゲート',
      'ゲート習得完了',
    ];

    final slideById = <String, TutorialSlide>{};
    for (final page in originalPages) {
      for (final slide in page.slides) {
        slideById[slide.slideId] = slide;
      }
    }

    final selectedPages = <TutorialPage>[];
    for (int i = 0; i < selectedSlideIds.length; i++) {
      final slideId = selectedSlideIds[i];
      final slide = slideById[slideId];
      if (slide == null) {
        throw StateError('指定スライドが見つかりません: $slideId');
      }
      selectedPages.add(
        TutorialPage(
          pageNumber: i + 1,
          pageId: slideId,
          pageTitle: selectedTitles[i],
          slides: [slide],
        ),
      );
    }

    return selectedPages;
  }

  /// 元のチュートリアルページリスト（スライド分割あり）
  static List<TutorialPage> _getOriginalTutorialPages() {
    return [
      // ページ0: Welcome
      const TutorialPage(
        pageNumber: 0,
        pageId: 'welcome',
        pageTitle: 'Welcomeページ',
        slides: [
          TutorialSlide(
            slideId: 'welcome-1',
            texts: [
              '量子の世界へようこそ。',
              'このゲームは、量子コンピュータの動作原理を活用したリバーシ風ゲームです。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/QC_and_Othello.png'},
            ),
          ),
        ],
      ),

      // ページ1: 基本操作
      const TutorialPage(
        pageNumber: 1,
        pageId: 'operation',
        pageTitle: '基本操作',
        slides: [
          TutorialSlide(
            slideId: 'operation-1',
            texts: [
              '8x8の盤面のそれぞれのマスにある駒を量子コンピュータの最小単位(量子ビット)として、その盤面の縦横1列、もしくは正方4マスに対して量子コンピュータの演算(量子ゲート)をかけていくゲームです。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.animation,
              data: {'type': 'operation_demo'},
            ),
          ),
        ],
      ),

      // ページ1.5: 量子コンピュータとは？
      const TutorialPage(
        pageNumber: 1,
        pageId: 'quantum_computer_intro',
        pageTitle: '量子コンピュータとは？',
        slides: [
          TutorialSlide(
            slideId: 'quantum_computer_intro-1',
            texts: [
              '「原子よりも小さな粒子の世界の不思議なルール」="量子力学"の性質を活用することで、従来のコンピュータでは解けない複雑な問題を高速に計算できるコンピュータです。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/Quantum.png'},
            ),
          ),
        ],
      ),

      // ページ2: 量子コンピュータの最小単位(qビット)
      const TutorialPage(
        pageNumber: 2,
        pageId: 'qbit',
        pageTitle: '量子コンピュータの最小単位(qビット)',
        slides: [
          TutorialSlide(
            slideId: 'qbit-1',
            texts: [
              '従来のコンピュータでは、その最小単位(ビット)は0か1のどちらかの値を取ります。',
              '量子コンピュータの最小単位(量子ビット)では、1ビットが0か1だけではなく、その中間の状態(重ね合わせの状態)が存在し、0か1が確定していない中間の状態を取ることができます。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.comparison,
            ),
          ),
          TutorialSlide(
            slideId: 'qbit-2',
            texts: [
              'このゲームでは、0を白駒、1を黒駒、そして重ね合わせの状態をグレー駒として、量子コンピュータの中身を模擬します。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.board,
              data: {'mode': 'mini_board_with_image'},
            ),
          ),
        ],
      ),

      // ページ3: 重ね合わせについて
      const TutorialPage(
        pageNumber: 3,
        pageId: 'superposition',
        pageTitle: '重ね合わせについて',
        slides: [
          TutorialSlide(
            slideId: 'superposition-1',
            texts: [
              'さて、このグレー駒の状態とは、どういう状態でしょうか？',
              '例えば、コイントスをして空中で回っている最中のような、白(0)か黒(1)にまだ確定しておらず、どちらになる可能性もあるような状態のことを指しています。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.diagram,
              data: {'type': 'gray_piece_equals_video'},
            ),
          ),
          TutorialSlide(
            slideId: 'superposition-2',
            texts: [
              'グレー駒がどちらの色に転んだかは、量子コンピュータの操作、"測定"をすることで、白(0)か黒(1)に確定し、計算結果を得ることができます。',
              'このゲームでは、グレー駒は測定すると50%の確率で白(0)か黒(1)に確定するものとします。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.diagram,
              data: {'type': 'measurement'},
            ),
          ),
        ],
      ),

      // ページ4: 駒の種類 / ゲートについて
      const TutorialPage(
        pageNumber: 4,
        pageId: 'piece_and_gate_intro',
        pageTitle: '駒の種類 / ゲートについて',
        slides: [
          TutorialSlide(
            slideId: 'piece_types-1',
            texts: [
              'このゲームでは、普通のリバーシと同じ白と黒だけでなく、その中間の状態を表すグレープラス、グレーマイナスという駒があります。グレーの駒は、対戦終了時に50%の確率で白か黒になります。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.diagram,
              data: {'type': 'piece_kinds'},
            ),
          ),
          TutorialSlide(
            slideId: 'gate_about-1',
            texts: [
              'このゲームでは、駒を挟んでひっくり返す代わりに、量子コンピュータの演算である"ゲート"を駒に適用して別の種類の駒に変化させます。以下の6つのゲートを用います。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/GateKinds.png'},
            ),
          ),
        ],
      ),

      // ページ5: Xゲート
      const TutorialPage(
        pageNumber: 5,
        pageId: 'gate_x',
        pageTitle: 'Xゲート',
        slides: [
          TutorialSlide(
            slideId: 'gate_x-1',
            texts: [
              '1つのビットに作用し、白と黒を入れ替えます。',
              'グレー駒は変化させません。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/gateX.png'},
            ),
          ),
        ],
      ),

      // ページ6: Hゲート
      const TutorialPage(
        pageNumber: 6,
        pageId: 'gate_h',
        pageTitle: 'Hゲート',
        slides: [
          TutorialSlide(
            slideId: 'gate_h-1',
            texts: [
              '1つのビットに作用し、白とグレープラス、黒とグレーマイナスを入れ替えます。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/gateH.png'},
            ),
          ),
        ],
      ),

      // ページ7: Zゲート
      const TutorialPage(
        pageNumber: 7,
        pageId: 'gate_z',
        pageTitle: 'Zゲート',
        slides: [
          TutorialSlide(
            slideId: 'gate_z-1',
            texts: [
              '1つのビットに作用し、グレープラスとグレーマイナスを入れ替えます。',
              '白と黒は変化させません。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/gateZ.png'},
            ),
          ),
        ],
      ),

      // ページ8: Yゲート
      const TutorialPage(
        pageNumber: 8,
        pageId: 'gate_y',
        pageTitle: 'Yゲート',
        slides: [
          TutorialSlide(
            slideId: 'gate_y-1',
            texts: [
              '1つのビットに作用し、白と黒、グレープラスとグレーマイナスを入れ替えます。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/gateY.png'},
            ),
          ),
        ],
      ),

      // ページ9: SWAPゲート
      const TutorialPage(
        pageNumber: 9,
        pageId: 'gate_swap',
        pageTitle: 'SWAPゲート',
        slides: [
          TutorialSlide(
            slideId: 'gate_swap-1',
            texts: [
              '2つの隣接する駒に作用し、その駒を入れ替えます。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/gateSWAP.png'},
            ),
          ),
        ],
      ),

      // ページ10: CNOTゲート#1 - 基本動作
      const TutorialPage(
        pageNumber: 10,
        pageId: 'gate_cnot_1',
        pageTitle: 'CNOTゲート#1 - 基本動作',
        slides: [
          TutorialSlide(
            slideId: 'gate_cnot_1-1',
            texts: [
              '2つの隣接する駒に作用し、1駒目が黒の時のみ、2駒目にXゲートが作用(白と黒を入れ替え)します。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/gateCNOT.png'},
            ),
          ),
        ],
      ),

      // ページ10.5: ゲート習得完了
      const TutorialPage(
        pageNumber: 10,
        pageId: 'gate_mastery_complete',
        pageTitle: 'チュートリアル完了',
        slides: [
          TutorialSlide(
            slideId: 'gate_mastery_complete-1',
            texts: [
              'チュートリアルはこれで完了です。',
              'チャレンジモード、VSモード、そしてスタディモードを通じて、楽しく量子コンピュータの計算の世界に触れてみてください。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/AllGate.png'},
            ),
          ),
        ],
      ),

      // ページ11: CNOTゲート#2 - エンタングルメント
      const TutorialPage(
        pageNumber: 11,
        pageId: 'gate_cnot_2',
        pageTitle: 'CNOTゲート#2 - エンタングルメント',
        slides: [
          TutorialSlide(
            slideId: 'gate_cnot_2-1',
            texts: [
              'さて、ここでCNOTゲートについて少し深く考えてみます。1駒目が黒や白ではなく、グレーだった場合はどうなるでしょう？',
              'グレーの場合、50%で白、50%で黒なので、2駒目が反転するかどうかも確率的になります。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/CNOTgray.png'},
            ),
          ),
          TutorialSlide(
            slideId: 'gate_cnot_2-2',
            texts: [
              '例えば、1駒目が白だった時、2駒目は反転せず白のままです。1駒目が黒だった時、2駒目は反転しており、黒になります。',
              'このように、測定するまではどちらかわからないが、1駒目を測定して白なら、2駒目も必ず白。1駒目を測定して黒なら2駒目も必ず黒。というように運命を共にした状態になるのです。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/CNOT3.png'},
            ),
          ),
          TutorialSlide(
            slideId: 'gate_cnot_2-3',
            texts: [
              'このような状態を"エンタングルメント"と呼び、このゲームでは以下の通りに表現することとします。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/entanglement.png'},
            ),
          ),
        ],
      ),

      // ページ12: CNOTゲート#3 - 全パターン一覧
      const TutorialPage(
        pageNumber: 12,
        pageId: 'gate_cnot_3',
        pageTitle: 'CNOTゲート#3 - 全パターン一覧',
        slides: [
          TutorialSlide(
            slideId: 'gate_cnot_3-1',
            texts: [
              '最後に、CNOTゲートの2駒の組み合わせ全パターンです。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/blackCNOT_all.png'},
            ),
          ),
          TutorialSlide(
            slideId: 'gate_cnot_3-2',
            texts: [
              'VSモードにおける黒プレイヤーの場合は、1駒目の条件が反転することとします。',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.image,
              data: {'path': 'assets/whiteCNOT_all.png'},
            ),
          ),
        ],
      ),

      // ページ13: 終わりに
      const TutorialPage(
        pageNumber: 13,
        pageId: 'finish',
        pageTitle: '終わりに',
        slides: [
          TutorialSlide(
            slideId: 'finish-1',
            texts: [
              '量子コンピュータでは、重ね合わせとエンタングルメントをうまく回路の中で使うことで、高速な計算が可能になるのです。',
              'スタディモードの次のステップに進んで、量子コンピュータと量子アルゴリズムの一端を感じてみてください...!',
            ],
            visualElement: TutorialVisualElement(
              type: VisualElementType.board,
            ),
          ),
        ],
      ),
    ];
  }
}

