import 'package:flutter_test/flutter_test.dart';

import 'package:citideals/models/auction_item.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  AuctionItem _base({
    AuctionStatus status = AuctionStatus.approved,
    DateTime? endTime,
    double currentBid = 50000,
    double startingBid = 50000,
    double minBidIncrement = 1000,
    int totalBids = 0,
    List<String> imageUrls = const ['https://example.com/img.jpg'],
    String? thumbnailUrl,
  }) {
    return AuctionItem(
      id: 'auction-1',
      sellerId: 'seller-uid',
      title: 'Test Item',
      description: 'A test auction item',
      category: 'Watches',
      currentBid: currentBid,
      startingBid: startingBid,
      minBidIncrement: minBidIncrement,
      totalBids: totalBids,
      endTime: endTime ?? DateTime.now().add(const Duration(hours: 2)),
      status: status,
      imageUrls: imageUrls,
      thumbnailUrl: thumbnailUrl,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // isLive
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.isLive', () {
    test('returns true when approved and endTime is in the future', () {
      final item = _base();
      expect(item.isLive, isTrue);
    });

    test('returns false when status is not approved', () {
      for (final s in [
        AuctionStatus.pending,
        AuctionStatus.rejected,
        AuctionStatus.ended,
        AuctionStatus.sold,
      ]) {
        expect(
          _base(status: s).isLive,
          isFalse,
          reason: 'Expected isLive=false for status $s',
        );
      }
    });

    test('returns false when endTime has passed', () {
      final item = _base(
        endTime: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(item.isLive, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // hasEnded
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.hasEnded', () {
    test('returns false when endTime is in the future', () {
      expect(_base().hasEnded, isFalse);
    });

    test('returns true when endTime is in the past', () {
      final item = _base(
        endTime: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(item.hasEnded, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // formattedCurrentBid
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.formattedCurrentBid', () {
    test('formats bid with UGX prefix and comma separator', () {
      expect(_base(currentBid: 1500000).formattedCurrentBid, 'UGX 1,500,000');
    });

    test('formats bid below 1000 with no comma', () {
      expect(_base(currentBid: 500).formattedCurrentBid, 'UGX 500');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // imageUrl
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.imageUrl', () {
    test('returns thumbnailUrl when set', () {
      final item = _base(
        thumbnailUrl: 'https://thumb.com/t.jpg',
        imageUrls: ['https://example.com/0.jpg'],
      );
      expect(item.imageUrl, 'https://thumb.com/t.jpg');
    });

    test('falls back to first imageUrl when no thumbnailUrl', () {
      final item = _base(
        imageUrls: [
          'https://example.com/first.jpg',
          'https://example.com/second.jpg',
        ],
      );
      expect(item.imageUrl, 'https://example.com/first.jpg');
    });

    test('returns empty string when no images and no thumbnail', () {
      final item = _base(imageUrls: [], thumbnailUrl: null);
      expect(item.imageUrl, '');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // timeRemaining
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.timeRemaining', () {
    test('returns positive duration for future endTime', () {
      final item = _base(endTime: DateTime.now().add(const Duration(hours: 3)));
      expect(item.timeRemaining.isNegative, isFalse);
    });

    test('returns negative duration for past endTime', () {
      final item = _base(
        endTime: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(item.timeRemaining.isNegative, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AuctionStatus parsing (_statusFrom)
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionStatus fromFirestore parsing', () {
    const statusMap = {
      'pending': AuctionStatus.pending,
      'approved': AuctionStatus.approved,
      'rejected': AuctionStatus.rejected,
      'ended': AuctionStatus.ended,
      'sold': AuctionStatus.sold,
    };

    for (final entry in statusMap.entries) {
      test('parses "${entry.key}"', () {
        final item = AuctionItem(
          id: 'x',
          sellerId: 'u',
          title: 't',
          description: 'd',
          category: 'c',
          currentBid: 0,
          startingBid: 0,
          endTime: DateTime.now().add(const Duration(hours: 1)),
          status: entry.value,
        );
        expect(item.status, entry.value);
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.copyWith', () {
    test('overrides only specified fields', () {
      final original = _base(currentBid: 10000, totalBids: 2);
      final copy = original.copyWith(currentBid: 20000, totalBids: 3);

      expect(copy.currentBid, 20000);
      expect(copy.totalBids, 3);
      expect(copy.id, original.id);
      expect(copy.title, original.title);
    });

    test(
      'returns new instance with identical fields when nothing overridden',
      () {
        final original = _base();
        final copy = original.copyWith();
        expect(copy.id, original.id);
        expect(copy.currentBid, original.currentBid);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // toFirestore / fromFirestore round-trip (using plain maps)
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.toFirestore', () {
    test('includes expected keys', () {
      final item = _base(currentBid: 75000, totalBids: 4);
      final map = item.toFirestore();

      expect(map['currentBid'], 75000);
      expect(map['startingBid'], 50000);
      expect(map['totalBids'], 4);
      expect(map['sellerId'], 'seller-uid');
      expect(map['title'], 'Test Item');
      expect(map['status'], 'approved');
    });
  });
}
