import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/help_support_screen.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/login_screen.dart';
import 'package:straycare_splash/screens/ngo_home_screen.dart';
import 'package:straycare_splash/screens/my_activity_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/notification_screen.dart';
import 'package:straycare_splash/screens/personal_information_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/screens/rescue_points.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

/// StrayCare "My Profile" screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.userName = 'Ziya Shaikh',
    this.userEmail = 'ziya.shaikh182650@gmail.com',
    this.userPhone = '+91 98765 43210',
    this.userLocation = 'Bandra, Mumbai, India',
    this.userBadge = 'Rescuer',
    this.reportsSubmitted = 32,
    this.animalsHelped = 18,
    this.ongoingCases = 6,
    this.rescuePoints = 250,
    this.avatarAssetPath,
    this.onBack,
    this.onSettings,
    this.onEditAvatar,
    this.onPersonalInformation,
    this.onNotifications,
    this.onMyActivity,
    this.onRescuePoints,
    this.onHelpSupport,
    this.onLogOut,
    this.currentTabIndex = 4,
    this.onTabChanged,
    this.showBottomNav = true,
  });

  final String userName;
  final String userEmail;
  final String userPhone;
  final String userLocation;
  final String userBadge;

  final int reportsSubmitted;
  final int animalsHelped;
  final int ongoingCases;
  final int rescuePoints;

  final String? avatarAssetPath;

  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onPersonalInformation;
  final VoidCallback? onNotifications;
  final VoidCallback? onMyActivity;
  final VoidCallback? onRescuePoints;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onLogOut;

  final int currentTabIndex;
  final void Function(int index)? onTabChanged;
  final bool showBottomNav;

  static const Color kBackground = Color(0xFFEDE3F5);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kSubtitleGray = Color(0xFF8D8398);

  void _confirmLogOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: kDeepPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'You can log back in anytime to keep tracking your rescues.',
            style: TextStyle(color: kSubtitleGray),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: kSubtitleGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logOut(context);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: kPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');

    if (!context.mounted) return;

    onLogOut?.call();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                onBack: onBack,
                onSettings: onSettings,
              ),
              const SizedBox(height: 18),
              _ProfileCard(
                userName: userName,
                userEmail: userEmail,
                userPhone: userPhone,
                userLocation: userLocation,
                userBadge: userBadge,
                avatarAssetPath: avatarAssetPath,
                onEditAvatar: onEditAvatar,
              ),
              const SizedBox(height: 16),
              _StatsCard(
                reportsSubmitted: reportsSubmitted,
                animalsHelped: animalsHelped,
                ongoingCases: ongoingCases,
                rescuePoints: rescuePoints,
                onRescuePoints: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RescuePointsScreen(
                        rescuePoints: rescuePoints,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // All user information and navigation callbacks are passed here.
              _ActionList(
                userName: userName,
                userEmail: userEmail,
                userPhone: userPhone,
                userLocation: userLocation,
                userBadge: userBadge,
                onPersonalInformation: onPersonalInformation,
                onNotifications: onNotifications,
                onMyActivity: onMyActivity ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyActivityScreen(),
                        ),
                      );
                    },
                onRescuePoints: onRescuePoints ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescuePointsScreen(
                            rescuePoints: rescuePoints,
                          ),
                        ),
                      );
                    },
                onHelpSupport: onHelpSupport ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HelpSupportScreen(
                            showBottomNav: showBottomNav,
                          ),
                        ),
                      );
                    },
                onLogOut: () => _confirmLogOut(context),
              ),

              FutureBuilder<SharedPreferences>(
                future: SharedPreferences.getInstance(),
                builder: (context, snapshot) {
                  final prefs = snapshot.data;
                  final isApprovedNgo = prefs?.getString('role') == 'ngo' ||
                      prefs?.getString('partner_status') == 'approved';
                  if (!isApprovedNgo) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _ModeSwitchCard(
                      title: 'Switch to NGO Dashboard',
                      subtitle: 'Open your rescue operations workspace',
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const NgoHomeScreen(),
                        ),
                        (route) => route.isFirst,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),
              const _ImpactBanner(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? StrayCareBottomNav(
              currentIndex: currentTabIndex,
              onTap: onTabChanged ?? (index) => _handleNavTap(context, index),
            )
          : null,
    );
  }

  void _handleNavTap(BuildContext context, int index) {
    if (index == currentTabIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
        break;

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportRescueScreen(),
          ),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AiScannerScreen(),
          ),
        );
        break;

      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyReportsScreen(),
          ),
        );
        break;

      case 4:
        break;
    }
  }
}

class _ModeSwitchCard extends StatelessWidget {
  const _ModeSwitchCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1E7F7),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, color: ProfileScreen.kPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: ProfileScreen.kDeepPurple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: ProfileScreen.kSubtitleGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: ProfileScreen.kPurple),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Top bar
// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onSettings,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -4,
          top: -6,
          child: Icon(
            Icons.pets,
            size: 46,
            color: ProfileScreen.kPurple.withValues(alpha: 0.08),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: Icon(
                  Icons.arrow_back,
                  color: ProfileScreen.kDeepPurple,
                  size: 24,
                ),
              ),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: ProfileScreen.kDeepPurple,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Together we can save more lives.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: ProfileScreen.kSubtitleGray,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onSettings,
              icon: const Icon(
                Icons.settings_outlined,
                color: ProfileScreen.kDeepPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Profile card
// -----------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userLocation,
    required this.userBadge,
    required this.avatarAssetPath,
    required this.onEditAvatar,
  });

  final String userName;
  final String userEmail;
  final String userPhone;
  final String userLocation;
  final String userBadge;
  final String? avatarAssetPath;
  final VoidCallback? onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(
          assetPath: avatarAssetPath,
          onEdit: onEditAvatar,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      userName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: ProfileScreen.kDeepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BadgeChip(label: userBadge),
                ],
              ),
              const SizedBox(height: 10),
              _ContactRow(
                icon: Icons.email_outlined,
                text: userEmail,
              ),
              const SizedBox(height: 6),
              _ContactRow(
                icon: Icons.phone_outlined,
                text: userPhone,
              ),
              const SizedBox(height: 6),
              _ContactRow(
                icon: Icons.location_on_outlined,
                text: userLocation,
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.pets,
            size: 12,
            color: ProfileScreen.kPurple,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ProfileScreen.kPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    this.bold = false,
  });

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: ProfileScreen.kSubtitleGray,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: bold
                  ? ProfileScreen.kDeepPurple
                  : ProfileScreen.kSubtitleGray,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.assetPath,
    required this.onEdit,
  });

  final String? assetPath;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ProfileScreen.kPurple,
              width: 2.5,
            ),
          ),
          child: ClipOval(
            child: assetPath != null
                ? Image.asset(
                    assetPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: ProfileScreen.kPurple,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF1E7F7),
      child: const Icon(
        Icons.pets,
        color: ProfileScreen.kPurple,
        size: 38,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Stats card
// -----------------------------------------------------------------------------

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.reportsSubmitted,
    required this.animalsHelped,
    required this.ongoingCases,
    required this.rescuePoints,
    this.onRescuePoints,
  });

  final int reportsSubmitted;
  final int animalsHelped;
  final int ongoingCases;
  final int rescuePoints;
  final VoidCallback? onRescuePoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              iconBg: const Color(0xFFF1E7F7),
              icon: Icons.description_outlined,
              iconColor: ProfileScreen.kPurple,
              value: '$reportsSubmitted',
              label: 'Reports\nSubmitted',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatColumn(
              iconBg: const Color(0xFFFBE6EF),
              icon: Icons.pets,
              iconColor: ProfileScreen.kPink,
              value: '$animalsHelped',
              label: 'Animals\nHelped',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatColumn(
              iconBg: const Color(0xFFF1E7F7),
              icon: Icons.verified_outlined,
              iconColor: ProfileScreen.kDeepPurple,
              value: '$ongoingCases',
              label: 'Ongoing\nCases',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: GestureDetector(
              onTap: onRescuePoints,
              child: _StatColumn(
                iconBg: const Color(0xFFFBE6EF),
                icon: Icons.workspace_premium_outlined,
                iconColor: ProfileScreen.kPink,
                value: '$rescuePoints',
                label: 'Rescue\nPoints',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
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
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ProfileScreen.kDeepPurple,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: ProfileScreen.kSubtitleGray,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      color: const Color(0xFFEFE4F6),
    );
  }
}

// -----------------------------------------------------------------------------
// Action list
// -----------------------------------------------------------------------------

class _ActionList extends StatelessWidget {
  const _ActionList({
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userLocation,
    required this.userBadge,
    required this.onPersonalInformation,
    required this.onNotifications,
    required this.onMyActivity,
    required this.onRescuePoints,
    required this.onHelpSupport,
    required this.onLogOut,
  });

  final String userName;
  final String userEmail;
  final String userPhone;
  final String userLocation;
  final String userBadge;

  final VoidCallback? onPersonalInformation;
  final VoidCallback? onNotifications;
  final VoidCallback? onMyActivity;
  final VoidCallback? onRescuePoints;
  final VoidCallback? onHelpSupport;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'View and edit your personal details',
            onTap: onPersonalInformation ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonalInformationScreen(
                        userName: userName,
                        userEmail: userEmail,
                        userPhone: userPhone,
                        userLocation: userLocation,
                        userBadge: userBadge,
                      ),
                    ),
                  );
                },
          ),
          const _ActionDivider(),
          _ActionRow(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'Manage your alerts and updates',
            onTap: onNotifications ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
          ),
          const _ActionDivider(),
          _ActionRow(
            icon: Icons.pets,
            title: 'My Activity',
            subtitle: 'View your recent actions and history',
            onTap: onMyActivity,
          ),
          const _ActionDivider(),
          _ActionRow(
            icon: Icons.star_border_rounded,
            title: 'Rescue Points',
            subtitle: 'Track your points and achievements',
            onTap: onRescuePoints,
          ),
          const _ActionDivider(),
          _ActionRow(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'Get help and find answers',
            onTap: onHelpSupport,
          ),
          const _ActionDivider(),
          _ActionRow(
            icon: Icons.logout,
            title: 'Log Out',
            subtitle: 'Sign out from your account',
            accent: true,
            onTap: onLogOut,
          ),
        ],
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFF0E6F5),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = accent ? ProfileScreen.kPink : ProfileScreen.kDeepPurple;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1E7F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: ProfileScreen.kSubtitleGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: iconColor.withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Impact banner
// -----------------------------------------------------------------------------

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
              color: ProfileScreen.kPurple,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're making a difference!",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: ProfileScreen.kDeepPurple,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Thank you for helping animals in need. Together, we can save more lives.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B5F76),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.pets,
            color: ProfileScreen.kPink,
            size: 30,
          ),
        ],
      ),
    );
  }
}
