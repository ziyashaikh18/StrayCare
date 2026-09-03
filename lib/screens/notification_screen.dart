import 'package:flutter/material.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';

enum NotificationCategory { updates, reports, system }

class NotificationItem {
  const NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.category,
    this.metaIcon,
    this.metaText,
    this.isUnread = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String timeAgo;
  final NotificationCategory category;
  final IconData? metaIcon;
  final String? metaText;
  final bool isUnread;
}

/// StrayCare "Notifications" screen matching the design mock:
/// top bar with back + settings, filter tabs (All/Updates/Reports/System)
/// with counts, a scrollable list of notification cards, an impact
/// banner, and the shared bottom nav bar.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onBack,
    this.onSettings,
    this.currentTabIndex = 4,
    this.showBottomNav = true,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final int currentTabIndex;
  final bool showBottomNav;

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kCardBorder = Color(0xFFE7DBF2);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationCategory? _selectedFilter; // null = All

  static const List<NotificationItem> _items = [
    NotificationItem(
      icon: Icons.favorite,
      iconColor: Color(0xFFE0426B),
      iconBg: Color(0xFFFCE1E8),
      title: 'Report #RC-2025-0156 Update',
      description: 'Your report "Injured Dog" is now In Progress.',
      timeAgo: '2m ago',
      category: NotificationCategory.reports,
      metaIcon: Icons.pets,
      metaText: 'Bandra, Mumbai',
      isUnread: true,
    ),
    NotificationItem(
      icon: Icons.check_circle,
      iconColor: Color(0xFF3FAE5C),
      iconBg: Color(0xFFDFF4E4),
      title: 'Report #RC-2025-0123 Resolved',
      description: 'Great news! The case "Sick Cat" has been resolved. '
          'Thank you for your help!',
      timeAgo: '30m ago',
      category: NotificationCategory.reports,
      metaIcon: Icons.pets,
      metaText: 'Santacruz, Mumbai',
      isUnread: true,
    ),
    NotificationItem(
      icon: Icons.favorite,
      iconColor: Color(0xFF6A3EA1),
      iconBg: Color(0xFFF1E7F7),
      title: 'You earned 25 Rescue Points!',
      description: 'Thank you for making a difference.',
      timeAgo: '1h ago',
      category: NotificationCategory.updates,
      metaIcon: Icons.star_border_rounded,
      metaText: 'Keep helping to earn more points!',
      isUnread: true,
    ),
    NotificationItem(
      icon: Icons.groups_rounded,
      iconColor: Color(0xFFE0A03D),
      iconBg: Color(0xFFFBEDD6),
      title: 'New Volunteer Opportunity',
      description: '"Weekend Feeding Drive" in Andheri on 25 May. '
          'Join other rescuers and make an impact!',
      timeAgo: '3h ago',
      category: NotificationCategory.updates,
      metaIcon: Icons.calendar_today_outlined,
      metaText: '25 May 2025 \u2022 10:00 AM',
    ),
    NotificationItem(
      icon: Icons.description_outlined,
      iconColor: Color(0xFF3E8FD9),
      iconBg: Color(0xFFDCEBFB),
      title: 'Your Report is Under Review',
      description: 'We are reviewing your report "Cat - Not Eating". '
          'You\u2019ll be notified once there is an update.',
      timeAgo: '5h ago',
      category: NotificationCategory.reports,
      metaIcon: Icons.pets,
      metaText: 'Khar, Mumbai',
    ),
    NotificationItem(
      icon: Icons.shield_outlined,
      iconColor: Color(0xFF6A3EA1),
      iconBg: Color(0xFFEBE0F7),
      title: 'Safety Tip of the Day',
      description: 'If you find an injured animal, keep your distance '
          'and contact a local NGO. Stay safe!',
      timeAgo: 'Yesterday',
      category: NotificationCategory.system,
    ),
    NotificationItem(
      icon: Icons.notifications_none_rounded,
      iconColor: Color(0xFFE0426B),
      iconBg: Color(0xFFFCE1E8),
      title: 'Don\u2019t forget to follow up',
      description: 'Please share more details or photos to help us '
          'prioritize the case better.',
      timeAgo: '2d ago',
      category: NotificationCategory.system,
      metaIcon: Icons.pets,
      metaText: 'Report #RC-2025-0178',
    ),
    NotificationItem(
      icon: Icons.card_giftcard_rounded,
      iconColor: Color(0xFF3FAE5C),
      iconBg: Color(0xFFDFF4E4),
      title: 'Milestone Unlocked!',
      description:
          'You\u2019ve helped 10 animals so far. You\u2019re truly amazing!',
      timeAgo: '3d ago',
      category: NotificationCategory.system,
    ),
  ];

  List<NotificationItem> get _filteredItems {
    if (_selectedFilter == null) return _items;
    return _items.where((i) => i.category == _selectedFilter).toList();
  }

  int _countFor(NotificationCategory? category) {
    if (category == null) return _items.length;
    return _items.where((i) => i.category == category).length;
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
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NotificationsScreen.kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onBack: widget.onBack ?? () => Navigator.maybePop(context),
              onSettings: widget.onSettings,
            ),
            const SizedBox(height: 12),
            _FilterTabs(
              selected: _selectedFilter,
              allCount: _countFor(null),
              updatesCount: _countFor(NotificationCategory.updates),
              reportsCount: _countFor(NotificationCategory.reports),
              systemCount: _countFor(NotificationCategory.system),
              onSelected: (category) {
                setState(() => _selectedFilter = category);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                itemCount: _filteredItems.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == _filteredItems.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: _ImpactBanner(),
                    );
                  }
                  return _NotificationCard(item: _filteredItems[index]);
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
  const _TopBar({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback? onSettings;

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
                color: NotificationsScreen.kDeepPurple,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: NotificationsScreen.kDeepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Stay updated with your rescue journey',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: NotificationsScreen.kSubtitleGray,
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

// ───────────────────────── Filter tabs ─────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.allCount,
    required this.updatesCount,
    required this.reportsCount,
    required this.systemCount,
    required this.onSelected,
  });

  final NotificationCategory? selected;
  final int allCount;
  final int updatesCount;
  final int reportsCount;
  final int systemCount;
  final void Function(NotificationCategory?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            icon: Icons.notifications_none_rounded,
            label: 'All',
            count: allCount,
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            icon: Icons.campaign_outlined,
            label: 'Updates',
            count: updatesCount,
            isSelected: selected == NotificationCategory.updates,
            onTap: () => onSelected(NotificationCategory.updates),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            icon: Icons.description_outlined,
            label: 'Reports',
            count: reportsCount,
            isSelected: selected == NotificationCategory.reports,
            onTap: () => onSelected(NotificationCategory.reports),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            icon: Icons.settings_outlined,
            label: 'System',
            count: systemCount,
            isSelected: selected == NotificationCategory.system,
            onTap: () => onSelected(NotificationCategory.system),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? NotificationsScreen.kPurple : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? NotificationsScreen.kPurple
                  : NotificationsScreen.kCardBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : NotificationsScreen.kSubtitleGray,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : NotificationsScreen.kDeepPurple,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : NotificationsScreen.kPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Notification card ─────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotificationsScreen.kCardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
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
                        item.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: NotificationsScreen.kDeepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: NotificationsScreen.kSubtitleGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF4A4152),
                    height: 1.35,
                  ),
                ),
                if (item.metaText != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.metaIcon != null) ...[
                        Icon(
                          item.metaIcon,
                          size: 12,
                          color: NotificationsScreen.kSubtitleGray,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          item.metaText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: NotificationsScreen.kSubtitleGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isUnread
                    ? NotificationsScreen.kPink
                    : const Color(0xFFCBC0D6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Impact banner ─────────────────────────

class _ImpactBanner extends StatelessWidget {
  const _ImpactBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.pets,
              color: NotificationsScreen.kPink,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: NotificationsScreen.kDeepPurple,
                    ),
                    children: [
                      TextSpan(text: 'Every notification is a step towards '),
                      TextSpan(
                        text: 'saving a life',
                        style: TextStyle(color: NotificationsScreen.kPink),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thank you for being a part of StrayCare!',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5F76)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.favorite,
            color: NotificationsScreen.kPurple,
            size: 28,
          ),
        ],
      ),
    );
  }
}
