import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/firebase/backend_warmup.dart';
import 'game_mode_selection_screen.dart';

/// ホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _versionLabel;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = 'v${info.version}';
    });
  }

  Future<void> _openModes() async {
    if (_opening) return;
    setState(() => _opening = true);
    BackendWarmup.kickoff();
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const GameModeSelectionScreen(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      } else {
        _opening = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/home_background2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    top: constraints.maxHeight * 0.25,
                    left: 0,
                    right: 0,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Qリバーシ',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Quantum Computing Reversi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: _opening ? null : _openModes,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        backgroundColor: const Color(0xFF6B46C1),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      child: const Text(
                        'START',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_versionLabel != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 16,
                      child: Text(
                        _versionLabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
