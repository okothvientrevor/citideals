import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/auth/auth_repository.dart';
import '../../models/auction_item.dart';
import '../../services/auctions_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pressable.dart';
import '../submission/category_schemas.dart';

class SubmissionReviewScreen extends ConsumerStatefulWidget {
  final AuctionItem item;
  const SubmissionReviewScreen({super.key, required this.item});

  @override
  ConsumerState<SubmissionReviewScreen> createState() =>
      _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState
    extends ConsumerState<SubmissionReviewScreen> {
  bool _busy = false;
  int _imageIndex = 0;
  late bool _setAsTrending;

  @override
  void initState() {
    super.initState();
    _setAsTrending = widget.item.isFeatured;
  }

  Future<void> _decide(bool approve, [String? reason]) async {
    final session = ref.read(authStateProvider).value;
    if (session == null) {
      _toastError('Not signed in.');
      return;
    }
    if (!session.isAdmin) {
      _toastError(
        'Your session does not have admin privileges yet. Sign out and sign back in to refresh your token.',
      );
      return;
    }

    final confirmed = await _confirmApprove(approve);
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(auctionsRepositoryProvider);
      final itemId = widget.item.id;

      debugPrint(
        '[AdminReview] ${approve ? "Approving" : "Rejecting"} '
        'auction $itemId by ${session.user.uid}',
      );

      if (approve) {
        await repo.approveItem(
          itemId,
          session.user.uid,
          isTrending: _setAsTrending,
        );
      } else {
        await repo.rejectItem(itemId, session.user.uid, reason ?? '');
      }

      debugPrint('[AdminReview] Success');
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: approve ? AppTheme.mint : AppTheme.coral,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            approve ? 'Approved & published!' : 'Submission rejected.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint('[AdminReview] Error: $e\n$stack');
      if (!mounted) return;
      _toastError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Returns true if the user confirms the action.
  Future<bool> _confirmApprove(bool approve) async {
    if (!approve) return true; // reject sheet already acts as confirmation
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text('Approve & publish?'),
            content: Text(
              '"${widget.item.title}" will go live immediately and be visible to all users.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.mint),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Publish'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _toastError(Object e) {
    final String msg;
    if (e is FirebaseException) {
      // e.g. permission-denied, not-found, etc.
      msg = '[${e.code}] ${e.message ?? e.toString()}';
    } else {
      msg = e.toString();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.coral,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action failed',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRejectSheet() async {
    final ctrl = TextEditingController();
    final reason = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
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
                    const SizedBox(height: 18),
                    Text(
                      'Reject submission',
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The seller will see this reason.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: ctrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Reason (optional but recommended)',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Pressable(
                            onTap: () => Navigator.pop(
                              ctx,
                              ctrl.text.trim().isEmpty ? '' : ctrl.text.trim(),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.coral,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Text(
                                  'Reject',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (reason != null) {
      await _decide(false, reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final schema = categorySchemas[item.category];
    final session = ref.watch(authStateProvider).value;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Pressable(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.40),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Pending review',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Image gallery ─────────────────────────────────────────────
              SizedBox(
                height: 320,
                child: item.imageUrls.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.image_rounded, size: 64),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          PageView.builder(
                            itemCount: item.imageUrls.length,
                            onPageChanged: (i) =>
                                setState(() => _imageIndex = i),
                            itemBuilder: (_, i) => Image.network(
                              item.imageUrls[i],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (item.imageUrls.length > 1)
                            Positioned(
                              bottom: 14,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    item.imageUrls.length,
                                    (i) => AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: i == _imageIndex ? 16 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: i == _imageIndex
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // image count badge
                          if (item.imageUrls.length > 1)
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_imageIndex + 1} / ${item.imageUrls.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category + title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(item.title, style: theme.textTheme.displayMedium),

                    const SizedBox(height: 20),

                    // ── Submission metadata ────────────────────────────────
                    _section(theme, 'Submission info', [
                      _iconRow(
                        theme,
                        Icons.person_rounded,
                        'Submitted by',
                        item.sellerName ?? item.sellerId,
                      ),
                      _iconRow(
                        theme,
                        Icons.calendar_today_rounded,
                        'Submitted',
                        DateFormat.yMMMd().add_jm().format(item.createdAt),
                      ),
                      _iconRow(
                        theme,
                        Icons.timer_rounded,
                        'Auction ends',
                        DateFormat.yMMMd().add_jm().format(item.endTime),
                      ),
                      _iconRow(
                        theme,
                        Icons.attach_money_rounded,
                        'Starting bid',
                        'UGX ${NumberFormat('#,##0').format(item.startingBid)}',
                      ),
                      _iconRow(
                        theme,
                        Icons.trending_up_rounded,
                        'Min increment',
                        'UGX ${NumberFormat('#,##0').format(item.minBidIncrement)}',
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Description ────────────────────────────────────────
                    Text('Description', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      item.description.isEmpty
                          ? '(no description provided)'
                          : item.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),

                    // ── Category-specific fields ───────────────────────────
                    if (schema != null) ...[
                      const SizedBox(height: 20),
                      _section(theme, '${item.category} details', [
                        for (final f in schema.fields)
                          _iconRow(
                            theme,
                            Icons.label_rounded,
                            f.label,
                            _formatValue(item.categoryData[f.key]),
                          ),
                      ]),
                    ],

                    // ── Debug info ─────────────────────────────────────────
                    const SizedBox(height: 20),
                    _debugSection(theme, item, session?.user.uid),
                  ],
                ),
              ),
            ],
          ),

          // ── Action bar ────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor.withOpacity(0),
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0, 0.4, 1],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (session != null && !session.isAdmin)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Admin claim not active. Sign out & back in to refresh your token.',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ── Trending toggle ────────────────────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _setAsTrending
                            ? AppTheme.primary.withOpacity(0.12)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _setAsTrending
                              ? AppTheme.primary.withOpacity(0.4)
                              : theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: _setAsTrending
                                ? AppTheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mark as trending',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: _setAsTrending
                                        ? AppTheme.primary
                                        : null,
                                  ),
                                ),
                                Text(
                                  'Shows in the Trending section with a larger banner',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _setAsTrending,
                            activeColor: AppTheme.primary,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _setAsTrending = v),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Pressable(
                            onTap: _busy ? null : _showRejectSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              decoration: BoxDecoration(
                                color: AppTheme.coral.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.coral.withOpacity(0.3),
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.close_rounded,
                                      color: _busy
                                          ? AppTheme.coral.withOpacity(0.4)
                                          : AppTheme.coral,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reject',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color: _busy
                                                ? AppTheme.coral.withOpacity(
                                                    0.4,
                                                  )
                                                : AppTheme.coral,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Pressable(
                            onTap: _busy ? null : () => _decide(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              decoration: BoxDecoration(
                                gradient: _busy ? null : AppTheme.mintGradient,
                                color: _busy
                                    ? AppTheme.mint.withOpacity(0.4)
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: _busy
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppTheme.mint.withOpacity(
                                            0.35,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _busy
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Approve & publish',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _iconRow(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugSection(ThemeData theme, AuctionItem item, String? adminUid) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Debug info',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.4),
          fontWeight: FontWeight.w700,
        ),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _copyableRow(theme, 'Doc ID', item.id),
              _copyableRow(theme, 'Seller UID', item.sellerId),
              _copyableRow(theme, 'Reviewer UID', adminUid ?? '—'),
              _copyableRow(theme, 'Status', item.status.name),
            ],
          ),
        ),
      ],
    );
  }

  Widget _copyableRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Icon(
              Icons.copy_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'Yes' : 'No';
    if (v is DateTime) return DateFormat.yMMMd().format(v);
    return v.toString();
  }
}
