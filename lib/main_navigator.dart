import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_repository.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'screens/raffles_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_auctions_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/modern_nav_bar.dart';

class MainNavigator extends ConsumerStatefulWidget {
  const MainNavigator({super.key});

  @override
  ConsumerState<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends ConsumerState<MainNavigator> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authStateProvider).value;
    final isAdmin = session?.isAdmin ?? false;

    final screens = <Widget>[
      const HomeScreen(),
      const LiveAuctionsScreen(),
      const RafflesScreen(),
      const _PlaceholderScreen(
        icon: Icons.receipt_long_rounded,
        title: 'My Bids',
        subtitle: 'All your active and past bids',
      ),
      if (isAdmin) const AdminDashboardScreen(),
      const ProfileScreen(),
    ];

    final items = <ModernNavItem>[
      const ModernNavItem(icon: Icons.gavel_rounded, label: 'Live'),
      const ModernNavItem(
        icon: Icons.local_fire_department_rounded,
        label: 'Hot',
      ),
      const ModernNavItem(icon: Icons.emoji_events_rounded, label: 'Raffles'),
      const ModernNavItem(icon: Icons.receipt_long_rounded, label: 'Bids'),
      if (isAdmin)
        const ModernNavItem(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Admin',
        ),
      const ModernNavItem(icon: Icons.person_rounded, label: 'You'),
    ];

    final safeIndex = _currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(safeIndex),
          child: screens[safeIndex],
        ),
      ),
      bottomNavigationBar: ModernNavBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: items,
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(title, style: theme.textTheme.displaySmall),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
