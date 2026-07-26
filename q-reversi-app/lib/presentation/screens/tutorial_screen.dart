import 'package:flutter/material.dart';
import '../../domain/services/tutorial_service.dart';
import '../../domain/services/tutorial_progress_service.dart';
import '../../domain/entities/tutorial_content.dart';
import '../widgets/tutorial/tutorial_visual_element_widget.dart';

/// チュートリアル画面
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  /// モード選択側でチャレンジへ誘導するための戻り値
  static const String resultOpenChallenge = 'open_challenge';

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late PageController _pageController;
  late List<TutorialPage> _pages;
  int _currentPageIndex = 0;
  final TutorialProgressService _progressService = TutorialProgressService();

  @override
  void initState() {
    super.initState();
    _pages = TutorialService.getFullTutorial();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPageIndex = pageIndex;
    });
  }

  void _nextPage() async {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 最後のページの場合は終了し、完了をマーク
      await _progressService.markTutorialCompleted();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  bool get _isFirstPage => _currentPageIndex == 0;
  bool get _isLastPage => _currentPageIndex == _pages.length - 1;
  bool get _isGateMasteryPage =>
      _pages[_currentPageIndex].pageId == 'gate_mastery_complete';

  Future<void> _goHome() async {
    await _progressService.markTutorialCompleted();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _goToChallenge() async {
    await _progressService.markTutorialCompleted();
    if (!mounted) return;
    Navigator.pop(context, TutorialScreen.resultOpenChallenge);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text(
          'チュートリアル',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            // スキップをマーク
            await _progressService.markTutorialSkipped();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 進捗表示
            _buildProgressIndicator(),
            
            // ページコンテンツ
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, pageIndex) {
                  final page = _pages[pageIndex];
                  return _buildPage(page, pageIndex);
                },
              ),
            ),
            
            // ナビゲーションボタン
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final currentPage = _pages[_currentPageIndex];
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ページタイトル（左側、中央配置）
          Expanded(
            child: Text(
              currentPage.pageTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // ページ番号（右側）
          Text(
            '${currentPage.pageNumber}/${_pages.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(TutorialPage page, int pageIndex) {
    // スライド制を廃止し、各ページの最初のスライドのみを表示
    final slide = page.slides[0];
    return _buildSlide(slide, page);
  }

  Widget _buildSlide(TutorialSlide slide, TutorialPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // テキスト
              ...slide.texts.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              )),
              
              const SizedBox(height: 16),
              
              // 視覚要素（残りのスペースを使用）
              if (slide.visualElement != null)
                Expanded(
                  child: _buildVisualElement(slide.visualElement!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisualElement(TutorialVisualElement visualElement) {
    return TutorialVisualElementWidget(
      visualElement: visualElement,
    );
  }

  Widget _buildNavigationButtons() {
    if (_isGateMasteryPage) {
      return Container(
        height: kToolbarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A).withOpacity(0.8),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isFirstPage ? null : _previousPage,
              child: const Text(
                '前へ',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: _goHome,
              child: const Text(
                '閉じる',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: _goToChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'チャレンジへ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isFirstPage
                ? null
                : _previousPage,
            child: const Text(
              '前へ',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          if (_isLastPage)
            TextButton(
              onPressed: _goHome,
              child: const Text(
                '終了',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            TextButton(
              onPressed: () async {
                // スキップをマーク
                await _progressService.markTutorialSkipped();
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text(
                'スキップ',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ElevatedButton(
            onPressed: _isLastPage ? _goToChallenge : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLastPage
                  ? const Color(0xFF2196F3)
                  : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
            child: Text(
              _isLastPage ? 'チャレンジへ' : '次へ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

