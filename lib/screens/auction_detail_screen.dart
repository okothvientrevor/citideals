import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../features/auth/auth_repository.dart';
import '../features/submission/category_schemas.dart';
import '../models/auction_item.dart';
import '../models/bid.dart';
import '../services/auctions_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/deposit_bottom_sheet.dart';
import '../widgets/pressable.dart';

// ─── Purple gradient — ENDS IN card + Place Bid button ───────────────────────
const _luminaGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF8B5CF6), Color(0xFFB04CF5)],
);

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AuctionDetailScreen extends ConsumerStatefulWidget {
  final AuctionItem item;
  final String? heroTag;
  const AuctionDetailScreen({super.key, required this.item, this.heroTag});

  @override
  ConsumerState<AuctionDetailScreen> createState() =>
      _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  bool _isFavorite = false;
  bool _isAnonymous = false;
  bool _placingBid = false;
  int _selectedTab = 0;
  int _imgIndex = 0;
  late final PageController _pageCtrl;
  late final TextEditingController _bidCtrl;
  final _fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    final minBid = widget.item.currentBid + widget.item.minBidIncrement;
    _bidCtrl = TextEditingController(text: _fmt.format(minBid.round()));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bidCtrl.dispose();
    super.dispose();
  }

  // ── Bid stream ──────────────────────────────────────────────────────────
  Stream<List<Bid>> _bidStream(String id) {
    return ref
        .read(firestoreProvider)
        .collection('auctions')
        .doc(id)
        .collection('bids')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((s) {
          final bids = s.docs.map((d) {
            final data = d.data();
            final ts = data['timestamp'];
            return Bid(
              id: d.id,
              auctionItemId: id,
              userId: (data['userId'] as String?) ?? '',
              userName: (data['userName'] as String?) ?? 'Bidder',
              amount: (data['amount'] as num?)?.toDouble() ?? 0,
              timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
              isWinning: (data['isWinning'] as bool?) ?? false,
            );
          }).toList();
          bids.sort((a, b) {
            final d = b.amount.compareTo(a.amount);
            return d != 0 ? d : b.timestamp.compareTo(a.timestamp);
          });
          final seen = <String>{};
          final out = <Bid>[];
          for (final b in bids) {
            if (seen.add(b.userId)) out.add(b);
          }
          return out;
        });
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  String _resolveUserName(AuthSession session) {
    if (_isAnonymous) return 'Anonymous';
    final dn = session.user.displayName;
    if (dn != null && dn.trim().isNotEmpty) {
      return dn.trim().split(' ').first;
    }
    final email = session.user.email ?? '';
    final prefix = email.split('@').first;
    return prefix.isEmpty
        ? 'Bidder'
        : prefix[0].toUpperCase() + prefix.substring(1);
  }

  double _parseBid() => double.tryParse(_bidCtrl.text.replaceAll(',', '')) ?? 0;

  void _nudgeBid(double delta) {
    final next = _parseBid() + delta;
    setState(() => _bidCtrl.text = _fmt.format(next.round()));
    HapticFeedback.selectionClick();
  }

  Future<void> _placeBid(
    AuctionItem item, [
    double previousBidAmount = 0,
  ]) async {
    final session = ref.read(authStateProvider).value;
    if (session == null) {
      _toast('Sign in to place a bid.');
      return;
    }
    final amount = _parseBid();
    final minBid = item.currentBid + item.minBidIncrement;
    if (amount < minBid) {
      _toast('Minimum bid is UGX ${_fmt.format(minBid.round())}');
      return;
    }
    // Validate OK — show deposit sheet; actual bid fires on user confirmation
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => DepositBottomSheet(
        bidAmount: amount,
        previousBidAmount: previousBidAmount,
        isSignedIn: true,
        onConfirm: () => _executeBid(item, session, amount),
      ),
    );
  }

  Future<void> _executeBid(
    AuctionItem item,
    AuthSession session,
    double amount,
  ) async {
    setState(() => _placingBid = true);
    try {
      await ref
          .read(auctionsRepositoryProvider)
          .placeBid(
            auctionId: item.id,
            userId: session.user.uid,
            userName: _resolveUserName(session),
            amount: amount,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.mint,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: const Duration(seconds: 2),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Bid placed!',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } on FirebaseException catch (e) {
      _toast('[${e.code}] ${e.message ?? 'Bid rejected'}');
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _placingBid = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.coral,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showAllBids(AuctionItem item, List<Bid> bids) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _AllBidsSheet(bids: bids, hasEnded: item.hasEnded),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final stream = ref.read(auctionsRepositoryProvider).watch(widget.item.id);
    return StreamBuilder<AuctionItem>(
      stream: stream,
      initialData: widget.item,
      builder: (context, snap) {
        final item = snap.data ?? widget.item;
        return StreamBuilder<List<Bid>>(
          stream: _bidStream(item.id),
          builder: (context, bidsSnap) {
            final bids = bidsSnap.data ?? const <Bid>[];
            final currentUserId = ref.read(authStateProvider).value?.user.uid;
            final prevBid = currentUserId == null
                ? 0.0
                : bids
                      .where((b) => b.userId == currentUserId)
                      .fold(0.0, (mx, b) => b.amount > mx ? b.amount : mx);
            final images = item.imageUrls.isNotEmpty
                ? item.imageUrls
                : [item.imageUrl];
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final theme = Theme.of(context);

            return Scaffold(
              backgroundColor: isDark
                  ? const Color(0xFF0E0E14)
                  : theme.colorScheme.surface,
              extendBody: true,
              body: Stack(
                children: [
                  // ── Scrollable content ────────────────────────────────
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image carousel
                        _ImageCarousel(
                          images: images,
                          imgIndex: _imgIndex,
                          heroTag: widget.heroTag ?? 'auction_image_${item.id}',
                          pageCtrl: _pageCtrl,
                          onPageChanged: (i) => setState(() => _imgIndex = i),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + heart
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Pressable(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      setState(
                                        () => _isFavorite = !_isFavorite,
                                      );
                                    },
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: _isFavorite
                                            ? AppTheme.coral.withOpacity(0.15)
                                            : isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        _isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: _isFavorite
                                            ? AppTheme.coral
                                            : isDark
                                            ? Colors.white54
                                            : theme.colorScheme.onSurface
                                                  .withOpacity(0.4),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Seller
                              Row(
                                children: [
                                  Text(
                                    'by ${item.sellerName ?? 'CitiDeals'}',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : theme.colorScheme.onSurface
                                                .withOpacity(0.5),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (item.isVerified) ...[
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 15,
                                      color: AppTheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Stat cards
                              _StatCards(item: item),
                              const SizedBox(height: 26),

                              // Recent bids
                              _RecentBidsSection(
                                bids: bids,
                                item: item,
                                onViewAll: () => _showAllBids(item, bids),
                                fmt: _fmt,
                              ),
                              const SizedBox(height: 26),

                              // Tabs
                              _TabSelector(
                                selected: _selectedTab,
                                onChanged: (t) =>
                                    setState(() => _selectedTab = t),
                              ),
                              const SizedBox(height: 18),

                              // Tab content
                              _TabBody(selectedTab: _selectedTab, item: item),

                              const SizedBox(height: 160),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Floating top bar ──────────────────────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _GlassButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            if (item.isLive) const _PulsingLiveBadge(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bottom bid bar ──────────────────────────────────────
              bottomNavigationBar: item.hasEnded
                  ? _EndedBar(item: item)
                  : _BidBar(
                      item: item,
                      ctrl: _bidCtrl,
                      fmt: _fmt,
                      placingBid: _placingBid,
                      isAnonymous: _isAnonymous,
                      onNudge: _nudgeBid,
                      onPlaceBid: () => _placeBid(item, prevBid),
                      onToggleAnonymous: (v) =>
                          setState(() => _isAnonymous = v),
                    ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image carousel
// ─────────────────────────────────────────────────────────────────────────────

class _ImageCarousel extends StatelessWidget {
  final List<String> images;
  final int imgIndex;
  final String heroTag;
  final PageController pageCtrl;
  final ValueChanged<int> onPageChanged;

  const _ImageCarousel({
    required this.images,
    required this.imgIndex,
    required this.heroTag,
    required this.pageCtrl,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SizedBox(
            height: 320,
            child: images.length == 1
                ? Hero(
                    tag: heroTag,
                    child: Image.network(
                      images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  )
                : PageView.builder(
                    controller: pageCtrl,
                    onPageChanged: onPageChanged,
                    itemCount: images.length,
                    itemBuilder: (ctx, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
                  ),
          ),
        ),
        // Bottom gradient fade
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 100,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xF00E0E14)],
                ),
              ),
            ),
          ),
        ),
        // Index badge
        if (images.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${imgIndex + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        // Dot indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == imgIndex ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == imgIndex ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF1A1A2C),
    child: const Icon(Icons.image_rounded, size: 64, color: Colors.white24),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat cards — CURRENT BID | ENDS IN
// ─────────────────────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  final AuctionItem item;
  const _StatCards({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final cardBg = isDark
        ? const Color(0xFF1A1A2C)
        : theme.colorScheme.surfaceContainerHighest;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT BID',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white38
                        : theme.colorScheme.onSurface.withOpacity(0.38),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.formattedCurrentBid,
                  style: TextStyle(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.totalBids} bids',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white38
                        : theme.colorScheme.onSurface.withOpacity(0.38),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: item.hasEnded ? null : _luminaGradient,
              color: item.hasEnded ? cardBg : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: item.hasEnded
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENDS IN',
                  style: TextStyle(
                    color: Colors.white.withOpacity(
                      item.hasEnded ? 0.38 : 0.75,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                item.hasEnded
                    ? Text(
                        'Ended',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : theme.colorScheme.onSurface.withOpacity(0.38),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : CountdownTimer(
                        endTime: item.endTime,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  item.hasEnded ? 'Auction closed' : 'Remaining',
                  style: TextStyle(
                    color: Colors.white.withOpacity(
                      item.hasEnded ? 0.28 : 0.65,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent bids
// ─────────────────────────────────────────────────────────────────────────────

class _RecentBidsSection extends StatelessWidget {
  final List<Bid> bids;
  final AuctionItem item;
  final VoidCallback onViewAll;
  final NumberFormat fmt;

  const _RecentBidsSection({
    required this.bids,
    required this.item,
    required this.onViewAll,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final preview = bids.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Bids',
              style: TextStyle(
                color: isDark ? Colors.white : theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (bids.isNotEmpty)
              Pressable(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'No bids yet — be the first!',
              style: TextStyle(
                color: isDark
                    ? Colors.white38
                    : theme.colorScheme.onSurface.withOpacity(0.38),
                fontSize: 14,
              ),
            ),
          )
        else
          ...preview.asMap().entries.map(
            (e) => _BidRow(bid: e.value, isFirst: e.key == 0, fmt: fmt),
          ),
      ],
    );
  }
}

class _BidRow extends StatelessWidget {
  final Bid bid;
  final bool isFirst;
  final NumberFormat fmt;

  const _BidRow({required this.bid, required this.isFirst, required this.fmt});

  String get _initials {
    final parts = bid.userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final n = bid.userName;
    return n.isNotEmpty
        ? n.substring(0, n.length.clamp(0, 2)).toUpperCase()
        : '??';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isFirst ? _luminaGradient : null,
              color: isFirst
                  ? null
                  : isDark
                  ? const Color(0xFF1E2A4A)
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                _initials,
                style: TextStyle(
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        bid.userName,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isFirst) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: _luminaGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LEADING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  bid.timeAgo,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white38
                        : theme.colorScheme.onSurface.withOpacity(0.38),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'UGX ${fmt.format(bid.amount)}',
            style: TextStyle(
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab selector + content
// ─────────────────────────────────────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TabSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    const tabs = ['Description', 'Specifications', 'Shipping'];
    return Row(
      children: tabs.asMap().entries.map((e) {
        final active = e.key == selected;
        return Pressable(
          onTap: () => onChanged(e.key),
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.value,
                  style: TextStyle(
                    color: active
                        ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                        : (isDark
                              ? Colors.white38
                              : theme.colorScheme.onSurface.withOpacity(0.38)),
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: active ? 20.0 : 0.0,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TabBody extends StatelessWidget {
  final int selectedTab;
  final AuctionItem item;

  const _TabBody({required this.selectedTab, required this.item});

  @override
  Widget build(BuildContext context) {
    return switch (selectedTab) {
      0 => _DescriptionTab(item: item),
      1 => _SpecificationsTab(item: item),
      _ => const _ShippingTab(),
    };
  }
}

class _DescriptionTab extends StatelessWidget {
  final AuctionItem item;
  const _DescriptionTab({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Text(
      item.description.isNotEmpty
          ? item.description
          : 'No description provided.',
      style: TextStyle(
        color: isDark
            ? Colors.white60
            : theme.colorScheme.onSurface.withOpacity(0.6),
        fontSize: 14,
        height: 1.65,
      ),
    );
  }
}

class _SpecificationsTab extends StatelessWidget {
  final AuctionItem item;
  const _SpecificationsTab({required this.item});

  String _fmtVal(dynamic v) {
    if (v == null) return '';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is num && v >= 1000) {
      return v.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final schema = categorySchemas[item.category];
    final entries = <({String key, String value, IconData? icon})>[];

    if (schema != null) {
      for (final field in schema.fields) {
        final raw = item.categoryData[field.key];
        if (raw == null || raw.toString().isEmpty) continue;
        if (field.type == FieldType.multiline) continue;
        entries.add((key: field.label, value: _fmtVal(raw), icon: field.icon));
      }
    } else {
      for (final e in item.categoryData.entries) {
        if (e.value == null || e.value.toString().isEmpty) continue;
        entries.add((
          key: e.key,
          value: _fmtVal(e.value),
          icon: Icons.info_outline_rounded,
        ));
      }
    }

    if (entries.isEmpty) {
      return Text(
        'No specifications available.',
        style: TextStyle(
          color: isDark
              ? Colors.white38
              : theme.colorScheme.onSurface.withOpacity(0.38),
          fontSize: 14,
        ),
      );
    }

    return Column(
      children: entries.asMap().entries.map((e) {
        final spec = e.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF16161F)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                spec.icon ?? Icons.info_outline_rounded,
                size: 18,
                color: isDark
                    ? Colors.white38
                    : theme.colorScheme.onSurface.withOpacity(0.38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  spec.key,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white54
                        : theme.colorScheme.onSurface.withOpacity(0.55),
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                spec.value,
                style: TextStyle(
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShippingTab extends StatelessWidget {
  const _ShippingTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    const items = [
      (
        Icons.local_shipping_outlined,
        'Delivery',
        'Nationwide delivery available',
      ),
      (Icons.inventory_2_outlined, 'Packaging', 'Secure double-box packaging'),
      (
        Icons.verified_user_outlined,
        'Authenticity',
        'Certificate of authenticity included',
      ),
      (Icons.replay_rounded, 'Returns', '7-day return policy on all lots'),
    ];
    return Column(
      children: items.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s.$1, size: 18, color: AppTheme.primaryLight),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.$2,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    s.$3,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white38
                          : theme.colorScheme.onSurface.withOpacity(0.38),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bid bar
// ─────────────────────────────────────────────────────────────────────────────

class _BidBar extends StatelessWidget {
  final AuctionItem item;
  final TextEditingController ctrl;
  final NumberFormat fmt;
  final bool placingBid;
  final bool isAnonymous;
  final ValueChanged<double> onNudge;
  final VoidCallback onPlaceBid;
  final ValueChanged<bool> onToggleAnonymous;

  const _BidBar({
    required this.item,
    required this.ctrl,
    required this.fmt,
    required this.placingBid,
    required this.isAnonymous,
    required this.onNudge,
    required this.onPlaceBid,
    required this.onToggleAnonymous,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E0E14) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E1E2C)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input + chip row
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A2C)
                          : const Color(0xFFF5F5FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.07)
                            : const Color(0xFF8B5CF6).withOpacity(0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(left: 14, right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.07)
                                : const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'UGX',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF7C3AED),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
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
                _NudgeBtn(label: '+1k', onTap: () => onNudge(1000)),
                const SizedBox(width: 6),
                _NudgeBtn(label: '+5k', onTap: () => onNudge(5000)),
              ],
            ),
            const SizedBox(height: 10),
            // Anonymous toggle
            Row(
              children: [
                const SizedBox(width: 2),
                Icon(
                  Icons.visibility_off_outlined,
                  size: 15,
                  color: isDark
                      ? Colors.white38
                      : theme.colorScheme.onSurface.withOpacity(0.35),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bid anonymously',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white54
                          : theme.colorScheme.onSurface.withOpacity(0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.78,
                  child: Switch(
                    value: isAnonymous,
                    onChanged: onToggleAnonymous,
                    activeColor: const Color(0xFF8B5CF6),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Place bid button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Pressable(
                onTap: placingBid ? null : onPlaceBid,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF8B5CF6,
                        ).withOpacity(placingBid ? 0.15 : 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: placingBid
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
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 10),
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
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _NudgeBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NudgeBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2C) : const Color(0xFFF0EBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.35 : 0.25),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _EndedBar extends StatelessWidget {
  final AuctionItem item;
  const _EndedBar({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return Container(
      color: isDark ? const Color(0xFF0E0E14) : theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1A2C)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  color: isDark
                      ? Colors.white38
                      : theme.colorScheme.onSurface.withOpacity(0.38),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Auction Ended · ${item.formattedCurrentBid}',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white38
                        : theme.colorScheme.onSurface.withOpacity(0.38),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All Bids bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AllBidsSheet extends StatelessWidget {
  final List<Bid> bids;
  final bool hasEnded;

  const _AllBidsSheet({required this.bids, required this.hasEnded});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final fmt = NumberFormat('#,##0', 'en_US');
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12121A) : theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white24
                      : theme.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Bids',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${bids.length}',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF1E1E2C)
                  : theme.colorScheme.outline.withOpacity(0.15),
            ),
            // Winner banner
            if (hasEnded && bids.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: _luminaGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Winner',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${bids.first.userName} · UGX ${fmt.format(bids.first.amount)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            // List
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: bids.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFF1E1E2C)),
                itemBuilder: (ctx, i) {
                  final bid = bids[i];
                  final isLeading = i == 0 && !hasEnded;
                  final name = bid.userName.trim();
                  final parts = name.split(' ');
                  final initials = parts.length >= 2
                      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                      : name.isNotEmpty
                      ? name.substring(0, name.length.clamp(0, 2)).toUpperCase()
                      : '??';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isLeading ? _luminaGradient : null,
                            color: isLeading
                                ? null
                                : isDark
                                ? const Color(0xFF1E2A4A)
                                : theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    bid.userName,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isLeading) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _luminaGradient,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'LEADING',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                bid.timeAgo,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.38,
                                        ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'UGX ${fmt.format(bid.amount)}',
                          style: TextStyle(
                            color: isLeading
                                ? const Color(0xFFB04CF5)
                                : isDark
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing LIVE badge
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingLiveBadge extends StatefulWidget {
  const _PulsingLiveBadge();

  @override
  State<_PulsingLiveBadge> createState() => _PulsingLiveBadgeState();
}

class _PulsingLiveBadgeState extends State<_PulsingLiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFFB91C1C),
            const Color(0xFFEF4444),
            _anim.value,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.55 * _anim.value),
              blurRadius: 12 * _anim.value,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fiber_manual_record_rounded,
              size: 8,
              color: Colors.white,
            ),
            SizedBox(width: 5),
            Text(
              'LIVE',
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
    );
  }
}
