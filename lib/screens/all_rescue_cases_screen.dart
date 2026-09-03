import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/profile_screen.dart';
import 'package:straycare_splash/screens/notification_screen.dart';

// ───────────────────────── Models ─────────────────────────

/// AI-estimated priority tier for a case.
enum CasePriority { critical, high, medium, low }

/// Strict 4-state lifecycle: New → Assigned → In Review → Resolved
enum CaseStatus { newCase, assigned, inReview, resolved }

class RescueCase {
  const RescueCase({
    required this.id,
    required this.title,
    required this.animalType,
    required this.imagePath,
    required this.priority,
    required this.aiConfidence,
    required this.status,
    required this.location,
    required this.distanceKm,
    required this.timeAgo,
    required this.description,
    required this.photoCount,
    this.reporterName,
    this.reporterEmail,
    this.reporterPhone,
    this.assignedNgoName,
    this.assignedNgoEmail,
    this.assignedAt,
    this.inReviewAt,
    this.resolvedAt,
    this.isDuplicate = false,
    this.duplicateOfId,
  });

  final String id;
  final String title;
  final String animalType;
  final String imagePath;
  final CasePriority priority;
  final int aiConfidence;
  final CaseStatus status;
  final String location;
  final double distanceKm;
  final String timeAgo;
  final String description;
  final int photoCount;

  final String? reporterName;
  final String? reporterEmail;
  final String? reporterPhone;

  final String? assignedNgoName;
  final String? assignedNgoEmail;

  final DateTime? assignedAt;
  final DateTime? inReviewAt;
  final DateTime? resolvedAt;

  final bool isDuplicate;
  final String? duplicateOfId;

  factory RescueCase.fromJson(Map<String, dynamic> json) {
    final animalType = json['animalType']?.toString() ?? 'Rescue Animal';
    final injuryType = json['injuryType']?.toString();
    final title = (injuryType != null && injuryType.trim().isNotEmpty)
        ? '$animalType – $injuryType'
        : (json['title']?.toString() ?? animalType);

    final rawImageUrl = json['imageUrl']?.toString() ??
        json['image']?.toString() ??
        json['imagePath']?.toString() ??
        'assets/images/InjuredDog.jpeg';

    final reporterObj = json['reporter'] is Map ? json['reporter'] : null;
    final userObj = json['user'] is Map ? json['user'] : null;
    final assignedNgoObj = json['assignedNgo'] is Map ? json['assignedNgo'] : null;

    final String? repName =
        reporterObj?['name']?.toString() ?? userObj?['name']?.toString();
    final String? repEmail =
        reporterObj?['email']?.toString() ?? userObj?['email']?.toString();
    final String? repPhone =
        reporterObj?['phone']?.toString() ?? userObj?['phone']?.toString();

    final String? ngoName = assignedNgoObj?['name']?.toString();
    final String? ngoEmail = assignedNgoObj?['email']?.toString();

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return RescueCase(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? 'RC-UNKNOWN',
      title: title,
      animalType: animalType,
      imagePath: rawImageUrl,
      priority: _parsePriority(json['severity'] ?? json['priority']),
      aiConfidence: (json['aiConfidence'] as num?)?.toInt() ??
          (json['confidence'] as num?)?.toInt() ??
          88,
      status: _parseStatus(json['status']),
      location: json['location']?.toString() ?? 'Unknown location',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.2,
      timeAgo: _calculateTimeAgo(json['createdAt']?.toString()) ??
          json['timeAgo']?.toString() ??
          'Recently',
      description: json['description']?.toString() ?? 'No description provided.',
      photoCount: (json['photoCount'] as num?)?.toInt() ?? 1,
      reporterName: repName,
      reporterEmail: repEmail,
      reporterPhone: repPhone,
      assignedNgoName: ngoName,
      assignedNgoEmail: ngoEmail,
      assignedAt: parseDate(json['assignedAt']),
      inReviewAt: parseDate(json['inReviewAt']),
      resolvedAt: parseDate(json['resolvedAt']),
      isDuplicate: json['isDuplicate'] == true,
      duplicateOfId:
          json['duplicateOfId']?.toString() ?? json['duplicateOf']?.toString(),
    );
  }
}

CasePriority _parsePriority(dynamic value) {
  if (value == null) return CasePriority.medium;
  final str = value.toString().toLowerCase();
  if (str.contains('crit')) return CasePriority.critical;
  if (str.contains('high')) return CasePriority.high;
  if (str.contains('low')) return CasePriority.low;
  return CasePriority.medium;
}

CaseStatus _parseStatus(dynamic value) {
  if (value == null) return CaseStatus.newCase;
  final str = value.toString().toLowerCase().replaceAll('_', '').trim();
  if (str == 'assigned') return CaseStatus.assigned;
  if (str == 'inreview' || str == 'inprogress') return CaseStatus.inReview;
  if (str == 'resolved') return CaseStatus.resolved;
  return CaseStatus.newCase;
}

String _toBackendStatus(CaseStatus status) {
  switch (status) {
    case CaseStatus.newCase:
      return 'new';
    case CaseStatus.assigned:
      return 'assigned';
    case CaseStatus.inReview:
      return 'inReview';
    case CaseStatus.resolved:
      return 'resolved';
  }
}

String? _calculateTimeAgo(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  try {
    final date = DateTime.parse(dateStr).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${(diff.inDays / 7).floor()} w ago';
  } catch (_) {
    return null;
  }
}

/// The shared NGO/Admin dashboard: full, live, AI-prioritised,
/// status-tracked list of all submitted rescue cases.
class AllRescueCasesScreen extends StatefulWidget {
  const AllRescueCasesScreen({
    super.key,
    this.onBack,
    this.currentTabIndex = 0,
    this.showBottomNav = true,
    this.showBackButton = true,
  });

  final VoidCallback? onBack;
  final int currentTabIndex;
  final bool showBottomNav;
  final bool showBackButton;

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
  static const String _apiBaseUrl = 'http://10.250.236.99:5000';

  _DashboardFilter _filter = _DashboardFilter.all;

  bool _isLoading = true;
  String? _errorMessage;
  List<RescueCase> _cases = [];

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/reports/admin/all'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic reportList = data['data']?['reports'] ??
            data['reports'] ??
            (data['data'] is List ? data['data'] : null);

        if (reportList is List) {
          final List<RescueCase> loaded = [];
          for (final item in reportList) {
            if (item is Map<String, dynamic>) {
              loaded.add(RescueCase.fromJson(item));
            } else if (item is Map) {
              loaded.add(RescueCase.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          if (mounted) {
            setState(() {
              _cases = loaded;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _cases = [];
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load cases (${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Cannot connect to backend: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _assignCase(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/api/reports/$id/assign'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case assigned to you successfully!'),
              backgroundColor: AllRescueCasesScreen.kPurple,
            ),
          );
        }
        await _fetchCases();
      } else {
        String msg = 'Failed to assign case';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) msg = data['message'];
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFFE0524B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning case: $e'),
            backgroundColor: const Color(0xFFE0524B),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String id, CaseStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final statusString = _toBackendStatus(status);

      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/api/reports/$id/status'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': statusString}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to ${_statusStyle(status).label}'),
              backgroundColor: AllRescueCasesScreen.kPurple,
            ),
          );
        }
        await _fetchCases();
      } else {
        String msg = 'Failed to update status';
        try {
          final data = jsonDecode(response.body);
          if (data['message'] != null) msg = data['message'];
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFFE0524B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: const Color(0xFFE0524B),
          ),
        );
      }
    }
  }

  void _showStatusSelectionSheet(BuildContext context, RescueCase rescueCase) {
    // Determine allowed forward transitions
    final List<CaseStatus> allowedNext = [];
    if (rescueCase.status == CaseStatus.newCase) {
      allowedNext.addAll([CaseStatus.assigned, CaseStatus.inReview, CaseStatus.resolved]);
    } else if (rescueCase.status == CaseStatus.assigned) {
      allowedNext.addAll([CaseStatus.inReview, CaseStatus.resolved]);
    } else if (rescueCase.status == CaseStatus.inReview) {
      allowedNext.add(CaseStatus.resolved);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
              const Text(
                'Update Case Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AllRescueCasesScreen.kDeepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current: ${_statusStyle(rescueCase.status).label} • Progression: New → Assigned → In Review → Resolved',
                style: const TextStyle(
                  fontSize: 12,
                  color: AllRescueCasesScreen.kSubtitleGray,
                ),
              ),
              const SizedBox(height: 16),
              if (rescueCase.status == CaseStatus.resolved)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF4E4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF3FAE5C)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This rescue case is fully resolved.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...CaseStatus.values.map((status) {
                  final style = _statusStyle(status);
                  final isCurrent = rescueCase.status == status;
                  final isAllowed = allowedNext.contains(status);

                  return Opacity(
                    opacity: (isCurrent || isAllowed) ? 1.0 : 0.4,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isCurrent ? style.bg : const Color(0xFFFAF7FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? style.text
                              : AllRescueCasesScreen.kCardBorder,
                          width: isCurrent ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(style.icon, color: style.text),
                        title: Text(
                          style.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? style.text
                                : AllRescueCasesScreen.kDeepPurple,
                          ),
                        ),
                        trailing: isCurrent
                            ? Icon(Icons.check_circle, color: style.text, size: 20)
                            : (isAllowed
                                ? const Icon(Icons.arrow_forward_rounded,
                                    color: AllRescueCasesScreen.kPurple, size: 18)
                                : const Text(
                                    'Locked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AllRescueCasesScreen.kSubtitleGray,
                                    ),
                                  )),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: isAllowed
                            ? () {
                                Navigator.pop(ctx);
                                _updateStatus(rescueCase.id, status);
                              }
                            : null,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

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
    if (!widget.showBottomNav) return;
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AllRescueCasesScreen.kPurple,
            ),
            SizedBox(height: 14),
            Text(
              'Loading rescue cases...',
              style: TextStyle(
                fontSize: 13,
                color: AllRescueCasesScreen.kSubtitleGray,
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
              const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: Color(0xFFE0524B),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AllRescueCasesScreen.kDeepPurple,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchCases,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AllRescueCasesScreen.kPurple,
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

    if (_filtered.isEmpty) {
      return RefreshIndicator(
        color: AllRescueCasesScreen.kPurple,
        onRefresh: _fetchCases,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 350,
            child: _EmptyState(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AllRescueCasesScreen.kPurple,
      onRefresh: _fetchCases,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        itemCount: _filtered.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _filtered[index];
          return _RescueCaseCard(
            rescueCase: item,
            onTap: () => _showCaseDetail(context, item),
            onAssign: () => _assignCase(item.id),
            onStatusTap: () => _showStatusSelectionSheet(context, item),
          );
        },
      ),
    );
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
              showBackButton: widget.showBackButton,
              onBack: widget.onBack ?? () => Navigator.maybePop(context),
              onNotifications: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsScreen(
                    showBottomNav: widget.showBottomNav,
                  ),
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
              child: _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? StrayCareBottomNav(
              currentIndex: widget.currentTabIndex,
              onTap: (index) => _handleNavTap(context, index),
            )
          : null,
    );
  }

  void _showCaseDetail(BuildContext context, RescueCase rescueCase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CaseDetailSheet(
        rescueCase: rescueCase,
        onAssign: () {
          Navigator.pop(ctx);
          _assignCase(rescueCase.id);
        },
        onStatusChange: () {
          Navigator.pop(ctx);
          _showStatusSelectionSheet(context, rescueCase);
        },
      ),
    );
  }
}

// ───────────────────────── Top bar ─────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBackButton,
    required this.onBack,
    required this.onNotifications,
  });

  final bool showBackButton;
  final VoidCallback onBack;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBackButton)
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
                  'Live rescue feed & NGO dispatcher',
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

// ───────────────────────── Styles ─────────────────────────

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
    case CaseStatus.assigned:
      return (
        bg: const Color(0xFFEBE0F7),
        text: AllRescueCasesScreen.kPurple,
        label: 'Assigned',
        icon: Icons.assignment_ind_outlined
      );
    case CaseStatus.inReview:
      return (
        bg: const Color(0xFFFBEAD6),
        text: const Color(0xFFE8A23D),
        label: 'In Review',
        icon: Icons.visibility_outlined
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

// ───────────────────────── Image Helper ─────────────────────────

class _CaseImage extends StatelessWidget {
  const _CaseImage({
    required this.imagePath,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final String imagePath;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget errorWidget = Container(
      width: width,
      height: height,
      color: const Color(0xFFF1E7F7),
      child: const Icon(
        Icons.pets,
        color: AllRescueCasesScreen.kPurple,
        size: 28,
      ),
    );

    Widget image;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      image = Image.network(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else {
      image = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}

// ───────────────────────── Case card ─────────────────────────

class _RescueCaseCard extends StatelessWidget {
  const _RescueCaseCard({
    required this.rescueCase,
    required this.onTap,
    required this.onAssign,
    required this.onStatusTap,
  });

  final RescueCase rescueCase;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final priority = _priorityStyle(rescueCase.priority);
    final status = _statusStyle(rescueCase.status);
    final isAssigned = rescueCase.assignedNgoName != null ||
        rescueCase.status == CaseStatus.assigned ||
        rescueCase.status == CaseStatus.inReview ||
        rescueCase.status == CaseStatus.resolved;

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
                      _CaseImage(
                        imagePath: rescueCase.imagePath,
                        width: 100,
                        height: 100,
                        borderRadius: 12,
                      ),
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AllRescueCasesScreen.kPurple
                                .withValues(alpha: 0.92),
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
                            GestureDetector(
                              onTap: onStatusTap,
                              child: _Pill(
                                bg: status.bg,
                                text: status.text,
                                icon: status.icon,
                                label: status.label,
                                trailingIcon: Icons.arrow_drop_down,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (rescueCase.reporterName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 12,
                                    color: AllRescueCasesScreen.kSubtitleGray),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    'Reporter: ${rescueCase.reporterName}${rescueCase.reporterEmail != null ? ' (${rescueCase.reporterEmail})' : ''}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AllRescueCasesScreen.kDeepPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (rescueCase.assignedNgoName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined,
                                    size: 12,
                                    color: AllRescueCasesScreen.kPurple),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    'Assigned to: ${rescueCase.assignedNgoName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AllRescueCasesScreen.kPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Action buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isAssigned) ...[
                    InkWell(
                      onTap: onAssign,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E7F7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AllRescueCasesScreen.kPurple
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded,
                                size: 14, color: AllRescueCasesScreen.kPurple),
                            SizedBox(width: 4),
                            Text(
                              'Assign to me',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AllRescueCasesScreen.kPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: onStatusTap,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AllRescueCasesScreen.kCardBorder,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note_rounded,
                              size: 15,
                              color: AllRescueCasesScreen.kSubtitleGray),
                          SizedBox(width: 4),
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AllRescueCasesScreen.kDeepPurple,
                            ),
                          ),
                        ],
                      ),
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
    this.trailingIcon,
  });

  final Color bg;
  final Color text;
  final IconData icon;
  final String label;
  final IconData? trailingIcon;

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
          if (trailingIcon != null) ...[
            const SizedBox(width: 2),
            Icon(trailingIcon, size: 14, color: text),
          ],
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
              'Pull down to refresh or try a different filter.',
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
  const _CaseDetailSheet({
    required this.rescueCase,
    required this.onAssign,
    required this.onStatusChange,
  });

  final RescueCase rescueCase;
  final VoidCallback onAssign;
  final VoidCallback onStatusChange;

  @override
  Widget build(BuildContext context) {
    final priority = _priorityStyle(rescueCase.priority);
    final status = _statusStyle(rescueCase.status);
    final isAssigned = rescueCase.assignedNgoName != null ||
        rescueCase.status == CaseStatus.assigned ||
        rescueCase.status == CaseStatus.inReview ||
        rescueCase.status == CaseStatus.resolved;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              _CaseImage(
                imagePath: rescueCase.imagePath,
                width: double.infinity,
                height: 180,
                borderRadius: 14,
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
                  GestureDetector(
                    onTap: onStatusChange,
                    child: _Pill(
                      bg: status.bg,
                      text: status.text,
                      icon: status.icon,
                      label: status.label,
                      trailingIcon: Icons.arrow_drop_down,
                    ),
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
              if (rescueCase.reporterName != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person,
                          color: AllRescueCasesScreen.kPurple, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reported by: ${rescueCase.reporterName}${rescueCase.reporterEmail != null ? ' (${rescueCase.reporterEmail})' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AllRescueCasesScreen.kDeepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (rescueCase.assignedNgoName != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE0F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user,
                          color: AllRescueCasesScreen.kPurple, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assigned NGO: ${rescueCase.assignedNgoName}${rescueCase.assignedNgoEmail != null ? ' (${rescueCase.assignedNgoEmail})' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AllRescueCasesScreen.kPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
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
                  Expanded(
                    child: Text(
                      '${rescueCase.location} • ${rescueCase.distanceKm} km • ${rescueCase.timeAgo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AllRescueCasesScreen.kSubtitleGray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onStatusChange,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Status'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AllRescueCasesScreen.kDeepPurple,
                        side: const BorderSide(
                            color: AllRescueCasesScreen.kCardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (!isAssigned) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onAssign,
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Assign to me'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AllRescueCasesScreen.kPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}