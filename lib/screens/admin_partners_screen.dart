import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class AdminPartnersScreen extends StatefulWidget {
  const AdminPartnersScreen({super.key});

  @override
  State<AdminPartnersScreen> createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _partners = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadPartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/partners'),
        headers: {
          if (prefs.getString('token')?.isNotEmpty == true)
            'Authorization': 'Bearer ${prefs.getString('token')}',
        },
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['message'] ?? 'Could not load approved partners');
      }

      final rawPartners = body['data']?['partners'];
      if (!mounted) return;
      setState(() {
        _partners = rawPartners is List
            ? rawPartners
                .whereType<Map>()
                .map((partner) => Map<String, dynamic>.from(partner))
                .toList()
            : [];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPartners {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _partners;

    return _partners.where((partner) {
      final values = [
        partner['organizationName'],
        partner['name'],
        partner['email'],
      ].map((value) => value?.toString().toLowerCase() ?? '');
      return values.any((value) => value.contains(query));
    }).toList();
  }

  String _value(Map<String, dynamic> partner, String key,
      [String fallback = 'Not provided']) {
    final value = partner[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final partners = _filteredPartners;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadPartners,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
          children: [
            const Text(
              'Approved Partners',
              style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E1A47)),
            ),
            const SizedBox(height: 6),
            const Text(
              'NGOs approved by the StrayCare team.',
              style: TextStyle(color: Color(0xFF8D8398)),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search organization, partner, or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()))
            else if (_error != null)
              _MessageState(message: _error!, onRetry: _loadPartners)
            else if (partners.isEmpty)
              const _MessageState(message: 'No approved NGO partners yet.')
            else
              ...partners.map(
                (partner) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PartnerCard(
                    organization: _value(partner, 'organizationName'),
                    name: _value(partner, 'name'),
                    email: _value(partner, 'email'),
                    phone: _value(partner, 'phone'),
                    address:
                        _value(partner, 'address', _value(partner, 'location')),
                    approvedAt: partner['approvedAt']?.toString(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard(
      {required this.organization,
      required this.name,
      required this.email,
      required this.phone,
      required this.address,
      this.approvedAt});

  final String organization;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String? approvedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFF1E9FA),
              child: Icon(Icons.apartment_outlined, color: Color(0xFF6A3EA1)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(organization,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E1A47)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5F5EA),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Approved',
                  style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 14),
          _Detail(icon: Icons.person_outline, text: name),
          _Detail(icon: Icons.email_outlined, text: email),
          _Detail(icon: Icons.phone_outlined, text: phone),
          _Detail(icon: Icons.location_on_outlined, text: address),
          if (approvedAt != null && approvedAt!.isNotEmpty)
            _Detail(
                icon: Icons.calendar_today_outlined,
                text: 'Approved: ${approvedAt!.split('T').first}'),
        ]),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(children: [
          Icon(icon, size: 16, color: const Color(0xFF8D8398)),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(text, style: const TextStyle(color: Color(0xFF6F647A))))
        ]),
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 44),
        child: Column(children: [
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6F647A))),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ]),
      );
}
