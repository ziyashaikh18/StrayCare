import 'package:flutter/material.dart';

/// StrayCare "Personal Information" screen matching the design mock:
/// top bar with edit icon, avatar card, editable detail fields,
/// an expandable Emergency Contact section, and a gradient Save button.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({
    super.key,
    this.userName = 'Ziya Shaikh',
    this.userEmail = 'ziya.shaikh@email.com',
    this.userPhone = '+91 98765 43210',
    this.userLocation = 'Bandra, Mumbai, India',
    this.userBadge = 'Rescuer',
    this.dateOfBirth = '12 March 2004',
    this.gender = 'Female',
    this.bio =
        'Animal lover 🐾 | Passionate about rescuing and helping animals in need.',
    this.avatarAssetPath,
    this.onSave,
  });

  final String userName;
  final String userEmail;
  final String userPhone;
  final String userLocation;
  final String userBadge;
  final String dateOfBirth;
  final String gender;
  final String bio;
  final String? avatarAssetPath;

  /// Called with the updated field values when the user taps Save Changes.
  final void Function(Map<String, String> updatedFields)? onSave;

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  static const int kBioMaxLength = 150;

  static const Color kBackground = Color(0xFFEDE3F5);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPink = Color(0xFFE0426B);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kFieldBorder = Color(0xFFE7DBF2);
  static const Color kIconBg = Color(0xFFF1E7F7);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  late String _dateOfBirth;
  late String _gender;
  bool _emergencyExpanded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _phoneController = TextEditingController(text: widget.userPhone);
    _locationController = TextEditingController(text: widget.userLocation);
    _bioController = TextEditingController(text: widget.bio);
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _dateOfBirth = widget.dateOfBirth;
    _gender = widget.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1930),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPurple),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      setState(() {
        _dateOfBirth = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      });
    }
  }

  Future<void> _pickGender() async {
    final options = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (option) => ListTile(
                    title: Text(
                      option,
                      style: TextStyle(
                        color: kDeepPurple,
                        fontWeight: option == _gender
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: option == _gender
                        ? const Icon(Icons.check, color: kPurple)
                        : null,
                    onTap: () => Navigator.pop(context, option),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() => _gender = selected);
    }
  }

  void _handleSave() {
    widget.onSave?.call({
      'fullName': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'location': _locationController.text,
      'dateOfBirth': _dateOfBirth,
      'gender': _gender,
      'bio': _bioController.text,
      'emergencyContactName': _emergencyNameController.text,
      'emergencyContactPhone': _emergencyPhoneController.text,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 18),
              _ProfileSummaryCard(
                userName: widget.userName,
                userBadge: widget.userBadge,
                avatarAssetPath: widget.avatarAssetPath,
                onEditAvatar: () {},
              ),
              const SizedBox(height: 16),
              _FieldsCard(
                nameController: _nameController,
                emailController: _emailController,
                phoneController: _phoneController,
                locationController: _locationController,
                bioController: _bioController,
                dateOfBirth: _dateOfBirth,
                gender: _gender,
                onPickDateOfBirth: _pickDateOfBirth,
                onPickGender: _pickGender,
                bioMaxLength: kBioMaxLength,
              ),
              const SizedBox(height: 16),
              _EmergencyContactCard(
                expanded: _emergencyExpanded,
                onToggle: () =>
                    setState(() => _emergencyExpanded = !_emergencyExpanded),
                nameController: _emergencyNameController,
                phoneController: _emergencyPhoneController,
              ),
              const SizedBox(height: 20),
              _SaveButton(onTap: _handleSave),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: kPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Top bar ─────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1E7F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: _PersonalInformationScreenState.kDeepPurple,
              size: 20,
            ),
          ),
        ),
        const Expanded(
          child: Column(
            children: [
              Text(
                'Personal Information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _PersonalInformationScreenState.kDeepPurple,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your personal details and how we can reach you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _PersonalInformationScreenState.kSubtitleGray,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _PersonalInformationScreenState.kFieldBorder,
            ),
          ),
          child: const Icon(
            Icons.edit_outlined,
            color: _PersonalInformationScreenState.kPurple,
            size: 18,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Profile summary card ─────────────────────────

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.userName,
    required this.userBadge,
    required this.avatarAssetPath,
    required this.onEditAvatar,
  });

  final String userName;
  final String userBadge;
  final String? avatarAssetPath;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(assetPath: avatarAssetPath, onEdit: onEditAvatar),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _PersonalInformationScreenState.kDeepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E7F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield,
                        size: 12,
                        color: _PersonalInformationScreenState.kPurple,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        userBadge,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _PersonalInformationScreenState.kPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Update your photo and basic information.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _PersonalInformationScreenState.kSubtitleGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.assetPath, required this.onEdit});

  final String? assetPath;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFF1E7F7),
          ),
          child: ClipOval(
            child: assetPath != null
                ? Image.asset(
                    assetPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _fallback(),
                  )
                : _fallback(),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: _PersonalInformationScreenState.kPurple,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onEdit,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return const Icon(
      Icons.pets,
      color: _PersonalInformationScreenState.kDeepPurple,
      size: 44,
    );
  }
}

// ───────────────────────── Fields card ─────────────────────────

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.locationController,
    required this.bioController,
    required this.dateOfBirth,
    required this.gender,
    required this.onPickDateOfBirth,
    required this.onPickGender,
    required this.bioMaxLength,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController locationController;
  final TextEditingController bioController;
  final String dateOfBirth;
  final String gender;
  final VoidCallback onPickDateOfBirth;
  final VoidCallback onPickGender;
  final int bioMaxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledField(
            icon: Icons.person_outline,
            label: 'Full Name',
            child: _TextInput(controller: nameController),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            icon: Icons.email_outlined,
            label: 'Email Address',
            child: _TextInput(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            child: _TextInput(
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            icon: Icons.location_on_outlined,
            label: 'Location',
            child: _TextInput(controller: locationController),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            icon: Icons.calendar_today_outlined,
            label: 'Date of Birth',
            child: _DropdownField(value: dateOfBirth, onTap: onPickDateOfBirth),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            icon: Icons.person_outline,
            label: 'Gender',
            child: _DropdownField(value: gender, onTap: onPickGender),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            icon: Icons.notes_rounded,
            label: 'Bio',
            child: _BioInput(controller: bioController, maxLength: bioMaxLength),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(top: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFF1E7F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 17,
            color: _PersonalInformationScreenState.kPurple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _PersonalInformationScreenState.kDeepPurple,
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: _PersonalInformationScreenState.kDeepPurple,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _PersonalInformationScreenState.kFieldBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _PersonalInformationScreenState.kPurple,
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: _PersonalInformationScreenState.kFieldBorder,
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _PersonalInformationScreenState.kFieldBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _PersonalInformationScreenState.kDeepPurple,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _PersonalInformationScreenState.kPurple,
            ),
          ],
        ),
      ),
    );
  }
}

class _BioInput extends StatefulWidget {
  const _BioInput({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  State<_BioInput> createState() => _BioInputState();
}

class _BioInputState extends State<_BioInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _PersonalInformationScreenState.kFieldBorder,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: widget.controller,
            maxLength: widget.maxLength,
            maxLines: 3,
            buildCounter: (context,
                    {required currentLength, required isFocused, maxLength}) =>
                null,
            style: const TextStyle(
              fontSize: 14,
              color: _PersonalInformationScreenState.kDeepPurple,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Text(
            '${widget.controller.text.length}/${widget.maxLength}',
            style: const TextStyle(
              fontSize: 11,
              color: _PersonalInformationScreenState.kSubtitleGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Emergency contact ─────────────────────────

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.expanded,
    required this.onToggle,
    required this.nameController,
    required this.phoneController,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE6EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.phone_iphone_rounded,
                      color: _PersonalInformationScreenState.kPink,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contact',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _PersonalInformationScreenState.kDeepPurple,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Person we can contact in case of emergency.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _PersonalInformationScreenState.kSubtitleGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _PersonalInformationScreenState.kPurple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _TextInput(controller: nameController),
                  const SizedBox(height: 10),
                  _TextInput(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Save button ─────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                _PersonalInformationScreenState.kPurple,
                _PersonalInformationScreenState.kPink,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: const Text(
            'Save Changes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
