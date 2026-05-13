import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/submission/submit_listing_screen.dart';
import '../main_navigator.dart';
import '../models/auction_item.dart';
import '../models/raffle.dart';
import '../services/auctions_repository.dart';
import '../services/raffles_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/auction_card.dart';
import '../widgets/cached_image.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/pressable.dart';
import 'auction_detail_screen.dart';
import 'raffles_screen.dart' show RaffleDetailsScreen;

final _numFmt = NumberFormat('#,##0', 'en_US');

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

enum _DiscoverSort {
  endingSoon('Ending Soon'),
  newest('Newest'),
  priceLow('Price: Low → High'),
  priceHigh('Price: High → Low'),
  mostBids('Most Bids');

  final String label;
  const _DiscoverSort(this.label);
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedCategory = 0;
  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _DiscoverSort _sort = _DiscoverSort.endingSoon;

  final List<_Category> _categories = const [
    _Category('All', Icons.apps_rounded),
    _Category('Watches', Icons.watch_rounded),
    _Category('Art', Icons.palette_rounded),
    _Category('Cars', Icons.directions_car_rounded),
    _Category('Real Estate', Icons.home_work_rounded),
    _Category('Jewelry', Icons.diamond_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _searchQuery) setState(() => _searchQuery = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    ref.read(tabIndexProvider.notifier).setTab(index);
  }

  void _openRaffle(Raffle raffle) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RaffleDetailsScreen(raffle: raffle)),
    );
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<_DiscoverSort>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Sort by', style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                for (final s in _DiscoverSort.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.label),
                    trailing: s == _sort
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppTheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(ctx).pop(s),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) setState(() => _sort = selected);
  }

  List<AuctionItem> _applyDiscoverFilters(List<AuctionItem> source) {
    final selectedCat = _categories[_selectedCategory].label;
    Iterable<AuctionItem> out = source.where(
      (it) => selectedCat == 'All' || it.category == selectedCat,
    );
    if (_searchQuery.isNotEmpty) {
      out = out.where((it) {
        final hay = [
          it.title,
          it.category,
          it.sellerName ?? '',
          it.location ?? '',
        ].join(' ').toLowerCase();
        return hay.contains(_searchQuery);
      });
    }
    final list = out.toList();
    switch (_sort) {
      case _DiscoverSort.endingSoon:
        list.sort((a, b) => a.endTime.compareTo(b.endTime));
        break;
      case _DiscoverSort.newest:
        list.sort((a, b) => b.endTime.compareTo(a.endTime));
        break;
      case _DiscoverSort.priceLow:
        list.sort((a, b) => a.currentBid.compareTo(b.currentBid));
        break;
      case _DiscoverSort.priceHigh:
        list.sort((a, b) => b.currentBid.compareTo(a.currentBid));
        break;
      case _DiscoverSort.mostBids:
        list.sort((a, b) => b.totalBids.compareTo(a.totalBids));
        break;
    }
    return list;
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
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trendingAsync = ref.watch(trendingAuctionsStreamProvider);
    final rafflesAsync = ref.watch(activeRafflesStreamProvider);
    final liveAsync = ref.watch(liveAuctionsStreamProvider);

    final trending = trendingAsync.value ?? const <AuctionItem>[];
    final raffles = rafflesAsync.value ?? const <Raffle>[];
    final discover = _applyDiscoverFilters(
      liveAsync.value ?? const <AuctionItem>[],
    );

    final heroItem = trending.isNotEmpty ? trending.first : null;
    final tickerItems = trending.length > 1
        ? trending.sublist(1)
        : const <AuctionItem>[];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_list_item_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubmitListingScreen()),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            // Header
            SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Trending Now
            SliverToBoxAdapter(
              child: _TrendingSection(
                heroItem: heroItem,
                tickerItems: tickerItems,
                onTapItem: (item) => _openDetail(item, 'trending'),
                onSeeAll: () => _switchTab(1),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),

            // Featured Raffles
            if (raffles.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  label: 'FEATURED',
                  title: 'Featured Raffles',
                  onSeeAll: () => _switchTab(2),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _FeaturedRafflesCarousel(
                  raffles: raffles,
                  onTap: _openRaffle,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
            ],

            // CTA
            SliverToBoxAdapter(
              child: _ExperienceCTA(onStartBidding: () => _switchTab(1)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),

            // Discover grid
            SliverToBoxAdapter(
              child: _DiscoverHeader(
                searchOpen: _searchOpen,
                onToggleSearch: () {
                  setState(() {
                    _searchOpen = !_searchOpen;
                    if (!_searchOpen) {
                      _searchCtrl.clear();
                      _searchQuery = '';
                    }
                  });
                },
                onTapSort: _openSortSheet,
                currentSort: _sort,
              ),
            ),
            if (_searchOpen) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DiscoverSearchBar(controller: _searchCtrl),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _CategoryChips(
                categories: _categories,
                selected: _selectedCategory,
                onChange: (i) => setState(() => _selectedCategory = i),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (discover.isEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No items in this category yet',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _AnimatedEntry(
                      index: i,
                      child: AuctionCard(
                        item: discover[i],
                        compact: true,
                        heroTag: 'auction_image_discover_${discover[i].id}',
                        onTap: () => _openDetail(discover[i], 'discover'),
                      ),
                    ),
                    childCount: discover.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => AppTheme.primaryGradient.createShader(b),
              child: Text(
                'citideals',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Spacer(),
            Pressable(
              onTap: () => HapticFeedback.selectionClick(),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trending Now section
// ─────────────────────────────────────────────────────────────────────────────

class _TrendingSection extends StatelessWidget {
  final AuctionItem? heroItem;
  final List<AuctionItem> tickerItems;
  final ValueChanged<AuctionItem> onTapItem;
  final VoidCallback onSeeAll;

  const _TrendingSection({
    required this.heroItem,
    required this.tickerItems,
    required this.onTapItem,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE NOW',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                      fontSize: 11,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Trending Now', style: theme.textTheme.displaySmall),
                  Pressable(
                    onTap: onSeeAll,
                    child: Row(
                      children: [
                        Text(
                          'View All',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.primary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (heroItem != null)
          _HeroAuctionCard(item: heroItem!, onTap: () => onTapItem(heroItem!)),
        if (tickerItems.isNotEmpty) ...[
          const SizedBox(height: 14),
          _TrendingTicker(items: tickerItems, onTap: onTapItem),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero card – full-width, image background
// ─────────────────────────────────────────────────────────────────────────────

class _HeroAuctionCard extends StatelessWidget {
  final AuctionItem item;
  final VoidCallback onTap;

  const _HeroAuctionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 210,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.imageUrl.isNotEmpty)
                Hero(
                  tag: 'auction_image_trending_${item.id}',
                  child: CachedImage(
                    url: item.imageUrl,
                    fit: BoxFit.cover,
                    targetWidth: 900,
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.82),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accent.withOpacity(0.7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Current Bid: ${item.formattedCurrentBid}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
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

// ─────────────────────────────────────────────────────────────────────────────
// Auto-scrolling vertical ticker
// ─────────────────────────────────────────────────────────────────────────────

class _TrendingTicker extends StatefulWidget {
  final List<AuctionItem> items;
  final ValueChanged<AuctionItem> onTap;

  const _TrendingTicker({required this.items, required this.onTap});

  @override
  State<_TrendingTicker> createState() => _TrendingTickerState();
}

class _TrendingTickerState extends State<_TrendingTicker> {
  late final PageController _pc;
  Timer? _timer;
  int _page = 0;

  List<List<AuctionItem>> get _pages {
    final pairs = <List<AuctionItem>>[];
    for (var i = 0; i < widget.items.length; i += 2) {
      pairs.add([
        widget.items[i],
        if (i + 1 < widget.items.length) widget.items[i + 1],
      ]);
    }
    return pairs;
  }

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.items.length > 2) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final pages = _pages;
        if (pages.isEmpty) return;
        final next = (_page + 1) % pages.length;
        _pc.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pages = _pages;
    if (pages.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0A0A14)
            : AppTheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : AppTheme.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 236,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (p) => setState(() => _page = p),
              itemCount: pages.length,
              itemBuilder: (ctx, i) {
                final pair = pages[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: _TickerCard(
                          item: pair[0],
                          onTap: () => widget.onTap(pair[0]),
                        ),
                      ),
                      if (pair.length > 1) ...[
                        const SizedBox(height: 8),
                        Expanded(
                          child: _TickerCard(
                            item: pair[1],
                            onTap: () => widget.onTap(pair[1]),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (pages.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.primary
                          : AppTheme.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single ticker card
// ─────────────────────────────────────────────────────────────────────────────

class _TickerCard extends StatelessWidget {
  final AuctionItem item;
  final VoidCallback onTap;

  const _TickerCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.06))
              : Border.all(color: AppTheme.primary.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: item.imageUrl.isNotEmpty
                    ? CachedImage(
                        url: item.imageUrl,
                        fit: BoxFit.cover,
                        targetWidth: 220,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.formattedCurrentBid,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      CountdownTimer(
                        endTime: item.endTime,
                        textStyle: const TextStyle(
                          color: Color(0xFFFF3B30),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured raffle card
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedRafflesCarousel extends StatefulWidget {
  final List<Raffle> raffles;
  final ValueChanged<Raffle> onTap;

  const _FeaturedRafflesCarousel({required this.raffles, required this.onTap});

  @override
  State<_FeaturedRafflesCarousel> createState() =>
      _FeaturedRafflesCarouselState();
}

class _FeaturedRafflesCarouselState extends State<_FeaturedRafflesCarousel> {
  late final PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.raffles.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _FeaturedRaffleCard(
          raffle: widget.raffles.first,
          onTap: () => widget.onTap(widget.raffles.first),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _pc,
            itemCount: widget.raffles.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _FeaturedRaffleCard(
                raffle: widget.raffles[i],
                onTap: () => widget.onTap(widget.raffles[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.raffles.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primary
                    : AppTheme.primary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FeaturedRaffleCard extends StatelessWidget {
  final Raffle raffle;
  final VoidCallback onTap;

  const _FeaturedRaffleCard({required this.raffle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = raffle.maxTickets > 0
        ? (raffle.soldTickets / raffle.maxTickets).clamp(0.0, 1.0)
        : 0.0;
    final pctLabel = '${(pct * 100).round()}% SOLD';
    final ticketLabel = 'UGX ${_numFmt.format(raffle.ticketPrice)} / Ticket';

    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.5)
                  : AppTheme.primary.withOpacity(0.07),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.04))
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: raffle.bannerImage.isNotEmpty
                        ? CachedImage(
                            url: raffle.bannerImage,
                            fit: BoxFit.cover,
                            targetWidth: 900,
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pctLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raffle.title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticketLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: isDark
                            ? const Color(0xFF252525)
                            : const Color(0xFFE8EDFF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primary,
                          side: BorderSide(
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primary,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        child: const Text('Enter Now'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Experience Velocity CTA
// ─────────────────────────────────────────────────────────────────────────────

class _ExperienceCTA extends StatelessWidget {
  final VoidCallback onStartBidding;

  const _ExperienceCTA({required this.onStartBidding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : AppTheme.primary.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.04))
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Column(
            children: [
              Text(
                'Experience Velocity.',
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Join the elite circle of bidders and secure exclusive assets through our secure, high-speed auction platform. Real-time updates, guaranteed verification.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onStartBidding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Start Bidding',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onStartBidding,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppTheme.primaryLight
                            : AppTheme.primary,
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.primaryLight
                              : AppTheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'How it Works',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String? label;
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    this.label,
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(title, style: theme.textTheme.displaySmall),
            ],
          ),
          Pressable(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.10),
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

// ─────────────────────────────────────────────────────────────────────────────
// Category filter chips
// ─────────────────────────────────────────────────────────────────────────────

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
          final sel = i == selected;
          final cat = categories[i];
          return Pressable(
            onTap: () {
              HapticFeedback.selectionClick();
              onChange(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: sel ? AppTheme.primaryGradient : null,
                color: sel ? null : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.30),
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
                    color: sel
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: sel ? Colors.white : theme.colorScheme.onSurface,
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

// ─────────────────────────────────────────────────────────────────────────────
// Discover section header — title + search + sort
// ─────────────────────────────────────────────────────────────────────────────

class _DiscoverHeader extends StatelessWidget {
  final bool searchOpen;
  final VoidCallback onToggleSearch;
  final VoidCallback onTapSort;
  final _DiscoverSort currentSort;

  const _DiscoverHeader({
    required this.searchOpen,
    required this.onToggleSearch,
    required this.onTapSort,
    required this.currentSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPLORE',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primary,
                    fontSize: 11,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Discover', style: theme.textTheme.displaySmall),
              ],
            ),
          ),
          _IconChip(
            icon: searchOpen ? Icons.close_rounded : Icons.search_rounded,
            onTap: onToggleSearch,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _IconChip(
            icon: Icons.tune_rounded,
            onTap: onTapSort,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _IconChip({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkCard
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }
}

class _DiscoverSearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _DiscoverSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.18),
        ),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by title, category or seller',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.primary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          isCollapsed: false,
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fade-in + slide-up entry animation
// ─────────────────────────────────────────────────────────────────────────────

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
      builder: (context, value, c) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 24),
          child: c,
        ),
      ),
      child: child,
    );
  }
}
