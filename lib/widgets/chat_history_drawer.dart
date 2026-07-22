import 'package:flutter/material.dart';
import '../main.dart';

class ChatHistoryDrawer extends StatelessWidget {
  const ChatHistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final currentSessionId = appState.chatSessionId;
    final sessions = appState.chatSessions.where((session) {
      final sessionId = session['id']?.toString() ?? '';
      if (sessionId == currentSessionId) {
        final hasUserMessage = appState.chatMessages.any((msg) => msg.role == 'user');
        return hasUserMessage;
      }
      return true;
    }).toList();
    final isLoading = appState.isSessionsLoading;

    return Drawer(
      backgroundColor: const Color(0xFF081326),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFFECC741), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Lịch sử trò chuyện',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),

            // "New Chat" Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: appState.isChatThinking
                    ? null
                    : () async {
                        Navigator.of(context).pop(); // Đóng drawer
                        await appState.resetChatSession();
                      },
                icon: const Icon(Icons.add_comment_outlined, size: 18),
                label: const Text(
                  'Cuộc trò chuyện mới',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFECC741),
                  foregroundColor: const Color(0xFF0F1E36),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            // Sessions List
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0ED8AB),
                      ),
                    )
                  : sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 40,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Không có lịch sử trò chuyện',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sessions.length,
                          itemBuilder: (context, index) {
                            final session = sessions[index];
                            final sessionId = session['id']?.toString() ?? '';
                            final sessionName = session['name']?.toString() ?? '';
                            final updatedAtStr = session['updatedAt']?.toString() ??
                                session['createdAt']?.toString() ??
                                '';
                            
                            final isCurrent = currentSessionId == sessionId;
                            final displayName = sessionName.isNotEmpty
                                ? sessionName
                                : 'Trò chuyện #${sessionId.length > 4 ? sessionId.substring(sessionId.length - 4) : sessionId}';

                            DateTime? parsedTime;
                            if (updatedAtStr.isNotEmpty) {
                              try {
                                parsedTime = DateTime.parse(updatedAtStr).toLocal();
                              } catch (_) {}
                            }

                            final timeText = parsedTime != null
                                ? '${parsedTime.day}/${parsedTime.month} ${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}'
                                : '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? const Color(0xFFECC741).withOpacity(0.08)
                                    : Colors.white.withOpacity(0.01),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent
                                      ? const Color(0xFFECC741).withOpacity(0.4)
                                      : Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? const Color(0xFFECC741).withOpacity(0.12)
                                        : Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: isCurrent
                                        ? const Color(0xFFECC741)
                                        : Colors.white60,
                                  ),
                                ),
                                title: Text(
                                  displayName,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? const Color(0xFFECC741)
                                        : Colors.white,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: timeText.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: Text(
                                          timeText,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.3),
                                            fontSize: 10,
                                          ),
                                        ),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.white38,
                                  ),
                                  hoverColor: Colors.red.withOpacity(0.1),
                                  onPressed: () {
                                    _confirmDeleteSession(context, appState, sessionId, displayName);
                                  },
                                ),
                                onTap: isCurrent || appState.isChatThinking
                                    ? null
                                    : () async {
                                        Navigator.of(context).pop(); // Đóng drawer
                                        await appState.loadChatSessionDetail(sessionId);
                                      },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSession(
    BuildContext context,
    AppState appState,
    String sessionId,
    String displayName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F1E36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
              SizedBox(width: 8),
              Text(
                'Xóa cuộc trò chuyện',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa cuộc trò chuyện "$displayName" không? Hành động này không thể hoàn tác.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                appState.deleteChatSession(sessionId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
