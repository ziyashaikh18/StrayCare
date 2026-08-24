import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'notification_screen.dart';

/// StrayCare "AI Analysis & Priority" screen — runs AFTER the report form
/// (photos + animal type + condition + behavior + description) and BEFORE
/// final submission.
///
/// Layout mirrors the RescuePriority-style reference:
/// photo + priority gauge -> image/text analysis split -> overall priority
/// bar -> duplicate check -> [Edit Report] [Submit to NGO]
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<AiAnalysisResult>(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AiAnalysisScreen(
///       photos: _photos,
///       animalType: _animalType,
///       condition: _condition,
///       behaviors: _behaviors,
///       description: _descriptionController.text,
///       location: _locationController.text,
///       dateLabel: _formattedDate,
///       timeLabel: _formattedTime,
///     ),
///   ),
/// );
/// // result == null -> user tapped "Edit Report" and popped back to the
/// //   report form (this screen does nothing else, no changes are lost
/// //   since it's just Navigator.pop()).
/// // result != null -> user tapped "Submit to NGO"; hand result off to
/// //   your submit/Review flow.
/// ```
class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({
    super.key,
    required this.photos,
    required this.animalType,
    required this.condition,
    required this.behaviors,
    required this.description,
    required this.location,
    this.dateLabel,
    this.timeLabel,
    this.distanceLabel,
  });

  final List<XFile> photos;
  final String animalType;
  final String condition;
  final Set<String> behaviors;
  final String description;
  final String location;
  final String? dateLabel;
  final String? timeLabel;
  final String? distanceLabel;

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

enum AiPriority { critical, high, medium, low }

class AiAnalysisResult {
  const AiAnalysisResult({
    required this.priority,
    required this.score,
    required this.imageFindings,
    required this.imageSeverity,
    required this.textFindings,
    required this.textSeverity,
    required this.duplicateFound,
  });

  final AiPriority priority;
  final int score; // 0-100
  final List<String> imageFindings;
  final AiPriority imageSeverity;
  final List<String> textFindings;
  final AiPriority textSeverity;
  final bool duplicateFound;
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen>
    with SingleTickerProviderStateMixin {
  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kLightPurple = Color(0xFFF1E9FA);
  static const Color kBorderPurple = Color(0xFFDCCBE8);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kOrange = Color(0xFFE8A23D);
  static const Color kBlue = Color(0xFF1565C0);
  static const Color kGreen = Color(0xFF2E7D32);

  late final AnimationController _gaugeController;
  bool _analyzing = true;
  AiAnalysisResult? _result;

  @override
  void initState() {
    super.initState();

    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _runAnalysis();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  // ───────────────────────── Analysis (replace with real model/API call) ─────

  Future<void> _runAnalysis() async {
    // TODO: Replace with a real call — upload widget.photos.first to your
    // computer-vision model, run NLP on the description/behavior fields,
    // and check for duplicates against recent reports in your backend.
    // Map the response into an AiAnalysisResult below.
    await Future.delayed(const Duration(milliseconds: 1600));

    final result = _computeHeuristicResult();

    if (!mounted) return;

    setState(() {
      _result = result;
      _analyzing = false;
    });

    _gaugeController.forward(from: 0);
  }

  /// Local heuristic placeholder splitting "image" and "text" analysis,
  /// used until a real model/API is wired in.
  AiAnalysisResult _computeHeuristicResult() {
    // ---- Image analysis (based on condition + photo presence) ----
    final imageFindings = <String>[];
    int imageScore = 0;

    if (widget.photos.isNotEmpty) {
      switch (widget.condition) {
        case 'Injured':
          imageScore += 3;
          imageFindings.add('Visible wounds detected on face and body.');
          imageFindings.add('Signs of injury and possible infection.');
          break;
        case 'Sick':
          imageScore += 2;
          imageFindings.add('Animal appears lethargic in the photo.');
          break;
        case 'Weak':
          imageScore += 3;
          imageFindings.add('Animal appears unable to move.');
          break;
        default:
          imageScore += 1;
          imageFindings.add('No obvious visible injury detected.');
      }
    } else {
      imageFindings.add('No photo provided for visual analysis.');
    }

    // ---- Text analysis (based on description + behavior) ----
    final textFindings = <String>[];
    int textScore = 0;
    final desc = widget.description.toLowerCase();

    if (widget.condition == 'Injured') {
      textScore += 2;
      textFindings.add('Report mentions injury.');
    }
    if (widget.behaviors.contains('Unable to move')) {
      textScore += 3;
      textFindings.add('Report indicates animal is unable to move.');
    }
    final painWords = ['pain', 'bleed', 'blood', 'wound', 'hit', 'accident'];
    if (painWords.any(desc.contains)) {
      textScore += 2;
      textFindings.add('Description language suggests pain or trauma.');
    }
    if (widget.behaviors.contains('Scared')) {
      textScore += 1;
      textFindings.add('Animal shows signs of fear or distress.');
    }
    if (widget.behaviors.contains('Aggressive')) {
      textScore += 1;
      textFindings.add('Animal may be defensive — approach with caution.');
    }
    if (textFindings.isEmpty) {
      textFindings.add('No urgent keywords detected in the description.');
    } else {
      textFindings.add('Indicates urgent help required.');
    }

    final imageSeverity = _severityFromScore(imageScore);
    final textSeverity = _severityFromScore(textScore);

    final combined = (imageScore * 1.0 + textScore * 1.0);
    const maxPossible = 11.0; // rough ceiling for normalization
    final score = (55 + (combined / maxPossible) * 45).clamp(0, 100).round();

    final priority = _priorityFromScore(score);

    return AiAnalysisResult(
      priority: priority,
      score: score,
      imageFindings: imageFindings,
      imageSeverity: imageSeverity,
      textFindings: textFindings,
      textSeverity: textSeverity,
      // TODO: replace with a real backend duplicate-report check.
      duplicateFound: false,
    );
  }

  AiPriority _severityFromScore(int score) {
    if (score >= 5) return AiPriority.critical;
    if (score >= 3) return AiPriority.high;
    if (score >= 1) return AiPriority.medium;
    return AiPriority.low;
  }

  AiPriority _priorityFromScore(int score) {
    if (score >= 80) return AiPriority.critical;
    if (score >= 60) return AiPriority.high;
    if (score >= 35) return AiPriority.medium;
    return AiPriority.low;
  }

  // ───────────────────────── Priority styling ─────────────────────────

  Color _priorityColor(AiPriority priority) {
    switch (priority) {
      case AiPriority.critical:
        return kPink;
      case AiPriority.high:
        return kOrange;
      case AiPriority.medium:
        return kBlue;
      case AiPriority.low:
        return kGreen;
    }
  }

  String _priorityLabel(AiPriority priority) {
    switch (priority) {
      case AiPriority.critical:
        return 'CRITICAL';
      case AiPriority.high:
        return 'HIGH';
      case AiPriority.medium:
        return 'MEDIUM';
      case AiPriority.low:
        return 'LOW';
    }
  }

  String _priorityHint(AiPriority priority) {
    switch (priority) {
      case AiPriority.critical:
        return 'Immediate attention needed';
      case AiPriority.high:
        return 'Prompt attention recommended';
      case AiPriority.medium:
        return 'Follow-up recommended';
      case AiPriority.low:
        return 'Low urgency, routine review';
    }
  }

  String _severityLabel(AiPriority p) {
    switch (p) {
      case AiPriority.critical:
      case AiPriority.high:
        return 'High Severity';
      case AiPriority.medium:
        return 'Medium Severity';
      case AiPriority.low:
        return 'Low Severity';
    }
  }

  // ───────────────────────── Meta fallbacks ─────────────────────────
  // If the caller (report_screen.dart) doesn't pass dateLabel/timeLabel,
  // fall back to "now" instead of showing a blank/dash. For an accurate
  // "found at" time, pass dateLabel/timeLabel explicitly when navigating
  // here, e.g.:
  //   AiAnalysisScreen(
  //     ...,
  //     dateLabel: _formattedDate,
  //     timeLabel: _formattedTime,
  //   )

  String _resolvedTimeLabel(BuildContext context) {
    if (widget.timeLabel != null && widget.timeLabel!.trim().isNotEmpty) {
      return widget.timeLabel!;
    }
    return TimeOfDay.now().format(context);
  }

  String _resolvedDateLabel() {
    if (widget.dateLabel != null && widget.dateLabel!.trim().isNotEmpty) {
      return widget.dateLabel!;
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // ───────────────────────── Actions ─────────────────────────

  /// Pops back to the report screen (previous page in the stack).
  /// No result is passed, so nothing is submitted — the report form
  /// keeps whatever the user already entered.
  void _editReport() {
    Navigator.pop(context);
  }

  void _submitToNgo() {
    if (_result == null) return;
    Navigator.pop(context, _result);
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    _analyzing ? _buildAnalyzingState() : _buildResultState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Top bar ─────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back,
            onTap: _analyzing ? null : _editReport,
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/images/logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.pets,
                color: kPurple,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'StrayCare',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: kDeepPurple,
            ),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CircleButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                    color: kPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Analyzing state ─────────────────────────

  Widget _buildAnalyzingState() {
    return Center(
      key: const ValueKey('analyzing'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.photos.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(widget.photos.first.path),
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                color: kPurple,
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Analyzing photo & report…',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: kDeepPurple,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Running computer vision and NLP\nto calculate priority score',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: kSubtitleGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Result state ─────────────────────────

  Widget _buildResultState() {
    final result = _result!;

    return SingleChildScrollView(
      key: const ValueKey('result'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBlock(),
          const SizedBox(height: 14),
          _buildPhotoAndGaugeCard(result),
          const SizedBox(height: 14),
          _buildAnalysisSummaryHeader(),
          const SizedBox(height: 10),
          _buildAnalysisSplitCards(result),
          const SizedBox(height: 12),
          _buildOverallPriorityCard(result),
          const SizedBox(height: 12),
          _buildDuplicateCheckCard(result),
          const SizedBox(height: 18),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: kDeepPurple,
              letterSpacing: -0.2,
            ),
            children: [
              TextSpan(text: '✨ AI Analysis & '),
              TextSpan(
                text: 'Priority',
                style: TextStyle(color: kPink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Our AI has analyzed the image and your report',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: kSubtitleGray,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoAndGaugeCard(AiAnalysisResult result) {
    final color = _priorityColor(result.priority);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorderPurple),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.photos.isNotEmpty
                            ? Image.file(
                                File(widget.photos.first.path),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: kLightPurple,
                                child: const Icon(
                                  Icons.pets,
                                  color: kPurple,
                                  size: 36,
                                ),
                              ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_full,
                              size: 13,
                              color: kDeepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: _buildGauge(result),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _priorityLabel(result.priority),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _priorityHint(result.priority),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: kSubtitleGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetaChip(
                  icon: Icons.location_on_outlined,
                  primary: widget.location.isEmpty
                      ? 'Location not set'
                      : widget.location,
                  secondary: widget.distanceLabel,
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: kBorderPurple,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              Expanded(
                child: _MetaChip(
                  icon: Icons.access_time,
                  primary: widget.timeLabel ?? '—',
                  secondary: widget.dateLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(AiAnalysisResult result) {
    final color = _priorityColor(result.priority);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'PRIORITY SCORE',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: kSubtitleGray,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _gaugeController,
          builder: (context, child) {
            final animatedScore = result.score * _gaugeController.value;
            return SizedBox(
              width: double.infinity,
              height: 82,
              child: CustomPaint(
                painter: _GaugePainter(
                  score: animatedScore,
                  color: color,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${animatedScore.round()}',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: color,
                              height: 1,
                            ),
                          ),
                          const TextSpan(
                            text: ' /100',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kSubtitleGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalysisSummaryHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kPurple),
          ),
          child: const Text(
            'AI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: kPurple,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'AI ANALYSIS SUMMARY',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: kDeepPurple,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisSplitCards(AiAnalysisResult result) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _AnalysisCard(
              icon: Icons.image_outlined,
              title: 'Image Analysis',
              subtitle: '(Computer Vision)',
              severityLabel: _severityLabel(result.imageSeverity),
              severityColor: _priorityColor(result.imageSeverity),
              findings: result.imageFindings,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _AnalysisCard(
              icon: Icons.description_outlined,
              title: 'Text Analysis',
              subtitle: '(NLP)',
              severityLabel: _severityLabel(result.textSeverity),
              severityColor: _priorityColor(result.textSeverity),
              findings: result.textFindings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallPriorityCard(AiAnalysisResult result) {
    final color = _priorityColor(result.priority);
    const totalSegments = 15;
    final filledSegments = ((result.score / 100) * totalSegments).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderPurple),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Priority',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Combined analysis of\nimage and report text',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: kSubtitleGray,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _priorityLabel(result.priority),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${result.score}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const TextSpan(
                      text: '/100',
                      style: TextStyle(
                        fontSize: 11,
                        color: kSubtitleGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < totalSegments; i++)
                    Container(
                      width: 4,
                      height: 12,
                      margin: const EdgeInsets.only(left: 1.5),
                      decoration: BoxDecoration(
                        color: i < filledSegments
                            ? color
                            : const Color(0xFFE9E1EE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateCheckCard(AiAnalysisResult result) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderPurple),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: kPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duplicate Check',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'We compared this report\nwith recent reports.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: kSubtitleGray,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (!result.duplicateFound)
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: kGreen, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'No Duplicates Found',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: kGreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'This report appears\nto be unique.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 10,
                    color: kSubtitleGray,
                    height: 1.2,
                  ),
                ),
              ],
            )
          else
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: kOrange, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Similar Report Found',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: kOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _editReport,
            icon: const Icon(Icons.edit_outlined, color: kPurple, size: 17),
            label: const Text(
              'Edit Report',
              style: TextStyle(
                color: kPurple,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: kPurple, width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _submitToNgo,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [kPink, kPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPurple.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Submit to NGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Small shared widgets ─────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kBorderPurple = Color(0xFFDCCBE8);

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kBorderPurple),
          ),
          child: Icon(
            icon,
            color: enabled ? kPurple : kSubtitleGray,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.primary,
    this.secondary,
  });

  final IconData icon;
  final String primary;
  final String? secondary;

  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kSubtitleGray = Color(0xFF8D8398);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: kPurple),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: kDeepPurple,
                ),
              ),
              if (secondary != null)
                Text(
                  secondary!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kSubtitleGray,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.severityLabel,
    required this.severityColor,
    required this.findings,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String severityLabel;
  final Color severityColor;
  final List<String> findings;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kLightPurple = Color(0xFFF1E9FA);
  static const Color kBorderPurple = Color(0xFFDCCBE8);
  static const Color kSubtitleGray = Color(0xFF8D8398);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderPurple),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kLightPurple,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: kPurple, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: kDeepPurple,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: kPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              severityLabel,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: severityColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final finding in findings)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                finding,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: kSubtitleGray,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Semi-circular "rainbow" gauge painter, background track + colored fill
/// proportional to [score] (0-100), with a knob at the end of the fill.
class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.score,
    required this.color,
  });

  final double score;
  final Color color;

  static const Color kTrack = Color(0xFFEFE7F6);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.height * 0.14;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      (size.height - strokeWidth / 2) * 2 - strokeWidth,
    );

    const startAngle = math.pi; // 180°, left
    const sweepMax = math.pi; // half circle, ends at 360°/0°, over the top

    final trackPaint = Paint()
      ..color = kTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepMax, false, trackPaint);

    final fillSweep = sweepMax * (score.clamp(0, 100) / 100);

    final fillPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepMax,
        colors: [color.withValues(alpha: 0.75), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, fillSweep, false, fillPaint);

    // Knob at the end of the fill arc.
    final endAngle = startAngle + fillSweep;
    final radius = rect.width / 2;
    final center = rect.center;
    final knobCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    final knobBorder = Paint()..color = color;
    final knobFill = Paint()..color = Colors.white;

    canvas.drawCircle(knobCenter, strokeWidth * 0.42, knobBorder);
    canvas.drawCircle(knobCenter, strokeWidth * 0.24, knobFill);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
