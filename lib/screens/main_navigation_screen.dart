import 'package:flutter/material.dart';

import '../main.dart';
import 'chat_tab.dart';
import 'home_tab.dart';
import 'pricing_tab.dart';
import 'profile_screen.dart';
import 'quiz_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = AppState.of(context).currentUser;
    final avatarUrl = user?.avatarUrl.trim() ?? '';
    final normalizedPlan = (user?.currentPlan ?? 'free').toLowerCase();
    final isFreePlan = normalizedPlan == 'free';
    final canUseQuiz = !isFreePlan;

    final tabs = <Widget>[
      const HomeTab(),
      const ChatTab(),
      if (isFreePlan) const PricingTab(),
      if (canUseQuiz) const QuizTab(),
    ];
    final titles = <String>[
      'La Bàn Định Hướng 4S',
      'Trợ Lý AI Career Advisor',
      if (isFreePlan) 'Bảng Giá',
      if (canUseQuiz) 'Trắc Nghiệm Tính Cách',
    ];
    final navigationItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Trang chủ',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: 'Trợ lý AI',
      ),
      if (isFreePlan)
        const BottomNavigationBarItem(
          icon: Icon(Icons.workspace_premium_outlined),
          activeIcon: Icon(Icons.workspace_premium),
          label: 'Pricing',
        ),
      if (canUseQuiz)
        const BottomNavigationBarItem(
          icon: Icon(Icons.psychology_outlined),
          activeIcon: Icon(Icons.psychology),
          label: 'Trắc nghiệm',
        ),
    ];

    final currentIndex = _currentTabIndex >= tabs.length ? 0 : _currentTabIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF081326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E36),
        elevation: 0,
        title: Text(
          titles[currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              height: 32,
              width: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFECC741).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: avatarUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 18,
                        color: Color(0xFFECC741),
                      )
                    : Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.person,
                          size: 18,
                          color: Color(0xFFECC741),
                        ),
                      ),
              ),
            ),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tabs[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          backgroundColor: const Color(0xFF0F1E36),
          selectedItemColor: const Color(0xFFECC741),
          unselectedItemColor: Colors.white38,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          type: BottomNavigationBarType.fixed,
          items: navigationItems,
        ),
      ),
    );
  }
}
