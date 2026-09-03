import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void dispose() {
    for (final controller in [_organization, _contact, _email, _phone, _address, _website, _animals]) {
      controller.dispose();
    }
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partnership request submitted. An admin will review your application.')),
        );
        Navigator.pop(context);
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
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
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
      ),
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
