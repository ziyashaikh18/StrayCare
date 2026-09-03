import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'partner_request_form_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';

class _Organization {
  const _Organization({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    this.website,
    this.hours = 'Open 24 hours',
    this.isOpen = true,
    this.isFeatured = false,
    this.isVerified = false,
    this.icon = Icons.pets,
    this.description,
  }) : iconColor = const Color(0xFF6A3EA1);

  final String id;
  final String name;
  final String category;
  final String address;
  final String phone;
  final String? website;
  final String hours;
  final bool isOpen;
  final bool isFeatured;
  final bool isVerified;
  final IconData icon;
  final Color iconColor;
  final String? description;
}

class RescueOrganizationsScreen extends StatefulWidget {
  const RescueOrganizationsScreen({super.key});

  @override
  State<RescueOrganizationsScreen> createState() =>
      _RescueOrganizationsScreenState();
}

class _RescueOrganizationsScreenState
    extends State<RescueOrganizationsScreen> {
  static const Color kBackground = Color(0xFFF8F2FA);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kCardBorder = Color(0xFFD9C7EA);
  static const Color kAccentPurple = Color(0xFF6A3EA1);

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favorites = {};

  int _selectedFilter = 0;
  int _navIndex = 0;

  final List<String> _filters = const [
    'All',
    'Animal Shelters',
    'NGOs',
    'Wildlife',
    'Rehabilitation',
    'Emergency',
  ];

  final _Organization _featured = const _Organization(
    id: 'gully-stray-care',
    name: 'Gully Stray Care',
    category: 'Animal Welfare Organization',
    address: 'Mumbai, Maharashtra',
    phone: '+91 93232 63322',
    website: 'https://gullystraycare.org/',
    hours: 'Emergency guidance',
    isOpen: true,
    isFeatured: true,
    isVerified: true,
    description:
        'Working for the welfare of stray animals through rescue, '
        'treatment, sterilization.',
  );

  final List<_Organization> _organizations = const [
    _Organization(
      id: 'helping-hands',
      name: 'Helping Hands Animal Welfare Foundation',
      category: 'Animal shelter',
      address: 'Narayan Niwas, 1678, Road No 24 B, Mumbai',
      phone: '083502 65889',
      website: 'https://helpinghandsanimalwelfarefoundation.com/',
      hours: 'Open 24 hours',
      isOpen: true,
      icon: Icons.home_work_outlined,
    ),
    _Organization(
      id: 'yoda-mumbai',
      name: 'YODA — Youth Organization in Defence of Animals',
      category: 'Community service / nonprofit',
      address: 'Shardal, Swami Vivekanand Marg, Mumbai',
      phone: '080 6366 9333',
      website: 'https://yoda.co.in/',
      hours: 'Opens tomorrow 09:30',
      isOpen: false,
      icon: Icons.groups_outlined,
    ),
    _Organization(
      id: 'raww-worli',
      name: 'RAWW (Resqink Association For Wildlife Welfare)',
      category: 'Wildlife rescue / public service',
      address:
          'Nature Library, Dr Annie Besant Road, Worli, Mumbai',
      phone: '076666 80202',
      website: 'https://www.raww.in/',
      hours: 'Opens tomorrow 10:00',
      isOpen: false,
      icon: Icons.forest_outlined,
      description:
          'Focused primarily on wildlife, bird and reptile rescue.',
    ),
    _Organization(
      id: 'yoda-borivali',
      name: 'YODA — Borivali Branch',
      category: 'Community service / nonprofit',
      address: '1992, 1999 Number, Borivali, Mumbai',
      phone: '080 6366 9333',
      website: 'https://yoda.co.in/',
      hours: 'Opens tomorrow 09:00',
      isOpen: false,
      icon: Icons.groups_outlined,
    ),
    _Organization(
      id: 'sarrp-india',
      name: 'SARRP INDIA',
      category: 'Reptile rescue / rehabilitation',
      address:
          'Swapna Cooperative Housing Society, Lt Road, Borivali, Mumbai',
      phone: '097693 35531',
      website: 'https://sarrpindia.org/',
      hours: 'Open 24 hours',
      isOpen: true,
      icon: Icons.pets_outlined,
    ),
    _Organization(
      id: 'amtm',
      name: 'Animal Matter To Me (AMTM)',
      category: 'Animal hospital / rescue / rehabilitation',
      address: 'Madh, Mumbai',
      phone: '',
      website: 'https://amtmindia.org/',
      hours: 'Open 24 hours',
      isOpen: true,
      icon: Icons.local_hospital_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Organization> get _filteredOrganizations {
    final query = _searchController.text.trim().toLowerCase();
    final selectedFilter = _filters[_selectedFilter].toLowerCase();

    return _organizations.where((org) {
      final searchableText =
          '${org.name} ${org.category} ${org.address}'.toLowerCase();

      final matchesSearch =
          query.isEmpty || searchableText.contains(query);

      final category = org.category.toLowerCase();
      final name = org.name.toLowerCase();

      final matchesFilter = switch (selectedFilter) {
        'all' => true,
        'animal shelters' => category.contains('shelter'),
        'ngos' =>
          category.contains('nonprofit') ||
          category.contains('organization') ||
          category.contains('welfare'),
        'wildlife' =>
          category.contains('wildlife') ||
          name.contains('wildlife'),
        'rehabilitation' =>
          category.contains('rehabilitation') ||
          name.contains('rehabilitation'),
        'emergency' => org.isOpen,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showMessage('Invalid link.');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      _showMessage('Could not open this link.');
    }
  }

  Future<void> _openWebsite(String? website) async {
    if (website == null || website.isEmpty) {
      _showMessage('Website is not available.');
      return;
    }

    await _launchUrl(website);
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) {
      _showMessage('Phone number is not available.');
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await _launchUrl('tel:$cleanPhone');
  }

  Future<void> _openGoogleMaps(_Organization org) async {
    final query = '${org.name}, ${org.address}';

    final mapsUri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': query,
      },
    );

    final launched = await launchUrl(
      mapsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      _showMessage('Could not open Google Maps.');
    }
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organizations = _filteredOrganizations;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchAndFilterRow(),
            const SizedBox(height: 10),
            _buildCategoryChips(),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                children: [
                  _buildFeaturedCard(_featured),
                  const SizedBox(height: 14),
                  if (organizations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No organizations found.',
                          style: TextStyle(
                            color: Color(0xFF8D8398),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final org in organizations) ...[
                      _buildOrgTile(org),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 4),
                  _buildSuggestBanner(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StrayCareBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() {
            _navIndex = index;
          });

          if (index == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
            ),
            color: kDeepPurple,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rescue Organizations',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Connect with verified NGOs and animal welfare organizations',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8D8398),
                  ),
                ),
              ],
            ),
          ),
          _iconBadgeButton(
            icon: Icons.notifications_none_rounded,
            badgeCount: 3,
            onTap: () => _showMessage('Notifications'),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 18,
            backgroundColor: kAccentPurple,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadgeButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: kCardBorder,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: kDeepPurple,
              size: 20,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0426B),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kCardBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'Search organizations, NGOs, shelters...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8D8398),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF8D8398),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: kAccentPurple,
                width: 1.2,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: kAccentPurple,
                ),
                SizedBox(width: 6),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kAccentPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? kAccentPurple : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? kAccentPurple : kCardBorder,
                  width: 1,
                ),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : kDeepPurple,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCard(_Organization org) {
    final isFav = _favorites.contains(org.id);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kCardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0426B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 11,
                      color: Colors.white,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Featured',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _toggleFavorite(org.id),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 15,
                    color: const Color(0xFFE0426B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Left: name + category + description. Right: goat image.
          // IntrinsicHeight + CrossAxisAlignment.stretch makes the image
          // grow/shrink to exactly match the text column's real height —
          // no fixed height, so no leftover gap and no cropped image.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              org.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kDeepPurple,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (org.isVerified) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: kAccentPurple,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        org.category,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: kAccentPurple,
                        ),
                      ),
                      if (org.description != null) ...[
                        const SizedBox(height: 7),
                        Text(
                          org.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF4A4152),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 140,
                    child: Image.asset(
                      'assets/images/goat.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 140),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _infoLine(Icons.location_on_outlined, org.address),
          const SizedBox(height: 4),
          _infoLine(
            Icons.access_time,
            org.hours,
            valueColor: kAccentPurple,
          ),
          const SizedBox(height: 4),
          _infoLine(Icons.call_outlined, org.phone),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWebsite(org.website),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(
                      Icons.language,
                      size: 18,
                    ),
                    label: const Text(
                      'Website',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 54,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => _call(org.phone),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAccentPurple,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: kCardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.call,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 54,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => _openGoogleMaps(org),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAccentPurple,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: kCardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(
    IconData icon,
    String text, {
    Color? valueColor,
  }) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: valueColor ?? const Color(0xFF8D8398),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: valueColor != null ? FontWeight.w700 : null,
              color: valueColor ?? const Color(0xFF4A4152),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrgTile(_Organization org) {
    final isFav = _favorites.contains(org.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kCardBorder,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFF1E7F7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              org.icon,
              color: org.iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  org.category,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: kAccentPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  org.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF8D8398),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: org.isOpen
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE0426B),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        org.hours,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: org.isOpen
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE0426B),
                        ),
                      ),
                    ),
                  ],
                ),
                if (org.phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    org.phone,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF8D8398),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: [
              GestureDetector(
                onTap: () => _toggleFavorite(org.id),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 15,
                    color: const Color(0xFFE0426B),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _call(org.phone),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: kAccentPurple,
                  child: Icon(
                    Icons.call,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kCardBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🐶🐱', style: TextStyle(fontSize: 22)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Want to work with StrayCare?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: kDeepPurple,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Join our rescue partner network.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8D8398),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PartnerRequestFormScreen(),
                ),
              ),
              icon: const Icon(Icons.add_business_outlined, size: 18),
              label: const Text(
                'Become a Rescue Partner',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}