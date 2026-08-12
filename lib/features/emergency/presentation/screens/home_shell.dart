import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard_tab.dart';
import 'emergency_history_screen.dart';
import '../widgets/ai_guide_tab.dart';
import '../widgets/blood_bank_tab.dart';
import '../widgets/profile_tab.dart';
import '../controllers/emergency_controller.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(homeTabIndexProvider);

    final List<Widget> pages = const [
      DashboardTab(),
      EmergencyHistoryScreen(),
      AiGuideTab(),
      BloodBankTab(),
      ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
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
                _navItem(context, ref, 0, Icons.home_rounded, 'Home', currentIndex),
                _navItem(context, ref, 1, Icons.history_rounded, 'History', currentIndex),
                _navItem(context, ref, 2, Icons.smart_toy_rounded, 'AI Assistant', currentIndex, isAi: true),
                _navItem(context, ref, 3, Icons.water_drop_rounded, 'Blood Bank', currentIndex),
                _navItem(context, ref, 4, Icons.person_outline_rounded, 'Profile', currentIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    IconData icon,
    String label,
    int currentIndex, {
    bool isAi = false,
  }) {
    final isSelected = currentIndex == index;
    const activeColor = Color(0xFFC62828);

    if (isAi) {
      return GestureDetector(
        onTap: () => ref.read(homeTabIndexProvider.notifier).state = index,
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
      onTap: () => ref.read(homeTabIndexProvider.notifier).state = index,
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
