import 'package:flutter/material.dart';
import 'package:straycare_splash/screens/profile_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

// ═══════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════

enum ReportPriority { critical, high, medium, low }

enum ReportStatus { inProgress, resolved, closed }

@immutable
class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.location,
    required this.distanceKm,
    required this.dateTime,
    this.photoCount = 0,
    this.image,
  });

  final String id;
  final String title;
  final ReportPriority priority;
  final ReportStatus status;
  final String location;
  final double distanceKm;
  final DateTime dateTime;
  final int photoCount;

  /// Pass e.g. FileImage(File(photo.path)) for a locally-taken photo, or
  /// NetworkImage(url) once reports are synced from a backend. Null shows
  /// a placeholder icon.
  final ImageProvider? image;
}

// ═══════════════════════════════════════════════════════════════════
// REPOSITORY — swap the body of these methods for real API calls later.
// The screen only depends on `reportsListenable` + `addReport`/`fetch`,
// so MyReportsScreen itself won't need to change when the backend lands.
// ═══════════════════════════════════════════════════════════════════

class ReportsRepository {
  ReportsRepository._internal() {
    _seedWithSampleData(); // TODO: remove once real submissions/backend exist.
  }

  static final ReportsRepository instance = ReportsRepository._internal();

  final ValueNotifier<List<ReportItem>> reportsListenable =
      ValueNotifier<List<ReportItem>>(const []);

  List<ReportItem> get reports => reportsListenable.value;

  /// Call this right after a report is successfully submitted
  /// (e.g. from AiAnalysisScreen._submitToNgo(), after your backend call
  /// succeeds). It prepends the new report so it shows up first under
  /// "Recent Reports" immediately — no navigation/refresh needed.
  void addReport(ReportItem report) {
    reportsListenable.value = [report, ...reportsListenable.value];
  }

  /// TODO: once you have a backend, replace this with a real fetch
  /// (e.g. GET /reports) and call `reportsListenable.value = fetched;`
  Future<void> refresh() async {
    // No-op placeholder for pull-to-refresh until backend sync exists.
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// Call this when the user deletes a report (e.g. taps the cross on a
  /// card). TODO: once you have a backend, also fire a DELETE /reports/:id
  /// call here before/after removing it locally.
  void removeReport(String id) {
    reportsListenable.value =
        reportsListenable.value.where((r) => r.id != id).toList();
  }

  void _seedWithSampleData() {
    final now = DateTime.now();
    reportsListenable.value = [
      ReportItem(
        id: 's1',
        title: 'Injured Dog',
        priority: ReportPriority.critical,
        status: ReportStatus.inProgress,
        location: 'Bandra, Mumbai',
        distanceKm: 1.2,
        dateTime: now.subtract(const Duration(days: 1)),
        photoCount: 3,
      ),
      ReportItem(
        id: 's2',
        title: 'Sick Cat',
        priority: ReportPriority.high,
        status: ReportStatus.inProgress,
        location: 'Santacruz, Mumbai',
        distanceKm: 2.4,
        dateTime: now.subtract(const Duration(days: 2)),
        photoCount: 2,
      ),
      ReportItem(
        id: 's3',
        title: 'Dog - Minor Injury',
        priority: ReportPriority.medium,
        status: ReportStatus.resolved,
        location: 'Andheri, Mumbai',
        distanceKm: 3.1,
        dateTime: now.subtract(const Duration(days: 3)),
        photoCount: 2,
      ),
      ReportItem(
        id: 's4',
        title: 'Cat - Not Eating',
        priority: ReportPriority.medium,
        status: ReportStatus.resolved,
        location: 'Khar, Mumbai',
        distanceKm: 2.0,
        dateTime: now.subtract(const Duration(days: 4)),
        photoCount: 1,
      ),
      ReportItem(
        id: 's5',
        title: 'Injured Dog',
        priority: ReportPriority.critical,
        status: ReportStatus.closed,
        location: 'Dadar, Mumbai',
        distanceKm: 4.3,
        dateTime: now.subtract(const Duration(days: 7)),
        photoCount: 1,
      ),
    ];
  }
}

enum _SortOrder { newest, oldest }

enum _FilterTab { all, inProgress, resolved, closed }

// ═══════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kBorderPurple = Color(0xFFDCCBE8);
  static const Color kLightPurple = Color(0xFFF1E9FA);

  static const Color kCritical = Color(0xFFE0426B);
  static const Color kHigh = Color(0xFFE8A23D);
  static const Color kMedium = Color(0xFFE8A23D);
  static const Color kLow = Color(0xFF2E7D32);

  static const Color kInProgressBg = Color(0xFFFBE1EA);
  static const Color kInProgressFg = Color(0xFFE0426B);
  static const Color kResolvedBg = Color(0xFFE1F2E3);
  static const Color kResolvedFg = Color(0xFF2E7D32);
  static const Color kClosedBg = Color(0xFFE9E4EF);
  static const Color kClosedFg = Color(0xFF6B6270);

  _FilterTab _tab = _FilterTab.all;
  _SortOrder _sort = _SortOrder.newest;
  bool _refreshing = false;

  final _repo = ReportsRepository.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildFilterTabs(),
            Expanded(
              child: ValueListenableBuilder<List<ReportItem>>(
                valueListenable: _repo.reportsListenable,
                builder: (context, allReports, _) {
                  final filtered = _applyFilter(allReports);
                  final sorted = _applySort(filtered);

                  return RefreshIndicator(
                    color: kPurple,
                    onRefresh: () async {
                      setState(() => _refreshing = true);
                      await _repo.refresh();
                      if (mounted) setState(() => _refreshing = false);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatsCard(allReports),
                          const SizedBox(height: 20),
                          _buildRecentReportsHeader(),
                          const SizedBox(height: 10),
                          if (_refreshing)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: kPurple,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          if (sorted.isEmpty)
                            _buildEmptyState()
                          else
                            for (final report in sorted) ...[
                              _ReportCard(
                                report: report,
                                colors: const _ReportCardColors(
                                  deepPurple: kDeepPurple,
                                  subtitleGray: kSubtitleGray,
                                  borderPurple: kBorderPurple,
                                  lightPurple: kLightPurple,
                                  purple: kPurple,
                                  critical: kCritical,
                                  high: kHigh,
                                  medium: kMedium,
                                  low: kLow,
                                  inProgressBg: kInProgressBg,
                                  inProgressFg: kInProgressFg,
                                  resolvedBg: kResolvedBg,
                                  resolvedFg: kResolvedFg,
                                  closedBg: kClosedBg,
                                  closedFg: kClosedFg,
                                ),
                                onTap: () {
                                  // TODO: push a report-detail screen here.
                                },
                                onDelete: () => _confirmDelete(report),
                              ),
                              const SizedBox(height: 12),
                            ],
                          const SizedBox(height: 6),
                          _buildCantFindBanner(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StrayCareBottomNav(
        currentIndex: 3,
        onTap: _handleNavTap,
      ),
    );
  }

  // ───────────────────────── Filtering / sorting ─────────────────────────

  List<ReportItem> _applyFilter(List<ReportItem> reports) {
    switch (_tab) {
      case _FilterTab.all:
        return reports;
      case _FilterTab.inProgress:
        return reports.where((r) => r.status == ReportStatus.inProgress).toList();
      case _FilterTab.resolved:
        return reports.where((r) => r.status == ReportStatus.resolved).toList();
      case _FilterTab.closed:
        return reports.where((r) => r.status == ReportStatus.closed).toList();
    }
  }

  List<ReportItem> _applySort(List<ReportItem> reports) {
    final sorted = [...reports];
    sorted.sort((a, b) => _sort == _SortOrder.newest
        ? b.dateTime.compareTo(a.dateTime)
        : a.dateTime.compareTo(b.dateTime));
    return sorted;
  }

  // ───────────────────────── Header ─────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Track all the rescue reports you've submitted",
                  style: TextStyle(fontSize: 12.5, color: kSubtitleGray),
                ),
              ],
            ),
          ),
          _CircleIconButton(icon: Icons.search, onTap: _showSearch, filled: false),
          const SizedBox(width: 8),
          _CircleIconButton(icon: Icons.tune, onTap: _showFilterSheet, filled: false),
        ],
      ),
    );
  }

  void _showSearch() {
    showSearch(context: context, delegate: _ReportSearchDelegate(_repo.reports));
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort by',
                  style: TextStyle(fontWeight: FontWeight.w800, color: kDeepPurple, fontSize: 15),
                ),
                RadioListTile<_SortOrder>(
                  value: _SortOrder.newest,
                  groupValue: _sort,
                  activeColor: kPurple,
                  title: const Text('Newest first'),
                  onChanged: (v) {
                    setState(() => _sort = v!);
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<_SortOrder>(
                  value: _SortOrder.oldest,
                  groupValue: _sort,
                  activeColor: kPurple,
                  title: const Text('Oldest first'),
                  onChanged: (v) {
                    setState(() => _sort = v!);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ───────────────────────── Filter tabs ─────────────────────────

  Widget _buildFilterTabs() {
    final tabs = [
      (_FilterTab.all, Icons.description_outlined, 'All Reports'),
      (_FilterTab.inProgress, Icons.hourglass_empty, 'In Progress'),
      (_FilterTab.resolved, Icons.check_circle_outline, 'Resolved'),
      (_FilterTab.closed, Icons.inventory_2_outlined, 'Closed'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (tabValue, icon, label) = tabs[index];
          final selected = _tab == tabValue;

          return GestureDetector(
            onTap: () => setState(() => _tab = tabValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? kPurple : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: selected ? null : Border.all(color: kBorderPurple),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: selected ? Colors.white : kSubtitleGray),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : kSubtitleGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────── Stats card ─────────────────────────

  Widget _buildStatsCard(List<ReportItem> reports) {
    final total = reports.length;
    final inProgress = reports.where((r) => r.status == ReportStatus.inProgress).length;
    final resolved = reports.where((r) => r.status == ReportStatus.resolved).length;
    final closed = reports.where((r) => r.status == ReportStatus.closed).length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              iconBg: kLightPurple,
              icon: Icons.description_outlined,
              iconColor: kPurple,
              value: '$total',
              label: 'Total\nReports',
            ),
          ),
          Expanded(
            child: _StatItem(
              iconBg: const Color(0xFFFDF0DD),
              icon: Icons.hourglass_empty,
              iconColor: kHigh,
              value: '$inProgress',
              label: 'In\nProgress',
            ),
          ),
          Expanded(
            child: _StatItem(
              iconBg: kResolvedBg,
              icon: Icons.check_circle_outline,
              iconColor: kResolvedFg,
              value: '$resolved',
              label: 'Resolved',
            ),
          ),
          Expanded(
            child: _StatItem(
              iconBg: kClosedBg,
              icon: Icons.inventory_2_outlined,
              iconColor: kClosedFg,
              value: '$closed',
              label: 'Closed',
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Recent reports header ─────────────────────────

  Widget _buildRecentReportsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recent Reports',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDeepPurple),
          ),
        ),
        GestureDetector(
          onTap: _showFilterSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort: ${_sort == _SortOrder.newest ? 'Newest' : 'Oldest'}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kPurple),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 17, color: kPurple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: kSubtitleGray),
          SizedBox(height: 10),
          Text(
            'No reports in this category yet',
            style: TextStyle(color: kSubtitleGray, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Can't find your report banner ─────────────────────────

  Widget _buildCantFindBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kLightPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: kPurple),
            child: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Can't find your report?",
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: kDeepPurple),
                ),
                SizedBox(height: 4),
                Text(
                  'Reports are usually updated within a few minutes. Pull down to refresh.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5F76), height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.pets, color: kPink, size: 28),
        ],
      ),
    );
  }

  // ───────────────────────── Delete ─────────────────────────

  void _confirmDelete(ReportItem report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete report?',
          style: TextStyle(color: kDeepPurple, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently remove "${report.title}" from your reports.',
          style: const TextStyle(color: kSubtitleGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: kSubtitleGray, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _repo.removeReport(report.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${report.title}" deleted'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: kPink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Bottom nav ─────────────────────────

  void _handleNavTap(int index) {
    if (index == 3) return;

    if (index == 0) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportRescueScreen()));
      return;
    }
    if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AiScannerScreen()));
      return;
    }
    if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Small shared widgets
// ═══════════════════════════════════════════════════════════════════

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap, this.filled = true});

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kBorderPurple = Color(0xFFDCCBE8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: Icon(icon, color: kDeepPurple, size: 22),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kSubtitleGray = Color(0xFF8D8398);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kDeepPurple),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10.5, color: kSubtitleGray, height: 1.2),
        ),
      ],
    );
  }
}

class _ReportCardColors {
  const _ReportCardColors({
    required this.deepPurple,
    required this.subtitleGray,
    required this.borderPurple,
    required this.lightPurple,
    required this.purple,
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
    required this.inProgressBg,
    required this.inProgressFg,
    required this.resolvedBg,
    required this.resolvedFg,
    required this.closedBg,
    required this.closedFg,
  });

  final Color deepPurple;
  final Color subtitleGray;
  final Color borderPurple;
  final Color lightPurple;
  final Color purple;
  final Color critical;
  final Color high;
  final Color medium;
  final Color low;
  final Color inProgressBg;
  final Color inProgressFg;
  final Color resolvedBg;
  final Color resolvedFg;
  final Color closedBg;
  final Color closedFg;

  Color priorityColor(ReportPriority p) {
    switch (p) {
      case ReportPriority.critical:
        return critical;
      case ReportPriority.high:
        return high;
      case ReportPriority.medium:
        return medium;
      case ReportPriority.low:
        return low;
    }
  }

  IconData priorityIcon(ReportPriority p) {
    return p == ReportPriority.critical ? Icons.warning_rounded : Icons.circle;
  }

  String priorityLabel(ReportPriority p) {
    switch (p) {
      case ReportPriority.critical:
        return 'Critical';
      case ReportPriority.high:
        return 'High';
      case ReportPriority.medium:
        return 'Medium';
      case ReportPriority.low:
        return 'Low';
    }
  }

  (Color, Color, String) statusStyle(ReportStatus s) {
    switch (s) {
      case ReportStatus.inProgress:
        return (inProgressBg, inProgressFg, 'In Progress');
      case ReportStatus.resolved:
        return (resolvedBg, resolvedFg, 'Resolved');
      case ReportStatus.closed:
        return (closedBg, closedFg, 'Closed');
    }
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.colors,
    required this.onTap,
    this.onDelete,
  });

  final ReportItem report;
  final _ReportCardColors colors;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final priorityColor = colors.priorityColor(report.priority);
    final (statusBg, statusFg, statusLabel) = colors.statusStyle(report.status);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.borderPurple),
                boxShadow: const [
                  BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(colors.priorityIcon(report.priority), size: 10, color: priorityColor),
                          const SizedBox(width: 4),
                          Text(
                            colors.priorityLabel(report.priority),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: priorityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: colors.subtitleGray),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${report.location} • ${report.distanceKm.toStringAsFixed(1)} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: colors.subtitleGray),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: colors.subtitleGray),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(report.dateTime),
                          style: TextStyle(fontSize: 11.5, color: colors.subtitleGray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusFg),
                    ),
                  ),
                      const SizedBox(height: 34),
                      Icon(Icons.chevron_right, color: colors.subtitleGray, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (onDelete != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Icon(Icons.close, size: 13, color: colors.subtitleGray),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: report.image != null
              ? Image(
                  image: report.image!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _fallbackThumb(),
                )
              : _fallbackThumb(),
        ),
        if (report.photoCount > 0)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: colors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt, size: 9, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    '${report.photoCount}',
                    style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallbackThumb() {
    return Container(
      width: 72,
      height: 72,
      color: colors.lightPurple,
      child: Icon(Icons.pets, color: colors.purple, size: 26),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hour12:$minute $period';
  }
}

// ═══════════════════════════════════════════════════════════════════
// Search
// ═══════════════════════════════════════════════════════════════════

class _ReportSearchDelegate extends SearchDelegate<void> {
  _ReportSearchDelegate(this._reports);

  final List<ReportItem> _reports;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = _reports
        .where((r) => r.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return const Center(
        child: Text('No matching reports', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        return ListTile(
          leading: const Icon(Icons.pets),
          title: Text(r.title),
          subtitle: Text(r.location),
        );
      },
    );
  }
}