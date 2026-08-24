import 'package:flutter/material.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/profile_screen.dart';
import 'package:straycare_splash/screens/notification_screen.dart';

// ───────────────────────── Models ─────────────────────────

/// AI-estimated priority tier for a case. This mirrors the "AI-based
/// case priority classification" feature: a computer-vision model reads
/// visible injury indicators from the photo, an NLP model reads the
/// reporter's text description, and the two scores are combined into
/// one of these tiers.
enum CasePriority { critical, high, medium, low }

/// Where a case currently sits in the NGO's rescue workflow. This is
/// the "Case status tracking" feature.
enum CaseStatus { newCase, inReview, assigned, resolved }

class RescueCase {
  const RescueCase({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.priority,
    required this.aiConfidence,
    required this.status,
    required this.location,
    required this.distanceKm,
    required this.timeAgo,
    required this.description,
    required this.photoCount,
    this.isDuplicate = false,
    this.duplicateOfId,
  });

  final String id;
  final String title;
  final String imagePath;

  /// Combined vision + NLP priority tier.
  final CasePriority priority;

  /// 0-100 AI confidence score behind the priority tier, e.g. "92%
  /// visible urgency" — shown so NGO reviewers can judge how much to
  /// trust the AI ranking.
  final int aiConfidence;

  final CaseStatus status;
  final String location;
  final double distanceKm;
  final String timeAgo;
  final String description;
  final int photoCount;

  /// "Duplicate report detection" — flags when the image/location/time
  /// similarity model thinks this is the same animal/incident as
  /// another open report.
  final bool isDuplicate;
  final String? duplicateOfId;
}

/// The "View All" destination for Home's Urgent Rescue Cases card, and
/// the RescuePriority NGO dashboard: a full, AI-prioritised, filterable,
/// status-tracked list of every submitted rescue case.
class AllRescueCasesScreen extends StatefulWidget {
  const AllRescueCasesScreen({
    super.key,
    this.onBack,
    this.currentTabIndex = 0,
  });

  final VoidCallback? onBack;
  final int currentTabIndex;

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kCardBorder = Color(0xFFD9C7EA);

  @override
  State<AllRescueCasesScreen> createState() => _AllRescueCasesScreenState();
}

enum _DashboardFilter { all, critical, inReview, duplicates, resolved }

class _AllRescueCasesScreenState extends State<AllRescueCasesScreen> {
  _DashboardFilter _filter = _DashboardFilter.all;

  static const List<RescueCase> _cases = [
    RescueCase(
      id: 'RC-2025-0156',
      title: 'Injured Dog',
      imagePath: 'assets/images/InjuredDog.jpeg',
      priority: CasePriority.critical,
      aiConfidence: 94,
      status: CaseStatus.inReview,
      location: 'Bandra, Mumbai',
      distanceKm: 1.2,
      timeAgo: '12 min ago',
      description: 'Dog with leg injury, unable to walk properly.',
      photoCount: 3,
    ),
    RescueCase(
      id: 'RC-2025-0157',
      title: 'Injured Dog (possible duplicate)',
      imagePath: 'assets/images/InjuredDog.jpeg',
      priority: CasePriority.critical,
      aiConfidence: 91,
      status: CaseStatus.newCase,
      location: 'Bandra, Mumbai',
      distanceKm: 1.3,
      timeAgo: '9 min ago',
      description: 'Dog with leg injury near the same junction, limping.',
      photoCount: 2,
      isDuplicate: true,
      duplicateOfId: 'RC-2025-0156',
    ),
    RescueCase(
      id: 'RC-2025-0123',
      title: 'Sick Cat',
      imagePath: 'assets/images/sickcat.jpeg',
      priority: CasePriority.high,
      aiConfidence: 82,
      status: CaseStatus.assigned,
      location: 'Santacruz, Mumbai',
      distanceKm: 2.4,
      timeAgo: '34 min ago',
      description: 'Cat looks weak and not eating since yesterday.',
      photoCount: 2,
    ),
    RescueCase(
      id: 'RC-2025-0140',
      title: 'Rabbit – Skin Infection',
      imagePath: 'assets/images/rabbit .png',
      priority: CasePriority.medium,
      aiConfidence: 68,
      status: CaseStatus.newCase,
      location: 'Khar, Mumbai',
      distanceKm: 2.7,
      timeAgo: '1 hr ago',
      description: 'Visible skin infection and hair loss. Needs treatment.',
      photoCount: 1,
    ),
    RescueCase(
      id: 'RC-2025-0138',
      title: 'Abandoned Kitten',
      imagePath: 'assets/images/abondened kitten.png',
      priority: CasePriority.medium,
      aiConfidence: 61,
      status: CaseStatus.inReview,
      location: 'Bandra East, Mumbai',
      distanceKm: 3.1,
      timeAgo: '2 hr ago',
      description: 'Small kitten seen alone near the garbage area.',
      photoCount: 2,
    ),
    RescueCase(
      id: 'RC-2025-0178',
      title: 'Injured Dog',
      imagePath: 'assets/images/injured dog.png',
      priority: CasePriority.critical,
      aiConfidence: 97,
      status: CaseStatus.assigned,
      location: 'Mahim, Mumbai',
      distanceKm: 3.5,
      timeAgo: '2 hr 30 min ago',
      description: 'Hit by vehicle. Bleeding from mouth.',
      photoCount: 1,
    ),
    RescueCase(
      id: 'RC-2025-0099',
      title: 'Stray Dog Recovering',
      imagePath: 'assets/images/InjuredDog.jpeg',
      priority: CasePriority.low,
      aiConfidence: 34,
      status: CaseStatus.resolved,
      location: 'Andheri, Mumbai',
      distanceKm: 4.6,
      timeAgo: '1 day ago',
      description: 'Follow-up visit done, wound healing well.',
      photoCount: 1,
    ),
  ];

  List<RescueCase> get _filtered {
    switch (_filter) {
      case _DashboardFilter.all:
        return _cases;
      case _DashboardFilter.critical:
        return _cases.where((c) => c.priority == CasePriority.critical).toList();
      case _DashboardFilter.inReview:
        return _cases.where((c) => c.status == CaseStatus.inReview).toList();
      case _DashboardFilter.duplicates:
        return _cases.where((c) => c.isDuplicate).toList();
      case _DashboardFilter.resolved:
        return _cases.where((c) => c.status == CaseStatus.resolved).toList();
    }
  }

  void _handleNavTap(BuildContext context, int index) {
    if (index == widget.currentTabIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportRescueScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiScannerScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyReportsScreen()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _cases.length;
    final critical =
        _cases.where((c) => c.priority == CasePriority.critical).length;
    final inReview =
        _cases.where((c) => c.status == CaseStatus.inReview).length;
    final duplicates = _cases.where((c) => c.isDuplicate).length;

    return Scaffold(
      backgroundColor: AllRescueCasesScreen.kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onBack: widget.onBack ?? () => Navigator.maybePop(context),
              onNotifications: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _DashboardStatsStrip(
              total: total,
              critical: critical,
              inReview: inReview,
              duplicates: duplicates,
            ),
            const SizedBox(height: 12),
            _FilterTabs(
              selected: _filter,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filtered.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                      itemCount: _filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _RescueCaseCard(
                          rescueCase: _filtered[index],
                          onTap: () => _showCaseDetail(context, _filtered[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StrayCareBottomNav(
        currentIndex: widget.currentTabIndex,
        onTap: (index) => _handleNavTap(context, index),
      ),
    );
  }

  void _showCaseDetail(BuildContext context, RescueCase rescueCase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CaseDetailSheet(rescueCase: rescueCase),
    );
  }
}

// ───────────────────────── Top bar ─────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onNotifications});

  final VoidCallback onBack;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.only(top: 4, right: 10),
              child: Icon(
                Icons.arrow_back,
                color: AllRescueCasesScreen.kDeepPurple,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Rescue Cases',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AllRescueCasesScreen.kDeepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'AI-prioritised for faster action',
                  style: TextStyle(
                    fontSize: 13,
                    color: AllRescueCasesScreen.kSubtitleGray,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onNotifications,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AllRescueCasesScreen.kCardBorder,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AllRescueCasesScreen.kDeepPurple,
                    size: 20,
                  ),
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: const BoxDecoration(
                      color: AllRescueCasesScreen.kPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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

// ───────────────────────── Dashboard stats ─────────────────────────

class _DashboardStatsStrip extends StatelessWidget {
  const _DashboardStatsStrip({
    required this.total,
    required this.critical,
    required this.inReview,
    required this.duplicates,
  });

  final int total;
  final int critical;
  final int inReview;
  final int duplicates;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        icon: Icons.pets,
        value: '$total',
        label: 'Total Cases',
        color: AllRescueCasesScreen.kPurple,
      ),
      (
        icon: Icons.warning_amber_rounded,
        value: '$critical',
        label: 'Critical',
        color: const Color(0xFFE0524B),
      ),
      (
        icon: Icons.hourglass_bottom_rounded,
        value: '$inReview',
        label: 'In Review',
        color: const Color(0xFFE8A23D),
      ),
      (
        icon: Icons.content_copy_rounded,
        value: '$duplicates',
        label: 'Duplicates',
        color: AllRescueCasesScreen.kDeepPurple,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFE1F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AllRescueCasesScreen.kCardBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 46,
                color: const Color(0xFFC9AFDA),
              ),
            Expanded(
              child: Column(
                children: [
                  Icon(stats[i].icon, color: stats[i].color, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    stats[i].value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AllRescueCasesScreen.kDeepPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats[i].label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AllRescueCasesScreen.kSubtitleGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── Filter tabs ─────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final _DashboardFilter selected;
  final void Function(_DashboardFilter) onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = {
      _DashboardFilter.all: 'All',
      _DashboardFilter.critical: 'Critical',
      _DashboardFilter.inReview: 'In Review',
      _DashboardFilter.duplicates: 'Duplicates',
      _DashboardFilter.resolved: 'Resolved',
    };

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final entry in labels.entries) ...[
            _FilterChip(
              label: entry.value,
              isSelected: selected == entry.key,
              onTap: () => onSelected(entry.key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AllRescueCasesScreen.kPurple : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AllRescueCasesScreen.kPurple
                  : AllRescueCasesScreen.kCardBorder,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : AllRescueCasesScreen.kDeepPurple,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Case card ─────────────────────────

({Color bg, Color text, String label}) _priorityStyle(CasePriority p) {
  switch (p) {
    case CasePriority.critical:
      return (
        bg: const Color(0xFFFCE1E1),
        text: const Color(0xFFE0524B),
        label: 'Critical'
      );
    case CasePriority.high:
      return (
        bg: const Color(0xFFFBEAD6),
        text: const Color(0xFFE8A23D),
        label: 'High'
      );
    case CasePriority.medium:
      return (
        bg: const Color(0xFFFBEAD6),
        text: const Color(0xFFE8A23D),
        label: 'Medium'
      );
    case CasePriority.low:
      return (
        bg: const Color(0xFFE1F3E3),
        text: const Color(0xFF3FAE5C),
        label: 'Low'
      );
  }
}

({Color bg, Color text, String label, IconData icon}) _statusStyle(CaseStatus s) {
  switch (s) {
    case CaseStatus.newCase:
      return (
        bg: const Color(0xFFDCEBFB),
        text: const Color(0xFF3E8FD9),
        label: 'New',
        icon: Icons.fiber_new_rounded
      );
    case CaseStatus.inReview:
      return (
        bg: const Color(0xFFFBEAD6),
        text: const Color(0xFFE8A23D),
        label: 'In Review',
        icon: Icons.visibility_outlined
      );
    case CaseStatus.assigned:
      return (
        bg: const Color(0xFFEBE0F7),
        text: AllRescueCasesScreen.kPurple,
        label: 'Assigned',
        icon: Icons.groups_outlined
      );
    case CaseStatus.resolved:
      return (
        bg: const Color(0xFFDFF4E4),
        text: const Color(0xFF3FAE5C),
        label: 'Resolved',
        icon: Icons.check_circle_outline
      );
  }
}

class _RescueCaseCard extends StatelessWidget {
  const _RescueCaseCard({required this.rescueCase, required this.onTap});

  final RescueCase rescueCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priority = _priorityStyle(rescueCase.priority);
    final status = _statusStyle(rescueCase.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: rescueCase.isDuplicate
                  ? const Color(0xFFE8A23D)
                  : AllRescueCasesScreen.kCardBorder,
              width: rescueCase.isDuplicate ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rescueCase.isDuplicate)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEAD6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.content_copy_rounded,
                          size: 13,
                          color: Color(0xFFE8A23D),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rescueCase.duplicateOfId != null
                                ? 'Possible duplicate of ${rescueCase.duplicateOfId}'
                                : 'Possible duplicate report',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFAD7422),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          rescueCase.imagePath,
                          // Updated: wider and less tall, with BoxFit.cover
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 100,
                            height: 100,
                            color: const Color(0xFFF1E7F7),
                            child: const Icon(
                              Icons.pets,
                              color: AllRescueCasesScreen.kPurple,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AllRescueCasesScreen.kPurple.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                '${rescueCase.photoCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rescueCase.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: AllRescueCasesScreen.kDeepPurple,
                                ),
                              ),
                            ),
                            Text(
                              '${rescueCase.distanceKm} km',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AllRescueCasesScreen.kPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Pill(
                              bg: priority.bg,
                              text: priority.text,
                              icon: Icons.bolt_rounded,
                              label:
                                  '${priority.label} · ${rescueCase.aiConfidence}%',
                            ),
                            _Pill(
                              bg: status.bg,
                              text: status.text,
                              icon: status.icon,
                              label: status.label,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: AllRescueCasesScreen.kSubtitleGray,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${rescueCase.location} • ${rescueCase.timeAgo}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AllRescueCasesScreen.kSubtitleGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rescueCase.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF4A4152),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.bg,
    required this.text,
    required this.icon,
    required this.label,
  });

  final Color bg;
  final Color text;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Empty state ─────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets,
              size: 40,
              color: AllRescueCasesScreen.kCardBorder,
            ),
            SizedBox(height: 12),
            Text(
              'No cases in this filter',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AllRescueCasesScreen.kDeepPurple,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try a different filter to see more cases.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AllRescueCasesScreen.kSubtitleGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Case detail sheet ─────────────────────────

class _CaseDetailSheet extends StatelessWidget {
  const _CaseDetailSheet({required this.rescueCase});

  final RescueCase rescueCase;

  @override
  Widget build(BuildContext context) {
    final priority = _priorityStyle(rescueCase.priority);
    final status = _statusStyle(rescueCase.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7DBF2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                rescueCase.imagePath,
                // Updated: slightly shorter height, still full width, BoxFit.cover
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 180,
                  color: const Color(0xFFF1E7F7),
                  child: const Icon(
                    Icons.pets,
                    color: AllRescueCasesScreen.kPurple,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              rescueCase.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AllRescueCasesScreen.kDeepPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Case ${rescueCase.id}',
              style: const TextStyle(
                fontSize: 12,
                color: AllRescueCasesScreen.kSubtitleGray,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  bg: priority.bg,
                  text: priority.text,
                  icon: Icons.bolt_rounded,
                  label:
                      'AI Priority: ${priority.label} (${rescueCase.aiConfidence}%)',
                ),
                _Pill(
                  bg: status.bg,
                  text: status.text,
                  icon: status.icon,
                  label: status.label,
                ),
                if (rescueCase.isDuplicate)
                  const _Pill(
                    bg: Color(0xFFFBEAD6),
                    text: Color(0xFFAD7422),
                    icon: Icons.content_copy_rounded,
                    label: 'Flagged as duplicate',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              rescueCase.description,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF4A4152),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 14, color: AllRescueCasesScreen.kSubtitleGray),
                const SizedBox(width: 4),
                Text(
                  '${rescueCase.location} • ${rescueCase.distanceKm} km • ${rescueCase.timeAgo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AllRescueCasesScreen.kSubtitleGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // If the case is already assigned to a rescue team, only show
            // a full-width Close button — the Assign action is omitted.
            if (rescueCase.status == CaseStatus.assigned)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AllRescueCasesScreen.kPurple,
                    side: const BorderSide(
                        color: AllRescueCasesScreen.kCardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AllRescueCasesScreen.kPurple,
                        side: const BorderSide(
                            color: AllRescueCasesScreen.kCardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AllRescueCasesScreen.kPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Assign to Rescue Team'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}