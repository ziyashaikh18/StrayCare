import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'admin_home_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'ngo_home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _message('Enter the verification code.');
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email, 'code': code}),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['success'] != true) {
        _message(data['message']?.toString() ?? 'Verification failed.');
        return;
      }

      final token = data['data']?['token']?.toString();
      final role = data['data']?['user']?['role']?.toString();
      if (token == null || role == null) {
        _message('Verification succeeded, but the session was incomplete.');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role);
      _message('Email verified successfully.');
      if (!mounted) return;
      final Widget next = role == 'admin'
          ? const AdminHomeScreen()
          : role == 'ngo'
              ? const NgoHomeScreen()
              : const HomeScreen();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => next),
        (_) => false,
      );
    } on Exception catch (error) {
      if (mounted) _message('Unable to verify email: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/resend-verification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email}),
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      final data = jsonDecode(response.body);
      _message(data['message']?.toString() ?? 'Could not resend code.');
    } on Exception catch (error) {
      if (mounted) _message('Unable to resend code: $error');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EEF9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8FD),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF7D4BB6)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Icon(Icons.mark_email_read_rounded, size: 88, color: Color(0xFF55C765)),
                    const SizedBox(height: 24),
                    const Text('Verify Your Email', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Color(0xFF3E1E68))),
                    const SizedBox(height: 12),
                    Text('Enter the verification code sent to ${widget.email}.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Color(0xFF8E849B), height: 1.5)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Verification Code',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _verify,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7D4BB6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 17), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                        child: Text(_isSubmitting ? 'Verifying...' : 'Verify Email'),
                      ),
                    ),
                    TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: Text(_isResending ? 'Resending...' : 'Resend Verification Code', style: const TextStyle(color: Color(0xFF7D4BB6), fontWeight: FontWeight.w700)),
                    ),
                    TextButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false), child: const Text('Use a different email', style: TextStyle(color: Color(0xFF8E849B)))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
