import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  String _name = 'Administrator';
  String _email = 'Email not available';

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
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'token',
      'role',
      'userId',
      'user_name',
      'user_email',
      'user_phone',
      'user_location',
      'user_address',
      'organizationName',
      'partner_status',
    ]) {
      await prefs.remove(key);
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Sign out from the administrator account.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child:
                  const Text('Log Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (shouldLogout == true) await _logout();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          const Text('Admin Profile',
              style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E1A47))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              const CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFFF1E9FA),
                  child: Icon(Icons.admin_panel_settings_outlined,
                      size: 42, color: Color(0xFF6A3EA1))),
              const SizedBox(height: 14),
              Text(_name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E1A47))),
              const SizedBox(height: 5),
              Text(_email, style: const TextStyle(color: Color(0xFF8D8398))),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1E9FA),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Administrator',
                    style: TextStyle(
                        color: Color(0xFF6A3EA1), fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
          ),
        ],
      ),
    );
  }
}
