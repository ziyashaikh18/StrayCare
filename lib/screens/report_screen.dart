import 'dart:io';

import 'package:straycare_splash/screens/ai_analysis_screen.dart';
import 'package:straycare_splash/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:straycare_splash/screens/ai_scanner_screen.dart';
import 'package:straycare_splash/widgets/bottom_nav.dart';
import 'package:straycare_splash/screens/my_report_screen.dart';
import 'package:straycare_splash/screens/report_submitted_screen.dart';


/// StrayCare "Report a Rescue" screen — step 1 of 4.
class ReportRescueScreen extends StatefulWidget {
  const ReportRescueScreen({super.key});

  @override
  State<ReportRescueScreen> createState() => _ReportRescueScreenState();
}

class _ReportRescueScreenState extends State<ReportRescueScreen> {
  static const Color kBackground = Color(0xFFEDE3F5);
  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kLightPurple = Color(0xFFF1E9FA);
  static const Color kBorderPurple = Color(0xFFDCCBE8);
  static const Color kSubtitleGray = Color(0xFF8D8398);

  final _imagePicker = ImagePicker();

  final _locationController = TextEditingController(
    text: 'Bandra West, Mumbai, Maharashtra 400050',
  );

  final _descriptionController = TextEditingController();
  final _otherAnimalController = TextEditingController();

  final List<XFile> _photos = [];
  final Set<String> _behaviors = {};

  String _animalType = 'Dog';
  String _condition = 'Injured';

  DateTime _foundDate = DateTime(2025, 5, 20);

  TimeOfDay _foundTime = const TimeOfDay(
    hour: 10,
    minute: 30,
  );

  int _descriptionLength = 0;

  @override
  void initState() {
    super.initState();

    _descriptionController.addListener(_updateDescriptionLength);
  }

  void _updateDescriptionLength() {
    if (!mounted) return;

    setState(() {
      _descriptionLength = _descriptionController.text.length;
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _otherAnimalController.dispose();
    super.dispose();
  }

  // ───────────────────────── Photo selection ─────────────────────────

  Future<void> _pickFromCamera() async {
    final result = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (context) => const AiScannerScreen(),
      ),
    );

    if (result == null) {
      return;
    }

    if (_photos.length >= 5) {
      _showMessage('You can upload a maximum of 5 photos');
      return;
    }

    setState(() {
      _photos.add(result);
    });
  }

  Future<void> _pickFromGallery() async {
    try {
      final remainingPhotos = 5 - _photos.length;

      if (remainingPhotos <= 0) {
        _showMessage('You can upload a maximum of 5 photos');
        return;
      }

      final selectedPhotos = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (selectedPhotos.isEmpty) {
        return;
      }

      final photosToAdd = selectedPhotos.take(remainingPhotos).toList();

      setState(() {
        _photos.addAll(photosToAdd);
      });

      if (selectedPhotos.length > remainingPhotos) {
        _showMessage('Only 5 photos can be uploaded');
      }
    } catch (e) {
      debugPrint('Gallery selection error: $e');
      _showMessage('Could not select photos');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  // ───────────────────────── Location ─────────────────────────

  Future<void> _useCurrentLocation() async {
    // TODO: Add geolocator integration here.
    _showMessage('Current location is not connected yet');
  }

  // ───────────────────────── Date and time ─────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _foundDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _foundTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _foundTime = picked;
      });
    }
  }

  // ───────────────────────── Submit ─────────────────────────

  Future<void> _handleContinue() async {
    if (_photos.isEmpty) {
      _showMessage('Please add at least one photo');
      return;
    }

    final result = await Navigator.push<AiAnalysisResult>(
      context,
      MaterialPageRoute(
        builder: (context) => AiAnalysisScreen(
          photos: _photos,
          animalType: _animalType,
          condition: _condition,
          behaviors: _behaviors,
          description: _descriptionController.text,
          location: _locationController.text,
        ),
      ),
    );

    // result == null means the user tapped "Edit Report" and came back.
    if (result == null || !mounted) return;

    // TODO: once you add a dedicated Review screen (step 3 of 4), move this
    // submission call there instead of firing it straight from here. For
    // now this treats "Continue" as the final submit action.
    _submitReport(result);
  }

  void _submitReport(AiAnalysisResult result) {
    final reportId = _generateReportId();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ReportSubmittedScreen(
          reportId: reportId,
          animalType: _animalType == 'Other' && _otherAnimalController.text.isNotEmpty
              ? _otherAnimalController.text
              : _animalType,
          location: _locationController.text,
          submittedAt: DateTime.now(),
          photoPath: _photos.first.path,
          priorityLabel: result.priority.name,
          // TODO: if AiAnalysisResult exposes a numeric urgency score,
          // pass it here instead, e.g. priorityScore: result.score.
        ),
      ),
    );
  }

  String _generateReportId() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final suffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'SC-$yy$mm$dd-$suffix';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ───────────────────────── Bottom navigation ─────────────────────────

  void _handleNavTap(int index) {
    if (index == 0) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    if (index == 1) {
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AiScannerScreen(),
        ),
      );
      return;
    }

    if (index == 3) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const MyReportsScreen()),
  );
  return;
}

    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
      return;
    }
  }

  // ───────────────────────── Formatting ─────────────────────────

  String get _formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[_foundDate.month - 1]} '
        '${_foundDate.day}, ${_foundDate.year}';
  }

  String get _formattedTime {
    return _foundTime.format(context);
  }

  // ───────────────────────── Main layout ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildUploadPhotosCard(),
                          const SizedBox(height: 10),
                          _buildAnimalTypeCard(),
                          const SizedBox(height: 10),
                          _buildLocationCard(),
                          const SizedBox(height: 10),
                          _buildDateAndConditionRow(),
                          const SizedBox(height: 10),
                          _buildBehaviorCard(),
                          const SizedBox(height: 10),
                          _buildDescriptionCard(),
                          const SizedBox(height: 12),
                          _buildContinueButton(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: StrayCareBottomNav(
        currentIndex: 1,
        onTap: _handleNavTap,
      ),
    );
  }

  // ───────────────────────── Header ─────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () {
              Navigator.maybePop(context);
            },
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report a Rescue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kDeepPurple,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Your report can save a life ',
                      style: TextStyle(
                        fontSize: 13,
                        color: kSubtitleGray,
                      ),
                    ),
                    Text(
                      '\u{1F49D}',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: kLightPurple,
              child: Icon(
                Icons.person,
                color: kPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Upload photos ─────────────────────────

  Widget _buildUploadPhotosCard() {
    return _SectionCard(
      icon: Icons.image_outlined,
      title: 'Upload Photos',
      subtitle: 'Clear photos help AI detect injuries better',
      trailing: const Icon(
        Icons.info_outline,
        color: kSubtitleGray,
        size: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_photos.isNotEmpty) ...[
            _buildPhotoPreviewList(),
            const SizedBox(height: 10),
          ],
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _pickFromGallery,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: kLightPurple.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: kBorderPurple,
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: kPurple,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to upload photos',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kDeepPurple,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'or drag and drop',
                    style: TextStyle(
                      color: kSubtitleGray,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OutlinedPillButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: _pickFromCamera,
                      ),
                      const SizedBox(width: 8),
                      _OutlinedPillButton(
                        icon: Icons.photo_outlined,
                        label: 'Gallery',
                        onTap: _pickFromGallery,
                      ),
                    ],
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${_photos.length}/5 photo(s) added',
                      style: const TextStyle(
                        color: kPurple,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: kPurple,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 11,
                      color: kSubtitleGray,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(
                        text: 'Tips: ',
                        style: TextStyle(
                          color: kPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Take clear photos in good lighting, include full '
                            'body and close-up of injury. Max 5 photos.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreviewList() {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final photo = _photos[index];

          return Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(photo.path),
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 82,
                      height: 82,
                      color: kLightPurple,
                      child: const Icon(
                        Icons.image,
                        color: kPurple,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () => _removePhoto(index),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────── Animal type ─────────────────────────

  Widget _buildAnimalTypeCard() {
    final types = [
      ('Dog', Icons.pets),
      ('Cat', Icons.cruelty_free),
      ('Other', Icons.more_horiz),
    ];

    return _SectionCard(
      icon: Icons.pets,
      title: 'Animal Type',
      subtitle: 'What type of animal is this?',
      child: Column(
        children: [
          Row(
            children: [
              for (final type in types) ...[
                Expanded(
                  child: _SelectablePill(
                    icon: type.$2,
                    label: type.$1,
                    selected: _animalType == type.$1,
                    onTap: () {
                      setState(() {
                        _animalType = type.$1;
                      });
                    },
                  ),
                ),
                if (type.$1 != types.last.$1) const SizedBox(width: 8),
              ],
            ],
          ),
          if (_animalType == 'Other') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderPurple),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pets,
                    color: kPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _otherAnimalController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: kDeepPurple,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter animal name',
                        hintStyle: TextStyle(
                          color: kSubtitleGray,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Location ─────────────────────────

  Widget _buildLocationCard() {
    return _SectionCard(
      icon: Icons.location_on_outlined,
      title: 'Location',
      subtitle: 'Where did you find this animal?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderPurple),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.search,
                    color: kSubtitleGray,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kDeepPurple,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search or enter address',
                      hintStyle: TextStyle(
                        color: kSubtitleGray,
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                _CircleIconButton(
                  icon: Icons.my_location,
                  onTap: _useCurrentLocation,
                  size: 32,
                  margin: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderPurple),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: kPurple,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationController.text,
                    style: const TextStyle(
                      fontSize: 12,
                      color: kDeepPurple,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: kSubtitleGray,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Date and condition ─────────────────────────

  Widget _buildDateAndConditionRow() {
    final conditionOptions = [
      (
        'Injured',
        Icons.healing,
        const Color(0xFFE23744),
        _condition == 'Injured',
      ),
      (
        'Sick',
        Icons.sick_outlined,
        kDeepPurple,
        _condition == 'Sick',
      ),
      (
        "Can't move",
        Icons.accessibility_new,
        kDeepPurple,
        _condition == 'Weak',
      ),
      (
        'Other',
        Icons.more_horiz,
        kDeepPurple,
        _condition == 'Other',
      ),
    ];

    void selectCondition(String label) {
      setState(() {
        if (label == 'Injured') {
          _condition = 'Injured';
        } else if (label == 'Sick') {
          _condition = 'Sick';
        } else if (label == "Can't move") {
          _condition = 'Weak';
        } else {
          _condition = 'Other';
        }
      });
    }

    Widget conditionRow(int startIndex) {
      return Expanded(
        child: Row(
          children: [
            for (var i = startIndex; i < startIndex + 2; i++) ...[
              Expanded(
                child: _ConditionChip(
                  icon: conditionOptions[i].$2,
                  label: conditionOptions[i].$1,
                  color: conditionOptions[i].$3,
                  selected: conditionOptions[i].$4,
                  onTap: () {
                    selectCondition(conditionOptions[i].$1);
                  },
                ),
              ),
              if (i == startIndex) const SizedBox(width: 6),
            ],
          ],
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SectionCard(
              icon: Icons.calendar_today_outlined,
              title: 'When did you\nfind the animal?',
              titleFontSize: 12.5,
              expandChild: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DropdownField(
                    icon: Icons.calendar_today_outlined,
                    label: _formattedDate,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 8),
                  _DropdownField(
                    icon: Icons.access_time,
                    label: _formattedTime,
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SectionCard(
              icon: Icons.favorite_border,
              title: 'Animal Condition',
              subtitle: 'What best describes the animal?',
              titleFontSize: 13,
              expandChild: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  conditionRow(0),
                  const SizedBox(height: 6),
                  conditionRow(2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Behavior ─────────────────────────

  Widget _buildBehaviorCard() {
    final behaviors = [
      (
        'Calm',
        Icons.sentiment_satisfied_alt,
        const Color(0xFF2E7D32),
      ),
      (
        'Aggressive',
        Icons.sentiment_very_dissatisfied,
        const Color(0xFFE08A00),
      ),
      (
        'Scared',
        Icons.sentiment_dissatisfied,
        const Color(0xFF1565C0),
      ),
      (
        'Unable to move',
        Icons.pets,
        kPurple,
      ),
      (
        'Running away',
        Icons.directions_run,
        const Color(0xFF00897B),
      ),
    ];

    return _SectionCard(
      icon: Icons.pets,
      title: 'Animal Behavior',
      subtitle: 'How is the animal behaving?',
      child: Row(
        children: [
          for (final behavior in behaviors) ...[
            Expanded(
              child: _BehaviorChip(
                icon: behavior.$2,
                label: behavior.$1,
                color: behavior.$3,
                selected: _behaviors.contains(behavior.$1),
                onTap: () {
                  setState(() {
                    if (_behaviors.contains(behavior.$1)) {
                      _behaviors.remove(behavior.$1);
                    } else {
                      _behaviors.add(behavior.$1);
                    }
                  });
                },
              ),
            ),
            if (behavior.$1 != behaviors.last.$1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Description ─────────────────────────

  Widget _buildDescriptionCard() {
    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'Short Description',
      titleSuffix: ' (Optional)',
      subtitle: 'Describe what you see',
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderPurple),
            ),
            child: TextField(
              controller: _descriptionController,
              maxLength: 250,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 13,
                color: kDeepPurple,
              ),
              decoration: const InputDecoration(
                hintText:
                    'E.g. Dog has a leg injury, bleeding, not able to walk...',
                hintStyle: TextStyle(
                  color: kSubtitleGray,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                counterText: '',
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 6,
            child: Text(
              '$_descriptionLength/250',
              style: const TextStyle(
                fontSize: 10,
                color: kSubtitleGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Submit button ─────────────────────────

  Widget _buildContinueButton() {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _handleContinue,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7B4397),
                    kPurple,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPurple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 13,
              color: kSubtitleGray,
            ),
            SizedBox(width: 4),
            Text(
              'Your information is safe and secure',
              style: TextStyle(
                fontSize: 11,
                color: kSubtitleGray,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────── Section card ─────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.titleSuffix,
    this.titleFontSize = 16,
    this.expandChild = false,
  });

  final IconData icon;
  final String title;
  final String? titleSuffix;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final double titleFontSize;
  final bool expandChild;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kLightPurple = Color(0xFFF1E9FA);
  static const Color kSubtitleGray = Color(0xFF8D8398);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBDA7D2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: kPurple.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kLightPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: kPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: kDeepPurple,
                        ),
                        children: [
                          TextSpan(text: title),
                          if (titleSuffix != null)
                            TextSpan(
                              text: titleSuffix,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: kSubtitleGray,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: kSubtitleGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          expandChild ? Expanded(child: child) : child,
        ],
      ),
    );
  }
}

// ───────────────────────── Circle button ─────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.margin,
  }) : filled = false;

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final double size;
  final EdgeInsets? margin;

  static const Color kPurple = Color(0xFF6A3EA1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: filled ? kPurple : Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(
                      color: const Color(0xFFDCCBE8),
                    ),
            ),
            child: Icon(
              icon,
              color: filled ? Colors.white : kPurple,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Outlined button ─────────────────────────

class _OutlinedPillButton extends StatelessWidget {
  const _OutlinedPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kBorderPurple = Color(0xFFDCCBE8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorderPurple),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: kDeepPurple,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kDeepPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Animal type pill ─────────────────────────

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kLightPurple = Color(0xFFF1E9FA);
  static const Color kBorderPurple = Color(0xFFDCCBE8);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kLightPurple : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kPurple : kBorderPurple,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected ? kPurple : kDeepPurple,
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? kPurple : kDeepPurple,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 7,
                right: 7,
                child: _CheckBadge(),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Check badge ─────────────────────────

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({
    this.color = const Color(0xFF6A3EA1),
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.check,
        color: Colors.white,
        size: 11,
      ),
    );
  }
}

// ───────────────────────── Dropdown field ─────────────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kSubtitleGray = Color(0xFF8D8398);
  static const Color kBorderPurple = Color(0xFFDCCBE8);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderPurple),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: kSubtitleGray,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: kDeepPurple,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 15,
              color: kSubtitleGray,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Condition chip ─────────────────────────

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  static const Color kDeepPurple = Color(0xFF2E1A47);
  static const Color kBorderPurple = Color(0xFFDCCBE8);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color : kBorderPurple,
                width: selected ? 1.2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? color : kDeepPurple,
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : kDeepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: 3,
              right: 3,
              child: _CheckBadge(color: color),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Behavior chip ─────────────────────────

class _BehaviorChip extends StatelessWidget {
  const _BehaviorChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  static const Color kDeepPurple = Color(0xFF2E1A47);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.25),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 15,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                color: kDeepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}