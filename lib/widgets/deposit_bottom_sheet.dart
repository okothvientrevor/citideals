import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable.dart';

/// Shown after the user has entered a valid bid amount.
/// Displays a deposit breakdown and lets the user confirm.
/// Actual payment is handled later; this call just records the intent.
class DepositBottomSheet extends StatelessWidget {
  final double bidAmount;
  final double previousBidAmount;
  final bool isSignedIn;
  final VoidCallback onConfirm;

  const DepositBottomSheet({
    super.key,
    required this.bidAmount,
    this.previousBidAmount = 0,
    required this.isSignedIn,
    required this.onConfirm,
  });

  /// Deposit = 10 % of the bid amount.
  static double depositFor(double bid) => (bid * 0.10).roundToDouble();

  /// Non-refundable processing fee = 10 % of the deposit.
  static double nonRefundableFor(double deposit) =>
      (deposit * 0.10).roundToDouble();

  String _fmt(double v) => 'UGX ${NumberFormat('#,##0').format(v.round())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTopUp = previousBidAmount > 0;

    final newDeposit = depositFor(bidAmount);
    final alreadyPaid = depositFor(previousBidAmount);
    // Amount the user needs to pay now (the incremental top-up or full deposit)
    final payNow = isTopUp
        ? (newDeposit - alreadyPaid).clamp(0.0, double.infinity)
        : newDeposit;
    final nonRefundable = nonRefundableFor(payNow);
    final refund = payNow - nonRefundable;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
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
              const SizedBox(height: 24),

              // Icon badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.mint.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  size: 30,
                  color: AppTheme.mint,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isTopUp
                    ? 'Deposit Top-up Required'
                    : 'Refundable Deposit Required',
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                isTopUp
                    ? 'Your previous deposit of ${_fmt(alreadyPaid)} has been credited. Only pay the top-up difference.'
                    : 'Pay a deposit to participate in this auction',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Breakdown card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _DepositRow(
                      label: 'Bid amount',
                      value: _fmt(bidAmount),
                      valueStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.outline.withOpacity(0.4),
                    ),
                    _DepositRow(
                      label: isTopUp ? 'Top-up deposit' : 'Deposit amount',
                      value: _fmt(payNow),
                      valueStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.outline.withOpacity(0.4),
                    ),
                    _DepositRow(
                      label: 'Non-refundable fee',
                      value: _fmt(nonRefundable),
                      valueStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.coral,
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.colorScheme.outline.withOpacity(0.4),
                    ),
                    _DepositRow(
                      label: 'Refund if you don\'t win',
                      value: _fmt(refund),
                      valueStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info text
              Text(
                isTopUp
                    ? 'You already paid ${_fmt(alreadyPaid)} for your previous bid. '
                          'This top-up covers your new bid. If you don\'t win, '
                          '${_fmt(refund)} is refunded and ${_fmt(nonRefundable)} is kept as a processing fee.'
                    : 'If you win, the deposit is applied to your purchase. '
                          'If you don\'t win, ${_fmt(refund)} is refunded and '
                          '${_fmt(nonRefundable)} is retained as a processing fee.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // CTA button
              Pressable(
                onTap: isSignedIn
                    ? () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        onConfirm();
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: isSignedIn
                        ? AppTheme.primaryGradient
                        : const LinearGradient(
                            colors: [Color(0xFF888888), Color(0xFF666666)],
                          ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: isSignedIn
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isTopUp
                            ? 'Pay Top-up — ${_fmt(payNow)}'
                            : 'Pay Deposit — ${_fmt(payNow)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sign-in hint / cancel
              if (!isSignedIn)
                Text(
                  'Sign in to pay the deposit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
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

class _DepositRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DepositRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value, style: valueStyle ?? theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
