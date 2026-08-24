import 'dart:io';
import 'package:flutter/material.dart';

/// StrayCare "AI Scan Assistant" chat screen.
///
/// Shown after [AiAnalysisLoadingScreen] finishes. Presents the AI's
/// injury-detection result as a chat bubble + card, then lets the user
/// chat with quick-action buttons ("Create a report", "What should I do?",
/// "Scan another") or type a free-form message.
class InjuryResult {
  const InjuryResult({
    required this.title,
    required this.severity,
    required this.description,
  });

  final String title;
  final String severity; // e.g. "Low" | "Medium" | "High"
  final String description;

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF5B6E);
      case 'medium':
        return const Color(0xFFF5A623);
      default:
        return const Color(0xFF4CD37E);
    }
  }
}

enum _MsgType {
  botText,
  userText,
  analysisCard,
  quickActions,
  guidanceFeedback,
  locationPrompt,
}

class _ChatMsg {
  _ChatMsg({
    required this.type,
    required this.time,
    this.text,
  }) : feedbackGiven = false , locationResolved = false;

  final _MsgType type;
  final String time;
  final String? text;
  bool feedbackGiven;
  bool locationResolved;
}

class AiScanAssistantScreen extends StatefulWidget {
  const AiScanAssistantScreen({
    super.key,
    required this.imagePath,
    this.result,
  });

  /// Path to the captured/selected image (from the scanner or gallery).
  final String imagePath;

  /// Injury analysis result. Falls back to a mock result if not provided,
  /// so this screen can be wired up before the real AI model is ready.
  final InjuryResult? result;

  @override
  State<AiScanAssistantScreen> createState() => _AiScanAssistantScreenState();
}

class _AiScanAssistantScreenState extends State<AiScanAssistantScreen> {
  static const Color kPurple = Color(0xFF6A3EA1);
  static const Color kPurpleLight = Color(0xFFB88CE8);
  static const Color kBg = Color(0xFF0A0620);
  static const Color kHeaderBg = Color(0xFF0D0826);
  static const Color kBubble = Color(0xFF171033);
  static const Color kBubbleBorder = Color(0xFF2A2050);

  late final InjuryResult _result;
  final List<_ChatMsg> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _result = widget.result ??
        const InjuryResult(
          title: 'Possible Injury Detected',
          severity: 'High',
          description:
              'There appears to be a wound on the head. The area looks '
              'painful and may need medical care.',
        );
    _seedConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────────────────────── Conversation setup ─────────────────────────

  String get _now => _formatTime(DateTime.now());

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _seedConversation() {
    _messages.addAll([
      _ChatMsg(
        type: _MsgType.botText,
        time: _now,
        text: "I've analyzed the image you uploaded. Here's what I found:",
      ),
      _ChatMsg(type: _MsgType.analysisCard, time: _now),
      _ChatMsg(
        type: _MsgType.botText,
        time: _now,
        text: 'What would you like to do next?',
      ),
      _ChatMsg(type: _MsgType.quickActions, time: _now),
    ]);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _addMessage(_ChatMsg msg) {
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  // ───────────────────────── Quick action handling ─────────────────────────

  void _handleQuickAction(String action) {
    switch (action) {
      case 'report':
        _addMessage(_ChatMsg(type: _MsgType.userText, time: _now, text: 'Create a report'));
        _addMessage(_ChatMsg(
          type: _MsgType.botText,
          time: _now,
          text: "Got it — I'll put together a report with the photo and "
              "detection details so you can submit it to a nearby NGO.",
        ));
        // TODO: hook up to real report-submission flow / API.
        break;

      case 'guidance':
        _addMessage(_ChatMsg(type: _MsgType.userText, time: _now, text: 'What should I do?'));
        _addMessage(_ChatMsg(
          type: _MsgType.botText,
          time: _now,
          text: 'If the animal is safe, try to keep it calm and avoid '
              'touching the injured area. Contact a nearby rescue or vet '
              'as soon as possible.',
        ));
        _addMessage(_ChatMsg(type: _MsgType.guidanceFeedback, time: _now));
        _addMessage(_ChatMsg(
          type: _MsgType.botText,
          time: _now,
          text: 'Need help finding a rescue organization near you?',
        ));
        _addMessage(_ChatMsg(type: _MsgType.locationPrompt, time: _now));
        break;

      case 'rescan':
        Navigator.pop(context, 'rescan');
        break;
    }
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _addMessage(_ChatMsg(type: _MsgType.userText, time: _now, text: text));
    _inputController.clear();

    // TODO: replace with a real response from the AI backend.
    _addMessage(_ChatMsg(
      type: _MsgType.botText,
      time: _now,
      text: "Thanks — I've noted that. Let me know if you'd like a report "
          "or nearby rescue options.",
    ));
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _buildDateDivider();
                  return _buildMessage(_messages[index - 1]);
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Top bar ─────────────────────────

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        color: kHeaderBg,
        border: Border(bottom: BorderSide(color: kBubbleBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'AI Scan Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Here to help animals',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Text(
          'Today, ${_messages.isNotEmpty ? _messages.first.time : _now}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
        ),
      ),
    );
  }

  // ───────────────────────── Message router ─────────────────────────

  Widget _buildMessage(_ChatMsg msg) {
    switch (msg.type) {
      case _MsgType.botText:
        return _botBubble(msg.text!, msg.time);
      case _MsgType.userText:
        return _userBubble(msg.text!, msg.time);
      case _MsgType.analysisCard:
        return _analysisCard(msg.time);
      case _MsgType.quickActions:
        return _quickActionsRow();
      case _MsgType.guidanceFeedback:
        return _feedbackRow(msg);
      case _MsgType.locationPrompt:
        return _locationPromptRow(msg);
    }
  }

  // ───────────────────────── Bot avatar + bubble ─────────────────────────

  Widget _botAvatar() {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kPurple.withValues(alpha: 0.35),
        shape: BoxShape.circle,
        border: Border.all(color: kPurpleLight.withValues(alpha: 0.6)),
      ),
      child: const Icon(Icons.pets, color: kPurpleLight, size: 16),
    );
  }

  Widget _botBubble(String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    color: kBubble,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _userBubble(String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF8A4FC7), kPurple]),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35)),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
                      const SizedBox(width: 4),
                      Icon(Icons.done_all, size: 14, color: kPurpleLight.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Analysis card ─────────────────────────

  Widget _analysisCard(String time) {
    final file = File(widget.imagePath);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: kBubble,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBubbleBorder),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: file.existsSync()
                      ? Image.file(file, width: 96, height: 96, fit: BoxFit.cover)
                      : Container(
                          width: 96,
                          height: 96,
                          color: Colors.white10,
                          child: const Icon(Icons.pets, color: Colors.white38),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result.title,
                        style: const TextStyle(
                          color: Color(0xFFEF5B6E),
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                          children: [
                            const TextSpan(text: 'Severity: '),
                            TextSpan(
                              text: _result.severity,
                              style: TextStyle(
                                color: _result.severityColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _result.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
        ],
      ),
    );
  }

  // ───────────────────────── Quick actions row ─────────────────────────

  Widget _quickActionsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 42),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _quickActionChip(
            icon: Icons.add_circle_outline,
            title: 'Create a report',
            subtitle: 'Submit to NGO',
            onTap: () => _handleQuickAction('report'),
          ),
          _quickActionChip(
            icon: Icons.help_outline,
            title: 'What should I do?',
            subtitle: 'Get simple guidance',
            onTap: () => _handleQuickAction('guidance'),
          ),
          _quickActionChip(
            icon: Icons.refresh,
            title: 'Scan another',
            subtitle: 'Check new image',
            onTap: () => _handleQuickAction('rescan'),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 108,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kPurpleLight.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: kPurpleLight, size: 18),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: kPurpleLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Feedback row (thumbs) ─────────────────────────

  Widget _feedbackRow(_ChatMsg msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 42, right: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _feedbackIcon(Icons.thumb_up_alt_outlined, () {
              setState(() => msg.feedbackGiven = true);
            }),
            const SizedBox(width: 14),
            _feedbackIcon(Icons.thumb_down_alt_outlined, () {
              setState(() => msg.feedbackGiven = true);
            }),
            if (msg.feedbackGiven) ...[
              const SizedBox(width: 8),
              Text('Thanks for the feedback!',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _feedbackIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: Colors.white54),
      ),
    );
  }

  // ───────────────────────── Location prompt ─────────────────────────

  Widget _locationPromptRow(_ChatMsg msg) {
    if (msg.locationResolved) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 42),
      child: Row(
        children: [
          _promptButton(
            icon: Icons.location_on_outlined,
            label: 'Yes, show nearby',
            onTap: () {
              setState(() => msg.locationResolved = true);
              _addMessage(_ChatMsg(type: _MsgType.userText, time: _now, text: 'Yes, show nearby'));
              _addMessage(_ChatMsg(
                type: _MsgType.botText,
                time: _now,
                text: 'Looking up rescue organizations near you now...',
              ));
              // TODO: navigate to a nearby-NGO / map screen here.
            },
          ),
          const SizedBox(width: 10),
          _promptButton(
            label: 'No, thanks',
            onTap: () {
              setState(() => msg.locationResolved = true);
              _addMessage(_ChatMsg(type: _MsgType.userText, time: _now, text: 'No, thanks'));
              _addMessage(_ChatMsg(
                type: _MsgType.botText,
                time: _now,
                text: 'Okay! Let me know if you need anything else.',
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _promptButton({IconData? icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPurpleLight.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: kPurpleLight),
                const SizedBox(width: 6),
              ],
              Text(label, style: const TextStyle(color: kPurpleLight, fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Input bar ─────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: kHeaderBg,
        border: Border(top: BorderSide(color: kBubbleBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: kBubble,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kBubbleBorder),
              ),
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleSend,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF8A4FC7), kPurple]),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}