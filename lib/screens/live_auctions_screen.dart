import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auction_item.dart';
import '../services/auctions_repository.dart';
import '../widgets/auction_card.dart';
import '../theme/app_theme.dart';
import 'auction_detail_screen.dart';

class LiveAuctionsScreen extends ConsumerStatefulWidget {
  const LiveAuctionsScreen({super.key});

  @override
  ConsumerState<LiveAuctionsScreen> createState() => _LiveAuctionsScreenState();
}

class _LiveAuctionsScreenState extends ConsumerState<LiveAuctionsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final liveAsync = ref.watch(liveAuctionsStreamProvider);
    final endedAsync = ref.watch(endedAuctionsStreamProvider);
    final liveAuctions = liveAsync.value ?? const <AuctionItem>[];
    final endedAuctions = endedAsync.value ?? const <AuctionItem>[];

    // Total unique bidders = sum of totalBids across live items
    final totalBidders = liveAuctions.fold(0, (sum, a) => sum + a.totalBids);

    return Scaffold(
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
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
                              color: AppTheme.coral,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.coral.withOpacity(0.4),
                                  blurRadius: 12,
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bidding wars 🔥',
                              style: theme.textTheme.displayMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StatsRow(
                        activeBidders: totalBidders,
                        items: liveAuctions.length,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: liveAuctions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 350 + (index * 70)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 24),
                        child: child,
                      ),
                    ),
                    child: AuctionCard(
                      item: liveAuctions[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AuctionDetailScreen(item: liveAuctions[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            // ── Closed Bids section ────────────────────────────────
            if (endedAuctions.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
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
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: endedAuctions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = endedAuctions[index];
                    return Stack(
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
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.mint.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
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
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int activeBidders;
  final int items;
  const _StatsRow({required this.activeBidders, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            icon: Icons.people_alt_rounded,
            label: '$activeBidders bidders',
            gradient: AppTheme.primaryGradient,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            icon: Icons.gavel_rounded,
            label: '$items live items',
            gradient: AppTheme.mintGradient,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
