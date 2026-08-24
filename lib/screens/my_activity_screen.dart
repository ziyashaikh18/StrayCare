import 'package:flutter/material.dart';

import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

/// StrayCare My Activity screen.
class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({
    super.key,
    this.reportsSubmitted = 32,
    this.animalsHelped = 18,
    this.ongoingCases = 6,
    this.rescuePoints = 250,
    this.currentTabIndex = 4,
    this.onBack,
    this.onTabChanged,
  });

  final int reportsSubmitted;
  final int animalsHelped;
  final int ongoingCases;
  final int rescuePoints;

  final int currentTabIndex;
  final VoidCallback? onBack;
  final void Function(int index)? onTabChanged;

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  ActivityFilter selectedFilter = ActivityFilter.all;
  ActivitySort selectedSort = ActivitySort.newestFirst;

  List<ActivityEntry> get _filteredActivities {
    final activities = activityEntries.where((entry) {
      if (selectedFilter == ActivityFilter.all) return true;
      return entry.filter == selectedFilter;
    }).toList();

    if (selectedSort == ActivitySort.oldestFirst) {
      return activities.reversed.toList();
    }

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ActivityColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    ActivityHeader(
                      onBack: widget.onBack ??
                          () => Navigator.maybePop(context),
                    ),
                    const SizedBox(height: 20),
                    ActivityStatsCard(
                      reportsSubmitted: widget.reportsSubmitted,
                      animalsHelped: widget.animalsHelped,
                      ongoingCases: widget.ongoingCases,
                      rescuePoints: widget.rescuePoints,
                    ),
                    const SizedBox(height: 20),
                    ActivityFilterBar(
                      selectedFilter: selectedFilter,
                      onFilterSelected: (filter) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ActivityTimelineHeader(
                      selectedSort: selectedSort,
                      onSortChanged: (sort) {
                        setState(() {
                          selectedSort = sort;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    ActivityTimeline(
                      activities: _filteredActivities,
                    ),
                    const SizedBox(height: 24),
                    const ImpactCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StrayCareBottomNav(
        currentIndex: widget.currentTabIndex,
        onTap: widget.onTabChanged ??
            (index) => _handleBottomNavigation(context, index),
      ),
    );
  }

  void _handleBottomNavigation(BuildContext context, int index) {
    if (index == widget.currentTabIndex) return;

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
// Theme
// -----------------------------------------------------------------------------

class ActivityColors {
  static const Color background = Color(0xFFF8F7FB);
  static const Color deepPurple = Color(0xFF2B145A);
  static const Color primaryPurple = Color(0xFF6D3FD1);
  static const Color pink = Color(0xFFFF4D8D);
  static const Color secondaryText = Color(0xFF81798D);
  static const Color border = Color(0xFFECE8F5);
  static const Color lightPurple = Color(0xFFF0E9FF);
  static const Color lightPink = Color(0xFFFFEAF1);
  static const Color lightGreen = Color(0xFFE8F7EC);
  static const Color lightOrange = Color(0xFFFFF1DE);
  static const Color impactBackground = Color(0xFFF0E9FF);

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];
}

// -----------------------------------------------------------------------------
// Activity models
// -----------------------------------------------------------------------------

enum ActivityFilter {
  all,
  reports,
  aiScans,
  rescue,
  points,
}

enum ActivitySort {
  newestFirst,
  oldestFirst,
}

class ActivityEntry {
  const ActivityEntry({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.filter,
  });

  final String title;
  final String description;
  final String date;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final ActivityFilter filter;
}

const List<ActivityEntry> activityEntries = [
  ActivityEntry(
    title: 'Report Submitted',
    description: 'You reported an injured dog near Bandra, Mumbai.',
    date: 'Today',
    time: '6:32 PM',
    icon: Icons.description_outlined,
    iconColor: ActivityColors.primaryPurple,
    iconBackground: ActivityColors.lightPurple,
    filter: ActivityFilter.reports,
  ),
  ActivityEntry(
    title: 'AI Scan Completed',
    description: 'Injury assessment completed for your uploaded image.',
    date: 'Today',
    time: '5:48 PM',
    icon: Icons.auto_awesome,
    iconColor: ActivityColors.pink,
    iconBackground: ActivityColors.lightPink,
    filter: ActivityFilter.aiScans,
  ),
  ActivityEntry(
    title: 'Report Updated',
    description: 'Your case status changed to Rescue In Progress.',
    date: 'Yesterday',
    time: '4:20 PM',
    icon: Icons.refresh_rounded,
    iconColor: ActivityColors.primaryPurple,
    iconBackground: ActivityColors.lightPurple,
    filter: ActivityFilter.reports,
  ),
  ActivityEntry(
    title: 'Animal Helped',
    description: 'Rescue team responded to your reported case.',
    date: 'Yesterday',
    time: '2:15 PM',
    icon: Icons.pets,
    iconColor: Color(0xFF2FAE66),
    iconBackground: ActivityColors.lightGreen,
    filter: ActivityFilter.rescue,
  ),
  ActivityEntry(
    title: 'Rescue Points Earned',
    description: '+50 points for submitting a verified rescue report.',
    date: 'Aug 20',
    time: '11:30 AM',
    icon: Icons.workspace_premium_outlined,
    iconColor: Color(0xFFE9952F),
    iconBackground: ActivityColors.lightOrange,
    filter: ActivityFilter.points,
  ),
  ActivityEntry(
    title: 'Rescue Organization Contacted',
    description: 'You viewed/contacted PFA Mumbai for a rescue case.',
    date: 'Aug 19',
    time: '6:10 PM',
    icon: Icons.phone_outlined,
    iconColor: ActivityColors.pink,
    iconBackground: ActivityColors.lightPink,
    filter: ActivityFilter.rescue,
  ),
];

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

class ActivityHeader extends StatelessWidget {
  const ActivityHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActivityBackButton(onTap: onBack),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Activity',
                style: TextStyle(
                  color: ActivityColors.deepPurple,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Your recent actions and contributions',
                style: TextStyle(
                  color: ActivityColors.secondaryText,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const AnimalHeaderIllustration(),
      ],
    );
  }
}

class _ActivityBackButton extends StatelessWidget {
  const _ActivityBackButton({
    required this.onTap,
  });

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
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.arrow_back,
            color: ActivityColors.deepPurple,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class AnimalHeaderIllustration extends StatelessWidget {
  const AnimalHeaderIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: ActivityColors.lightPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                color: ActivityColors.primaryPurple,
                size: 34,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 53,
              height: 53,
              decoration: const BoxDecoration(
                color: ActivityColors.lightPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_outlined,
                color: ActivityColors.pink,
                size: 31,
              ),
            ),
          ),
          const Positioned(
            top: 0,
            right: 25,
            child: Icon(
              Icons.favorite,
              color: ActivityColors.pink,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Stats
// -----------------------------------------------------------------------------

class ActivityStatsCard extends StatelessWidget {
  const ActivityStatsCard({
    super.key,
    required this.reportsSubmitted,
    required this.animalsHelped,
    required this.ongoingCases,
    required this.rescuePoints,
  });

  final int reportsSubmitted;
  final int animalsHelped;
  final int ongoingCases;
  final int rescuePoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ActivityColors.border,
        ),
        boxShadow: ActivityColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: ActivityStatCard(
              value: '$reportsSubmitted',
              label: 'Reports\nSubmitted',
              icon: Icons.description_outlined,
              iconColor: ActivityColors.primaryPurple,
              iconBackground: ActivityColors.lightPurple,
            ),
          ),
          const _StatsDivider(),
          Expanded(
            child: ActivityStatCard(
              value: '$animalsHelped',
              label: 'Animals\nHelped',
              icon: Icons.pets,
              iconColor: ActivityColors.pink,
              iconBackground: ActivityColors.lightPink,
            ),
          ),
          const _StatsDivider(),
          Expanded(
            child: ActivityStatCard(
              value: '$ongoingCases',
              label: 'Ongoing\nCases',
              icon: Icons.shield_outlined,
              iconColor: ActivityColors.primaryPurple,
              iconBackground: ActivityColors.lightPurple,
            ),
          ),
          const _StatsDivider(),
          Expanded(
            child: ActivityStatCard(
              value: '$rescuePoints',
              label: 'Rescue\nPoints',
              icon: Icons.workspace_premium_outlined,
              iconColor: ActivityColors.pink,
              iconBackground: ActivityColors.lightPink,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityStatCard extends StatelessWidget {
  const ActivityStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 19,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: ActivityColors.deepPurple,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: ActivityColors.secondaryText,
            fontSize: 9.5,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatsDivider extends StatelessWidget {
  const _StatsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 58,
      color: ActivityColors.border,
    );
  }
}

// -----------------------------------------------------------------------------
// Filter chips
// -----------------------------------------------------------------------------

class ActivityFilterBar extends StatelessWidget {
  const ActivityFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final ActivityFilter selectedFilter;
  final ValueChanged<ActivityFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ActivityFilter.all,
      ActivityFilter.reports,
      ActivityFilter.aiScans,
      ActivityFilter.rescue,
      ActivityFilter.points,
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final filter = filters[index];

          return FilterChipWidget(
            label: _filterLabel(filter),
            selected: filter == selectedFilter,
            onTap: () => onFilterSelected(filter),
          );
        },
      ),
    );
  }

  static String _filterLabel(ActivityFilter filter) {
    switch (filter) {
      case ActivityFilter.all:
        return 'All';
      case ActivityFilter.reports:
        return 'Reports';
      case ActivityFilter.aiScans:
        return 'AI Scans';
      case ActivityFilter.rescue:
        return 'Rescue';
      case ActivityFilter.points:
        return 'Points';
    }
  }
}

class FilterChipWidget extends StatelessWidget {
  const FilterChipWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ActivityColors.primaryPurple : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? ActivityColors.primaryPurple
                  : ActivityColors.primaryPurple,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : ActivityColors.primaryPurple,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Timeline
// -----------------------------------------------------------------------------

class ActivityTimelineHeader extends StatelessWidget {
  const ActivityTimelineHeader({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final ActivitySort selectedSort;
  final ValueChanged<ActivitySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Activity Timeline',
            style: TextStyle(
              color: ActivityColors.deepPurple,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        PopupMenuButton<ActivitySort>(
          initialValue: selectedSort,
          onSelected: onSortChanged,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ActivitySort.newestFirst,
              child: Text('Newest First'),
            ),
            PopupMenuItem(
              value: ActivitySort.oldestFirst,
              child: Text('Oldest First'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ActivityColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedSort == ActivitySort.newestFirst
                      ? 'Newest First'
                      : 'Oldest First',
                  style: const TextStyle(
                    color: ActivityColors.primaryPurple,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: ActivityColors.primaryPurple,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({
    super.key,
    required this.activities,
  });

  final List<ActivityEntry> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _EmptyActivityState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return TimelineItemCard(
          activity: activities[index],
          isFirst: index == 0,
          isLast: index == activities.length - 1,
        );
      },
    );
  }
}

class TimelineItemCard extends StatelessWidget {
  const TimelineItemCard({
    super.key,
    required this.activity,
    required this.isFirst,
    required this.isLast,
  });

  final ActivityEntry activity;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                if (!isFirst)
                  const Expanded(
                    flex: 1,
                    child: ColoredBox(
                      color: ActivityColors.primaryPurple,
                    ),
                  )
                else
                  const Spacer(flex: 1),
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: ActivityColors.primaryPurple,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ActivityColors.background,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  const Expanded(
                    flex: 2,
                    child: ColoredBox(
                      color: ActivityColors.primaryPurple,
                    ),
                  )
                else
                  const Spacer(flex: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: ActivityColors.border,
                ),
                boxShadow: ActivityColors.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: activity.iconBackground,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      activity.icon,
                      color: activity.iconColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            color: ActivityColors.deepPurple,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          activity.description,
                          style: const TextStyle(
                            color: ActivityColors.secondaryText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Text(
                              activity.date,
                              style: const TextStyle(
                                color: ActivityColors.primaryPurple,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: ActivityColors.secondaryText,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              activity.time,
                              style: const TextStyle(
                                color: ActivityColors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ActivityColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.filter_alt_off_outlined,
            color: ActivityColors.primaryPurple,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'No activity found',
            style: TextStyle(
              color: ActivityColors.deepPurple,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try selecting another filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ActivityColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Impact card
// -----------------------------------------------------------------------------

class ImpactCard extends StatelessWidget {
  const ImpactCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ActivityColors.impactBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          _TrophyIllustration(),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thank you for making a difference!',
                  style: TextStyle(
                    color: ActivityColors.deepPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your actions are creating a better tomorrow for animals in need.',
                  style: TextStyle(
                    color: ActivityColors.secondaryText,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.pets,
            color: ActivityColors.pink,
            size: 38,
          ),
        ],
      ),
    );
  }
}

class _TrophyIllustration extends StatelessWidget {
  const _TrophyIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 57,
      height: 57,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1C9),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        color: Color(0xFFE7A82F),
        size: 32,
      ),
    );
  }
}