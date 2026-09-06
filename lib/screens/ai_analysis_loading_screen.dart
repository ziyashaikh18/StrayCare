import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'ai_scan_assistant_screen.dart';

class AiAnalysisLoadingScreen extends StatefulWidget {
  const AiAnalysisLoadingScreen({super.key, required this.image});

  final XFile image;

  @override
  State<AiAnalysisLoadingScreen> createState() =>
      _AiAnalysisLoadingScreenState();
}

class _AiAnalysisLoadingScreenState extends State<AiAnalysisLoadingScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      setState(() {
        _progress += 0.01;

        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _goToResults();
        }
      });
    });
  }

  Future<File?> _persistImage() async {
    final sourceFile = File(widget.image.path);
    final exists = await sourceFile.exists();
    debugPrint('AI Scan original image path: ${widget.image.path}');
    debugPrint('AI Scan original file exists: $exists');

    if (!exists) return null;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final filename = widget.image.path.split(RegExp(r'[\\/]')).last;
    final permanentFile = File(
      '${documentsDirectory.path}/ai_scan_${DateTime.now().millisecondsSinceEpoch}_$filename',
    );
    await sourceFile.copy(permanentFile.path);
    debugPrint('AI Scan permanent image path: ${permanentFile.path}');
    return permanentFile;
  }

  Future<void> _goToResults() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    File? imageFile;
    try {
      imageFile = await _persistImage();
    } catch (error) {
      debugPrint('AI Scan image persistence failed: $error');
    }
    if (!mounted) return;

    if (imageFile == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: const Text(
            'Image is no longer available. Please scan the animal again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AiScanAssistantScreen(imageFile: imageFile!),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08041F),
      body: Stack(
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.pink.withValues(alpha: 0.4),
                    Colors.purple.withValues(alpha: 0.3),
                    Colors.blue.withValues(alpha: 0.3),
                    Colors.green.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Close Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Animated Glow Logo
                TweenAnimationBuilder(
                  tween: Tween(begin: 0.9, end: 1.1),
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: const Column(
                    children: [
                      Icon(
                        Icons.pets_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "STRAYCARE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 90),

                const Text(
                  "Analyzing...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 7,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  _progress < 0.3
                      ? "Detecting animal..."
                      : _progress < 0.7
                          ? "Analyzing injury..."
                          : "Generating results...",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text(
                    "AI Scan in Progress",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
