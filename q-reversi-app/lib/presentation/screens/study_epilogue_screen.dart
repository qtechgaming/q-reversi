import 'package:flutter/material.dart';

/// スタディ「終わりに」— 簡略化の注釈と参考書への誘導（1ページ）
class StudyEpilogueScreen extends StatelessWidget {
  const StudyEpilogueScreen({super.key});

  static const Color _bgTop = Color(0xFF0A0E27);
  static const Color _bgBottom = Color(0xFF1A1F3A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '終わりに',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ここまでお疲れさまでした。盤面やブロッホ球で、量子の「手触り」が少しでもつかめたなら幸いです。',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 24),
                _sectionTitle('このアプリの位相の扱い'),
                const SizedBox(height: 10),
                _bullet(
                  '一般に量子状態の振幅は複素数ですが、このゲームで使っている初期状態とゲート（H, X, Y, Z, CNOT, SWAP, CCZ）の範囲では、虚数単位 i はグローバル位相としてのみ現れます。',
                ),
                _bullet(
                  'グローバル位相とは、状態ベクトルの全成分に共通して掛かる位相（e^{iφ}）のことです。これは測定確率や物理的な予測を変えないため、観測可能な違いを生みません。',
                ),
                _bullet(
                  'このゲームでは表示を分かりやすくするため、グローバル位相は常に 1 になるように取り直して表示しています。',
                ),
                const SizedBox(height: 24),
                _sectionTitle('さらに学ぶには'),
                const SizedBox(height: 10),
                Text(
                  'ここまでで少しでも興味を持ってくれたら、次は入門書や講義をのぞいてみてください。そこでは、このゲームで表現しきれなかった部分も、数式を使って丁寧に説明されています。ぜひ、量子のより豊かな世界を追いかけてみてください。',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 16,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '数式は最初は難しく感じるかもしれませんが、一度つながるとゲームのルールのように美しく整理されています。あなたの好奇心が、次の一冊・次の一講義へつながることを願っています。',
                  style: TextStyle(
                    color: Color(0xFFB8C5FF),
                    fontSize: 15,
                    height: 1.65,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _bullet(String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '・',
            style: TextStyle(
              color: Color(0xFF9C6BFF),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Text(
              body,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
