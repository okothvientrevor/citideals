import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/auction_item.dart';
import '../models/bid.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/bid_bottom_sheet.dart';
import '../widgets/pressable.dart';
import '../data/mock_data.dart';

class AuctionDetailScreen extends StatefulWidget {
  final AuctionItem item;

  const AuctionDetailScreen({super.key, required this.item});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  late AuctionItem _item;
  late List<Bid> _bidHistory;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _bidHistory = MockData.getBidHistory(_item.id);
  }

  void _placeBid(double amount) {
    setState(() {
      _item = _item.copyWith(
        currentBid: amount,
        totalBids: _item.totalBids + 1,
      );
      _bidHistory.insert(
        0,
        Bid(
          id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
          auctionItemId: _item.id,
          userId: 'current_user',
          userName: 'You',
          amount: amount,
          timestamp: DateTime.now(),
          isWinning: true,
        ),
      );
    });

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
  }

  void _showBidSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) =>
          BidBottomSheet(item: _item, onPlaceBid: _placeBid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
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
                        tag: 'auction_image_${_item.id}',
                        child: Image.network(
                          _item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
                      if (_item.isLive)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 70,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                          ),
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
                  _GlassButton(
                    icon: Icons.ios_share_rounded,
                    onTap: () {},
                  ),
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
                              _item.category,
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_item.isVerified)
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
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(_item.title, style: theme.textTheme.displayMedium),
                      if (_item.location != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 16,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(_item.location!,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ],
                      const SizedBox(height: 22),
                      _BidStrip(item: _item),
                      const SizedBox(height: 24),
                      _SectionTitle(text: 'About this lot'),
                      const SizedBox(height: 10),
                      Text(
                        _item.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(
                        text: 'Bid history',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_bidHistory.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._bidHistory.map((bid) => _BidHistoryItem(bid: bid)),
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
                child: Pressable(
                  onTap: _showBidSheet,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.gavel_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Place bid · ${_item.formattedCurrentBid}+',
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
          Container(
            width: 1,
            height: 84,
            color: theme.colorScheme.outline,
          ),
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
                  Text(
                    'Local time',
                    style: theme.textTheme.bodySmall,
                  ),
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
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class _BidHistoryItem extends StatelessWidget {
  final Bid bid;
  const _BidHistoryItem({required this.bid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bid.isWinning
            ? AppTheme.primary.withOpacity(0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: bid.isWinning
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
                bid.userName[0].toUpperCase(),
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
                    if (bid.isWinning) ...[
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
