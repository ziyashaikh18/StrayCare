import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// StrayCare "Report Submitted Successfully" confirmation screen.
///
/// Shown after the user finishes submitting a rescue report. Displays the
/// generated report ID, a summary of what was submitted, a "what happens
/// next" status timeline, and quick follow-up actions.
class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({
    super.key,
    required this.reportId,
    required this.animalType,
    required this.location,
    required this.submittedAt,
    this.photoPath,
    this.priorityScore,
    this.priorityLabel = 'High',
    this.onViewMyReports,
    this.onSubmitAnother,
    this.onShareReport,
  }) : notificationBadgeCount = 3;

  final String reportId;
  final String animalType;
  final String location;
  final DateTime submittedAt;
  final String? photoPath;

  /// 0–100 urgency score shown next to the priority badge. If null, only
  /// the label badge is shown.
  final int? priorityScore;
  final String priorityLabel;

  final VoidCallback? onViewMyReports;
  final VoidCallback? onSubmitAnother;
  final VoidCallback? onShareReport;

  final int notificationBadgeCount;

  static const Color kBackground = Color(0xFFF6F1FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kBorderPurple = Color(0xFFE3D6EE);
  static const Color kGreen = Color(0xFF2E9E5B);
  static const Color kGreenBg = Color(0xFFE7F6ED);
  static const Color kOrange = Color(0xFFE0A030);
  static const Color kOrangeBg = Color(0xFFFBEEDA);

  Color get _priorityColor {
    switch (priorityLabel.toLowerCase()) {
      case 'high':
        return kOrange;
      case 'medium':
        return const Color(0xFFCC8B2E);
      default:
        return kGreen;
    }
  }

  Color get _priorityBg {
    switch (priorityLabel.toLowerCase()) {
      case 'high':
        return kOrangeBg;
      default:
        return kOrangeBg;
    }
  }

  String get _formattedSubmittedAt {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = submittedAt.hour % 12 == 0 ? 12 : submittedAt.hour % 12;
    final minute = submittedAt.minute.toString().padLeft(2, '0');
    final period = submittedAt.hour >= 12 ? 'PM' : 'AM';
    return '${submittedAt.day} ${months[submittedAt.month - 1]} '
        '${submittedAt.year} \u2022 $hour12:$minute $period';
  }

  void _copyReportId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: reportId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report ID copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareReport(BuildContext context) {
    if (onShareReport != null) {
      onShareReport!();
      return;
    }
    // TODO: wire up a real share sheet (e.g. via the share_plus package):
    //   Share.share('StrayCare report $reportId — help a $animalType at $location');
    Clipboard.setData(
      ClipboardData(text: 'StrayCare report $reportId — $animalType at $location'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report details copied to share'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _backToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: [
                  _buildSuccessCard(context),
                  const SizedBox(height: 14),
                  _buildReportSummaryCard(context),
                  const SizedBox(height: 14),
                  _buildWhatsNextCard(),
                  const SizedBox(height: 14),
                  _buildYouCanAlsoSection(context),
                ],
              ),
            ),
            _buildBackToHomeButton(context),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Header ─────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.maybePop(context),
          ),
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, color: kPurple, size: 20),
                SizedBox(width: 6),
                Text(
                  'StrayCare',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CircleButton(icon: Icons.notifications_none, onTap: () {}),
              if (notificationBadgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0435B),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$notificationBadgeCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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

  // ───────────────────────── Success card ─────────────────────────

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: kGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFE6CE)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Report Submitted Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: kDeepPurple,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thank you for helping animals in need.\n'
            'Our partner NGO has been notified.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: kSubtitleGray, height: 1.4),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text(
                  'REPORT ID',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: kSubtitleGray,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      reportId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kGreen,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _copyReportId(context),
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.copy, size: 16, color: kSubtitleGray),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Report summary ─────────────────────────

  Widget _buildReportSummaryCard(BuildContext context) {
    return _WhiteCard(
      title: 'REPORT SUMMARY',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhotoThumb(context),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(icon: Icons.pets, label: 'Animal', value: animalType),
                const SizedBox(height: 10),
                _SummaryRow(icon: Icons.location_on_outlined, label: 'Location', value: location),
                const SizedBox(height: 10),
                _SummaryRow(icon: Icons.access_time, label: 'Submitted On', value: _formattedSubmittedAt),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: kOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority Score', style: TextStyle(fontSize: 11.5, color: kSubtitleGray)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (priorityScore != null) ...[
                                Text(
                                  '$priorityScore',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kOrange,
                                  ),
                                ),
                                const Text('/100', style: TextStyle(fontSize: 11, color: kSubtitleGray)),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _priorityBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  priorityLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: _priorityColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(BuildContext context) {
    final path = photoPath;
    final hasPhoto = path != null && File(path).existsSync();

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: hasPhoto
              ? Image.file(File(path), width: 92, height: 132, fit: BoxFit.cover)
              : Container(
                  width: 92,
                  height: 132,
                  color: const Color(0xFFF1E9FA),
                  child: const Icon(Icons.pets, color: kPurple),
                ),
        ),
        if (hasPhoto)
          Positioned(
            right: 6,
            bottom: 6,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showFullPhoto(context, path),
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_in_full, size: 13, color: kDeepPurple),
              ),
            ),
          ),
      ],
    );
  }

  void _showFullPhoto(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  // ───────────────────────── What happens next ─────────────────────────

  Widget _buildWhatsNextCard() {
    final steps = [
      ('Submitted', Icons.check, true, _formattedSubmittedAt.split('\u2022').last.trim()),
      ('NGO Notified', Icons.notifications_none, true, 'Just now'),
      ('NGO Contacting', Icons.phone_outlined, false, 'Soon'),
      ('Rescue In Progress', Icons.local_shipping_outlined, false, 'Pending'),
      ('Resolved', Icons.favorite_border, false, 'Pending'),
    ];

    return _WhiteCard(
      title: 'WHAT HAPPENS NEXT?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: _TimelineStep(
                    icon: steps[i].$2,
                    active: steps[i].$3,
                  ),
                ),
                if (i != steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: (steps[i].$3 && steps[i + 1].$3)
                          ? kGreen
                          : kBorderPurple,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final step in steps)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        step.$1,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: step.$3 ? kGreen : kSubtitleGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.$4,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 8.5, color: kSubtitleGray),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kGreenBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFE6CE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 13),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'You will receive updates and notifications as this case progresses.',
                    style: TextStyle(fontSize: 12, color: kDeepPurple, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── You can also ─────────────────────────

  Widget _buildYouCanAlsoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'YOU CAN ALSO',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: kSubtitleGray,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.description_outlined,
                title: 'View My Reports',
                subtitle: 'Track all your reports',
                onTap: onViewMyReports ?? () => Navigator.maybePop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.add,
                title: 'Submit Another',
                subtitle: 'Report another case',
                onTap: onSubmitAnother ??
                    () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionCard(
                icon: Icons.share_outlined,
                title: 'Share Report',
                subtitle: 'Spread the word',
                onTap: () => _shareReport(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────── Back to home ─────────────────────────

  Widget _buildBackToHomeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _backToHome(context),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFE0435B), kPurple],
              ),
              boxShadow: [
                BoxShadow(
                  color: kPurple.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Back to Home',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Shared small widgets ─────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF6A3EA1), size: 20),
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6A3EA1).withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF6A3EA1),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1E9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF6A3EA1)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8D8398))),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E1A47)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  static const Color kGreen = Color(0xFF2E9E5B);
  static const Color kBorderPurple = Color(0xFFE3D6EE);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? kGreen : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: active ? kGreen : kBorderPurple, width: 1.6),
      ),
      child: Icon(icon, size: 15, color: active ? Colors.white : const Color(0xFF8D8398)),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3D6EE)),
          ),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF6A3EA1)),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF2E1A47)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 9.5, color: Color(0xFF8D8398)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}