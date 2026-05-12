import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/auction_item.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/deposit_bottom_sheet.dart';
import '../widgets/pressable.dart';

class BidBottomSheet extends StatefulWidget {
  final AuctionItem item;
  final bool isSignedIn;
  final double previousBidAmount;
  final Function(double) onPlaceBid;

  const BidBottomSheet({
    super.key,
    required this.item,
    required this.isSignedIn,
    this.previousBidAmount = 0,
    required this.onPlaceBid,
  });

  @override
  State<BidBottomSheet> createState() => _BidBottomSheetState();
}

class _BidBottomSheetState extends State<BidBottomSheet> {
  late TextEditingController _bidController;
  late double _minBid;
  late double _maxBid;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _minBid = widget.item.currentBid + (widget.item.currentBid * 0.05);
    _maxBid = widget.item.currentBid * 2;
    _currentValue = _minBid;
    _bidController = TextEditingController(
      text: NumberFormat('#,##0').format(_currentValue.round()),
    );
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  String _formatMoney(double v) {
    return 'UGX ${NumberFormat('#,##0').format(v.round())}';
  }

  void _setBid(double v) {
    setState(() {
      _currentValue = v.clamp(_minBid, _maxBid);
      _bidController.text = NumberFormat('#,##0').format(_currentValue.round());
    });
    HapticFeedback.selectionClick();
  }

  void _bump(double delta) {
    _setBid(_currentValue + delta);
  }

  void _placeBid() {
    final bidAmount =
        double.tryParse(_bidController.text.replaceAll(',', '')) ??
        _currentValue;
    if (bidAmount > widget.item.currentBid) {
      HapticFeedback.lightImpact();
      // Pop the bid sheet first, then show the deposit sheet above it.
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (_) => DepositBottomSheet(
          bidAmount: bidAmount,
          previousBidAmount: widget.previousBidAmount,
          isSignedIn: widget.isSignedIn,
          onConfirm: () => widget.onPlaceBid(bidAmount),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.coral,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text(
            'Bid must exceed current bid',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                  Text('Place your bid', style: theme.textTheme.displaySmall),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.title,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current bid',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.item.formattedCurrentBid,
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: theme.colorScheme.outline,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Time left',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                CountdownTimer(
                                  endTime: widget.item.endTime,
                                  compact: true,
                                  textStyle: theme.textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Your bid',
                    style: theme.textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6),
                          child: Text(
                            'UGX',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _bidController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            cursorColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              final value = double.tryParse(v);
                              if (value != null) {
                                setState(() {
                                  _currentValue = value.clamp(_minBid, _maxBid);
                                });
                              }
                            },
                          ),
                        ),
                        Column(
                          children: [
                            _StepBtn(
                              icon: Icons.add_rounded,
                              onTap: () => _bump(500),
                            ),
                            const SizedBox(height: 8),
                            _StepBtn(
                              icon: Icons.remove_rounded,
                              onTap: () => _bump(-500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor:
                          theme.colorScheme.surfaceContainerHighest,
                      thumbColor: Colors.white,
                      overlayColor: AppTheme.primary.withOpacity(0.15),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                        elevation: 4,
                      ),
                    ),
                    child: Slider(
                      value: _currentValue,
                      min: _minBid,
                      max: _maxBid,
                      onChanged: _setBid,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatMoney(_minBid),
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          _formatMoney(_maxBid),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _QuickBidButton(
                        label: '+1K',
                        onPressed: () => _bump(1000),
                      ),
                      const SizedBox(width: 10),
                      _QuickBidButton(
                        label: '+5K',
                        onPressed: () => _bump(5000),
                      ),
                      const SizedBox(width: 10),
                      _QuickBidButton(
                        label: '+10K',
                        onPressed: () => _bump(10000),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Pressable(
                    onTap: _placeBid,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.gavel_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Place bid',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _QuickBidButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickBidButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Pressable(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
