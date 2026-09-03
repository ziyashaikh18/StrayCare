import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class PartnerRequestFormScreen extends StatefulWidget {
  const PartnerRequestFormScreen({super.key});

  @override
  State<PartnerRequestFormScreen> createState() => _PartnerRequestFormScreenState();
}

class _PartnerRequestFormScreenState extends State<PartnerRequestFormScreen> {
  static const _apiBaseUrl = 'http://10.250.236.99:5000';
  final _formKey = GlobalKey<FormState>();
  final _organization = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _animals = TextEditingController();
  bool _emergencyRescue = false;
  bool _submitting = false;
  bool _loadingStatus = true;
  bool _statusRequestInFlight = false;
  Timer? _statusTimer;
  String? _status;
  String? _statusOrganizationName;
  String? _rejectionReason;
  String? _refreshError;

  @override
  void dispose() {
    _statusTimer?.cancel();
    for (final controller in [_organization, _contact, _email, _phone, _address, _website, _animals]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchPartnerStatus();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchPartnerStatus(),
    );
  }

  Future<void> _fetchPartnerStatus() async {
    if (!mounted || _statusRequestInFlight) return;
    _statusRequestInFlight = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/partner-requests/my-status'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      if (response.statusCode != 200) {
        throw Exception('Unable to refresh application status');
      }

      final data = jsonDecode(response.body);
      final request = data['data']?['request'];
      setState(() {
        _status = request is Map ? request['status']?.toString() : null;
        _statusOrganizationName =
            request is Map ? request['organizationName']?.toString() : null;
        _rejectionReason =
            request is Map ? request['rejectionReason']?.toString() : null;
        _refreshError = null;
        _loadingStatus = false;
      });
      await prefs.setString(
        'partner_status',
        request is Map ? request['status']?.toString() ?? '' : '',
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _refreshError = 'Unable to refresh application status.';
          _loadingStatus = false;
        });
      }
    } finally {
      _statusRequestInFlight = false;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/partner-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('token') ?? ''}',
        },
        body: jsonEncode({
          'organizationName': _organization.text.trim(),
          'contactPerson': _contact.text.trim(),
          'email': _email.text.trim(),
          'phone': _phone.text.trim(),
          'address': _address.text.trim(),
          'website': _website.text.trim(),
          'animalsSupported': _animals.text.trim(),
          'emergencyRescue': _emergencyRescue,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        await _fetchPartnerStatus();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Could not submit request');
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FA),
      appBar: AppBar(
        title: const Text('Become a Rescue Partner'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2E1A47),
        actions: [
          IconButton(
            tooltip: 'Refresh application status',
            onPressed: _statusRequestInFlight ? null : _fetchPartnerStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A3EA1)))
          : _status == null
              ? _buildApplicationForm()
              : _buildStatusView(),
    );
  }

  Widget _buildApplicationForm() {
    return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (_refreshError != null) ...[
              _statusMessage(_refreshError!, const Color(0xFFFFF3CD)),
              const SizedBox(height: 12),
            ],
            const Text('Tell us about your rescue organization.', style: TextStyle(color: Color(0xFF8D8398))),
            const SizedBox(height: 18),
            _field(_organization, 'Organization Name'),
            _field(_contact, 'Contact Person Name'),
            _field(_email, 'Email', keyboardType: TextInputType.emailAddress),
            _field(_phone, 'Phone', keyboardType: TextInputType.phone),
            _field(_address, 'Location / City'),
            _field(_website, 'Website (optional)', required: false),
            _field(_animals, 'Animals Supported'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Emergency Rescue Available?'),
              value: _emergencyRescue,
              activeColor: const Color(0xFF6A3EA1),
              onChanged: (value) => setState(() => _emergencyRescue = value),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6A3EA1),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_submitting ? 'Submitting...' : 'Submit Partnership Request'),
            ),
          ],
        ),
      );
  }

  Widget _buildStatusView() {
    final isApproved = _status == 'approved';
    final isRejected = _status == 'rejected';
    final title = isApproved
        ? 'Application Approved'
        : isRejected
            ? 'Application Rejected'
            : 'Application submitted';
    final message = isApproved
        ? 'You are now an authorized StrayCare Rescue Partner. Please log out and log in again to access your NGO dashboard.'
        : isRejected
            ? (_rejectionReason?.isNotEmpty == true
                ? _rejectionReason!
                : 'Your rescue partner application was not approved.')
            : 'Your rescue partner application is currently under review.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        if (_refreshError != null) ...[
          _statusMessage(_refreshError!, const Color(0xFFFFF3CD)),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isApproved
                    ? Icons.verified_rounded
                    : isRejected
                        ? Icons.cancel_outlined
                        : Icons.hourglass_top_rounded,
                color: isApproved ? const Color(0xFF3FAE5C) : const Color(0xFF6A3EA1),
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2E1A47))),
              if (_statusOrganizationName?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(_statusOrganizationName!, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6A3EA1))),
              ],
              const SizedBox(height: 10),
              Text(message, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF4A4152))),
              if (isApproved) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _logoutAndLoginAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6A3EA1),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Logout & Login Again'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusMessage(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(message, style: const TextStyle(color: Color(0xFF4A4152))),
    );
  }

  Future<void> _logoutAndLoginAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _field(TextEditingController controller, String label, {bool required = true, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
        validator: required ? (value) => value == null || value.trim().isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
