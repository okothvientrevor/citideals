import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/auction_item.dart';
import '../../services/auctions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pressable.dart';

class MySubmissionsScreen extends ConsumerWidget {
  const MySubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mySubmissionsStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My submissions')),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your submissions:\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _SubmissionTile(item: items[i]),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          Text('No submissions yet', style: theme.textTheme.displaySmall),
          const SizedBox(height: 6),
          Text(
            'Tap the + on the home tab to list your first item.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SubmissionTile extends ConsumerWidget {
  final AuctionItem item;
  const _SubmissionTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item.imageUrl.isEmpty
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.image_rounded,
                          color: Colors.white,
                        ),
                      )
                    : Image.network(item.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.isEmpty ? '(untitled)' : item.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(item.category, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  _StatusChip(status: item.status),
                  if (item.status == AuctionStatus.rejected &&
                      item.rejectionReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.rejectionReason!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.coral,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.status == AuctionStatus.approved) ...[
                    const SizedBox(height: 8),
                    _CloseAuctionButton(item: item),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AuctionStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AuctionStatus.pending => ('Pending review', AppTheme.amber),
      AuctionStatus.approved => ('Live', AppTheme.mint),
      AuctionStatus.rejected => ('Rejected', AppTheme.coral),
      AuctionStatus.ended => ('Ended', Colors.grey),
      AuctionStatus.sold => ('Sold', AppTheme.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _CloseAuctionButton extends ConsumerStatefulWidget {
  final AuctionItem item;
  const _CloseAuctionButton({required this.item});

  @override
  ConsumerState<_CloseAuctionButton> createState() =>
      _CloseAuctionButtonState();
}

class _CloseAuctionButtonState extends ConsumerState<_CloseAuctionButton> {
  bool _loading = false;

  Future<void> _confirmClose(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Auction'),
        content: Text(
          'Are you sure you want to close "${widget.item.title}"? '
          'This will end the auction immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.coral),
            child: const Text('Close Auction'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref.read(auctionsRepositoryProvider).closeAuction(widget.item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Auction closed successfully.'),
          backgroundColor: AppTheme.mint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : () => _confirmClose(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.coral.withOpacity(0.12),
          foregroundColor: AppTheme.coral,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppTheme.coral.withOpacity(0.4)),
          ),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        icon: _loading
            ? const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.coral,
                ),
              )
            : const Icon(Icons.close_rounded, size: 13),
        label: const Text('Close Auction'),
      ),
    );
  }
}
