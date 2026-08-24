import 'package:flutter/material.dart';

import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

/// One points-history entry.
class PointsHistoryEntry {
  const PointsHistoryEntry({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.points,
  });

  final String title;
  final String subtitle;
  final String timeAgo;
  final int points;
}

/// One method of earning points.
class EarnMethod {
  const EarnMethod({
    required this.icon,
    required this.label,
    required this.points,
  });

  final IconData icon;
  final String label;
  final int points;
}

/// One redeemable reward.
class RewardItem {
  const RewardItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cost,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int cost;
  final bool locked;
}

/// StrayCare Rescue Points screen.
class RescuePointsScreen extends StatelessWidget {
  const RescuePointsScreen({
    super.key,
    this.rescuePoints = 320,
    this.tierName = 'Silver Rescuer',
    this.nextTierName = 'Gold Rescuer',
    this.pointsToNextTier = 180,
    this.pointsForNextTier = 500,
    this.earnMethods,
    this.rewards,
    this.history,
    this.onBack,
    this.onRedeem,
    this.currentTabIndex = 4,
    this.onTabChanged,
  });

  final int rescuePoints;
  final String tierName;
  final String nextTierName;
  final int pointsToNextTier;
  final int pointsForNextTier;

  final List<EarnMethod>? earnMethods;
  final List<RewardItem>? rewards;
  final List<PointsHistoryEntry>? history;

  final VoidCallback? onBack;
  final void Function(RewardItem reward)? onRedeem;

  final int currentTabIndex;
  final void Function(int index)? onTabChanged;

  static const Color kBackground = Color(0xFFEDE3F5);
  static const Color kPrimaryPurple = Color(0xFF6A3EA1);
  static const Color kSecondaryPurple = Color(0xFF8B63C7);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kLightPurple = Color(0xFFF1E7F7);
  static const Color kTextDark = Color(0xFF2E1A47);
  static const Color kTextGrey = Color(0xFF8D8398);
  static const Color kCard = Colors.white;

  static const List<EarnMethod> _defaultEarnMethods = [
    EarnMethod(
      icon: Icons.description_outlined,
      label: 'Submit a report',
      points: 20,
    ),
    EarnMethod(
      icon: Icons.favorite_border_rounded,
      label: 'Help rescue an animal',
      points: 50,
    ),
    EarnMethod(
      icon: Icons.location_on_outlined,
      label: 'Verify a nearby case',
      points: 10,
    ),
    EarnMethod(
      icon: Icons.share_outlined,
      label: 'Share with friends',
      points: 15,
    ),
  ];

  static const List<RewardItem> _defaultRewards = [
    RewardItem(
      icon: Icons.pets,
      title: 'StrayCare Tote Bag',
      subtitle: 'Eco-friendly canvas tote',
      cost: 150,
    ),
    RewardItem(
      icon: Icons.local_cafe_outlined,
      title: '₹100 Cafe Voucher',
      subtitle: 'Partner cafes in Mumbai',
      cost: 250,
    ),
    RewardItem(
      icon: Icons.volunteer_activism_outlined,
      title: 'Donate to Shelter',
      subtitle: 'Fund a rescue meal kit',
      cost: 100,
    ),
    RewardItem(
      icon: Icons.card_giftcard_outlined,
      title: 'StrayCare Hoodie',
      subtitle: 'Limited edition, Gold tier',
      cost: 600,
      locked: true,
    ),
  ];

  static const List<PointsHistoryEntry> _defaultHistory = [
    PointsHistoryEntry(
      title: 'Report resolved',
      subtitle: 'Injured cat, Bandra West',
      timeAgo: '2d ago',
      points: 50,
    ),
    PointsHistoryEntry(
      title: 'Redeemed: Cafe Voucher',
      subtitle: 'Sent to your email',
      timeAgo: '5d ago',
      points: -250,
    ),
    PointsHistoryEntry(
      title: 'Verified nearby case',
      subtitle: 'Khar West',
      timeAgo: '6d ago',
      points: 10,
    ),
    PointsHistoryEntry(
      title: 'Submitted a report',
      subtitle: 'Stray dog, Andheri East',
      timeAgo: '1w ago',
      points: 20,
    ),
    PointsHistoryEntry(
      title: 'Shared with friends',
      subtitle: 'Referral bonus',
      timeAgo: '2w ago',
      points: 15,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final methods = earnMethods ?? _defaultEarnMethods;
    final rewardList = rewards ?? _defaultRewards;
    final historyList = history ?? _defaultHistory;

    final progress = pointsForNextTier <= 0
        ? 0.0
        : (rescuePoints / pointsForNextTier).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _TopBar(
                onBack: onBack ?? () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rescue Points',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: kPrimaryPurple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Earned by helping strays in your city',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PointsBalanceCard(
                      rescuePoints: rescuePoints,
                      tierName: tierName,
                      nextTierName: nextTierName,
                      pointsToNextTier: pointsToNextTier,
                      progress: progress,
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeading(title: 'Ways to Earn'),
                    const SizedBox(height: 12),
                    _EarnGrid(methods: methods),
                    const SizedBox(height: 20),
                    const _SectionHeading(title: 'Redeem Rewards'),
                    const SizedBox(height: 12),
                    _RewardsList(
                      rewards: rewardList,
                      currentPoints: rescuePoints,
                      onRedeem: onRedeem,
                    ),
                    const SizedBox(height: 20),
                    const _SectionHeading(title: 'Points History'),
                    const SizedBox(height: 12),
                    _HistoryCard(entries: historyList),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StrayCareBottomNav(
        currentIndex: currentTabIndex,
        onTap: onTabChanged ?? (index) => _handleNavigation(context, index),
      ),
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

      case 4:
        break;
    }
  }
}

// -----------------------------------------------------------------------------
// Top bar
// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(11),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: RescuePointsScreen.kPrimaryPurple,
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Points balance card
// -----------------------------------------------------------------------------

class _PointsBalanceCard extends StatelessWidget {
  const _PointsBalanceCard({
    required this.rescuePoints,
    required this.tierName,
    required this.nextTierName,
    required this.pointsToNextTier,
    required this.progress,
  });

  final int rescuePoints;
  final String tierName;
  final String nextTierName;
  final int pointsToNextTier;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RescuePointsScreen.kPrimaryPurple,
            RescuePointsScreen.kSecondaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: RescuePointsScreen.kPrimaryPurple.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: Icon(
              Icons.pets,
              size: 120,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tierName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Total Rescue Points',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$rescuePoints',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Icon(
                      Icons.pets,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    RescuePointsScreen.kPink,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$pointsToNextTier points to $nextTierName',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
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
// Section heading
// -----------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: RescuePointsScreen.kPrimaryPurple,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Earn grid (FIXED - Column layout + fixed height)
// -----------------------------------------------------------------------------

class _EarnGrid extends StatelessWidget {
  const _EarnGrid({
    required this.methods,
  });

  final List<EarnMethod> methods;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 600 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: methods.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 120, // Fixed height for every card
          ),
          itemBuilder: (context, index) {
            final method = methods[index];

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RescuePointsScreen.kCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: RescuePointsScreen.kPrimaryPurple.withValues(
                      alpha: 0.04,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: RescuePointsScreen.kLightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      method.icon,
                      size: 18,
                      color: RescuePointsScreen.kPrimaryPurple,
                    ),
                  ),
                  Text(
                    method.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: RescuePointsScreen.kTextDark,
                      height: 1.25,
                    ),
                  ),
                  Text(
                    '+${method.points} pts',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: RescuePointsScreen.kPink,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Rewards list
// -----------------------------------------------------------------------------

class _RewardsList extends StatelessWidget {
  const _RewardsList({
    required this.rewards,
    required this.currentPoints,
    required this.onRedeem,
  });

  final List<RewardItem> rewards;
  final int currentPoints;
  final void Function(RewardItem)? onRedeem;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rewards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final reward = rewards[index];
          final canAfford = currentPoints >= reward.cost && !reward.locked;

          return Container(
            width: 150,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: RescuePointsScreen.kCard,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: RescuePointsScreen.kPrimaryPurple.withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE7ED),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    reward.icon,
                    size: 19,
                    color: RescuePointsScreen.kPink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  reward.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: RescuePointsScreen.kTextDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: RescuePointsScreen.kTextGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: canAfford ? () => onRedeem?.call(reward) : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: reward.locked
                          ? const Color(0xFFF0EDF6)
                          : canAfford
                              ? RescuePointsScreen.kPrimaryPurple
                              : RescuePointsScreen.kLightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        reward.locked ? 'Locked' : '${reward.cost} pts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: reward.locked
                              ? RescuePointsScreen.kTextGrey
                              : canAfford
                                  ? Colors.white
                                  : RescuePointsScreen.kPrimaryPurple,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// History
// -----------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entries,
  });

  final List<PointsHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: RescuePointsScreen.kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RescuePointsScreen.kPrimaryPurple.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int index = 0; index < entries.length; index++) ...[
            _HistoryTile(entry: entries[index]),
            if (index != entries.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  color: Color(0xFFF0EDF6),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
  });

  final PointsHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isEarned = entry.points >= 0;
    final displayColor = isEarned
        ? const Color(0xFF2FAE66)
        : RescuePointsScreen.kPink;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEarned
                  ? const Color(0xFFE7F7EE)
                  : const Color(0xFFFDE7ED),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              isEarned ? Icons.add_rounded : Icons.redeem_rounded,
              size: 18,
              color: displayColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: RescuePointsScreen.kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.subtitle} · ${entry.timeAgo}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: RescuePointsScreen.kTextGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isEarned ? '+' : ''}${entry.points}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: displayColor,
            ),
          ),
        ],
      ),
    );
  }
}