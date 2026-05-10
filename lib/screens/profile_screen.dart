import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _ProfileHero()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: const [
                  Expanded(
                    child: _StatCard(
                      label: 'Bids',
                      value: '42',
                      icon: Icons.gavel_rounded,
                      gradient: AppTheme.primaryGradient,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Won',
                      value: '12',
                      icon: Icons.emoji_events_rounded,
                      gradient: AppTheme.amberGradient,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Watching',
                      value: '8',
                      icon: Icons.favorite_rounded,
                      gradient: AppTheme.mintGradient,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                'Account',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _MenuGroup(
              items: const [
                _MenuEntry(icon: Icons.history_rounded, title: 'Bid history'),
                _MenuEntry(
                  icon: Icons.favorite_border_rounded,
                  title: 'Watchlist',
                ),
                _MenuEntry(
                  icon: Icons.payment_rounded,
                  title: 'Payment methods',
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Preferences',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _MenuGroup(
              items: const [
                _MenuEntry(icon: Icons.settings_rounded, title: 'Settings'),
                _MenuEntry(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                ),
                _MenuEntry(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  destructive: true,
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
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
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
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
                          children: const [
                            Flexible(
                              child: Text(
                                'Alex Morgan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'alex@goldengavel.com',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Pressable(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                      child: const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Gold Member',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '2,400 pts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
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
  const _MenuEntry({
    required this.icon,
    required this.title,
    this.destructive = false,
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
      onTap: () {},
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
