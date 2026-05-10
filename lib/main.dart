import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/live_auctions_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/modern_nav_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const GoldenGavelApp());
}

class GoldenGavelApp extends StatelessWidget {
  const GoldenGavelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golden Gavel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LiveAuctionsScreen(),
    _PlaceholderScreen(
      icon: Icons.bolt_rounded,
      title: 'Drops',
      subtitle: 'Limited drops launching soon',
    ),
    _PlaceholderScreen(
      icon: Icons.receipt_long_rounded,
      title: 'My Bids',
      subtitle: 'All your active and past bids',
    ),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: ModernNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          ModernNavItem(icon: Icons.gavel_rounded, label: 'Live'),
          ModernNavItem(icon: Icons.local_fire_department_rounded, label: 'Hot'),
          ModernNavItem(icon: Icons.bolt_rounded, label: 'Drops'),
          ModernNavItem(icon: Icons.receipt_long_rounded, label: 'Bids'),
          ModernNavItem(icon: Icons.person_rounded, label: 'You'),
        ],
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
