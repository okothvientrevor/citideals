import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme_controller.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_repository.dart';
import '../features/submission/my_submissions_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider).value;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              name: session?.user.displayName ?? 'Guest',
              email: session?.user.email ?? '',
              photoUrl: session?.user.photoURL,
              isAdmin: session?.isAdmin ?? false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      label: 'Bids',
                      value: '0',
                      icon: Icons.gavel_rounded,
                      gradient: AppTheme.primaryGradient,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Won',
                      value: '0',
                      icon: Icons.emoji_events_rounded,
                      gradient: AppTheme.amberGradient,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Watching',
                      value: '0',
                      icon: Icons.favorite_rounded,
                      gradient: AppTheme.mintGradient,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SectionLabel(text: 'Account'),
          ),
          SliverToBoxAdapter(
            child: _MenuGroup(
              items: [
                _MenuEntry(
                  icon: Icons.history_rounded,
                  title: 'Bid history',
                  onTap: () {},
                ),
                _MenuEntry(
                  icon: Icons.favorite_border_rounded,
                  title: 'Watchlist',
                  onTap: () {},
                ),
                _MenuEntry(
                  icon: Icons.inventory_2_outlined,
                  title: 'My submissions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MySubmissionsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _SectionLabel(text: 'Preferences')),
          SliverToBoxAdapter(
            child: _MenuGroup(
              items: [
                _MenuEntry(
                  icon: Icons.brightness_6_rounded,
                  title: 'Appearance',
                  trailing: const _ThemeBadge(),
                  onTap: () => _showThemeSheet(context, ref),
                ),
                _MenuEntry(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  onTap: () {},
                ),
                _MenuEntry(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  destructive: true,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ThemePickerSheet(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Text(
        text,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ThemeBadge extends ConsumerWidget {
  const _ThemeBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeControllerProvider);
    final label = switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ThemePickerSheet extends ConsumerWidget {
  const _ThemePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(themeControllerProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text('Appearance', style: theme.textTheme.displaySmall),
              const SizedBox(height: 4),
              Text(
                'Choose how the app looks on this device.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _ThemeOption(
                icon: Icons.phone_iphone_rounded,
                label: 'System',
                description: 'Follows your device setting',
                selected: current == ThemeMode.system,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .set(ThemeMode.system),
              ),
              const SizedBox(height: 10),
              _ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                description: 'Bright, low-contrast feed',
                selected: current == ThemeMode.light,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .set(ThemeMode.light),
              ),
              const SizedBox(height: 10),
              _ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                description: 'Easy on the eyes at night',
                selected: current == ThemeMode.dark,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .set(ThemeMode.dark),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          color: selected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.18)
                    : AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? Colors.white.withOpacity(0.85)
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final bool isAdmin;

  const _ProfileHero({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                      image: photoUrl == null
                          ? null
                          : DecorationImage(
                              image: NetworkImage(photoUrl!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    child: photoUrl != null
                        ? null
                        : Center(
                            child: Text(
                              name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.star_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAdmin ? 'Admin' : 'Member',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.displaySmall?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MenuEntry {
  final IconData icon;
  final String title;
  final bool destructive;
  final Widget? trailing;
  final VoidCallback onTap;
  const _MenuEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
    this.trailing,
  });
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuEntry> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isLast = i == items.length - 1;
            return _MenuTile(item: item, divider: !isLast);
          }),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuEntry item;
  final bool divider;
  const _MenuTile({required this.item, required this.divider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.destructive ? AppTheme.coral : AppTheme.primary;

    return Pressable(
      onTap: item.onTap,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: color, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: item.destructive
                          ? AppTheme.coral
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (item.trailing != null) ...[
                  item.trailing!,
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
          if (divider)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 16),
              child: Container(
                height: 1,
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}
