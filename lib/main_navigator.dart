import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_repository.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'screens/raffles_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auctions_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/modern_nav_bar.dart';

/// Drives which tab is shown in [MainNavigator]. Any screen can write to this
/// to switch tabs (e.g. Home's "View All" buttons).
final tabIndexProvider = NotifierProvider<TabIndexController, int>(
  TabIndexController.new,
);

class TabIndexController extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    state = index;
  }
}

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {

  // 5 fixed screens — index 4 is admin-only, reachable via admin button
  static const _screens = <Widget>[
    HomeScreen(),
    AuctionsScreen(),
    RafflesScreen(),
    ProfileScreen(),
    AdminDashboardScreen(),
  ];

  static const _items = <ModernNavItem>[
    ModernNavItem(icon: Icons.explore_rounded, label: 'Discover'),
    ModernNavItem(icon: Icons.gavel_rounded, label: 'Auctions'),
    ModernNavItem(icon: Icons.confirmation_number_rounded, label: 'Raffles'),
    ModernNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _openAdmin() {
    ref.read(tabIndexProvider.notifier).setTab(4);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).value;
    final isAdmin = session?.isAdmin ?? false;
    final currentIndex = ref.watch(tabIndexProvider);
    final safeIndex = currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.025),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey<int>(safeIndex),
          child: _screens[safeIndex],
        ),
      ),
      bottomNavigationBar: ModernNavBar(
        currentIndex: safeIndex,
        onTap: (i) => ref.read(tabIndexProvider.notifier).setTab(i),
        items: _items,
        showAdminButton: isAdmin,
        onAdminTap: _openAdmin,
      ),
    );
  }
}
