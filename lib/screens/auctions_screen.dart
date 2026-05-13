import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/auth/auth_repository.dart';
import '../models/auction_item.dart';
import '../models/bid.dart';
import '../services/auctions_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_banner.dart';
import '../widgets/auction_card.dart';
import '../widgets/cached_image.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/pressable.dart';
import 'auction_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Gradient reused from auction_detail_screen for the bid button
// ─────────────────────────────────────────────────────────────────────────────
const _luminaGradient = LinearGradient(
  colors: [Color(0xFF8B5CF6), Color(0xFFB04CF5)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class AuctionsScreen extends ConsumerStatefulWidget {
  const AuctionsScreen({super.key});

  @override
  ConsumerState<AuctionsScreen> createState() => _AuctionsScreenState();
}

const _kCategories = [
  'All',
  'Electronics',
  'Watches',
  'Fashion',
  'Art',
  'Collectibles',
  'Vehicles',
  'Jewelry',
];

enum _AuctionSort {
  live('Live First'),
  endingSoon('Ending Soon'),
  mostBids('Most Bids'),
  priceLow('Price: Low → High'),
  priceHigh('Price: High → Low'),
  newest('Newest');

  final String label;
  const _AuctionSort(this.label);
}

class _AuctionsScreenState extends ConsumerState<AuctionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  _AuctionSort _sort = _AuctionSort.live;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final liveAsync = ref.watch(liveAuctionsStreamProvider);
    final liveAuctions = liveAsync.value ?? [];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E0E14)
          : theme.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.coral,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.coral.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fiber_manual_record_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'LIVE NOW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Auctions 🔥', style: theme.textTheme.displayMedium),
                      const SizedBox(height: 14),

                      // ── Search bar + sort button ───────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF16161F)
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.black.withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 14),
                                  Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: isDark
                                        ? Colors.white38
                                        : theme.colorScheme.onSurface
                                              .withOpacity(0.35),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Search auctions…',
                                        hintStyle: TextStyle(
                                          color: isDark
                                              ? Colors.white38
                                              : theme.colorScheme.onSurface
                                                    .withOpacity(0.35),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => _searchCtrl.clear(),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white38
                                              : theme.colorScheme.onSurface
                                                    .withOpacity(0.35),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Sort button
                          GestureDetector(
                            onTap: () => _showSortSheet(context),
                            child: Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                gradient: _sort != _AuctionSort.live
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: _sort == _AuctionSort.live
                                    ? (isDark
                                          ? const Color(0xFF16161F)
                                          : theme
                                                .colorScheme
                                                .surfaceContainerHighest)
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _sort != _AuctionSort.live
                                      ? Colors.transparent
                                      : isDark
                                      ? Colors.white.withOpacity(0.07)
                                      : Colors.black.withOpacity(0.06),
                                ),
                              ),
                              child: Icon(
                                Icons.sort_rounded,
                                size: 22,
                                color: _sort != _AuctionSort.live
                                    ? Colors.white
                                    : isDark
                                    ? Colors.white60
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.6,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Category chips (horizontal scroll) ──────────────────────
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _kCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = _kCategories[i];
                      final selected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? AppTheme.primaryGradient
                                : null,
                            color: selected
                                ? null
                                : isDark
                                ? const Color(0xFF16161F)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.30),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : isDark
                                  ? Colors.white60
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Tab bar ─────────────────────────────────────────────
          _AuctionTabBar(controller: _tabCtrl, isDark: isDark, theme: theme),

          // ── Tab views ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _AllBidsTab(
                  liveAuctions: liveAuctions,
                  liveAsync: liveAsync,
                  searchQuery: _searchQuery,
                  selectedCategory: _selectedCategory,
                  sort: _sort,
                ),
                const _MyBidsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0C0C14) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0B1437),
                  ),
                ),
                const SizedBox(height: 14),
                ..._AuctionSort.values.map((s) {
                  final selected = s == _sort;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _sort = s);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          gradient: selected ? AppTheme.primaryGradient : null,
                          color: selected
                              ? null
                              : isDark
                              ? const Color(0xFF16161F)
                              : const Color(0xFFF4F7FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : isDark
                                      ? Colors.white70
                                      : const Color(0xFF0B1437),
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _AuctionTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  final ThemeData theme;

  const _AuctionTabBar({
    required this.controller,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16161F)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.30),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? Colors.white54
            : theme.colorScheme.onSurface.withOpacity(0.5),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'All Bids'),
          Tab(text: 'My Bids'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All Bids tab — existing live auction list
// ─────────────────────────────────────────────────────────────────────────────

class _AllBidsTab extends ConsumerWidget {
  final List<AuctionItem> liveAuctions;
  final AsyncValue<List<AuctionItem>> liveAsync;
  final String searchQuery;
  final String selectedCategory;
  final _AuctionSort sort;

  const _AllBidsTab({
    required this.liveAuctions,
    required this.liveAsync,
    required this.searchQuery,
    required this.selectedCategory,
    required this.sort,
  });

  List<AuctionItem> _filtered(List<AuctionItem> items) {
    final list = items.where((a) {
      final matchCat =
          selectedCategory == 'All' ||
          a.category.toLowerCase() == selectedCategory.toLowerCase();
      final matchSearch =
          searchQuery.isEmpty || a.title.toLowerCase().contains(searchQuery);
      return matchCat && matchSearch;
    }).toList();

    switch (sort) {
      case _AuctionSort.live:
        list.sort((a, b) => a.endTime.compareTo(b.endTime));
      case _AuctionSort.endingSoon:
        list.sort((a, b) => a.endTime.compareTo(b.endTime));
      case _AuctionSort.mostBids:
        list.sort((a, b) => b.totalBids.compareTo(a.totalBids));
      case _AuctionSort.priceLow:
        list.sort((a, b) => a.currentBid.compareTo(b.currentBid));
      case _AuctionSort.priceHigh:
        list.sort((a, b) => b.currentBid.compareTo(a.currentBid));
      case _AuctionSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endedAsync = ref.watch(endedAuctionsStreamProvider);
    final endedAuctions = _filtered(endedAsync.value ?? []);
    final filtered = _filtered(liveAuctions);
    final theme = Theme.of(context);

    if (liveAsync.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 700));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          if (liveAuctions.isEmpty)
            const SizedBox.shrink()
          else if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  'No auctions match your search.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...List.generate(filtered.length, (i) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 320 + (i * 60)),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 20),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: AuctionCard(
                    item: filtered[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuctionDetailScreen(item: filtered[i]),
                      ),
                    ),
                  ),
                ),
              );
            }),

          // ── Closed Bids ────────────────────────────────────────
          if (endedAuctions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_clock_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Closed Bids',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            ...endedAuctions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Stack(
                  children: [
                    Opacity(
                      opacity: 0.6,
                      child: AuctionCard(
                        item: item,
                        showLiveBadge: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuctionDetailScreen(item: item),
                          ),
                        ),
                      ),
                    ),
                    if (item.totalBids > 0)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.mintGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Winner Selected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Bids tab
// ─────────────────────────────────────────────────────────────────────────────

class _MyBidsTab extends ConsumerStatefulWidget {
  const _MyBidsTab();

  @override
  ConsumerState<_MyBidsTab> createState() => _MyBidsTabState();
}

class _MyBidsTabState extends ConsumerState<_MyBidsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final session = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (session == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gavel_rounded,
              size: 52,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 14),
            Text(
              'Sign in to see your bids',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black38,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    final bidsAsync = ref.watch(myPlacedBidsStreamProvider);

    return bidsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      ),
      error: (e, st) {
        // Surface the underlying error so missing indexes / permission denied
        // are diagnosable on-device instead of a generic message.
        debugPrint('myPlacedBidsStreamProvider error: $e');
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 52,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(height: 14),
                Text(
                  'Unable to load bids',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(myPlacedBidsStreamProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      data: (bids) {
        if (bids.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 52,
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                const SizedBox(height: 14),
                Text(
                  "You haven't placed any bids yet.",
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black38,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: bids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (ctx, i) => _MyBidCard(
            key: ValueKey(bids[i].id),
            bid: bids[i],
            session: session,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single My Bid card — loads the auction item live, shows status badge + CTA
// ─────────────────────────────────────────────────────────────────────────────

class _MyBidCard extends ConsumerStatefulWidget {
  final Bid bid;
  final AuthSession session;

  const _MyBidCard({super.key, required this.bid, required this.session});

  @override
  ConsumerState<_MyBidCard> createState() => _MyBidCardState();
}

class _MyBidCardState extends ConsumerState<_MyBidCard> {
  // ── Status logic ────────────────────────────────────────────────────────
  _BidStatus _statusFor(AuctionItem auction) {
    if (auction.hasEnded) {
      return widget.bid.isWinning ? _BidStatus.won : _BidStatus.ended;
    }
    final mins = auction.timeRemaining.inMinutes;
    if (mins < 30) return _BidStatus.endingSoon;
    if (widget.bid.isWinning) return _BidStatus.winning;
    return _BidStatus.outbid;
  }

  // ── Quick bid sheet ──────────────────────────────────────────────────────
  Future<void> _showQuickBidSheet(
    BuildContext context,
    AuctionItem auction,
  ) async {
    final numFmt = NumberFormat('#,##0', 'en_US');
    final suggested = (auction.currentBid + auction.minBidIncrement);
    final ctrl = TextEditingController(text: suggested.toStringAsFixed(0));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuickBidSheet(
        auction: auction,
        session: widget.session,
        ctrl: ctrl,
        numFmt: numFmt,
        repoProvider: auctionsRepositoryProvider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numFmt = NumberFormat('#,##0', 'en_US');

    final auctionAsync = ref.watch(
      auctionByIdStreamProvider(widget.bid.auctionItemId),
    );

    return auctionAsync.when(
      loading: () => _CardSkeleton(isDark: isDark, theme: theme),
      error: (_, __) => const SizedBox.shrink(),
      data: (auction) {
        final status = _statusFor(auction);

        return Pressable(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuctionDetailScreen(item: auction),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C0C14) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.35)
                      : Colors.black.withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image + status badge ─────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Auction image
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: auction.imageUrl.isNotEmpty
                            ? CachedImage(
                                url: auction.imageUrl,
                                fit: BoxFit.cover,
                                targetWidth: 900,
                                errorPlaceholder: _ImagePlaceholder(
                                  isDark: isDark,
                                ),
                              )
                            : _ImagePlaceholder(isDark: isDark),
                      ),
                      // Status badge (top-left) — frosted glass
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _StatusBadge(status: status),
                      ),
                    ],
                  ),
                ),

                // ── Card body ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        auction.title,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? const Color(0xFF2A2A3C)
                            : const Color(0xFFE5E7EB),
                      ),
                      const SizedBox(height: 12),

                      // Bid info row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Left: label + price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _bidLabel(status),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.5,
                                        ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'UGX ${numFmt.format(_bidAmount(status, auction))}',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),

                          // Right: CTA based on status
                          _BidCta(
                            status: status,
                            endTime: auction.endTime,
                            isDark: isDark,
                            theme: theme,
                            onRebid: () => _showQuickBidSheet(context, auction),
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
      },
    );
  }

  String _bidLabel(_BidStatus s) {
    return switch (s) {
      _BidStatus.winning => 'Your Bid',
      _BidStatus.won => 'Your Bid',
      _BidStatus.outbid => 'Highest Bid',
      _BidStatus.endingSoon => 'Current',
      _BidStatus.ended => 'Highest Bid',
    };
  }

  double _bidAmount(_BidStatus s, AuctionItem auction) {
    return switch (s) {
      _BidStatus.winning || _BidStatus.won => widget.bid.amount,
      _ => auction.currentBid,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bid status enum
// ─────────────────────────────────────────────────────────────────────────────

enum _BidStatus { winning, outbid, endingSoon, won, ended }

// ─────────────────────────────────────────────────────────────────────────────
// Status badge widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final _BidStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (_, icon, label) = switch (status) {
      _BidStatus.winning => (
        const Color(0xFF22C55E),
        Icons.check_circle_rounded,
        'Winning',
      ),
      _BidStatus.outbid => (
        const Color(0xFFEF4444),
        Icons.warning_amber_rounded,
        'Outbid',
      ),
      _BidStatus.endingSoon => (
        const Color(0xFF3B82F6),
        Icons.access_time_rounded,
        'Ending Soon',
      ),
      _BidStatus.won => (
        const Color(0xFF22C55E),
        Icons.emoji_events_rounded,
        'Won!',
      ),
      _BidStatus.ended => (
        const Color(0xFF6B7280),
        Icons.lock_rounded,
        'Ended',
      ),
    };
    // Badge always uses frosted glass style regardless of status color
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: const Color(0xFF444444)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
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
// Right-side CTA for the bid card
// ─────────────────────────────────────────────────────────────────────────────

class _BidCta extends StatelessWidget {
  final _BidStatus status;
  final DateTime endTime;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onRebid;

  const _BidCta({
    required this.status,
    required this.endTime,
    required this.isDark,
    required this.theme,
    required this.onRebid,
  });

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _BidStatus.winning => _CountdownChip(
        prefix: 'Ends in',
        endTime: endTime,
        isDark: isDark,
        theme: theme,
      ),
      _BidStatus.outbid => Pressable(
        onTap: onRebid,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Rebid',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
      _BidStatus.endingSoon => _EndingSoonLabel(
        endTime: endTime,
        isDark: isDark,
      ),
      _BidStatus.won => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '🎉 Winner',
          style: TextStyle(
            color: Color(0xFF22C55E),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      _BidStatus.ended => Text(
        'Ended',
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    };
  }
}

class _CountdownChip extends StatelessWidget {
  final String prefix;
  final DateTime endTime;
  final bool isDark;
  final ThemeData theme;

  const _CountdownChip({
    required this.prefix,
    required this.endTime,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          prefix,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white54
                : theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        CountdownTimer(
          endTime: endTime,
          compact: true,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EndingSoonLabel extends StatelessWidget {
  final DateTime endTime;
  final bool isDark;

  const _EndingSoonLabel({required this.endTime, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Only ',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        CountdownTimer(
          endTime: endTime,
          compact: true,
          textStyle: const TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const Text(
          ' left',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Bid Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _QuickBidSheet extends ConsumerStatefulWidget {
  final AuctionItem auction;
  final AuthSession session;
  final TextEditingController ctrl;
  final NumberFormat numFmt;
  final Provider<AuctionsRepository> repoProvider;

  const _QuickBidSheet({
    required this.auction,
    required this.session,
    required this.ctrl,
    required this.numFmt,
    required this.repoProvider,
  });

  @override
  ConsumerState<_QuickBidSheet> createState() => _QuickBidSheetState();
}

class _QuickBidSheetState extends ConsumerState<_QuickBidSheet> {
  bool _placing = false;

  void _nudge(double amount) {
    final current = double.tryParse(widget.ctrl.text) ?? 0;
    widget.ctrl.text = (current + amount).toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _place() async {
    final amount = double.tryParse(widget.ctrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _placing = true);
    try {
      await ref
          .read(widget.repoProvider)
          .placeBid(
            auctionId: widget.auction.id,
            userId: widget.session.user.uid,
            userName:
                widget.session.user.displayName ??
                widget.session.user.email ??
                'User',
            amount: amount,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppBanner(
        context,
        'Bid of UGX ${widget.numFmt.format(amount)} placed!',
        type: AppBannerType.success,
      );
    } catch (e) {
      if (!mounted) return;
      showAppBanner(context, e.toString(), type: AppBannerType.error);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auction = widget.auction;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12121A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Item preview row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: auction.imageUrl.isNotEmpty
                          ? CachedImage(
                              url: auction.imageUrl,
                              fit: BoxFit.cover,
                              targetWidth: 180,
                            )
                          : Container(
                              color: isDark
                                  ? const Color(0xFF1A1A2C)
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(
                                Icons.image_rounded,
                                color: Colors.white38,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auction.title,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Current: UGX ${widget.numFmt.format(auction.currentBid)}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bid amount input
              Text(
                'Your bid amount',
                style: TextStyle(
                  color: isDark
                      ? Colors.white70
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A2C)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'UGX',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.38,
                                      ),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: widget.ctrl,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _NudgeBtn(
                    label: '+1k',
                    onTap: () => _nudge(1000),
                    isDark: isDark,
                    theme: theme,
                  ),
                  const SizedBox(width: 6),
                  _NudgeBtn(
                    label: '+5k',
                    onTap: () => _nudge(5000),
                    isDark: isDark,
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Place bid button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Pressable(
                  onTap: _placing ? null : _place,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _luminaGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _placing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Place Bid',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.local_offer_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
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

class _NudgeBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final ThemeData theme;

  const _NudgeBtn({
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1A1A2C)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB04CF5),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  final bool isDark;
  const _ImagePlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF16161F) : const Color(0xFFEEF2FF),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 40,
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  const _CardSkeleton({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark ? const Color(0xFF1A1A2C) : const Color(0xFFEEF2FF);
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
