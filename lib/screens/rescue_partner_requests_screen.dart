import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RescuePartnerRequestsScreen extends StatefulWidget {
  const RescuePartnerRequestsScreen({super.key});

  @override
  State<RescuePartnerRequestsScreen> createState() => _RescuePartnerRequestsScreenState();
}

class _RescuePartnerRequestsScreenState extends State<RescuePartnerRequestsScreen> {
  static const _apiBaseUrl = 'http://10.250.236.99:5000';
  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/partner-requests?status=pending'),
        headers: {'Authorization': 'Bearer ${prefs.getString('token') ?? ''}'},
      );
      if (response.statusCode != 200) throw Exception('Could not load requests');
      final data = jsonDecode(response.body);
      final requests = data['data']?['requests'];
      if (mounted && requests is List) {
        setState(() => _requests = requests.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(Map<String, dynamic> request, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final response = await http.patch(
      Uri.parse('$_apiBaseUrl/api/partner-requests/${request['id']}/$action'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${prefs.getString('token') ?? ''}',
      },
      body: jsonEncode(action == 'reject' ? {'rejectionReason': 'Application did not meet current partner requirements.'} : {}),
    );
    if (!mounted) return;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request could not be updated')));
    }
  }

  void _showDetails(Map<String, dynamic> request) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request['organizationName'] ?? 'Partner request', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2E1A47))),
              const SizedBox(height: 14),
              _detail('Contact', request['contactPerson']),
              _detail('Phone', request['phone']),
              _detail('Email', request['email']),
              _detail('Address', request['address']),
              _detail('Website', request['website']?.toString().isEmpty == false ? request['website'] : 'Not provided'),
              _detail('Animals supported', request['animalsSupported']),
              _detail('Emergency rescue', request['emergencyRescue'] == true ? 'Yes' : 'No'),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(sheetContext); _review(request, 'reject'); }, child: const Text('Reject'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () { Navigator.pop(sheetContext); _review(request, 'approve'); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6A3EA1)), child: const Text('Approve'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, dynamic value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text('$label: ${value ?? 'Not provided'}', style: const TextStyle(color: Color(0xFF4A4152))),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FA),
      appBar: AppBar(title: const Text('Rescue Partner Requests'), backgroundColor: Colors.transparent, foregroundColor: const Color(0xFF2E1A47)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A3EA1)))
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: _requests.isEmpty
                  ? ListView(children: const [SizedBox(height: 220), Center(child: Text('No pending partner requests.'))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (_, index) {
                        final request = _requests[index];
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(request['organizationName'] ?? 'Unnamed organization', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2E1A47))),
                            subtitle: Text('Contact: ${request['contactPerson'] ?? 'Not provided'}\n${request['address'] ?? 'Address not provided'}\nStatus: Pending'),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF6A3EA1)),
                            onTap: () => _showDetails(request),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
