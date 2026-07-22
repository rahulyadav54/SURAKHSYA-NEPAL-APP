import 'package:flutter/material.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/map_tab.dart';
import '../widgets/ai_guide_tab.dart';
import '../widgets/profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardTab(),
    MapTab(),
    AiGuideTab(),
    ProfileTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _navItem(1, Icons.history_rounded, 'History'),
                _navItem(2, Icons.smart_toy_rounded, 'AI Assistant', isAi: true),
                _navItem(3, Icons.info_outline_rounded, 'Safety Tips'),
                _navItem(4, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {bool isAi = false}) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFFC62828);

    if (isAi) {
      return GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                border: Border.all(
                  color: isSelected ? activeColor : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey.shade600,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
