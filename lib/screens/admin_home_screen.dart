import 'package:flutter/material.dart';

import 'all_rescue_cases_screen.dart';
import 'rescue_partner_requests_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _AdminOverview(
        onOpenRequests: () => setState(() => _currentIndex = 1),
        onOpenCases: () => setState(() => _currentIndex = 2),
      ),
      const RescuePartnerRequestsScreen(),
      const AllRescueCasesScreen(showBottomNav: false, showBackButton: false),
    ];

    return Scaffold(
      backgroundColor: AdminHomeScreen.kBackground,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Partner Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Cases',
          ),
        ],
      ),
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({required this.onOpenRequests, required this.onOpenCases});

  final VoidCallback onOpenRequests;
  final VoidCallback onOpenCases;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AdminHomeScreen.kDeepPurple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Platform administration and rescue case oversight.',
              style: TextStyle(color: Color(0xFF8D8398)),
            ),
            const SizedBox(height: 24),
            _OverviewAction(
              icon: Icons.handshake_outlined,
              title: 'Rescue partner requests',
              subtitle: 'Review pending NGO applications.',
              onTap: onOpenRequests,
            ),
            const SizedBox(height: 12),
            _OverviewAction(
              icon: Icons.assignment_outlined,
              title: 'Rescue case management',
              subtitle: 'View all reports and monitor their status.',
              onTap: onOpenCases,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewAction extends StatelessWidget {
  const _OverviewAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: Icon(icon, color: AdminHomeScreen.kPurple, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
