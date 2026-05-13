import 'package:flutter_test/flutter_test.dart';

import 'package:citideals/models/bid.dart';

void main() {
  Bid _bid({double amount = 100000, DateTime? timestamp}) {
    return Bid(
      id: 'bid-1',
      auctionItemId: 'auction-1',
      userId: 'user-1',
      userName: 'Alice',
      amount: amount,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // formattedAmount
  // ─────────────────────────────────────────────────────────────────────────
  group('Bid.formattedAmount', () {
    test('formats with UGX prefix and comma separator', () {
      expect(_bid(amount: 2500000).formattedAmount, 'UGX 2,500,000');
    });

    test('formats amounts under 1000 without comma', () {
      expect(_bid(amount: 500).formattedAmount, 'UGX 500');
    });

    test('formats exactly 1000', () {
      expect(_bid(amount: 1000).formattedAmount, 'UGX 1,000');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // timeAgo
  // ─────────────────────────────────────────────────────────────────────────
  group('Bid.timeAgo', () {
    test('returns "Just now" for very recent bids', () {
      final bid = _bid(
        timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
      );
      expect(bid.timeAgo, 'Just now');
    });

    test('returns minutes ago', () {
      final bid = _bid(
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      );
      expect(bid.timeAgo, '15m ago');
    });

    test('returns hours ago', () {
      final bid = _bid(
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(bid.timeAgo, '3h ago');
    });

    test('returns days ago', () {
      final bid = _bid(
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(bid.timeAgo, '2d ago');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // isWinning default
  // ─────────────────────────────────────────────────────────────────────────
  group('Bid.isWinning', () {
    test('defaults to false', () {
      expect(_bid().isWinning, isFalse);
    });

    test('can be set to true', () {
      final bid = Bid(
        id: 'b',
        auctionItemId: 'a',
        userId: 'u',
        userName: 'Bob',
        amount: 5000,
        timestamp: DateTime.now(),
        isWinning: true,
      );
      expect(bid.isWinning, isTrue);
    });
  });
}
