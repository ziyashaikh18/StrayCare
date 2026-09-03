import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:straycare_splash/screens/profile_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

// ═══════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════

enum ReportPriority { critical, high, medium, low }

enum MyReportStatus { newReport, assigned, inReview, resolved }

class MyReportItem {
  const MyReportItem({
    required this.id,
    required this.title,
    required this.animalType,
    required this.priority,
    required this.status,
    required this.location,
    required this.distanceKm,
    required this.createdAt,
    required this.updatedAt,
    required this.imageUrl,
    this.assignedNgoName,
    this.assignedNgoEmail,
    this.photoCount = 1,
    this.timeline = const [],
  });

  final String id;
  final String title;
  final String animalType;
  final ReportPriority priority;
  final MyReportStatus status;
  final String location;
  final double distanceKm;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String imageUrl;
  final String? assignedNgoName;
  final String? assignedNgoEmail;
  final int photoCount;
  final List<Map<String, dynamic>> timeline;

  factory MyReportItem.fromJson(Map<String, dynamic> json) {
    final animalType = json['animalType']?.toString() ?? 'Rescue Animal';
    final injuryType = json['injuryType']?.toString();
    final title = (injuryType != null && injuryType.trim().isNotEmpty)
        ? '$animalType – $injuryType'
        : (json['title']?.toString() ?? animalType);

    final rawImageUrl = json['imageUrl']?.toString() ??
        json['image']?.toString() ??
        json['imagePath']?.toString() ??
        'assets/images/InjuredDog.jpeg';

    final assignedNgoObj =
        json['assignedNgo'] is Map ? json['assignedNgo'] : null;

    DateTime parseDate(dynamic d, [DateTime? fallback]) {
      if (d == null) return fallback ?? DateTime.now();
      try {
        return DateTime.parse(d.toString()).toLocal();
      } catch (_) {
        return fallback ?? DateTime.now();
      }
    }

    final created = parseDate(json['createdAt']);
    final updated = parseDate(json['updatedAt'], created);

    List<Map<String, dynamic>> parsedTimeline = [];
    if (json['timeline'] is List) {
      for (final t in json['timeline']) {
        if (t is Map) {
          parsedTimeline.add(Map<String, dynamic>.from(t));
        }
      }
    }

    return MyReportItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? 'R-UNKNOWN',
      title: title,
      animalType: animalType,
      priority: _parsePriority(json['severity'] ?? json['priority']),
      status: _parseStatus(json['status']),
      location: json['location']?.toString() ?? 'Unknown location',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.2,
      createdAt: created,
      updatedAt: updated,
      imageUrl: rawImageUrl,
      assignedNgoName: assignedNgoObj?['name']?.toString(),
      assignedNgoEmail: assignedNgoObj?['email']?.toString(),
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 1,
      timeline: parsedTimeline,
    );
  }
}

ReportPriority _parsePriority(dynamic value) {
  if (value == null) return ReportPriority.medium;
  final str = value.toString().toLowerCase();
  if (str.contains('crit')) return ReportPriority.critical;
  if (str.contains('high')) return ReportPriority.high;
  if (str.contains('low')) return ReportPriority.low;
  return ReportPriority.medium;
}

MyReportStatus _parseStatus(dynamic value) {
  if (value == null) return MyReportStatus.newReport;
  final str = value.toString().toLowerCase().replaceAll('_', '').trim();
  if (str == 'assigned') return MyReportStatus.assigned;
  if (str == 'inreview' || str == 'inprogress') return MyReportStatus.inReview;
  if (str == 'resolved') return MyReportStatus.resolved;
  return MyReportStatus.newReport;
}

enum _SortOrder { newest, oldest }

enum _FilterTab { all, inProgress, resolved }

// ═══════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  static const String _apiBaseUrl = 'http://10.250.236.99:5000';

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kBorderPurple = Color(0xFFDCCBE8);
  static const Color kLightPurple = Color(0xFFF1E9FA);

  static const Color kInReviewBg = Color(0xFFFBEAD6);
  static const Color kInReviewFg = Color(0xFFE8A23D);
  static const Color kResolvedBg = Color(0xFFE1F2E3);
  static const Color kResolvedFg = Color(0xFF2E7D32);

  _FilterTab _tab = _FilterTab.all;
  _SortOrder _sort = _SortOrder.newest;

  bool _isLoading = true;
  String? _errorMessage;
  List<MyReportItem> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/reports/my'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic list = data['data']?['reports'] ??
            data['reports'] ??
            (data['data'] is List ? data['data'] : null);

        if (list is List) {
          final List<MyReportItem> loaded = [];
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              loaded.add(MyReportItem.fromJson(item));
            } else if (item is Map) {
              loaded.add(MyReportItem.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          if (mounted) {
            setState(() {
              _reports = loaded;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _reports = [];
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load reports (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Cannot connect to server: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<MyReportItem> _applyFilter(List<MyReportItem> reports) {
    switch (_tab) {
      case _FilterTab.all:
        return reports;
      case _FilterTab.inProgress:
        return reports
            .where((r) =>
                r.status == MyReportStatus.newReport ||
                r.status == MyReportStatus.assigned ||
                r.status == MyReportStatus.inReview)
            .toList();
      case _FilterTab.resolved:
        return reports
            .where((r) => r.status == MyReportStatus.resolved)
            .toList();
    }
  }

  List<MyReportItem> _applySort(List<MyReportItem> reports) {
    final sorted = [...reports];
    sorted.sort((a, b) => _sort == _SortOrder.newest
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(_reports);
    final sorted = _applySort(filtered);

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
              child: _buildBody(sorted),
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

  Widget _buildBody(List<MyReportItem> sorted) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: kPurple),
            SizedBox(height: 14),
            Text(
              'Loading your reports...',
              style: TextStyle(
                fontSize: 13,
                color: kSubtitleGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 44, color: Color(0xFFE0524B)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kDeepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchMyReports,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: kPurple,
      onRefresh: _fetchMyReports,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsCard(_reports),
            const SizedBox(height: 20),
            _buildRecentReportsHeader(),
            const SizedBox(height: 10),
            if (sorted.isEmpty)
              _buildEmptyState()
            else
              for (final report in sorted) ...[
                _MyReportCard(
                  report: report,
                  onTap: () => _showReportDetail(report),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 6),
            _buildCantFindBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                  ),
                ),
                Text(
                  'Live rescue tracking & updates',
                  style: TextStyle(fontSize: 12, color: kSubtitleGray),
                ),
              ],
            ),
          ),
          _CircleIconButton(
            icon: Icons.refresh_rounded,
            onTap: _fetchMyReports,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All Reports (${_reports.length})',
            isSelected: _tab == _FilterTab.all,
            onTap: () => setState(() => _tab = _FilterTab.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'In Progress (${_reports.where((r) => r.status != MyReportStatus.resolved).length})',
            isSelected: _tab == _FilterTab.inProgress,
            onTap: () => setState(() => _tab = _FilterTab.inProgress),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Resolved (${_reports.where((r) => r.status == MyReportStatus.resolved).length})',
            isSelected: _tab == _FilterTab.resolved,
            onTap: () => setState(() => _tab = _FilterTab.resolved),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(List<MyReportItem> allReports) {
    final total = allReports.length;
    final inProgress = allReports
        .where((r) => r.status != MyReportStatus.resolved)
        .length;
    final resolved = allReports
        .where((r) => r.status == MyReportStatus.resolved)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorderPurple),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              iconBg: kLightPurple,
              icon: Icons.assignment_outlined,
              iconColor: kPurple,
              value: '$total',
              label: 'Total Submitted',
            ),
          ),
          Container(width: 1, height: 44, color: kBorderPurple),
          Expanded(
            child: _StatItem(
              iconBg: kInReviewBg,
              icon: Icons.hourglass_bottom_rounded,
              iconColor: kInReviewFg,
              value: '$inProgress',
              label: 'In Progress',
            ),
          ),
          Container(width: 1, height: 44, color: kBorderPurple),
          Expanded(
            child: _StatItem(
              iconBg: kResolvedBg,
              icon: Icons.check_circle_outline,
              iconColor: kResolvedFg,
              value: '$resolved',
              label: 'Resolved',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Your Submissions',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: kDeepPurple),
          ),
        ),
        GestureDetector(
          onTap: _toggleSort,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort: ${_sort == _SortOrder.newest ? 'Newest' : 'Oldest'}',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: kPurple),
              ),
              const Icon(Icons.sort, size: 16, color: kPurple),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleSort() {
    setState(() {
      _sort =
          _sort == _SortOrder.newest ? _SortOrder.oldest : _SortOrder.newest;
    });
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: kSubtitleGray),
          SizedBox(height: 10),
          Text(
            'No reports found in this tab',
            style: TextStyle(
                color: kDeepPurple, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          SizedBox(height: 4),
          Text(
            'Reports you submit will appear here with live NGO status updates.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kSubtitleGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

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
            width: 48,
            height: 48,
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: kPurple),
            child: const Icon(Icons.fact_check_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Rescue Status',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: kDeepPurple),
                ),
                SizedBox(height: 3),
                Text(
                  'NGO and rescue team status changes sync in real-time. Pull down to refresh.',
                  style: TextStyle(
                      fontSize: 11.5, color: Color(0xFF6B5F76), height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.pets, color: kPink, size: 24),
        ],
      ),
    );
  }

  void _showReportDetail(MyReportItem report) {
    final statusData = _statusData(report.status);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                  child: _MyReportImage(
                    imageUrl: report.imageUrl,
                    width: double.infinity,
                    height: 180,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Report ID: ${report.id}',
                  style: const TextStyle(fontSize: 12, color: kSubtitleGray),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusData.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusData.icon,
                              size: 13, color: statusData.fg),
                          const SizedBox(width: 5),
                          Text(
                            statusData.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: statusData.fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _priorityColor(report.priority)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Priority: ${_priorityLabel(report.priority)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _priorityColor(report.priority),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (report.assignedNgoName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBE0F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user,
                            color: kPurple, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assigned Rescue Team / NGO',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: kSubtitleGray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                report.assignedNgoName!,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: kDeepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: kSubtitleGray),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.location,
                        style: const TextStyle(
                            fontSize: 12, color: kSubtitleGray),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: kSubtitleGray),
                    const SizedBox(width: 5),
                    Text(
                      'Submitted: ${_formatDate(report.createdAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: kSubtitleGray),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.update_rounded,
                        size: 13, color: kSubtitleGray),
                    const SizedBox(width: 5),
                    Text(
                      'Last updated: ${_formatDate(report.updatedAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: kSubtitleGray),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    if (index == 3) return;

    if (index == 0) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      return;
    }
    if (index == 1) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ReportRescueScreen()));
      return;
    }
    if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AiScannerScreen()));
      return;
    }
    if (index == 4) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Small helper widgets & functions
// ═══════════════════════════════════════════════════════════════════

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year;
  final hr = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/$y at $hr:$min';
}

Color _priorityColor(ReportPriority p) {
  switch (p) {
    case ReportPriority.critical:
      return const Color(0xFFE0426B);
    case ReportPriority.high:
      return const Color(0xFFE8A23D);
    case ReportPriority.medium:
      return const Color(0xFFE8A23D);
    case ReportPriority.low:
      return const Color(0xFF2E7D32);
  }
}

String _priorityLabel(ReportPriority p) {
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

({Color bg, Color fg, String label, IconData icon}) _statusData(
    MyReportStatus s) {
  switch (s) {
    case MyReportStatus.newReport:
      return (
        bg: const Color(0xFFDCEBFB),
        fg: const Color(0xFF3E8FD9),
        label: 'New',
        icon: Icons.fiber_new_rounded
      );
    case MyReportStatus.assigned:
      return (
        bg: const Color(0xFFEBE0F7),
        fg: const Color(0xFF6A3EA1),
        label: 'Assigned',
        icon: Icons.assignment_ind_outlined
      );
    case MyReportStatus.inReview:
      return (
        bg: const Color(0xFFFBEAD6),
        fg: const Color(0xFFE8A23D),
        label: 'In Review',
        icon: Icons.visibility_outlined
      );
    case MyReportStatus.resolved:
      return (
        bg: const Color(0xFFE1F2E3),
        fg: const Color(0xFF2E7D32),
        label: 'Resolved',
        icon: Icons.check_circle_outline
      );
  }
}

class _MyReportImage extends StatelessWidget {
  const _MyReportImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget fallback = Container(
      width: width,
      height: height,
      color: const Color(0xFFF1E7F7),
      child: const Icon(Icons.pets, color: Color(0xFF6A3EA1), size: 26),
    );

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }
  }
}

class _MyReportCard extends StatelessWidget {
  const _MyReportCard({
    required this.report,
    required this.onTap,
  });

  final MyReportItem report;
  final VoidCallback onTap;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kBorderPurple = Color(0xFFDCCBE8);
  static const Color kPurple = Color(0xFF6A3EA1);

  @override
  Widget build(BuildContext context) {
    final status = _statusData(report.status);
    final priorityColor = _priorityColor(report.priority);

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
            border: Border.all(color: kBorderPurple),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _MyReportImage(
                      imageUrl: report.imageUrl,
                      width: 90,
                      height: 90,
                    ),
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
                                report.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: kDeepPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _priorityLabel(report.priority),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: status.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(status.icon,
                                      size: 11, color: status.fg),
                                  const SizedBox(width: 3),
                                  Text(
                                    status.label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: status.fg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: kSubtitleGray),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                report.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: kSubtitleGray),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (report.assignedNgoName != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: kPurple.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user, size: 14, color: kPurple),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Assigned to ${report.assignedNgoName}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: kPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submitted ${_formatDate(report.createdAt)}',
                    style: const TextStyle(fontSize: 10.5, color: kSubtitleGray),
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kPurple,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: kPurple),
                    ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kBorderPurple = Color(0xFFDCCBE8);
  static const Color kDeepPurple = Color(0xFF2E1A47);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? kPurple : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kPurple : kBorderPurple,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : kDeepPurple,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  static const Color kDeepPurple = Color(0xFF2E1A47);

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
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: kDeepPurple),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 10, color: kSubtitleGray, height: 1.2),
        ),
      ],
    );
  }
}