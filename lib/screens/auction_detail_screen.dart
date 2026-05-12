import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_repository.dart';
import '../features/submission/category_schemas.dart';
import '../models/auction_item.dart';
import '../models/bid.dart';
import '../services/auctions_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/bid_bottom_sheet.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/pressable.dart';

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
  bool _placingBid = false;

  Stream<List<Bid>> _bidHistoryStream(String id) {
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
            final byAmount = b.amount.compareTo(a.amount);
            if (byAmount != 0) return byAmount;
            return b.timestamp.compareTo(a.timestamp);
          });

          // Keep only each user's highest bid so a bidder appears once.
          final seen = <String>{};
          final deduped = <Bid>[];
          for (final bid in bids) {
            if (seen.add(bid.userId)) deduped.add(bid);
          }
          return deduped;
        });
  }

  Future<void> _placeBid(AuctionItem item, double amount) async {
    final session = ref.read(authStateProvider).value;
    if (session == null) {
      _toast('Sign in to place a bid.');
      return;
    }

    setState(() => _placingBid = true);
    try {
      await ref
          .read(auctionsRepositoryProvider)
          .placeBid(
            auctionId: item.id,
            userId: session.user.uid,
            userName:
                session.user.displayName ?? session.user.email ?? 'Bidder',
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

  void _showBidSheet(AuctionItem item) async {
    HapticFeedback.lightImpact();
    final session = ref.read(authStateProvider).value;

    // Find the user's previous highest bid so the deposit sheet can
    // show only the incremental top-up instead of the full deposit.
    double previousBidAmount = 0;
    if (session != null) {
      try {
        final snap = await ref
            .read(firestoreProvider)
            .collection('auctions')
            .doc(item.id)
            .collection('bids')
            .where('userId', isEqualTo: session.user.uid)
            .orderBy('amount', descending: true)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          previousBidAmount =
              (snap.docs.first.data()['amount'] as num?)?.toDouble() ?? 0;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => BidBottomSheet(
        item: item,
        isSignedIn: session != null,
        previousBidAmount: previousBidAmount,
        onPlaceBid: (amount) => _placeBid(item, amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Stream live updates of this auction. Falls back to the passed-in item
    // until the first snapshot arrives.
    final stream = ref.read(auctionsRepositoryProvider).watch(widget.item.id);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: StreamBuilder<AuctionItem>(
        stream: stream,
        initialData: widget.item,
        builder: (context, snap) {
          final item = snap.data ?? widget.item;
          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 360,
                    pinned: true,
                    stretch: true,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [
                        StretchMode.zoomBackground,
                        StretchMode.blurBackground,
                      ],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: widget.heroTag ?? 'auction_image_${item.id}',
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                ),
                                child: const Icon(
                                  Icons.image_rounded,
                                  size: 64,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.35),
                                  Colors.transparent,
                                  theme.scaffoldBackgroundColor,
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                          if (item.isLive)
                            Positioned(
                              top: MediaQuery.of(context).padding.top + 70,
                              left: 20,
                              child: _LivePill(),
                            ),
                        ],
                      ),
                    ),
                    leading: _GlassButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    actions: [
                      _GlassButton(
                        icon: _isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorite ? AppTheme.accent : null,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isFavorite = !_isFavorite);
                        },
                      ),
                      _GlassButton(icon: Icons.ios_share_rounded, onTap: () {}),
                      const SizedBox(width: 12),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (item.isVerified)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            item.title,
                            style: theme.textTheme.displayMedium,
                          ),
                          if (item.location != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.place_rounded,
                                  size: 16,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.location!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 22),
                          _BidStrip(item: item),
                          const SizedBox(height: 24),
                          _SectionTitle(text: 'About this lot'),
                          const SizedBox(height: 10),
                          Text(
                            item.description,
                            style: theme.textTheme.bodyLarge,
                          ),
                          if (item.categoryData.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _SpecsCard(
                              category: item.category,
                              data: item.categoryData,
                            ),
                          ],
                          const SizedBox(height: 24),
                          _SectionTitle(
                            text: 'Bid history',
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${item.totalBids}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<List<Bid>>(
                            stream: _bidHistoryStream(item.id),
                            builder: (context, bidsSnap) {
                              final bids = bidsSnap.data ?? const <Bid>[];
                              if (bids.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 24,
                                  ),
                                  child: Text(
                                    'No bids yet — be the first!',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                );
                              }
                              final winner = bids.first;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.hasEnded)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.mintGradient,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Winner',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${winner.userName} · ${winner.formattedAmount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  for (final bid in bids)
                                    _BidHistoryItem(
                                      bid: bid,
                                      forceWinning: bid.id == winner.id,
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 140),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.scaffoldBackgroundColor.withOpacity(0),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: item.hasEnded
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_clock_rounded,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.45),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Auction Ended · ${item.formattedCurrentBid}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.45),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Pressable(
                            onTap: _placingBid
                                ? null
                                : () => _showBidSheet(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _placingBid
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.gavel_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Place bid · ${item.formattedCurrentBid}+',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.coral,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.coral.withOpacity(0.5),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _GlassButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(icon, color: color ?? Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  final String category;
  final Map<String, dynamic> data;

  const _SpecsCard({required this.category, required this.data});

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) {
      // Format numbers with commas if large (e.g. mileage)
      if (value >= 1000) {
        return value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
      }
      return value.toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = categorySchemas[category];

    // Build ordered list of (FieldDef?, key, value) for non-empty fields
    final entries = <({FieldDef? def, String key, String value})>[];
    if (schema != null) {
      for (final field in schema.fields) {
        final raw = data[field.key];
        if (raw == null || raw.toString().isEmpty) continue;
        // Skip multiline text fields (serviceHistory, provenance) — they
        // belong in the description section.
        if (field.type == FieldType.multiline) continue;
        entries.add((def: field, key: field.label, value: _formatValue(raw)));
      }
    } else {
      // Unknown category — show all keys generically
      for (final e in data.entries) {
        final raw = e.value;
        if (raw == null || raw.toString().isEmpty) continue;
        entries.add((def: null, key: e.key, value: _formatValue(raw)));
      }
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    final title = schema != null
        ? '${schema.name} Specifications'
        : 'Specifications';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(text: title),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 52,
                    color: theme.colorScheme.outline.withOpacity(0.5),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          entries[i].def?.icon ?? Icons.info_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entries[i].key,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                      Text(
                        entries[i].value,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BidStrip extends StatelessWidget {
  final AuctionItem item;
  const _BidStrip({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current bid',
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppTheme.primaryGradient.createShader(b),
                  child: Text(
                    item.formattedCurrentBid,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.totalBids} bids',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 84, color: theme.colorScheme.outline),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ends in',
                    style: theme.textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CountdownTimer(
                    endTime: item.endTime,
                    textStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Local time', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _SectionTitle({required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(text, style: theme.textTheme.headlineMedium),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class _BidHistoryItem extends StatelessWidget {
  final Bid bid;
  final bool forceWinning;
  const _BidHistoryItem({required this.bid, this.forceWinning = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use only forceWinning (= this is bids.first by amount).
    // bid.isWinning from Firestore is stale once outbid, so we ignore it.
    final isWinning = forceWinning;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinning
            ? AppTheme.primary.withOpacity(0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: isWinning
            ? Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                bid.userName.isEmpty ? '?' : bid.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isWinning) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.mintGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'WINNING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(bid.timeAgo, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            bid.formattedAmount,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
