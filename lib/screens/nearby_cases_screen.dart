import 'package:flutter/material.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/profile_screen.dart';
import 'package:straycare_splash/screens/notification_screen.dart';

enum AnimalCategory { dog, cat, other }

enum CaseSeverity { critical, high, medium }

class NearbyCase {
  const NearbyCase({
    required this.title,
    required this.severity,
    required this.location,
    required this.distanceKm,
    required this.timeAgo,
    required this.description,
    required this.imagePath,
    required this.photoCount,
    required this.category,
    this.isFavorite = false,
  });

  final String title;
  final CaseSeverity severity;
  final String location;
  final double distanceKm;
  final String timeAgo;
  final String description;
  final String imagePath;
  final int photoCount;
  final AnimalCategory category;
  final bool isFavorite;
}

/// StrayCare "Nearby Cases" screen matching the design mock:
/// top bar (back, title, notifications, profile), search + filter row,
/// category chips (All/Dogs/Cats/Others), a scrollable list of case
/// cards, a "Can't find a case?" report banner, and the shared bottom nav.
class NearbyCasesScreen extends StatefulWidget {
  const NearbyCasesScreen({
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

  static const Color kBackground = Color.fromARGB(255, 225, 215, 228);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kCardBorder = Color(0xFFD9C7EA);
  static const Color kBorderDark = Color(0xFF8F6BB5);
  static const Color kBorderCritical = Color(0xFFE0524B);
  static const Color kBorderHigh = Color(0xFFE8A23D);

  /// Standard card shadow with layered effect for 3D elevation
  static const List<BoxShadow> kCardShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      spreadRadius: 1,
      offset: Offset(0, 5),
    ),
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  @override
  State<NearbyCasesScreen> createState() => _NearbyCasesScreenState();
}

class _NearbyCasesScreenState extends State<NearbyCasesScreen> {
  AnimalCategory? _selectedCategory; // null = All
  final TextEditingController _searchController = TextEditingController();

  static const List<NearbyCase> _cases = [
    NearbyCase(
      title: 'Injured Dog',
      severity: CaseSeverity.critical,
      location: 'Bandra, Mumbai',
      distanceKm: 1.2,
      timeAgo: '12 min ago',
      description:
          'Dog with leg injury, unable to walk properly. Needs urgent medical help.',
      // Exact name as requested
      imagePath: 'assets/images/injured dog.png',
      photoCount: 3,
      category: AnimalCategory.dog,
    ),
    NearbyCase(
      title: 'Sick Cat',
      severity: CaseSeverity.high,
      location: 'Santacruz, Mumbai',
      distanceKm: 2.4,
      timeAgo: '34 min ago',
      description: 'Cat looks weak and not eating since yesterday.',
      imagePath: 'assets/images/sickcat.jpeg',
      photoCount: 2,
      category: AnimalCategory.cat,
    ),
    NearbyCase(
      title: 'Rabbit – Skin Infection',
      severity: CaseSeverity.medium,
      location: 'Khar, Mumbai',
      distanceKm: 2.7,
      timeAgo: '1 hr ago',
      description: 'Visible skin infection and hair loss. Needs treatment.',
      // Exact name as requested
      imagePath: 'assets/images/rabbit .png',
      photoCount: 1,
      category: AnimalCategory.other,
    ),
    NearbyCase(
      title: 'Abandoned Kitten',
      severity: CaseSeverity.medium,
      location: 'Bandra East, Mumbai',
      distanceKm: 3.1,
      timeAgo: '2 hr ago',
      description: 'Small kitten seen alone near the garbage area.',
      // Exact name as requested
      imagePath: 'assets/images/abondened kitten.png',
      photoCount: 2,
      category: AnimalCategory.cat,
    ),
    NearbyCase(
      title: 'Injured Dog',
      severity: CaseSeverity.critical,
      location: 'Mahim, Mumbai',
      distanceKm: 3.5,
      timeAgo: '2 hr 30 min ago',
      description: 'Hit by vehicle. Bleeding from mouth.',
      imagePath: 'assets/images/InjuredDog.jpeg',
      photoCount: 1,
      category: AnimalCategory.dog,
    ),
  ];

  List<NearbyCase> get _filteredCases {
    final query = _searchController.text.trim().toLowerCase();
    return _cases.where((c) {
      final matchesCategory =
          _selectedCategory == null || c.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          c.title.toLowerCase().contains(query) ||
          c.location.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NearbyCasesScreen.kBackground,
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
              onProfile: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    showBottomNav: widget.showBottomNav,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SearchAndFilterRow(
              controller: _searchController,
              onFilterTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Filter'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            _CategoryTabs(
              selected: _selectedCategory,
              onSelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            const SizedBox(height: 10),
            // Color legend strip for border meanings
            const _SeverityLegend(),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                itemCount: _filteredCases.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == _filteredCases.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: _ReportBanner(),
                    );
                  }
                  return _CaseCard(nearbyCase: _filteredCases[index]);
                },
              ),
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
}

// ───────────────────────── Top bar ─────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onNotifications,
    required this.onProfile,
  });

  final VoidCallback onBack;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

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
                color: NearbyCasesScreen.kDeepPurple,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nearby Cases',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: NearbyCasesScreen.kDeepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Animals near you who need help',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: NearbyCasesScreen.kSubtitleGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _NotificationButton(onTap: onNotifications),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfile,
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF6A3EA1),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                color: NearbyCasesScreen.kBorderDark,
                width: 1.5,
              ),
              boxShadow: NearbyCasesScreen.kCardShadow,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: NearbyCasesScreen.kDeepPurple,
              size: 20,
            ),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: const BoxDecoration(
                color: NearbyCasesScreen.kPink,
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
    );
  }
}

// ───────────────────────── Search + filter ─────────────────────────

class _SearchAndFilterRow extends StatelessWidget {
  const _SearchAndFilterRow({
    required this.controller,
    required this.onFilterTap,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onFilterTap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: NearbyCasesScreen.kBorderDark,
                  width: 1.5,
                ),
                boxShadow: NearbyCasesScreen.kCardShadow,
              ),
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: NearbyCasesScreen.kDeepPurple,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search by animal type, location...',
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    color: NearbyCasesScreen.kSubtitleGray,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: NearbyCasesScreen.kSubtitleGray,
                    size: 20,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: const Color(0xFFEFE1F8),
            borderRadius: BorderRadius.circular(23),
            child: InkWell(
              borderRadius: BorderRadius.circular(23),
              onTap: onFilterTap,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: NearbyCasesScreen.kBorderDark,
                    width: 1.5,
                  ),
                  boxShadow: NearbyCasesScreen.kCardShadow,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 17,
                      color: NearbyCasesScreen.kPurple,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: NearbyCasesScreen.kPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Category tabs ─────────────────────────

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

  final AnimalCategory? selected;
  final void Function(AnimalCategory?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'All',
            emoji: null,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Dogs',
            emoji: '\u{1F436}',
            isSelected: selected == AnimalCategory.dog,
            onTap: () => onSelected(AnimalCategory.dog),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Cats',
            emoji: '\u{1F431}',
            isSelected: selected == AnimalCategory.cat,
            onTap: () => onSelected(AnimalCategory.cat),
          ),
          const SizedBox(width: 8),
          _CategoryChip(
            label: 'Others',
            emoji: '\u{1F43E}',
            isSelected: selected == AnimalCategory.other,
            onTap: () => onSelected(AnimalCategory.other),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? NearbyCasesScreen.kPurple : Colors.white,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        borderRadius: BorderRadius.circular(21),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? NearbyCasesScreen.kPurple : Colors.white,
            borderRadius: BorderRadius.circular(21),
            boxShadow: isSelected
                ? NearbyCasesScreen.kCardShadow
                : [
                    const BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : NearbyCasesScreen.kDeepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Severity legend strip ─────────────────────────

class _SeverityLegend extends StatelessWidget {
  const _SeverityLegend();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _LegendItem(
            color: NearbyCasesScreen.kBorderCritical,
            label: 'Critical',
          ),
          SizedBox(width: 12),
          _LegendItem(
            color: NearbyCasesScreen.kBorderHigh,
            label: 'High',
          ),
          SizedBox(width: 12),
          _LegendItem(
            color: NearbyCasesScreen.kBorderDark,
            label: 'Medium',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Case card ─────────────────────────

class _CaseCard extends StatefulWidget {
  const _CaseCard({required this.nearbyCase});

  final NearbyCase nearbyCase;

  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  late bool _isFavorite = widget.nearbyCase.isFavorite;

  ({Color bg, Color text, IconData icon, String label, Color border})
      get _severityStyle {
    switch (widget.nearbyCase.severity) {
      case CaseSeverity.critical:
        return (
          bg: const Color(0xFFFCE1E1),
          text: const Color(0xFFE0524B),
          icon: Icons.warning_amber_rounded,
          label: 'Critical',
          border: const Color(0xFFE0524B),
        );
      case CaseSeverity.high:
        return (
          bg: const Color(0xFFFBEAD6),
          text: const Color(0xFFE8A23D),
          icon: Icons.circle,
          label: 'High',
          border: const Color(0xFFE8A23D),
        );
      case CaseSeverity.medium:
        return (
          bg: const Color(0xFFFBEAD6),
          text: const Color(0xFFE8A23D),
          icon: Icons.circle,
          label: 'Medium',
          border: NearbyCasesScreen.kBorderDark,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = _severityStyle;
    final nearbyCase = widget.nearbyCase;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: severity.border,
          width: 1.5,
        ),
        boxShadow: NearbyCasesScreen.kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area (100 x 100 square)
          Stack(
            children: [
              Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    nearbyCase.imagePath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1E7F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pets,
                          color: NearbyCasesScreen.kPurple,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: NearbyCasesScreen.kPurple.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${nearbyCase.photoCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        nearbyCase.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NearbyCasesScreen.kDeepPurple,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${nearbyCase.distanceKm} km',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: NearbyCasesScreen.kPurple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _isFavorite = !_isFavorite),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_rounded,
                            size: 19,
                            color: _isFavorite
                                ? NearbyCasesScreen.kPink
                                : const Color(0xFFBBAECB),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severity.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: severity.text.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(severity.icon, size: 11, color: severity.text),
                      const SizedBox(width: 4),
                      Text(
                        severity.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: severity.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 13,
                      color: NearbyCasesScreen.kSubtitleGray,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${nearbyCase.location} • ${nearbyCase.distanceKm} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: NearbyCasesScreen.kSubtitleGray,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: NearbyCasesScreen.kSubtitleGray,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nearbyCase.timeAgo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: NearbyCasesScreen.kSubtitleGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nearbyCase.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF4A4152),
                    height: 1.3,
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

// ───────────────────────── Report banner ─────────────────────────

class _ReportBanner extends StatelessWidget {
  const _ReportBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: NearbyCasesScreen.kBorderDark,
          width: 1.5,
        ),
        boxShadow: NearbyCasesScreen.kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: NearbyCasesScreen.kPurple,
              boxShadow: NearbyCasesScreen.kCardShadow,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Can't find a case?",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: NearbyCasesScreen.kDeepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Report a new case and help an animal in need near you.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: NearbyCasesScreen.kSubtitleGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: NearbyCasesScreen.kPurple,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportRescueScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: NearbyCasesScreen.kCardShadow,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Report Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.add, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
