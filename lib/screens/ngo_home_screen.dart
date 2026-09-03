import 'package:flutter/material.dart';
import 'package:straycare_splash/screens/all_rescue_cases_screen.dart';
import 'package:straycare_splash/screens/ngo_profile_screen.dart';
import 'package:straycare_splash/screens/nearby_cases_screen.dart';

/// NgoHomeScreen: Main dashboard for NGO and Admin users.
/// Hosts AllRescueCasesScreen with a minimal bottom navigation bar
/// containing [Cases, Map, Profile]. Does NOT include citizen actions
/// like "Report a Rescue".
class NgoHomeScreen extends StatefulWidget {
  const NgoHomeScreen({super.key});

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kSubtitleGray = Color(0xFF8D8398);

  @override
  State<NgoHomeScreen> createState() => _NgoHomeScreenState();
}

class _NgoHomeScreenState extends State<NgoHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NgoHomeScreen.kBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const AllRescueCasesScreen(
            showBottomNav: false,
            showBackButton: false,
          ),
          NearbyCasesScreen(
            showBottomNav: false,
            onBack: () => setState(() => _currentIndex = 0),
          ),
          NgoProfileScreen(
            onBack: () => setState(() => _currentIndex = 0),
          ),
        ],
      ),
      bottomNavigationBar: _NgoBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NgoBottomNav extends StatelessWidget {
  const _NgoBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.pets_rounded, label: 'Cases'),
      (icon: Icons.map_outlined, label: 'Map'),
      (icon: Icons.person_outline, label: 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              spreadRadius: 0.5,
              offset: Offset(0, 5),
            ),
            BoxShadow(
              color: Color(0x10A56DE2),
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            final color = isSelected
                ? NgoHomeScreen.kPurple
                : const Color(0xFFAFA4BB);

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: color,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Container(
                        width: 26,
                        height: 3,
                        decoration: BoxDecoration(
                          color: NgoHomeScreen.kPurple,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      )
                    else
                      const SizedBox(height: 3),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
