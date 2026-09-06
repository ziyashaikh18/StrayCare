import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'help_support_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';

class NgoProfileScreen extends StatefulWidget {
  const NgoProfileScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kPink = Color(0xFFE0426B);

  @override
  State<NgoProfileScreen> createState() => _NgoProfileScreenState();
}

class _NgoProfileScreenState extends State<NgoProfileScreen> {
  static const _apiBaseUrl = 'http://10.250.236.99:5000';

  String _name = 'Rescue team member';
  String _email = 'Email not available';
  String _phone = 'Phone not provided';
  String _location = 'Location not provided';
  String _role = 'NGO';
  String _organization = 'Organization details not provided';
  int _assigned = 0;
  int _inReview = 0;
  int _resolved = 0;
  bool _loadingStats = true;
  bool _isNgo = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _name = prefs.getString('user_name') ?? _name;
      _email = prefs.getString('user_email') ?? _email;
      _phone = prefs.getString('user_phone') ?? _phone;
      _location = prefs.getString('user_address') ??
          prefs.getString('user_location') ??
          _location;
      _role = (prefs.getString('role') ?? 'ngo').toUpperCase();
      _organization = prefs.getString('organizationName') ?? _organization;
      _isNgo = prefs.getString('role') == 'ngo';
    });

    await _loadStatistics(prefs.getString('token') ?? '');
  }

  Future<void> _loadStatistics(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/reports/admin/all'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final reports = data['data']?['reports'] ?? data['reports'];
      if (reports is! List || !mounted) return;

      var assigned = 0;
      var inReview = 0;
      var resolved = 0;
      for (final report in reports) {
        if (report is! Map) continue;
        final status = report['status']?.toString().toLowerCase();
        if (status == 'assigned') assigned++;
        if (status == 'inreview' ||
            status == 'in_review' ||
            status == 'inprogress') {
          inReview++;
        }
        if (status == 'resolved') resolved++;
      }

      setState(() {
        _assigned = assigned;
        _inReview = inReview;
        _resolved = resolved;
      });
    } catch (_) {
      // Keep zero values when the statistics service is unavailable.
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_location');
    await prefs.remove('organizationName');
    await prefs.remove('user_address');
    await prefs.remove('partner_status');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openLogoutConfirmation() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Sign out from this rescue operations account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _logOut();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(showBottomNav: false),
      ),
    );
  }

  void _openHelpSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpSupportScreen(showBottomNav: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NgoProfileScreen.kBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onBack: widget.onBack),
              const SizedBox(height: 18),
              _IdentityCard(
                name: _name,
                email: _email,
                phone: _phone,
                location: _location,
                role: _role,
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: 'Rescue operations'),
              const SizedBox(height: 10),
              _StatsCard(
                assigned: _assigned,
                inReview: _inReview,
                resolved: _resolved,
                loading: _loadingStats,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Organization / Partner',
                icon: Icons.apartment_outlined,
                value: _organization,
              ),
              if (_isNgo) ...[
                const SizedBox(height: 16),
                _PartnershipCard(
                  organization: _organization,
                  onRemove: _confirmRemovePartnership,
                ),
              ],
              const SizedBox(height: 16),
              _ActionCard(
                onNotifications: _openNotifications,
                onHelp: _openHelpSupport,
                onSettings: () =>
                    _showUnavailable('Settings are not configured yet.'),
                onLogout: _openLogoutConfirmation,
                onSwitchToCitizen: _isNgo
                    ? () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => route.isFirst,
                        )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnavailable(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmRemovePartnership() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove NGO Partnership?'),
        content: const Text(
          'You will stop being an NGO partner and this account will immediately become a normal Reporter account. Your reports and account history will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Remove Partnership',
              style: TextStyle(color: NgoProfileScreen.kPink),
            ),
          ),
        ],
      ),
    );

    if (shouldRemove != true || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/ngo/remove-partnership'),
        headers: {
          'Content-Type': 'application/json',
          if (prefs.getString('token')?.isNotEmpty == true)
            'Authorization': 'Bearer ${prefs.getString('token')}',
        },
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['success'] != true) {
        throw Exception(data['message'] ?? 'Could not remove partnership');
      }

      await prefs.setString('role', 'reporter');
      await prefs.setString('partner_status', 'none');
      await prefs.remove('organizationName');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showUnavailable(error.toString().replaceFirst('Exception: ', ''));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack ?? () => Navigator.maybePop(context),
          icon:
              const Icon(Icons.arrow_back, color: NgoProfileScreen.kDeepPurple),
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operations Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: NgoProfileScreen.kDeepPurple,
                ),
              ),
              Text(
                'Rescue team account and activity',
                style: TextStyle(
                    fontSize: 13.5, color: NgoProfileScreen.kSubtitleGray),
              ),
            ],
          ),
        ),
        const Icon(Icons.shield_outlined,
            color: NgoProfileScreen.kPurple, size: 28),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.role,
  });

  final String name;
  final String email;
  final String phone;
  final String location;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1E7F7),
            ),
            child: const Icon(Icons.person_outline,
                color: NgoProfileScreen.kPurple, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: NgoProfileScreen.kDeepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoleBadge(role: role),
                  ],
                ),
                const SizedBox(height: 10),
                _ContactLine(icon: Icons.email_outlined, text: email),
                _ContactLine(icon: Icons.phone_outlined, text: phone),
                _ContactLine(icon: Icons.location_on_outlined, text: location),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: NgoProfileScreen.kPurple,
        ),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: NgoProfileScreen.kSubtitleGray),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12.5, color: NgoProfileScreen.kSubtitleGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: NgoProfileScreen.kDeepPurple,
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.assigned,
    required this.inReview,
    required this.resolved,
    required this.loading,
  });

  final int assigned;
  final int inReview;
  final int resolved;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _Stat(
              value: assigned,
              label: 'Assigned cases',
              color: NgoProfileScreen.kPurple,
              loading: loading),
          const _Divider(),
          _Stat(
              value: inReview,
              label: 'In review',
              color: const Color(0xFFE8A23D),
              loading: loading),
          const _Divider(),
          _Stat(
              value: resolved,
              label: 'Resolved',
              color: const Color(0xFF3FAE5C),
              loading: loading),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.value,
      required this.label,
      required this.color,
      required this.loading});

  final int value;
  final String label;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: color, size: 23),
          const SizedBox(height: 7),
          Text(
            loading ? '-' : '$value',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: NgoProfileScreen.kDeepPurple),
          ),
          const SizedBox(height: 3),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10.5, color: NgoProfileScreen.kSubtitleGray)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 56, color: const Color(0xFFEFE4F6));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.title, required this.icon, required this.value});

  final String title;
  final IconData icon;
  final String value;

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
          Icon(icon, color: NgoProfileScreen.kPurple, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: NgoProfileScreen.kDeepPurple)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12, color: NgoProfileScreen.kSubtitleGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnershipCard extends StatelessWidget {
  const _PartnershipCard({required this.organization, required this.onRemove});

  final String organization;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6D5ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NGO Partnership',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: NgoProfileScreen.kDeepPurple),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: const Color(0xFFE5F5EA),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Approved',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(organization,
              style: const TextStyle(color: NgoProfileScreen.kSubtitleGray)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.link_off,
                color: NgoProfileScreen.kPink, size: 18),
            label: const Text('Remove NGO Partnership',
                style: TextStyle(
                    color: NgoProfileScreen.kPink,
                    fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: NgoProfileScreen.kPink),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(
      {required this.onNotifications,
      required this.onHelp,
      required this.onSettings,
      required this.onLogout,
      this.onSwitchToCitizen});

  final VoidCallback onNotifications;
  final VoidCallback onHelp;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback? onSwitchToCitizen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          if (onSwitchToCitizen != null) ...[
            _Action(
                icon: Icons.swap_horiz,
                title: 'Switch to Citizen Mode',
                subtitle: 'Open the normal reporter experience',
                onTap: onSwitchToCitizen!),
            const Divider(
                height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0E6F5)),
          ],
          _Action(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Manage operations alerts',
              onTap: onNotifications),
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0E6F5)),
          _Action(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Find rescue operations help',
              onTap: onHelp),
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0E6F5)),
          _Action(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'Manage account settings',
              onTap: onSettings),
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0E6F5)),
          _Action(
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out from this account',
              color: NgoProfileScreen.kPink,
              onTap: onLogout),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap,
      this.color = NgoProfileScreen.kDeepPurple});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: NgoProfileScreen.kSubtitleGray)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: color.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }
}
