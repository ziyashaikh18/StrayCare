import 'package:flutter/material.dart';

import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({
    super.key,
    this.currentTabIndex = 4,
    this.onTabChanged,
    this.showBottomNav = true,
  });

  final int currentTabIndex;
  final void Function(int index)? onTabChanged;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HelpColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HelpTopBar(
                      onBack: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(height: 20),
                    const _HelpHeader(),
                    const SizedBox(height: 22),
                    const _HelpSearchBar(),
                    const SizedBox(height: 18),
                    _EmergencyBanner(
                      onTap: () => _openPage(
                        context,
                        const EmergencyRescueGuideScreen(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _HelpSection(
                      title: 'Emergency & Rescue',
                      icon: Icons.medical_services_outlined,
                      iconColor: HelpColors.pink,
                      items: _emergencyItems,
                    ),
                    const SizedBox(height: 26),
                    _HelpSection(
                      title: 'Using StrayCare',
                      icon: Icons.pets_outlined,
                      iconColor: HelpColors.primaryPurple,
                      items: _usingStrayCareItems,
                    ),
                    const SizedBox(height: 26),
                    _HelpSection(
                      title: 'Account & App',
                      icon: Icons.settings_outlined,
                      iconColor: HelpColors.primaryPurple,
                      items: _accountItems,
                    ),
                    const SizedBox(height: 20),
                    _FaqBanner(
                      onTap: () => _openPage(
                        context,
                        const FaqScreen(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ContactSupportBanner(
                      onTap: () => _openPage(
                        context,
                        const ContactSupportScreen(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? StrayCareBottomNav(
              currentIndex: currentTabIndex,
              onTap: onTabChanged ?? (index) => _handleNavigation(context, index),
            )
          : null,
    );
  }

  static void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(_smoothRoute(page));
  }

  static Route<void> _smoothRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
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
    }
  }
}

// -----------------------------------------------------------------------------
// Colors
// -----------------------------------------------------------------------------

class HelpColors {
  static const Color background = Color(0xFFF8F6FB);
  static const Color primaryPurple = Color(0xFF6B4EFF);
  static const Color lightLavender = Color(0xFFEEE9FF);
  static const Color pink = Color(0xFFFF5A8A);
  static const Color lightPink = Color(0xFFFFEAF1);
  static const Color darkText = Color(0xFF2D2140);
  static const Color secondaryText = Color(0xFF7A7485);
  static const Color greenCard = Color(0xFFE8F7EC);
  static const Color border = Color(0xFFECE8F5);
  static const Color contactLavender = Color(0xFFF2EBFF);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

// -----------------------------------------------------------------------------
// Data
// -----------------------------------------------------------------------------

class HelpItem {
  const HelpItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.pageBuilder,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget Function() pageBuilder;
}

final List<HelpItem> _emergencyItems = [
  HelpItem(
    title: 'Emergency Rescue Guide',
    description: 'What to do and what not to do.',
    icon: Icons.medical_services_outlined,
    pageBuilder: () => const EmergencyRescueGuideScreen(),
  ),
  HelpItem(
    title: 'Injured Animal Guide',
    description: 'Step-by-step rescue guide.',
    icon: Icons.pets_outlined,
    pageBuilder: () => const InjuredAnimalGuideScreen(),
  ),
  HelpItem(
    title: 'Rescue Organizations',
    description: 'NGOs and emergency contacts.',
    icon: Icons.business_outlined,
    pageBuilder: () => const RescueOrganizationsScreen(),
  ),
];

final List<HelpItem> _usingStrayCareItems = [
  HelpItem(
    title: 'How To Report',
    description: 'Step-by-step reporting guide.',
    icon: Icons.assignment_outlined,
    pageBuilder: () => const HowToReportScreen(),
  ),
  HelpItem(
    title: 'AI Scan Guide',
    description: 'How AI works and best photo tips.',
    icon: Icons.memory_outlined,
    pageBuilder: () => const AiScanGuideScreen(),
  ),
  HelpItem(
    title: 'My Reports Help',
    description: 'Track status and understand updates.',
    icon: Icons.description_outlined,
    pageBuilder: () => const MyReportsHelpScreen(),
  ),
];

final List<HelpItem> _accountItems = [
  HelpItem(
    title: 'Account & Profile',
    description: 'Manage your account information.',
    icon: Icons.person_outline,
    pageBuilder: () => const AccountHelpScreen(),
  ),
  HelpItem(
    title: 'Notifications',
    description: 'Manage alerts and notifications.',
    icon: Icons.notifications_none_outlined,
    pageBuilder: () => const NotificationHelpScreen(),
  ),
  HelpItem(
    title: 'Privacy & Safety',
    description: 'How your data is protected.',
    icon: Icons.shield_outlined,
    pageBuilder: () => const PrivacySafetyScreen(),
  ),
  HelpItem(
    title: 'App Issues',
    description: 'Report bugs and technical problems.',
    icon: Icons.phone_android_outlined,
    pageBuilder: () => const AppIssuesScreen(),
  ),
];

// -----------------------------------------------------------------------------
// Main screen widgets
// -----------------------------------------------------------------------------

class _HelpTopBar extends StatelessWidget {
  const _HelpTopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back,
          onTap: onBack,
        ),
        const Spacer(),
        const Icon(
          Icons.pets,
          color: HelpColors.lightLavender,
          size: 34,
        ),
      ],
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help & Support',
                style: TextStyle(
                  color: HelpColors.darkText,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "We're here to help you and the animals.",
                style: TextStyle(
                  color: HelpColors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        _AnimalIllustration(),
      ],
    );
  }
}

class _AnimalIllustration extends StatelessWidget {
  const _AnimalIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 105,
      height: 86,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                color: HelpColors.lightLavender,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 34,
                color: HelpColors.primaryPurple,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 0,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: HelpColors.lightPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_outlined,
                size: 31,
                color: HelpColors.pink,
              ),
            ),
          ),
          const Positioned(
            top: 0,
            right: 20,
            child: Icon(
              Icons.favorite,
              color: HelpColors.pink,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSearchBar extends StatelessWidget {
  const _HelpSearchBar();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for help topics...',
        hintStyle: const TextStyle(
          color: HelpColors.secondaryText,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: HelpColors.secondaryText,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: HelpColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: HelpColors.primaryPurple,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HelpColors.lightPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const _CircleIcon(
            icon: Icons.emergency_outlined,
            backgroundColor: Colors.white,
            iconColor: HelpColors.pink,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency? Act Now!',
                  style: TextStyle(
                    color: HelpColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Quick guide for rescuing injured animals in urgent situations.',
                  style: TextStyle(
                    color: HelpColors.secondaryText,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: HelpColors.pink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Emergency',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<HelpItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: HelpColors.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 650
                ? 4
                : constraints.maxWidth >= 420
                    ? 3
                    : 2;

            final spacing = columns == 2 ? 10.0 : 12.0;
            final cardWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items.map((item) {
                return SizedBox(
                  width: cardWidth,
                  child: _HelpTopicCard(item: item),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HelpTopicCard extends StatelessWidget {
  const _HelpTopicCard({
    required this.item,
  });

  final HelpItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            HelpSupportScreen._smoothRoute(item.pageBuilder()),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 164,
          ),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: HelpColors.border,
            ),
            boxShadow: HelpColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.icon == Icons.medical_services_outlined ||
                          item.icon == Icons.pets_outlined
                      ? HelpColors.lightPink
                      : HelpColors.lightLavender,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: item.icon == Icons.medical_services_outlined ||
                          item.icon == Icons.pets_outlined
                      ? HelpColors.pink
                      : HelpColors.primaryPurple,
                  size: 21,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HelpColors.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: HelpColors.primaryPurple,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqBanner extends StatelessWidget {
  const _FaqBanner({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _BannerCard(
      backgroundColor: HelpColors.greenCard,
      icon: Icons.question_mark_rounded,
      iconBackgroundColor: Colors.white,
      iconColor: HelpColors.primaryPurple,
      title: 'Frequently Asked Questions',
      subtitle: 'Find answers to common questions.',
      trailing: Icons.arrow_forward_rounded,
      onTap: onTap,
    );
  }
}

class _ContactSupportBanner extends StatelessWidget {
  const _ContactSupportBanner({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HelpColors.contactLavender,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: HelpColors.primaryPurple,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still need more help?',
                  style: TextStyle(
                    color: HelpColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Our support team is here for you.',
                  style: TextStyle(
                    color: HelpColors.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
                SizedBox(height: 11),
                _ContactSupportButton(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: HelpColors.pink,
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _ContactSupportButton extends StatelessWidget {
  const _ContactSupportButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          HelpSupportScreen._smoothRoute(
            const ContactSupportScreen(),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: HelpColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      child: const Text(
        'Contact Support',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.backgroundColor,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _CircleIcon(
                icon: icon,
                backgroundColor: iconBackgroundColor,
                iconColor: iconColor,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: HelpColors.darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: HelpColors.secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                trailing,
                color: HelpColors.primaryPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 23,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(
            Icons.arrow_back,
            color: HelpColors.darkText,
            size: 21,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared detail page
// -----------------------------------------------------------------------------

class HelpDetailScaffold extends StatelessWidget {
  const HelpDetailScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.bottomButtonText,
    this.onBottomButtonPressed,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? bottomButtonText;
  final VoidCallback? onBottomButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HelpColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              leading: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: HelpColors.darkText,
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  color: HelpColors.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: HelpColors.darkText,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: HelpColors.secondaryText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ...children,
                    if (bottomButtonText != null) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onBottomButtonPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HelpColors.primaryPurple,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            bottomButtonText!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpContentCard extends StatelessWidget {
  const HelpContentCard({
    super.key,
    required this.child,
    this.color = Colors.white,
  });

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: HelpColors.border,
        ),
        boxShadow: HelpColors.cardShadow,
      ),
      child: child,
    );
  }
}

class HelpBullet extends StatelessWidget {
  const HelpBullet({
    super.key,
    required this.text,
    this.icon = Icons.check_circle_outline,
    this.color = HelpColors.primaryPurple,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: HelpColors.darkText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpStepCard extends StatelessWidget {
  const HelpStepCard({
    super.key,
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return HelpContentCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: HelpColors.lightLavender,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: HelpColors.primaryPurple,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: HelpColors.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: HelpColors.secondaryText,
                    fontSize: 13,
                    height: 1.4,
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

// -----------------------------------------------------------------------------
// Emergency Rescue Guide
// -----------------------------------------------------------------------------

class EmergencyRescueGuideScreen extends StatelessWidget {
  const EmergencyRescueGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'Emergency Rescue Guide',
      subtitle: 'Stay calm and follow these safety-first steps.',
      bottomButtonText: 'Emergency NGO Contacts',
      onBottomButtonPressed: () {
        Navigator.push(
          context,
          HelpSupportScreen._smoothRoute(
            const RescueOrganizationsScreen(),
          ),
        );
      },
      children: const [
        HelpContentCard(
          color: HelpColors.lightPink,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: HelpColors.pink,
                size: 25,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'If the animal or people nearby are in immediate danger, contact local emergency services or a nearby rescue organization.',
                  style: TextStyle(
                    color: HelpColors.darkText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        HelpContentCard(
          child: Column(
            children: [
              HelpBullet(text: 'Stay calm.'),
              HelpBullet(text: 'Observe from a safe distance.'),
              HelpBullet(text: 'Avoid sudden movements.'),
              HelpBullet(text: 'Move the animal only if necessary.'),
              HelpBullet(
                  text: 'Use a cloth or towel if handling is unavoidable.'),
              HelpBullet(text: 'Call a rescue organization.'),
              HelpBullet(
                text: 'Never force food or water.',
                icon: Icons.close_rounded,
                color: HelpColors.pink,
              ),
              HelpBullet(
                text: 'Do not treat serious injuries yourself.',
                icon: Icons.close_rounded,
                color: HelpColors.pink,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Injured Animal Guide
// -----------------------------------------------------------------------------

class InjuredAnimalGuideScreen extends StatelessWidget {
  const InjuredAnimalGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'Injured Animal Guide',
      subtitle: 'Use this step-by-step guide when you find an injured animal.',
      bottomButtonText: 'Report Animal',
      onBottomButtonPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportRescueScreen(),
          ),
        );
      },
      children: const [
        HelpStepCard(
          number: 1,
          title: 'Check surroundings',
          description: 'Make sure the area is safe before approaching.',
        ),
        HelpStepCard(
          number: 2,
          title: 'Assess breathing',
          description: 'Observe the animal without touching it unnecessarily.',
        ),
        HelpStepCard(
          number: 3,
          title: 'Check bleeding',
          description: 'Look for visible bleeding or serious injuries.',
        ),
        HelpStepCard(
          number: 4,
          title: 'Move the animal safely',
          description: 'Only move the animal when staying there is dangerous.',
        ),
        HelpStepCard(
          number: 5,
          title: 'Take clear photos',
          description: 'Capture useful images from a safe distance.',
        ),
        HelpStepCard(
          number: 6,
          title: 'Create a report in StrayCare',
          description: 'Add the location, photos, and useful observations.',
        ),
        HelpStepCard(
          number: 7,
          title: 'Contact a rescue organization',
          description: 'Share the report and request urgent assistance.',
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Rescue organizations
// -----------------------------------------------------------------------------

class RescueOrganization {
  const RescueOrganization({
    required this.name,
    required this.description,
    required this.phone,
    required this.website,
  });

  final String name;
  final String description;
  final String phone;
  final String website;
}

const List<RescueOrganization> _organizations = [
  RescueOrganization(
    name: 'Gully Stray Care',
    description: 'Community-focused animal rescue and support.',
    phone: '+91 98765 43210',
    website: 'Visit website',
  ),
  RescueOrganization(
    name: 'Animal Aid Unlimited',
    description: 'Rescue and veterinary support for street animals.',
    phone: '+91 90000 00000',
    website: 'Visit website',
  ),
  RescueOrganization(
    name: 'CUPA',
    description: 'Animal welfare, rescue, and shelter services.',
    phone: '+91 91111 11111',
    website: 'Visit website',
  ),
  RescueOrganization(
    name: 'Blue Cross of India',
    description: 'Animal rescue, treatment, and welfare programs.',
    phone: '+91 92222 22222',
    website: 'Visit website',
  ),
  RescueOrganization(
    name: 'BSPCA',
    description: 'Support for injured and abandoned animals.',
    phone: '+91 93333 33333',
    website: 'Visit website',
  ),
];

class RescueOrganizationsScreen extends StatelessWidget {
  const RescueOrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'Rescue Organizations',
      subtitle: 'Find an organization that can help with the situation.',
      children: _organizations.map((organization) {
        return _OrganizationCard(
          organization: organization,
        );
      }).toList(),
    );
  }
}

class _OrganizationCard extends StatelessWidget {
  const _OrganizationCard({
    required this.organization,
  });

  final RescueOrganization organization;

  @override
  Widget build(BuildContext context) {
    return HelpContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: HelpColors.lightLavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: HelpColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  organization.name,
                  style: const TextStyle(
                    color: HelpColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            organization.description,
            style: const TextStyle(
              color: HelpColors.secondaryText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                color: HelpColors.primaryPurple,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                organization.phone,
                style: const TextStyle(
                  color: HelpColors.darkText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.language, size: 17),
                  label: Text(organization.website),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HelpColors.primaryPurple,
                    side: const BorderSide(
                      color: HelpColors.primaryPurple,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call, size: 17),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HelpColors.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
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
}

// -----------------------------------------------------------------------------
// How to report
// -----------------------------------------------------------------------------

class HowToReportScreen extends StatelessWidget {
  const HowToReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'How To Report',
      subtitle: 'Create a useful report so rescuers can respond quickly.',
      bottomButtonText: 'Start Reporting',
      onBottomButtonPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportRescueScreen(),
          ),
        );
      },
      children: const [
        HelpStepCard(
          number: 1,
          title: 'Open the Report tab',
          description: 'Start a new rescue report from the Report section.',
        ),
        HelpStepCard(
          number: 2,
          title: 'Take or upload a photo',
          description: 'Use a clear photo that shows the animal and situation.',
        ),
        HelpStepCard(
          number: 3,
          title: 'Enter the location',
          description: 'Add the location where the animal was found.',
        ),
        HelpStepCard(
          number: 4,
          title: 'Add notes',
          description: 'Describe injuries, behavior, and nearby landmarks.',
        ),
        HelpStepCard(
          number: 5,
          title: 'Submit the report',
          description: 'Review the details and send the report.',
        ),
        HelpStepCard(
          number: 6,
          title: 'Track progress',
          description: 'Follow rescue updates from My Reports.',
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// AI scan guide
// -----------------------------------------------------------------------------

class AiScanGuideScreen extends StatelessWidget {
  const AiScanGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'AI Scan Guide',
      subtitle: 'Learn how AI Scan helps organize animal rescue information.',
      children: [
        const HelpContentCard(
          color: HelpColors.lightLavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.memory_outlined,
                color: HelpColors.primaryPurple,
                size: 30,
              ),
              SizedBox(height: 12),
              Text(
                'What AI Scan does',
                style: TextStyle(
                  color: HelpColors.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AI Scan can help identify visible details in an animal photo and provide useful guidance. Always verify the result and contact a rescue organization for urgent cases.',
                style: TextStyle(
                  color: HelpColors.secondaryText,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const Text(
          'Best photo practices',
          style: TextStyle(
            color: HelpColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const HelpContentCard(
          child: Column(
            children: [
              HelpBullet(text: 'Use good lighting.'),
              HelpBullet(text: 'Capture a clear image.'),
              HelpBullet(text: 'Include a single animal when possible.'),
              HelpBullet(text: 'Make visible injuries easy to see.'),
              HelpBullet(
                  text:
                      'Stay close enough for clarity but keep a safe distance.'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sample images',
          style: TextStyle(
            color: HelpColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _ImagePlaceholder(label: 'Good lighting')),
            SizedBox(width: 12),
            Expanded(child: _ImagePlaceholder(label: 'Clear subject')),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiScannerScreen(),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Open AI Scanner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HelpColors.primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: HelpColors.lightLavender,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HelpColors.border,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_outlined,
            color: HelpColors.primaryPurple,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: HelpColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// My reports help
// -----------------------------------------------------------------------------

class MyReportsHelpScreen extends StatelessWidget {
  const MyReportsHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'My Reports Help',
      subtitle: 'Understand the status of every rescue report.',
      bottomButtonText: 'Open My Reports',
      onBottomButtonPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyReportsScreen(),
          ),
        );
      },
      children: const [
        _StatusCard(
          title: 'Pending',
          description: 'Report received.',
          icon: Icons.schedule,
          color: HelpColors.secondaryText,
        ),
        _StatusCard(
          title: 'Under Review',
          description: 'The report is being checked.',
          icon: Icons.search,
          color: HelpColors.primaryPurple,
        ),
        _StatusCard(
          title: 'Assigned',
          description: 'A rescue team has been notified.',
          icon: Icons.assignment_turned_in_outlined,
          color: HelpColors.primaryPurple,
        ),
        _StatusCard(
          title: 'In Progress',
          description: 'Rescue work is underway.',
          icon: Icons.directions_run,
          color: HelpColors.pink,
        ),
        _StatusCard(
          title: 'Resolved',
          description: 'The case has been completed.',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        _StatusCard(
          title: 'Closed',
          description: 'The case has been closed.',
          icon: Icons.archive_outlined,
          color: HelpColors.secondaryText,
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return HelpContentCard(
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: HelpColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: HelpColors.secondaryText,
                    fontSize: 13,
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

// -----------------------------------------------------------------------------
// Account and app help pages
// -----------------------------------------------------------------------------

class AccountHelpScreen extends StatelessWidget {
  const AccountHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: 'Account & Profile',
      subtitle: 'Manage your account information in one place.',
      children: [
        HelpContentCard(
          child: Column(
            children: [
              HelpBullet(
                text:
                    'Update your name, phone number, email, and location from your profile.',
                icon: Icons.person_outline,
              ),
              HelpBullet(
                text:
                    'Keep your contact details updated so rescue teams can reach you.',
                icon: Icons.phone_outlined,
              ),
              HelpBullet(
                text:
                    'Review your activity, rescue points, and submitted reports.',
                icon: Icons.insights_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NotificationHelpScreen extends StatefulWidget {
  const NotificationHelpScreen({super.key});

  @override
  State<NotificationHelpScreen> createState() => _NotificationHelpScreenState();
}

class _NotificationHelpScreenState extends State<NotificationHelpScreen> {
  bool rescueUpdates = true;
  bool reportUpdates = true;
  bool ngoResponses = true;
  bool appAnnouncements = false;

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'Notifications',
      subtitle: 'Choose which alerts and updates you want to receive.',
      children: [
        const HelpContentCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification types',
                style: TextStyle(
                  color: HelpColors.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12),
              HelpBullet(
                text: 'Rescue updates',
                icon: Icons.pets_outlined,
              ),
              HelpBullet(
                text: 'Report status updates',
                icon: Icons.assignment_outlined,
              ),
              HelpBullet(
                text: 'NGO responses',
                icon: Icons.business_outlined,
              ),
              HelpBullet(
                text: 'App announcements',
                icon: Icons.campaign_outlined,
              ),
            ],
          ),
        ),
        _NotificationToggle(
          title: 'Rescue updates',
          value: rescueUpdates,
          onChanged: (value) {
            setState(() => rescueUpdates = value);
          },
        ),
        _NotificationToggle(
          title: 'Report status updates',
          value: reportUpdates,
          onChanged: (value) {
            setState(() => reportUpdates = value);
          },
        ),
        _NotificationToggle(
          title: 'NGO responses',
          value: ngoResponses,
          onChanged: (value) {
            setState(() => ngoResponses = value);
          },
        ),
        _NotificationToggle(
          title: 'App announcements',
          value: appAnnouncements,
          onChanged: (value) {
            setState(() => appAnnouncements = value);
          },
        ),
      ],
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return HelpContentCard(
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            color: HelpColors.primaryPurple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: HelpColors.darkText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: HelpColors.primaryPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class PrivacySafetyScreen extends StatelessWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpDetailScaffold(
      title: 'Privacy & Safety',
      subtitle:
          'Your information is used to support safe and effective rescue work.',
      children: [
        HelpContentCard(
          child: Column(
            children: [
              HelpBullet(
                text: 'Photos are stored securely.',
                icon: Icons.photo_camera_outlined,
              ),
              HelpBullet(
                text: 'Location information is used to help with rescue.',
                icon: Icons.location_on_outlined,
              ),
              HelpBullet(
                text: 'Your personal information is protected.',
                icon: Icons.lock_outline,
              ),
              HelpBullet(
                text: 'Your data is never sold.',
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AppIssuesScreen extends StatelessWidget {
  const AppIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'App Issues',
      subtitle: 'Tell us about bugs, technical problems, or improvements.',
      children: [
        _IssueActionCard(
          icon: Icons.bug_report_outlined,
          title: 'Report Bug',
          description: 'Tell us what went wrong.',
          onTap: () => _showMessage(context, 'Bug report form opened.'),
        ),
        _IssueActionCard(
          icon: Icons.feedback_outlined,
          title: 'Send Feedback',
          description: 'Share ideas to improve StrayCare.',
          onTap: () => _showMessage(context, 'Feedback form opened.'),
        ),
        const HelpContentCard(
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: HelpColors.primaryPurple,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'App Version: 1.0.0',
                  style: TextStyle(
                    color: HelpColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        _IssueActionCard(
          icon: Icons.support_agent_outlined,
          title: 'Contact Support',
          description: 'Get help from our support team.',
          onTap: () {
            Navigator.push(
              context,
              HelpSupportScreen._smoothRoute(
                const ContactSupportScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _IssueActionCard extends StatelessWidget {
  const _IssueActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: HelpColors.border,
            ),
            boxShadow: HelpColors.cardShadow,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.transparent,
                size: 1,
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: HelpColors.lightLavender,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: HelpColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: HelpColors.darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: HelpColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: HelpColors.primaryPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FAQ
// -----------------------------------------------------------------------------

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<Map<String, String>> questions = [
    {
      'question': 'What happens after reporting?',
      'answer':
          'Your report is received, reviewed, and shared with the appropriate rescue team when possible. You can follow updates in My Reports.',
    },
    {
      'question': 'How accurate is AI Scan?',
      'answer':
          'AI Scan provides assistance based on the photo. It is not a replacement for professional veterinary or rescue advice.',
    },
    {
      'question': 'Can I report anonymously?',
      'answer':
          'This depends on the information required by your rescue workflow. Avoid sharing unnecessary personal information in notes.',
    },
    {
      'question': 'How long does rescue take?',
      'answer':
          'Response time depends on urgency, distance, availability, weather, and the capacity of nearby rescue organizations.',
    },
    {
      'question': 'How do I update my report?',
      'answer':
          'Open the report from My Reports and use the available update option, if the report is still active.',
    },
    {
      'question': 'How do I contact an NGO?',
      'answer':
          'Open Rescue Organizations from Help & Support to view available contact details.',
    },
    {
      'question': 'How do I delete my account?',
      'answer':
          'Contact the support team and request account deletion. They may ask you to confirm ownership of the account.',
    },
    {
      'question': 'Can I track rescue progress?',
      'answer':
          'Yes. Open My Reports to view statuses such as Pending, Under Review, Assigned, In Progress, Resolved, and Closed.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return HelpDetailScaffold(
      title: 'Frequently Asked Questions',
      subtitle: 'Find quick answers to common StrayCare questions.',
      children: questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;

        return _FaqTile(
          key: PageStorageKey('faq-$index'),
          question: question['question']!,
          answer: question['answer']!,
        );
      }).toList(),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    super.key,
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HelpColors.border,
        ),
        boxShadow: HelpColors.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: HelpColors.lightLavender,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 3,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          iconColor: HelpColors.primaryPurple,
          collapsedIconColor: HelpColors.secondaryText,
          title: Text(
            question,
            style: const TextStyle(
              color: HelpColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  color: HelpColors.secondaryText,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Contact support
// -----------------------------------------------------------------------------

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final subjectController = TextEditingController();
  final messageController = TextEditingController();

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HelpColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: HelpColors.darkText,
          ),
        ),
        title: const Text(
          'Contact Support',
          style: TextStyle(
            color: HelpColors.darkText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HelpContentCard(
              color: HelpColors.contactLavender,
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    color: HelpColors.primaryPurple,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Our support team is ready to help you with your questions and app issues.',
                      style: TextStyle(
                        color: HelpColors.darkText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Send us a message',
              style: TextStyle(
                color: HelpColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: _inputDecoration('Subject'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 6,
              decoration: _inputDecoration('Describe your issue'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your support message has been saved.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HelpColors.primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Send Message',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: HelpColors.secondaryText,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: HelpColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: HelpColors.primaryPurple,
        ),
      ),
    );
  }
}
