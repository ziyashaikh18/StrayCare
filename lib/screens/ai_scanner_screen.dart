import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// StrayCare "AI Scanner" screen.
///
/// Uses the phone's real-time camera feed behind the scanner UI.
/// The scanner frame and purple laser animation remain unchanged.
class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen>
    with SingleTickerProviderStateMixin {
  
  static const Color kPurpleLight = Color(0xFFB88CE8);
  

  // Real camera
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  late final AnimationController _scanController;

  bool _cameraReady = false;
  bool _isScanning = true;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _initializeCamera();
  }

  // ───────────────────────── Camera initialization ─────────────────────────

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }

      // Start with the rear camera if available.
      final backCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _cameraIndex = backCameraIndex == -1 ? 0 : backCameraIndex;

      await _startCamera();
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _startCamera() async {
    // First completely release the currently active camera.
    final oldController = _cameraController;

    _cameraController = null;

    if (mounted) {
      setState(() {
        _cameraReady = false;
        _flashOn = false;
      });
    }

    if (oldController != null) {
      try {
        await oldController.dispose();
      } catch (e) {
        debugPrint('Old camera dispose error: $e');
      }
    }

    // Small delay gives Android time to release the previous camera session.
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted || _cameras.isEmpty) {
      return;
    }

    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _flashOn = false;
      });
    } on CameraException catch (e) {
      debugPrint(
        'Camera initialization failed: ${e.code} - ${e.description}',
      );

      await controller.dispose();

      if (mounted) {
        setState(() {
          _cameraController = null;
          _cameraReady = false;
        });

        _snack('Could not switch camera');
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');

      await controller.dispose();

      if (mounted) {
        setState(() {
          _cameraController = null;
          _cameraReady = false;
        });

        _snack('Could not switch camera');
      }
    }
  }

  // ───────────────────────── Flip camera ─────────────────────────

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) {
      _snack('Only one camera is available');
      return;
    }

    // Switch to the other camera.
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _startCamera();
  }

  // ───────────────────────── Flash ─────────────────────────

  Future<void> _toggleFlash() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      final newFlashState = !_flashOn;

      await controller.setFlashMode(
        newFlashState ? FlashMode.torch : FlashMode.off,
      );

      if (!mounted) return;

      setState(() {
        _flashOn = newFlashState;
      });
    } catch (e) {
      debugPrint('Flash error: $e');

      if (mounted) {
        _snack('Flash is not available on this camera');
      }
    }
  }

  // ───────────────────────── Capture image ─────────────────────────

  Future<void> _captureImage() async {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      _snack('Camera is not ready yet');
      return;
    }

    try {
      final XFile image = await controller.takePicture();

      debugPrint('Captured image: ${image.path}');

      _scanController.stop();

      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        Navigator.pop(context, image);
      }

      // TODO:
      // Send image.path to your AI injury detection model/API.
    } catch (e) {
      debugPrint('Capture error: $e');

      if (mounted) {
        _snack('Could not capture image');
      }
    }
  }
  Future<void> _openGallery() async {
  try {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (image == null) {
      return;
    }

    debugPrint('Gallery image selected: ${image.path}');

    if (!mounted) return;

    _scanController.stop();

    setState(() {
      _isScanning = false;
    });

    Navigator.pop(context, image);
  } catch (e) {
    debugPrint('Gallery error: $e');

    if (mounted) {
      _snack('Could not open gallery');
    }
  }
}

  // ───────────────────────── Camera preview ─────────────────────────

  Widget _buildCameraPreview() {
    final controller = _cameraController;

    if (!_cameraReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: kPurpleLight,
          ),
        ),
      );
    }

    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return const ColoredBox(
        color: Colors.black,
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  // ───────────────────────── Scanner controls ─────────────────────────

  

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ───────────────────────── Main screen ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // REAL-TIME PHONE CAMERA
          _buildCameraPreview(),

          // Dark scrim
          Container(
            color: Colors.black.withValues(alpha: 0.32),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 4),
                _buildTitleBlock(),
                const SizedBox(height: 14),
                _buildHintBadge(),
                const SizedBox(height: 18),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildScanFrame(),
                  ),
                ),
                const SizedBox(height: 14),
                _buildBottomControls(),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Top bar ─────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassCircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.maybePop(context),
          ),
          _GlassCircleButton(
            icon: _flashOn ? Icons.flash_on : Icons.flash_off,
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Title ─────────────────────────

  Widget _buildTitleBlock() {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            children: [
              TextSpan(
                text: 'AI ',
                style: TextStyle(
                  color: kPurpleLight,
                ),
              ),
              TextSpan(
                text: 'Scanner',
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Scan any stray animal to get\nAI insights and NGO Help',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.35,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Hint badge ─────────────────────────

  Widget _buildHintBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: kPurpleLight,
          ),
          SizedBox(width: 6),
          Text(
            'Position the animal within the frame',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Scanner frame ─────────────────────────

  Widget _buildScanFrame() {
    const cornerLength = 28.0;
    const cornerThickness = 3.5;

    return Stack(
      children: [
        // Four L-shaped viewfinder corners.
        const Positioned(
          top: 0,
          left: 0,
          child: _ScannerCorner(
            length: cornerLength,
            thickness: cornerThickness,
            corner: _Corner.topLeft,
          ),
        ),
        const Positioned(
          top: 0,
          right: 0,
          child: _ScannerCorner(
            length: cornerLength,
            thickness: cornerThickness,
            corner: _Corner.topRight,
          ),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          child: _ScannerCorner(
            length: cornerLength,
            thickness: cornerThickness,
            corner: _Corner.bottomLeft,
          ),
        ),
        const Positioned(
          bottom: 0,
          right: 0,
          child: _ScannerCorner(
            length: cornerLength,
            thickness: cornerThickness,
            corner: _Corner.bottomRight,
          ),
        ),

        // Moving laser line.
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: _scanController,
                builder: (context, _) {
                  final travel = constraints.maxHeight - 40;

                  final top = 20 +
                      (_isScanning
                          ? _scanController.value * travel
                          : travel / 2);

                  return Align(
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: Offset(0, top),
                      child: const _ScanLine(),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Scanning label.
        if (_isScanning)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: kPurpleLight,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Scanning...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────── Bottom controls ─────────────────────────

  Widget _buildBottomControls() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _LabeledIconButton(
        icon: Icons.image_outlined,
        label: 'Gallery',
        onTap: _openGallery,
      ),

      _ScanShutterButton(
        isScanning: _isScanning,
        onTap: _captureImage,
      ),

      _LabeledIconButton(
        icon: Icons.cameraswitch_outlined,
        label: 'Flip Camera',
        onTap: _flipCamera,
      ),
    ],
  );
} // closes _buildBottomControls()

} // ADD THIS — closes _AiScannerScreenState




// ───────────────────────── Glass circle top-bar button ─────────────────────────

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Viewfinder corner bracket ─────────────────────────

enum _Corner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class _ScannerCorner extends StatelessWidget {
  const _ScannerCorner({
    required this.length,
    required this.thickness,
    required this.corner,
  });

  final double length;
  final double thickness;
  final _Corner corner;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          thickness: thickness,
          corner: corner,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.thickness,
    required this.corner,
    required this.color,
  });

  final double thickness;
  final _Corner corner;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;

      case _Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;

      case _Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;

      case _Corner.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return false;
  }
}

// ───────────────────────── Moving scan line ─────────────────────────

class _ScanLine extends StatelessWidget {
  const _ScanLine();

  static const Color kPurpleLight = Color(0xFFB88CE8);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Glow trail above the line.
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                kPurpleLight.withValues(alpha: 0.28),
                kPurpleLight.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),

        // Bright core line.
        Container(
          width: double.infinity,
          height: 2.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                kPurpleLight,
                Colors.white,
                kPurpleLight,
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: kPurpleLight.withValues(alpha: 0.9),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
        ),

        // Glow trail below the line.
        Container(
          width: double.infinity,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kPurpleLight.withValues(alpha: 0.28),
                kPurpleLight.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Bottom control buttons ─────────────────────────

class _LabeledIconButton extends StatelessWidget {
  const _LabeledIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.14),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Scan shutter button ─────────────────────────

class _ScanShutterButton extends StatelessWidget {
  const _ScanShutterButton({
    required this.isScanning,
    required this.onTap,
  });

  static const Color kPurple = Color(0xFF6A3EA1);

  final bool isScanning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.white,
                width: 2.5,
              ),
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8A4FC7),
                  kPurple,
                ],
              ),
            ),
            child: Icon(
              isScanning ? Icons.crop_free : Icons.center_focus_strong,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
