import 'dart:async';
import 'package:flutter/material.dart';
import 'models/user.dart';
import 'models/chat.dart';
import 'models/university.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

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
  Timer? _refreshTimer;

  UserProfile? currentUser;
  bool isLoggedIn = false;
  bool isAuthInitializing = true;
  bool isLoggingOut = false;

  // AI Chat states
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
  List<UniversityWithScore> chatRecommendations = [];

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
            'Xin chào! Tôi là Trợ lý Hướng nghiệp AI 4S. Tôi có thể giúp bạn tìm ngành học, trường phù hợp, hoặc giải đáp thắc mắc về định hướng tương lai. Bạn muốn bắt đầu từ điều gì?',
        kind: 'welcome',
      ),
    );
    chatProfile.forEach((k, v) => chatProfile[k] = 0);
    signalCount = 0;
    usedPromptIndexes.clear();
    chatRecommendations = rankUniversities(chatProfile);
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
  }

  Future<void> logout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    _refreshTimer?.cancel();
    await _authService.logout();

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
  void addChatMessage(String text, {required bool isPreset, int? presetIndex}) {
    if (isChatThinking) return;

    setState(() {
      // 1. Add User Message
      chatMessages.add(
        ChatMessage(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          role: 'user',
          content: text,
        ),
      );

      isChatThinking = true;
    });

    // 2. Perform background analysis and reply generation after 700ms
    Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      setState(() {
        isChatThinking = false;
        String aiResponse = "";
        String? targetSchoolId;

        // Keyword analysis and profile merging
        final delta = extractDeltaFromMessage(text);
        delta.forEach((key, val) {
          chatProfile[key] = (chatProfile[key] ?? 0) + val;
        });
        signalCount += 1;

        if (isPreset && presetIndex != null) {
          usedPromptIndexes.add(presetIndex);

          // Get top matching school for preset
          final ranked = rankUniversities(chatProfile);
          final topSchool = ranked.first;
          targetSchoolId = topSchool.id;

          final keys = _getSchoolStrengthKeys(topSchool);
          final strengths = keys.map((k) => focusLabelsVi[k] ?? k).join(' và ');

          aiResponse =
              '${topSchool.name["vi"]} là lựa chọn phù hợp nhất với hồ sơ hiện tại của bạn. Trường nổi bật ở nhóm ${topSchool.major["vi"]}. Khu vực: ${topSchool.place["vi"]}. Mức học phí tham khảo: ${topSchool.tuition["vi"]}. Dựa trên các tín hiệu bạn đã cung cấp, mức độ tương thích cao nhất nằm ở nhóm $strengths.';
        } else {
          // Free text custom keyword matching
          final textLower = text.toLowerCase();
          if (textLower.contains('it') || textLower.contains('công nghệ')) {
            aiResponse =
                'Tôi ghi nhận bạn quan tâm đến công nghệ và máy tính. ĐH Bách Khoa TP.HCM (HCMUT) và ĐH Bách Khoa Hà Nội (HUST) là hai gợi ý hàng đầu về khối kỹ thuật - công nghệ với mức độ tương thích của bạn tăng lên đáng kể.';
          } else if (textLower.contains('học phí') ||
              textLower.contains('tiền')) {
            aiResponse =
                'Mức học phí tham khảo của các trường công như ĐH Bách Khoa (HCMUT) khoảng 15-25 triệu/học kỳ, trong khi RMIT Việt Nam có học phí từ 70-95 triệu/học kỳ. Bạn có thể xem chi tiết ở khay trường đề xuất ngay phía dưới.';
          } else if (textLower.contains('hồ chí minh') ||
              textLower.contains('hcm')) {
            aiResponse =
                'Tại TP.HCM, ĐH Bách Khoa TP.HCM (HCMUT) và RMIT Việt Nam là những lựa chọn được sinh viên đánh giá tốt nhất. Bạn có muốn xem thêm chi tiết học phí của hai trường này không?';
          } else if (textLower.contains('kinh doanh') ||
              textLower.contains('kinh tế')) {
            aiResponse =
                'Đối với khối kinh doanh và thị trường, ĐH Ngoại Thương (FTU) là lựa chọn cực kỳ uy tín. RMIT cũng rất nổi bật về Quản trị Kinh doanh và Marketing.';
          } else {
            aiResponse =
                'Cảm ơn bạn đã trò chuyện. Free-text chat hiện đang ở chế độ demo và hỗ trợ tư vấn các khối ngành IT, Kinh tế, Thiết kế, hoặc thông tin học phí tại TP.HCM. Bạn có thể chọn một chủ đề gợi ý nhanh ở trên để có phản hồi chi tiết.';
          }
        }

        // Add Assistant Message
        chatMessages.add(
          ChatMessage(
            id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
            role: 'assistant',
            content: aiResponse,
            kind: isPreset
                ? 'assistant_recommendation_detail'
                : 'assistant_demo',
            schoolId: targetSchoolId,
          ),
        );

        // Update recommendations
        chatRecommendations = rankUniversities(chatProfile);
      });
    });
  }

  List<String> _getSchoolStrengthKeys(University school) {
    List<MapEntry<String, int>> sorted = school.affinity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppProvider(
      state: this,
      child: MaterialApp(
        title: 'CareerGuidanceAI',
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
