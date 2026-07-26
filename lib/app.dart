import 'dart:async';
import 'package:flutter/material.dart';
import 'models/user.dart';
import 'models/chat.dart';
import 'models/quiz.dart';
import 'services/api_client.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'services/quiz_service.dart';
import 'services/chat_service.dart';
import 'services/web_stats_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppStateWrapper();
  }
}

class AppStateWrapper extends StatefulWidget {
  const AppStateWrapper({super.key});

  @override
  State<AppStateWrapper> createState() => AppState();
}

class AppState extends State<AppStateWrapper> {
  final AuthService _authService = AuthService.instance;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  Timer? _refreshTimer;

  UserProfile? currentUser;
  bool isLoggedIn = false;
  bool isAuthInitializing = true;
  bool isLoggingOut = false;

  // AI Chat states
  String? chatSessionId;
  final List<ChatMessage> chatMessages = [];
  final Map<String, int> chatProfile = {
    'tech': 0,
    'business': 0,
    'engineering': 0,
    'creative': 0,
    'social': 0,
  };
  int signalCount = 0;
  final List<int> usedPromptIndexes = [];
  bool isChatThinking = false;
  List<AiUniversityRecommendation> chatRecommendations = [];
  List<Map<String, dynamic>> allQuestions = [];
  List<Map<String, dynamic>> allQuestionOptions = [];
  List<String> activeQuickPrompts = [];

  // AI Chat History states
  List<Map<String, dynamic>> chatSessions = [];
  bool isSessionsLoading = false;
  bool isActiveSessionLoading = false;

  // Career Quiz states
  bool isQuizCompleted = false;
  Map<String, int> quizProfile = {
    'tech': 0,
    'business': 0,
    'engineering': 0,
    'creative': 0,
    'social': 0,
    'leftBrain': 0,
    'rightBrain': 0,
  };

  static AppState of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final AppProvider? provider = context
          .dependOnInheritedWidgetOfExactType<AppProvider>();
      assert(provider != null, 'No AppProvider found in context');
      return provider!.state;
    } else {
      final AppState? result = context.findAncestorStateOfType<AppState>();
      assert(result != null, 'No AppState found in context');
      return result!;
    }
  }

  @override
  void initState() {
    super.initState();
    _resetChatState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    await _authService.init(onSessionExpired: _handleSessionExpired);

    // Tăng tổng số lượt truy cập app hôm nay
    WebStatsService().incrementWebVisits();

    try {
      final restoredUser = await _authService.restoreSession();
      if (!mounted) return;

      setState(() {
        currentUser = restoredUser;
        isLoggedIn = restoredUser != null;
        isAuthInitializing = false;
        if (restoredUser != null) {
          _resetChatState();
        }
      });

      if (restoredUser != null) {
        _startRefreshTimer();
        WebStatsService().recordUserVisit(userId: restoredUser.userId);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isAuthInitializing = false;
      });

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(_authService.getErrorMessage(e)),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _handleSessionExpired() async {
    _refreshTimer?.cancel();
    if (!mounted) return;

    setState(() {
      currentUser = null;
      isLoggedIn = false;
      isLoggingOut = false;
      isQuizCompleted = false;
      _resetChatState();
    });
  }

  void _resetChatState() {
    chatMessages.clear();
    chatMessages.add(
      ChatMessage(
        id: 'welcome',
        role: 'assistant',
        content:
            'Xin chào! Tôi là Trợ lý Hướng nghiệp AI. Hãy chia sẻ để tôi có thể tìm ngành học và trường đại học phù hợp nhất với bạn nhé! 😊',
        kind: 'welcome',
      ),
    );
    chatSessionId = null;
    chatProfile.forEach((k, v) => chatProfile[k] = 0);
    signalCount = 0;
    usedPromptIndexes.clear();
    chatRecommendations.clear();
    activeQuickPrompts = [];
    chatSessions = [];
    isSessionsLoading = false;
    isActiveSessionLoading = false;
  }

  Future<void> _cleanupEmptySession() async {
    final currentId = chatSessionId;
    if (currentId != null) {
      final hasUserMessage = chatMessages.any((msg) => msg.role == 'user');
      if (!hasUserMessage) {
        try {
          await ChatService.instance.deleteChatSession(currentId);
        } catch (_) {
          // Silently ignore cleanup errors
        }
      }
    }
  }

  // Authentication Actions
  Future<void> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final profile = await _authService.login(email: email, password: password);

    if (!mounted) return;

    setState(() {
      currentUser = profile;
      isLoggedIn = true;
      isQuizCompleted = false;
      _resetChatState();
    });
    _startRefreshTimer();
    WebStatsService().recordUserVisit(userId: profile.userId);
  }

  Future<void> logout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    _refreshTimer?.cancel();

    // Khởi chạy đồng thời cả hai tiến trình dọn dẹp API ngầm không làm nghẽn UI
    _cleanupEmptySession().catchError((_) {});
    _authService.logout().catchError((_) {});

    if (!mounted) return;

    setState(() {
      currentUser = null;
      isLoggedIn = false;
      isLoggingOut = false;
      isQuizCompleted = false;
      _resetChatState();
    });
  }

  String getAuthErrorMessage(Object error) {
    return _authService.getErrorMessage(error);
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 12), (_) async {
      if (!isLoggedIn) return;

      try {
        await _authService.refreshAccessToken();
      } catch (_) {
        await _handleSessionExpired();
      }
    });
  }

  // Profile Updates
  void updateUserProfile(UserProfile profile) {
    setState(() {
      currentUser = profile;
    });
  }

  Future<void> uploadAvatar(String filePath) async {
    final avatarUrl = await _authService.uploadAvatar(filePath);
    if (!mounted || currentUser == null) return;

    setState(() {
      currentUser = currentUser!.copyWith(avatarUrl: avatarUrl);
    });
  }

  void upgradeSubscription(String planId) {
    setState(() {
      if (currentUser != null) {
        currentUser = currentUser!.copyWith(currentPlan: planId);
      }
    });
  }

  // Quiz Actions
  void completeQuiz(Map<String, int> profile) {
    setState(() {
      isQuizCompleted = true;
      quizProfile = Map.from(profile);
    });
  }

  void resetQuiz() {
    setState(() {
      isQuizCompleted = false;
      quizProfile = {
        'tech': 0,
        'business': 0,
        'engineering': 0,
        'creative': 0,
        'social': 0,
        'leftBrain': 0,
        'rightBrain': 0,
      };
    });
  }

  // AI Chat Actions
  List<String> _getQuickPromptsForQuestion(String? questionContent) {
    if (questionContent == null || questionContent.trim().isEmpty) {
      return [];
    }

    try {
      final question = allQuestions.firstWhere(
        (q) => q['content']?.toString().trim().toLowerCase() == questionContent.trim().toLowerCase(),
        orElse: () => {},
      );

      if (question.isEmpty) {
        return [];
      }

      final questionId = question['id']?.toString();
      final options = allQuestionOptions
          .where((opt) => opt['questionId']?.toString() == questionId)
          .toList();

      if (options.isEmpty) {
        return [];
      }

      options.sort((a, b) {
        final aOrder = int.tryParse(a['displayOrder']?.toString() ?? '') ?? 0;
        final bOrder = int.tryParse(b['displayOrder']?.toString() ?? '') ?? 0;
        return aOrder.compareTo(bOrder);
      });

      return options
          .map((opt) => opt['content']?.toString() ?? '')
          .where((text) => text.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> loadChatSessions() async {
    setState(() {
      isSessionsLoading = true;
    });

    try {
      final sessions = await ChatService.instance.getChatSessions();
      setState(() {
        chatSessions = sessions;
        isSessionsLoading = false;
      });
    } catch (e) {
      setState(() {
        isSessionsLoading = false;
      });
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Không thể tải lịch sử trò chuyện: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> loadChatSessionDetail(String sessionId) async {
    if (chatSessionId != sessionId) {
      await _cleanupEmptySession();
    }
    setState(() {
      isActiveSessionLoading = true;
      isChatThinking = true;
    });

    try {
      if (allQuestions.isEmpty) {
        final questions = await QuizService.instance.getQuestions();
        final options = await QuizService.instance.getQuestionOptions();
        allQuestions = questions;
        allQuestionOptions = options;
      }

      final detail = await ChatService.instance.getChatSessionDetail(sessionId);
      
      final chatHistory = detail['chatHistory'] as List<dynamic>? ?? [];
      final summary = detail['summary'];
      final nextQuestionContent = detail['nextQuestionContent']?.toString();

      final List<ChatMessage> restoredMessages = [];
      
      restoredMessages.add(
        ChatMessage(
          id: 'welcome',
          role: 'assistant',
          content: 'Xin chào! Tôi là Trợ lý Hướng nghiệp AI 4S. Tôi có thể giúp bạn tìm ngành học, trường phù hợp, hoặc giải đáp thắc mắc về định hướng tương lai. Bạn muốn bắt đầu từ điều gì?',
          kind: 'welcome',
        ),
      );

      if (chatHistory.isEmpty) {
        if (nextQuestionContent != null && nextQuestionContent.trim().isNotEmpty) {
          restoredMessages.add(
            ChatMessage(
              id: 'question-init',
              role: 'assistant',
              content: nextQuestionContent,
            ),
          );
        }
      } else {
        final firstQuestionText = chatHistory[0]['questionContent']?.toString();
        if (firstQuestionText != null && firstQuestionText.trim().isNotEmpty) {
          restoredMessages.add(
            ChatMessage(
              id: 'question-0',
              role: 'assistant',
              content: firstQuestionText,
            ),
          );
        }

        for (int i = 0; i < chatHistory.length; i++) {
          final item = chatHistory[i];
          final qId = item['questionId']?.toString() ?? i.toString();

          restoredMessages.add(
            ChatMessage(
              id: 'user-$qId',
              role: 'user',
              content: item['userAnswer']?.toString() ?? '',
            ),
          );

          final evaluation = item['evaluation']?.toString();
          if (evaluation != null && evaluation.trim().isNotEmpty) {
            restoredMessages.add(
              ChatMessage(
                id: 'eval-$qId',
                role: 'assistant',
                content: 'AI nhận xét: "$evaluation"',
                kind: 'assistant_demo',
              ),
            );
          }

          String? nextQText;
          if (i < chatHistory.length - 1) {
            nextQText = chatHistory[i + 1]['questionContent']?.toString();
          } else {
            nextQText = nextQuestionContent;
          }

          if (nextQText != null && nextQText.trim().isNotEmpty) {
            restoredMessages.add(
              ChatMessage(
                id: 'question-next-$qId',
                role: 'assistant',
                content: nextQText,
              ),
            );
          }
        }
      }

      List<AiUniversityRecommendation> restoredRecs = [];
      if (summary != null && summary['recommendations'] is List) {
        final recsList = summary['recommendations'] as List;
        restoredRecs = recsList.map((item) {
          return AiUniversityRecommendation.fromJson(
            Map<String, dynamic>.from(item as Map),
            'top3',
          );
        }).toList();
      }

      setState(() {
        chatSessionId = sessionId;
        chatMessages.clear();
        chatMessages.addAll(restoredMessages);
        chatRecommendations = restoredRecs;
        signalCount = restoredRecs.length;
        activeQuickPrompts = _getQuickPromptsForQuestion(nextQuestionContent);
        usedPromptIndexes.clear();
        isActiveSessionLoading = false;
        isChatThinking = false;
      });
    } catch (e) {
      setState(() {
        isActiveSessionLoading = false;
        isChatThinking = false;
      });
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Không thể tải chi tiết phiên trò chuyện: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    setState(() {
      isSessionsLoading = true;
    });

    try {
      final success = await ChatService.instance.deleteChatSession(sessionId);
      if (success) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Đã xóa phiên trò chuyện thành công.'),
            backgroundColor: Color(0xFF0ED8AB),
          ),
        );
      }
      
      final sessions = await ChatService.instance.getChatSessions();
      
      setState(() {
        chatSessions = sessions;
        isSessionsLoading = false;
        
        if (chatSessionId == sessionId) {
          _resetChatState();
          initChatSession();
        }
      });
    } catch (e) {
      setState(() {
        isSessionsLoading = false;
      });
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Xóa phiên trò chuyện thất bại: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> initChatSession() async {
    if (chatSessionId != null && chatMessages.length > 1) return;

    setState(() {
      chatSessionId = null;
      chatMessages.clear();
      chatMessages.add(
        ChatMessage(
          id: 'welcome',
          role: 'assistant',
          content: 'Xin chào! Tôi là Trợ lý Hướng nghiệp AI. Hãy chia sẻ để tôi có thể tìm ngành học và trường đại học phù hợp nhất với bạn nhé! 😊',
          kind: 'welcome',
        ),
      );
      activeQuickPrompts = [];
      chatRecommendations.clear();
      signalCount = 0;
      isChatThinking = false;
    });
  }

  Future<void> resetChatSession() async {
    await _cleanupEmptySession();
    setState(() {
      chatSessionId = null;
      chatMessages.clear();
      chatRecommendations.clear();
      signalCount = 0;
      usedPromptIndexes.clear();
      activeQuickPrompts = [];
    });
    await initChatSession();
  }

  Future<void> addChatMessage(String text, {required bool isPreset, int? presetIndex}) async {
    if (isChatThinking) return;

    setState(() {
      chatMessages.add(
        ChatMessage(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          role: 'user',
          content: text,
        ),
      );
      if (isPreset && presetIndex != null) {
        usedPromptIndexes.add(presetIndex);
      }
      isChatThinking = true;
    });

    try {
      // Đảm bảo dữ liệu câu hỏi được tải trước khi gửi tin nhắn tiếp theo
      if (allQuestions.isEmpty) {
        final questions = await QuizService.instance.getQuestions();
        final options = await QuizService.instance.getQuestionOptions();
        allQuestions = questions;
        allQuestionOptions = options;
      }

      final response = await ChatService.instance.continueGuidedChat(
        sessionId: chatSessionId,
        message: text,
      );

      final nextSessionId = response['sessionId']?.toString();
      final evaluation = response['evaluation']?.toString();
      final aiMessage = response['message']?.toString();
      final nextQuestion = response['nextQuestionContent']?.toString();
      final summary = response['summary'];

      setState(() {
        if (nextSessionId != null) {
          final isNewSession = chatSessionId == null;
          chatSessionId = nextSessionId;
          if (isNewSession) {
            loadChatSessions();
          }
        }

        isChatThinking = false;

        // 1. Thêm đánh giá nếu có
        if (evaluation != null && evaluation.trim().isNotEmpty) {
          chatMessages.add(
            ChatMessage(
              id: 'eval-${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: 'AI nhận xét: "$evaluation"',
              kind: 'assistant_demo',
            ),
          );
        }

        // 2. Thêm câu trả lời dẫn dắt
        if (aiMessage != null && aiMessage.trim().isNotEmpty) {
          chatMessages.add(
            ChatMessage(
              id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
              role: 'assistant',
              content: aiMessage,
              kind: isPreset ? 'assistant_recommendation_detail' : 'assistant_demo',
            ),
          );
        }

        // 3. Thêm câu hỏi tiếp theo nếu có (tránh trùng lặp nếu AI đã gộp câu hỏi này vào lời thoại dẫn dắt)
        if (nextQuestion != null && nextQuestion.trim().isNotEmpty) {
          // Trích xuất phần cốt lõi của câu hỏi (loại bỏ phần ví dụ trong ngoặc đơn nếu có để tránh AI viết lược bớt ví dụ)
          final questionCore = nextQuestion.split('(')[0].trim();
          
          final cleanAiMsg = (aiMessage ?? '').toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
          final cleanQuestionCore = questionCore.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

          if (cleanQuestionCore.isNotEmpty && !cleanAiMsg.contains(cleanQuestionCore)) {
            chatMessages.add(
              ChatMessage(
                id: 'question-${DateTime.now().millisecondsSinceEpoch}',
                role: 'assistant',
                content: nextQuestion,
              ),
            );
          }
        }

        activeQuickPrompts = _getQuickPromptsForQuestion(nextQuestion);
        usedPromptIndexes.clear(); // Reset used indexes for the new question options

        // 4. Cập nhật các trường đại học đề xuất
        if (summary != null && summary['recommendations'] is List) {
          final recsList = summary['recommendations'] as List;
          chatRecommendations = recsList.map((item) {
            return AiUniversityRecommendation.fromJson(
              Map<String, dynamic>.from(item as Map),
              'top3',
            );
          }).toList();
          signalCount = chatRecommendations.length;
        }
      });
    } catch (e) {
      setState(() {
        isChatThinking = false;
      });
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Gửi tin nhắn thất bại: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppProvider(
      state: this,
      child: MaterialApp(
        title: 'CareerGuidanceAI',
        scaffoldMessengerKey: scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF0F1E36),
          scaffoldBackgroundColor: const Color(0xFF081326),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFECC741), // Gold Accent
            secondary: Color(0xFF0ED8AB), // Emerald Accent
            background: Color(0xFF081326),
            surface: Color(0xFF0F1E36),
          ),
          fontFamily: 'sans-serif',
        ),
        builder: (context, child) {
          return _KeyboardDismissOnTap(child: child ?? const SizedBox.shrink());
        },
        home: isAuthInitializing
            ? const _AuthLoadingScreen()
            : isLoggedIn
            ? const MainNavigationScreen()
            : const LoginScreen(),
      ),
    );
  }
}

class _KeyboardDismissOnTap extends StatelessWidget {
  const _KeyboardDismissOnTap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final currentFocus = FocusManager.instance.primaryFocus;
        final focusContext = currentFocus?.context;
        final renderObject = focusContext?.findRenderObject();

        if (renderObject is RenderBox) {
          final offset = renderObject.localToGlobal(Offset.zero);
          final focusedRect = offset & renderObject.size;
          if (focusedRect.contains(event.position)) {
            return;
          }
        }

        currentFocus?.unfocus();
      },
      child: child,
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF081326),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFECC741))),
    );
  }
}

class AppProvider extends InheritedWidget {
  final AppState state;

  const AppProvider({super.key, required this.state, required super.child});

  @override
  bool updateShouldNotify(AppProvider oldWidget) {
    return true;
  }
}
