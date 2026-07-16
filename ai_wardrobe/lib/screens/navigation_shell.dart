import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/theme.dart';
import '../providers/navigation_provider.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'recommendation_screen.dart';
import 'profile_screen.dart';

class NavigationShell extends ConsumerStatefulWidget {
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const WardrobeScreen(),
    const RecommendationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: AtelierTheme.background,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(selectedIndex),
              child: _screens[selectedIndex],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: AtelierTheme.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AtelierTheme.border.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, index: 0, label: 'Home', selectedIndex: selectedIndex),
                      _buildNavItem(icon: Icons.checkroom_outlined, activeIcon: Icons.checkroom, index: 1, label: 'Wardrobe', selectedIndex: selectedIndex),
                      _buildNavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, index: 2, label: 'Style', selectedIndex: selectedIndex),
                      _buildNavItem(icon: Icons.person_outline, activeIcon: Icons.person, index: 3, label: 'Profile', selectedIndex: selectedIndex),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    required String label,
    required int selectedIndex,
  }) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => ref.read(navigationProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AtelierTheme.accent.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AtelierTheme.accent : AtelierTheme.secondaryText,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AtelierTheme.accent : AtelierTheme.secondaryText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
