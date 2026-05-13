import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme_controller.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_repository.dart';
import '../features/submission/my_submissions_screen.dart';
import '../models/auction_item.dart';
import '../models/raffle.dart';
import '../services/auctions_repository.dart';
import '../services/raffles_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';
import 'auction_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile / Settings Screen
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ProfileHero(
              name: session?.user.displayName ?? 'Guest',
              photoUrl: session?.user.photoURL,
              isAdmin: session?.isAdmin ?? false,
            ),
          ),

          // ── Stats ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _StatsRow(uid: session?.user.uid ?? ''),
            ),
          ),

          // ── Active Bids ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Active Bids',
              actionLabel: 'VIEW ALL',
              onAction: () {},
            ),
          ),
          SliverToBoxAdapter(child: const _ActiveBidsList()),

          // ── My Raffles ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'My Raffles',
              actionLabel: null,
              onAction: null,
            ),
          ),
          SliverToBoxAdapter(
            child: _MyRafflesList(uid: session?.user.uid ?? ''),
          ),

          // ── Settings menu ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _SettingsGroup(
                items: [
                  _SettingsEntry(
                    icon: Icons.credit_card_rounded,
                    title: 'Payment Methods',
                    onTap: () {},
                  ),
                  _SettingsEntry(
                    icon: Icons.settings_rounded,
                    title: 'Account Settings',
                    onTap: () {},
                  ),
                  _SettingsEntry(
                    icon: Icons.brightness_6_rounded,
                    title: 'Appearance',
                    trailing: _ThemeBadge(),
                    onTap: () => _showThemeSheet(context, ref),
                  ),
                  _SettingsEntry(
                    icon: Icons.inventory_2_outlined,
                    title: 'My Submissions',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MySubmissionsScreen(),
                      ),
                    ),
                  ),
                  _SettingsEntry(
                    icon: Icons.help_outline_rounded,
                    title: 'Support & Help',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          // ── Log out ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _LogOutRow(
                onTap: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ),
          ),

          // ── Recent Win banner ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: const _RecentWinBanner(),
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isAdmin;

  const _ProfileHero({
    required this.name,
    required this.photoUrl,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3),
                  width: 3,
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
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Name + role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.displaySmall?.copyWith(fontSize: 22),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: isAdmin
                          ? AppTheme.amberGradient
                          : AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN' : 'PREMIUM MEMBER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Edit button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit_rounded,
                size: 18,
                color: isDark ? Colors.white60 : AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  final String uid;
  const _StatsRow({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    final bidsAsync = ref.watch(myPlacedBidsStreamProvider);
    final ticketsAsync = ref.watch(myRaffleTicketsStreamProvider(uid));

    final totalBids = bidsAsync.maybeWhen(
      data: (b) => b.length,
      orElse: () => null,
    );
    final totalWins = bidsAsync.maybeWhen(
      data: (b) => b.where((bid) => bid.isWinning).length,
      orElse: () => null,
    );
    final tickets = ticketsAsync.maybeWhen(
      data: (t) => t.length,
      orElse: () => null,
    );

    return Row(
      children: [
        Expanded(
          child: _StatBox(
            value: totalBids != null ? '$totalBids' : '—',
            label: 'TOTAL BIDS',
            valueColor: theme.colorScheme.onSurface,
            bg: cardBg,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: totalWins != null ? '$totalWins' : '—',
            label: 'TOTAL WINS',
            valueGradient: AppTheme.primaryGradient,
            bg: cardBg,
            highlighted: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatBox(
            value: tickets != null ? '$tickets' : '—',
            label: 'TICKETS',
            valueColor: AppTheme.amber,
            bg: cardBg,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  final Gradient? valueGradient;
  final Color bg;
  final bool highlighted;

  const _StatBox({
    required this.value,
    required this.label,
    required this.bg,
    this.valueColor,
    this.valueGradient,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget valueText = Text(
      value,
      style: TextStyle(
        fontSize: highlighted ? 28 : 24,
        fontWeight: FontWeight.w900,
        color: valueGradient == null ? valueColor : null,
        letterSpacing: -0.5,
      ),
    );

    if (valueGradient != null) {
      valueText = ShaderMask(
        shaderCallback: (b) => valueGradient!.createShader(b),
        child: Text(
          value,
          style: TextStyle(
            fontSize: highlighted ? 28 : 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? Border.all(
                color: AppTheme.primary.withOpacity(isDark ? 0.3 : 0.2),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppTheme.primary.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valueText,
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active Bids — real list
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBidsList extends ConsumerWidget {
  const _ActiveBidsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bidsAsync = ref.watch(myPlacedBidsStreamProvider);
    return bidsAsync.when(
      loading: () => const _SectionSkeleton(),
      error: (_, __) => const _ActiveBidsEmpty(),
      data: (bids) {
        if (bids.isEmpty) return const _ActiveBidsEmpty();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (int i = 0; i < bids.length; i++) ...[
                _ProfileBidTile(bid: bids[i]),
                if (i < bids.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ActiveBidsEmpty extends StatelessWidget {
  const _ActiveBidsEmpty();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'No active bids yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact bid tile — loads auction data via stream provider
class _ProfileBidTile extends ConsumerWidget {
  final dynamic bid; // Bid model
  const _ProfileBidTile({required this.bid});

  _ProfileBidStatus _statusFor(AuctionItem auction) {
    if (auction.hasEnded) return _ProfileBidStatus.ended;
    final mins = auction.timeRemaining.inMinutes;
    if (mins < 30) return _ProfileBidStatus.endingSoon;
    if (bid.isWinning == true) return _ProfileBidStatus.leading;
    return _ProfileBidStatus.outbid;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numFmt = NumberFormat('#,##0', 'en_US');
    final auctionAsync = ref.watch(
      auctionByIdStreamProvider(bid.auctionItemId),
    );

    return auctionAsync.when(
      loading: () => _BidTileSkeleton(isDark: isDark),
      error: (_, __) => const SizedBox.shrink(),
      data: (auction) {
        final status = _statusFor(auction);
        if (status == _ProfileBidStatus.ended) return const SizedBox.shrink();

        final (tagLabel, tagColor) = switch (status) {
          _ProfileBidStatus.leading => ('LEADING', const Color(0xFF22C55E)),
          _ProfileBidStatus.outbid => ('OUTBID', const Color(0xFFEF4444)),
          _ProfileBidStatus.endingSoon => (
            'ENDING SOON',
            const Color(0xFF3B82F6),
          ),
          _ProfileBidStatus.ended => ('ENDED', Colors.grey),
        };

        return Pressable(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuctionDetailScreen(item: auction),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.25)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: auction.imageUrl.isNotEmpty
                        ? Image.network(
                            auction.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ThumbPlaceholder(isDark: isDark),
                          )
                        : _ThumbPlaceholder(isDark: isDark),
                  ),
                ),
                const SizedBox(width: 12),
                // Title + bid amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'UGX ${numFmt.format(bid.amount)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Status tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tagLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: tagColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _ProfileBidStatus { leading, outbid, endingSoon, ended }

class _ThumbPlaceholder extends StatelessWidget {
  final bool isDark;
  const _ThumbPlaceholder({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF1A1A2C) : const Color(0xFFF0F0F5),
      child: Icon(
        Icons.image_rounded,
        color: isDark ? Colors.white24 : Colors.black12,
        size: 22,
      ),
    );
  }
}

class _BidTileSkeleton extends StatelessWidget {
  final bool isDark;
  const _BidTileSkeleton({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Raffles — real list
// ─────────────────────────────────────────────────────────────────────────────

class _MyRafflesList extends ConsumerWidget {
  final String uid;
  const _MyRafflesList({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (uid.isEmpty) return const _MyRafflesEmpty();
    final ticketsAsync = ref.watch(myRaffleTicketsStreamProvider(uid));
    return ticketsAsync.when(
      loading: () => const _SectionSkeleton(),
      error: (_, __) => const _MyRafflesEmpty(),
      data: (tickets) {
        if (tickets.isEmpty) return const _MyRafflesEmpty();
        // Group tickets by raffleId
        final grouped = <String, int>{};
        for (final t in tickets) {
          grouped[t.raffleId] = (grouped[t.raffleId] ?? 0) + 1;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (int i = 0; i < grouped.entries.length; i++) ...[
                _RaffleTicketTile(
                  raffleId: grouped.entries.elementAt(i).key,
                  ticketCount: grouped.entries.elementAt(i).value,
                ),
                if (i < grouped.entries.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MyRafflesEmpty extends StatelessWidget {
  const _MyRafflesEmpty();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.amber.withOpacity(0.25)),
        ),
        child: Center(
          child: Text(
            'No raffle entries yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _RaffleTicketTile extends ConsumerWidget {
  final String raffleId;
  final int ticketCount;
  const _RaffleTicketTile({required this.raffleId, required this.ticketCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final raffleAsync = ref.watch(singleRaffleStreamProvider(raffleId));

    final title = raffleAsync.maybeWhen(
      data: (r) => r?.title ?? 'Raffle',
      orElse: () => 'Loading…',
    );
    final status = raffleAsync.maybeWhen(
      data: (r) => r?.status,
      orElse: () => null,
    );

    final (statusLabel, statusColor) = switch (status) {
      RaffleStatus.active => ('Active', AppTheme.mint),
      RaffleStatus.ended => ('Ended', Colors.grey),
      _ => ('Draft', AppTheme.amber),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.amber.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.amber.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppTheme.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$ticketCount ticket${ticketCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settings group
// ─────────────────────────────────────────────────────────────────────────────

class _SettingsEntry {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsEntry> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppTheme.primary.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return _SettingsTile(entry: items[i], divider: i < items.length - 1);
        }),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final _SettingsEntry entry;
  final bool divider;
  const _SettingsTile({required this.entry, required this.divider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Pressable(
      onTap: entry.onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(entry.icon, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(entry.title, style: theme.textTheme.titleMedium),
                ),
                if (entry.trailing != null) ...[
                  entry.trailing!,
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.35),
                ),
              ],
            ),
          ),
          if (divider)
            Padding(
              padding: const EdgeInsets.only(left: 58, right: 16),
              child: Divider(
                height: 1,
                color: theme.colorScheme.outline.withOpacity(
                  isDark ? 0.12 : 0.18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log out row
// ─────────────────────────────────────────────────────────────────────────────

class _LogOutRow extends StatelessWidget {
  final VoidCallback onTap;
  const _LogOutRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : AppTheme.coral.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.coral.withOpacity(isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppTheme.coral,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Log Out',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.coral,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.coral.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Win banner
// ─────────────────────────────────────────────────────────────────────────────

class _RecentWinBanner extends StatelessWidget {
  const _RecentWinBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1C1C), Color(0xFF1A0E0E)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.coral.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.coral.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.coral,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Win!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your last won item will appear here',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme badge + picker sheet (preserved from original)
// ─────────────────────────────────────────────────────────────────────────────

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
