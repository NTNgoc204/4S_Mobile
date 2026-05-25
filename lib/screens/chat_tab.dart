import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat.dart';
import '../models/university.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<StreamSubscription> _subscriptions = [];

  final List<String> _quickPrompts = [
    'Trường có học phí dưới 50 triệu',
    'Ngành IT nổi bật',
    'Trường ở TP.HCM',
    'Ngành kinh doanh dễ có việc',
    'Học bổng ngành kỹ thuật',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendManualMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final appState = AppState.of(context, listen: false);
    appState.addChatMessage(text, isPreset: false);
    _scrollToBottom();
  }

  void _sendPresetMessage(int index) {
    final text = _quickPrompts[index];
    final appState = AppState.of(context, listen: false);
    appState.addChatMessage(text, isPreset: true, presetIndex: index);
    _scrollToBottom();
  }

  void _showUniversityDetail(UniversityWithScore school) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1E36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          school.name['vi']!,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          school.place['vi']!,
                          style: const TextStyle(color: Colors.white60, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECC741).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Match: ${school.score}%',
                      style: const TextStyle(color: Color(0xFFECC741), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),
              _buildDetailRow(Icons.school, 'Khối ngành đào tạo:', school.major['vi']!),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.monetization_on, 'Học phí tham khảo:', school.tuition['vi']!),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.people, 'Quy mô sinh viên:', school.stats['students']!['vi']!),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.star, 'Thứ hạng nổi bật:', school.stats['rank']!['vi']!),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECC741),
                  foregroundColor: const Color(0xFF0F1E36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF0ED8AB), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              children: [
                TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final messages = appState.chatMessages;
    final isThinking = appState.isChatThinking;
    final recommendedSchools = appState.chatRecommendations;
    final isPro = appState.currentUser?.currentPlan == 'pro';

    // Trigger scroll to bottom on initial loaded messages or active responses
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        // Premium Pro indicator
        if (isPro)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFECC741).withOpacity(0.08),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.workspace_premium, color: Color(0xFFECC741), size: 16),
                SizedBox(width: 6),
                Text(
                  'Bản Premium: AI Hướng nghiệp không giới hạn',
                  style: TextStyle(color: Color(0xFFECC741), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // Message board list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length + (isThinking ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return _buildThinkingBubble();
              }

              final ChatMessage msg = messages[index];
              final bool isUser = msg.role == 'user';

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFECC741) : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? const Color(0xFF0F1E36) : Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Realtime horizontal school list
        if (appState.signalCount > 0) ...[
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recommendedSchools.length,
              itemBuilder: (context, index) {
                final school = recommendedSchools[index];
                return GestureDetector(
                  onTap: () => _showUniversityDetail(school),
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFECC741).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                school.name['vi']!,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                school.major['vi']!,
                                style: const TextStyle(color: Colors.white54, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECC741).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${school.score}%',
                            style: const TextStyle(color: Color(0xFFECC741), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // Input section + Presets tags
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E36),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick tag presets list
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickPrompts.length,
                    itemBuilder: (context, index) {
                      final bool isUsed = appState.usedPromptIndexes.contains(index);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          onPressed: isThinking || isUsed ? null : () => _sendPresetMessage(index),
                          backgroundColor: isUsed
                              ? Colors.white10
                              : const Color(0xFF0ED8AB).withOpacity(0.08),
                          side: BorderSide(
                            color: isUsed
                                ? Colors.transparent
                                : const Color(0xFF0ED8AB).withOpacity(0.2),
                          ),
                          label: Text(
                            _quickPrompts[index],
                            style: TextStyle(
                              color: isUsed ? Colors.white30 : const Color(0xFF0ED8AB),
                              fontSize: 12,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Keyboard input field
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          enabled: !isThinking,
                          decoration: const InputDecoration(
                            hintText: 'Hỏi bất kỳ về học phí, ngành IT...',
                            hintStyle: TextStyle(color: Colors.white30),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendManualMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFECC741),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF0F1E36), size: 18),
                        onPressed: isThinking ? null : _sendManualMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0ED8AB)),
            ),
            SizedBox(width: 10),
            Text(
              'Trợ lý đang phân tích tín hiệu...',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
