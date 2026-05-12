import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/submission/submit_listing_screen.dart';
import '../services/auctions_repository.dart';
import '../widgets/auction_card.dart';
import '../widgets/pressable.dart';
import '../theme/app_theme.dart';
import '../models/auction_item.dart';
import 'auction_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;
  final List<_Category> _categories = const [
    _Category('All', Icons.apps_rounded),
    _Category('Watches', Icons.watch_rounded),
    _Category('Art', Icons.palette_rounded),
    _Category('Cars', Icons.directions_car_rounded),
    _Category('Real Estate', Icons.home_work_rounded),
    _Category('Jewelry', Icons.diamond_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingAuctionsStreamProvider);
    final liveAsync = ref.watch(liveAuctionsStreamProvider);

    final trendingItems = trendingAsync.value ?? const <AuctionItem>[];
    final selectedCat = _categories[_selectedCategory].label;
    final featuredItems = (liveAsync.value ?? const <AuctionItem>[])
        .where((it) => selectedCat == 'All' || it.category == selectedCat)
        .toList();

    return Scaffold(
      floatingActionButton: _SubmitFab(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubmitListingScreen()),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) setState(() {});
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: _SearchBar()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Trending now',
                emoji: '🔥',
                onSeeAll: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 360,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: trendingItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return _AnimatedEntry(
                      index: index,
                      child: SizedBox(
                        width: 280,
                        child: AuctionCard(
                          item: trendingItems[index],
                          heroTag:
                              'auction_image_trending_${trendingItems[index].id}',
                          onTap: () =>
                              _openDetail(trendingItems[index], 'trending'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Discover',
                emoji: '✨',
                onSeeAll: () {},
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _CategoryChips(
                categories: _categories,
                selected: _selectedCategory,
                onChange: (i) => setState(() => _selectedCategory = i),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _AnimatedEntry(
                    index: index,
                    child: AuctionCard(
                      item: featuredItems[index],
                      compact: true,
                      heroTag:
                          'auction_image_discover_${featuredItems[index].id}',
                      onTap: () =>
                          _openDetail(featuredItems[index], 'discover'),
                    ),
                  );
                }, childCount: featuredItems.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _openDetail(AuctionItem item, [String section = 'default']) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => AuctionDetailScreen(
          item: item,
          heroTag: 'auction_image_${section}_${item.id}',
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hey, Alex 👋', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  'Find your next gem',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
              ],
            ),
            const Spacer(),
            _IconBubble(
              icon: Icons.notifications_rounded,
              onTap: () {},
              badge: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _IconBubble({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 20),
          ),
          if (badge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            Icon(
              Icons.search_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search watches, art, drops…',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  hintStyle: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Pressable(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String emoji;
  final VoidCallback onSeeAll;
  const _SectionHeader({
    required this.title,
    required this.emoji,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.displaySmall),
            ],
          ),
          Pressable(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'See all',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Category {
  final String label;
  final IconData icon;
  const _Category(this.label, this.icon);
}

class _CategoryChips extends StatelessWidget {
  final List<_Category> categories;
  final int selected;
  final ValueChanged<int> onChange;
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final selectedNow = i == selected;
          final cat = categories[i];
          return Pressable(
            onTap: () => onChange(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: selectedNow ? AppTheme.primaryGradient : null,
                color: selectedNow ? null : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: selectedNow
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon,
                    size: 16,
                    color: selectedNow
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selectedNow
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubmitFab extends StatelessWidget {
  final VoidCallback onTap;
  const _SubmitFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 86),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.add_rounded, color: Colors.white, size: 22),
              SizedBox(width: 6),
              Text(
                'List item',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final int index;
  final Widget child;
  const _AnimatedEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, c) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 24),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
