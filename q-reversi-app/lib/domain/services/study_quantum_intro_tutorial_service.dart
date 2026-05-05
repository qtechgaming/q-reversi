import '../entities/tutorial_content.dart';

/// スタディ「量子コンピュータとは？」専用のチュートリアルデータ。
///
/// 全体チュートリアルとは独立したスライド定義を持たせることで、
/// 相互の変更影響を抑える。
class StudyQuantumIntroTutorialService {
  static List<TutorialPage> getPages() {
    const selectedSlides = <TutorialSlide>[
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
      TutorialSlide(
        slideId: 'study_piece_kinds-1',
        texts: [
          '量子の世界では、白の状態を|\u20600\u2060⟩、黒の状態を|\u20601\u2060⟩、グレープラスの状態を|\u2060+\u2060⟩、グレーマイナスの状態を|\u2060-\u2060⟩という形で表現します。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.diagram,
          data: {
            'type': 'piece_kinds',
            'variant': 'bra_ket',
          },
        ),
      ),
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
          'このゲームでは、グレー駒は測定すると50%の確率で白(0)か黒(1)に確定するものとしています。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.diagram,
          data: {'type': 'measurement'},
        ),
      ),
      TutorialSlide(
        slideId: 'study_gate_intro-1',
        texts: [
          '次に、ゲートと呼ばれるコンピュータへの演算操作について説明します。',
          '従来のコンピュータでは、1つのビットを反転させる(NOTゲート)、2つのビットがどちらも1であれば1になる(ANDゲート)、2つのビットのどちらかが1であれば1になる(ORゲート)といった、1ビットや2ビットに作用させるゲートを使って、計算処理を実行しています。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/gateExample.png'},
        ),
      ),
      TutorialSlide(
        slideId: 'study_gate_intro-2',
        texts: [
          '量子コンピュータにも、量子ゲートと呼ばれる、量子ビットに作用させる演算操作があります。',
          'このゲームでは、代表的な量子ゲートを使用しています。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/QC_Gate.png'},
        ),
      ),
      TutorialSlide(
        slideId: 'gate_x-1',
        texts: [
          '1つのビットに作用し、白|\u20600\u2060⟩と黒|\u20601\u2060⟩を入れ替えます。',
          'グレー駒は変化させません。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/gateX.png'},
        ),
      ),
      TutorialSlide(
        slideId: 'gate_h-1',
        texts: [
          '1つのビットに作用し、白|\u20600\u2060⟩とグレープラス|\u2060+\u2060⟩、黒|\u20601\u2060⟩とグレーマイナス|\u2060-\u2060⟩を入れ替えます。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/gateH.png'},
        ),
      ),
      TutorialSlide(
        slideId: 'gate_z-1',
        texts: [
          '1つのビットに作用し、グレープラス|\u2060+\u2060⟩とグレーマイナス|\u2060-\u2060⟩を入れ替えます。',
          '白と黒は変化させません。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/gateZ.png'},
        ),
      ),
      TutorialSlide(
        slideId: 'gate_y-1',
        texts: [
          '1つのビットに作用し、白|\u20600\u2060⟩と黒|\u20601\u2060⟩、グレープラス|\u2060+\u2060⟩とグレーマイナス|\u2060-\u2060⟩を入れ替えます。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/gateY.png'},
        ),
      ),
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
      TutorialSlide(
        slideId: 'study_gate_cnot_1-1',
        texts: [
          'CNOTゲートはControl-NOT(コントロール・ノット)の略で、別名Control-X(コントロール・X)とも呼ばれます。\n2つの隣接する駒に作用し、1ビット目(制御ビット)が黒|\u20601\u2060⟩の時のみ、2ビット目(ターゲットビット)にXゲートの効果(白と黒の入れ替え)を適用します。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/gateCNOT.png'},
        ),
      ),
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
          'このような状態を"エンタングルメント(量子もつれ)"と呼び、このゲームでは以下の通りに表現することとします。',
        ],
        visualElement: TutorialVisualElement(
          type: VisualElementType.image,
          data: {'path': 'assets/entanglement.png'},
        ),
      ),
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
    ];

    const selectedTitles = [
      '量子コンピュータとは？',
      '量子ビット',
      'Qリバーシ',
      '駒の種類',
      'グレー駒の状態',
      '測定',
      'ゲート',
      '量子ゲート',
      'Xゲート',
      'Hゲート',
      'Zゲート',
      'Yゲート',
      'SWAPゲート',
      'CNOTゲート',
      'CNOTゲート(発展)',
      'CNOTゲート(発展)',
      'エンタングルメント',
      'CNOT全パターン[プレイヤー白]',
      'CNOT全パターン[プレイヤー黒]',
      '終わりに',
    ];

    final pages = <TutorialPage>[];
    for (int i = 0; i < selectedSlides.length; i++) {
      pages.add(
        TutorialPage(
          pageNumber: i + 3,
          pageId: selectedSlides[i].slideId,
          pageTitle: selectedTitles[i],
          slides: [selectedSlides[i]],
        ),
      );
    }
    return pages;
  }
}
