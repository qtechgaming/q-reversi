import 'package:flutter/material.dart';
import '../../domain/services/study_quantum_intro_tutorial_service.dart';
import '../../domain/entities/tutorial_content.dart';
import '../widgets/tutorial/tutorial_visual_element_widget.dart';

/// スタディ「量子コンピュータとは？」— チュートリアルと同じ表示形式（指定ページの抜粋）
class StudyQuantumIntroScreen extends StatefulWidget {
  const StudyQuantumIntroScreen({super.key});

  @override
  State<StudyQuantumIntroScreen> createState() =>
      _StudyQuantumIntroScreenState();
}

class _StudyQuantumIntroScreenState extends State<StudyQuantumIntroScreen> {
  late PageController _pageController;
  late List<TutorialPage> _pages;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = StudyQuantumIntroTutorialService.getPages();
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

  void _nextPage() {
    if (_currentPageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text(
          '量子コンピュータとは？',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, pageIndex) {
                  final page = _pages[pageIndex];
                  return _buildPage(page);
                },
              ),
            ),
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
          Text(
            '${_currentPageIndex + 1}/${_pages.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(TutorialPage page) {
    final slide = page.slides[0];
    return _buildSlide(slide);
  }

  Widget _buildSlide(TutorialSlide slide) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A).withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
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
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'スキップ',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
            child: Text(
              _isLastPage ? '閉じる' : '次へ',
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
