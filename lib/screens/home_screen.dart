import 'package:flutter/material.dart';

import 'package:straycare_splash/screens/ai_analysis_loading_screen.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/all_rescue_cases_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/nearby_cases_screen.dart';
import 'package:straycare_splash/screens/notification_screen.dart';
import 'package:straycare_splash/screens/profile_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/rescue_organizations_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.userName = 'Ziya',
  });

  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kCardBorder = Color(0xFFD9C7EA);

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openAiScanner() async {
    final image = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AiScannerScreen(),
      ),
    );

    if (image == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAnalysisLoadingScreen(
          imagePath: image.path,
        ),
      ),
    );
  }

  void _openReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportRescueScreen(),
      ),
    );
  }

  void _openMyReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyReportsScreen(),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openNearbyCases() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NearbyCasesScreen(),
      ),
    );
  }

  void _openAllRescueCases() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AllRescueCasesScreen(),
      ),
    );
  }

  void _openRescueOrganizations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RescueOrganizationsScreen(),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _navIndex = index;
    });

    switch (index) {
      case 0:
        return;

      case 1:
        _openReportScreen();
        return;

      case 2:
        _openAiScanner();
        return;

      case 3:
        _openMyReportScreen();
        return;

      case 4:
        _openProfile();
        return;

      default:
        _snack('This section is not implemented yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onNotifications: _openNotifications,
              onProfile: _openProfile,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeBanner(userName: widget.userName),
                    const SizedBox(height: 16),

                    _ReportRescueButton(onTap: _openReportScreen),
                    const SizedBox(height: 16),

                    _QuickActionsGrid(
                      onAiScanTap: _openAiScanner,
                      onNearbyCasesTap: _openNearbyCases,
                      onOrganizationsTap: _openRescueOrganizations,
                    ),
                    const SizedBox(height: 20),

                    _buildUrgentCasesCard(),
                    const SizedBox(height: 20),

                    const _StatsStrip(),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StrayCareBottomNav(
        currentIndex: _navIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildUrgentCasesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kCardBorder,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Urgent Rescue Cases',
              onViewAll: _openAllRescueCases,
            ),
            const SizedBox(height: 10),
            const _UrgentCasesBox(),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onNotifications,
    required this.onProfile,
  });

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StrayCare',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E1A47),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Smart Rescue. Better Tomorrow.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8D8398),
                  ),
                ),
              ],
            ),
          ),
          _IconBadgeButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: 3,
            onTap: onNotifications,
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onProfile,
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF6A3EA1),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  const _IconBadgeButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

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
                color: _HomeScreenState.kCardBorder,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: _HomeScreenState.kDeepPurple,
              size: 20,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0426B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
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
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({
    required this.userName,
  });

  final String userName;

  static const double _imageAspectRatio = 1797 / 875;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: _imageAspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/catwithdogbg.png',
              fit: BoxFit.cover,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.52,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 6, 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName! 👋',
                        style: const TextStyle(
                          fontSize: 21,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E1A47),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Together we can save more lives ❤️',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6A3EA1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Report injured or sick stray animals and help '
                        'rescue teams reach them faster.',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Color(0xFF6B5F76),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRescueButton extends StatelessWidget {
  const _ReportRescueButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5B2A8A),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5B2A8A),
                Color(0xFF3E1A6B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF8E5CC7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A3EA1).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report a Rescue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Help an animal in need',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onAiScanTap,
    required this.onNearbyCasesTap,
    required this.onOrganizationsTap,
  });

  final VoidCallback onAiScanTap;
  final VoidCallback onNearbyCasesTap;
  final VoidCallback onOrganizationsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.memory,
                iconColor: const Color(0xFF6A3EA1),
                iconBg: const Color(0xFFF1E7F7),
                title: 'AI Scan',
                subtitle: 'Detect injury & priority',
                onTap: onAiScanTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFFE05A9A),
                iconBg: const Color(0xFFFBE6EF),
                title: 'Nearby Cases',
                subtitle: 'Animals needing help',
                onTap: onNearbyCasesTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.groups_outlined,
          iconColor: const Color(0xFF6A3EA1),
          iconBg: const Color(0xFFF1E7F7),
          title: 'Rescue Organizations',
          subtitle: 'Connect with verified NGOs',
          onTap: onOrganizationsTap,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
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
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _HomeScreenState.kCardBorder,
              width: 1.3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                spreadRadius: 0.4,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x10A56DE2),
                blurRadius: 5,
                spreadRadius: 0.5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E1A47),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF8D8398),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFBBAECB),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onViewAll,
  });

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.pets,
          color: Color(0xFF2E1A47),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E1A47),
            ),
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6A3EA1),
                ),
              ),
              SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF6A3EA1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UrgentCasesBox extends StatelessWidget {
  const _UrgentCasesBox();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RescueCaseRow(
          title: 'Injured Dog',
          badgeLabel: 'Critical',
          badgeColor: Color(0xFFE0426B),
          badgeIcon: Icons.warning_amber_rounded,
          location: 'Bandra, Mumbai - 1.2 km',
          description: 'Dog with leg injury, unable to walk.',
          timeAgo: '12 min ago',
          imagePath: 'assets/images/InjuredDog.jpeg',
        ),
        Divider(
          height: 18,
          thickness: 0.8,
          indent: 8,
          endIndent: 8,
          color: Color(0xFFE9E1EE),
        ),
        _RescueCaseRow(
          title: 'Sick Cat',
          badgeLabel: 'High',
          badgeColor: Color(0xFFE8A23D),
          badgeIcon: Icons.circle,
          location: 'Santacruz, Mumbai - 2.4 km',
          description: 'Cat looks weak and not eating.',
          timeAgo: '34 min ago',
          imagePath: 'assets/images/sickcat.jpeg',
        ),
      ],
    );
  }
}

class _RescueCaseRow extends StatelessWidget {
  const _RescueCaseRow({
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeIcon,
    required this.location,
    required this.description,
    required this.timeAgo,
    required this.imagePath,
  });

  final String title;
  final String badgeLabel;
  final Color badgeColor;
  final IconData badgeIcon;
  final String location;
  final String description;
  final String timeAgo;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              imagePath,
              width: 92,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E1A47),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  badgeIcon,
                                  size: 10,
                                  color: badgeColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Color(0xFF8D8398),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF8D8398),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF4A4152),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Text(
                    timeAgo,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF8D8398),
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    const stats = [
      _Stat(
        icon: Icons.pets,
        value: '1,240+',
        label: 'Animals Helped',
      ),
      _Stat(
        icon: Icons.favorite,
        value: '25+',
        label: 'Rescue Partners',
      ),
      _Stat(
        icon: Icons.location_on_outlined,
        value: '12+',
        label: 'Cities Covered',
      ),
      _Stat(
        icon: Icons.verified_outlined,
        value: '100%',
        label: 'For a Kinder Tomorrow',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFEFE1F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD9C7EA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 58,
                color: const Color(0xFFC9AFDA),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      stats[i].icon,
                      color: const Color(0xFF6A3EA1),
                      size: 19,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats[i].value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E1A47),
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF8D8398),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}