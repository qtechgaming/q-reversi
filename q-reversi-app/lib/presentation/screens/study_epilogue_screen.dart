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
                _sectionTitle('このアプリで省略していること'),
                const SizedBox(height: 10),
                _bullet(
                  '一般の量子状態の振幅は複素数です。本アプリでは扱いやすさのため、多くの場面で「実数の振幅」に寄せて表示しており、虚数成分や位相（角度）の情報は盤上では表現しきれていません。',
                ),
                _bullet(
                  '状態ベクトル全体に −1 を掛けたり、複素数の位相だけを変えたりしても、測定で得られる確率は変わりません。そのため、見た目の簡潔さのために符号や全体位相の見せ方を教科書と完全には一致させていないことがあります。',
                ),
                _bullet(
                  '2マス・3マス画面では、エンタングルメントや可視化の都合から、駒の色や記号で「ざっくり」状態を示しています。厳密な状態ベクトルや行列表示とは一対一対応しない部分があります。',
                ),
                const SizedBox(height: 24),
                _sectionTitle('さらに学ぶには'),
                const SizedBox(height: 10),
                Text(
                  '量子情報・量子コンピュータの入門書や講義では、複素振幅、ユニタリー変換、テンソル積、測定のルールなどが丁寧に整理されています。ここから先は、参考書や信頼できる教材の世界で、今回盤面に載せきれなかった「ベクトル・行列による表現」や「虚数」「位相」も含めて、より豊かな世界を追いかけてみてください。',
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
