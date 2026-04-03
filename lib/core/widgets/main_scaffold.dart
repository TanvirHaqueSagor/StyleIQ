import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:styleiq/core/theme/app_theme.dart';

/// Persistent shell scaffold with bottom navigation bar.
/// Wraps the four main tabs: Home, Guide, Wardrobe, Profile.
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60 + (bottomPad > 0 ? 0 : 4),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            indicatorColor: AppTheme.primaryMain.withValues(alpha: 0.12),
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppTheme.primaryMain),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.public_outlined),
                selectedIcon: Icon(Icons.public, color: AppTheme.primaryMain),
                label: 'Guide',
              ),
              NavigationDestination(
                icon: Icon(Icons.checkroom_outlined),
                selectedIcon:
                    Icon(Icons.checkroom, color: AppTheme.primaryMain),
                label: 'Wardrobe',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppTheme.primaryMain),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
