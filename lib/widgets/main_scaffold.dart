import 'package:flutter/material.dart';
import 'package:straycare_splash/screens/home_screen.dart';
import 'package:straycare_splash/screens/report_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Decide which screen to show based on the selected bottom tab
    Widget body;
    switch (_currentIndex) {
      case 0:
        body = const HomeScreen();
        break;
      case 1:
        body = const ReportRescueScreen();
        break;
      case 2:
        body = const Center(child: Text('AI Scan (coming soon)'));
        break;
      case 3:
        body = const Center(child: Text('My Reports (coming soon)'));
        break;
      case 4:
      default:
        body = const Center(child: Text('Profile (coming soon)'));
        break;
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

/// This is your old _BottomNav, moved here so it is shared.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.add_circle_outline, label: 'Report'),
      (icon: Icons.memory, label: 'AI Scan'),
      (icon: Icons.description_outlined, label: 'My Reports'),
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
            final color =
                isSelected ? const Color(0xFF6A3EA1) : const Color(0xFFAFA4BB);

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: color, size: 22),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10.5,
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
                          color: const Color(0xFF6A3EA1),
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