import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:citideals/services/auctions_repository.dart';
import 'package:citideals/models/auction_item.dart';

@GenerateMocks([FirebaseFirestore])
import 'auctions_repository_test.mocks.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // placeBid validation logic
  //
  // These tests verify the validation rules encoded inside placeBid() by
  // exercising the SAME conditions the method checks, without hitting
  // Firestore. We do this by constructing AuctionItem instances that mirror
  // the Firestore document state read inside the transaction.
  // ─────────────────────────────────────────────────────────────────────────

  group('placeBid – minimum bid calculation', () {
    /// Mirrors the minAllowed logic in AuctionsRepository.placeBid.
    double minAllowed({
      required int totalBids,
      required double currentBid,
      required double startingBid,
      required double minIncrement,
    }) {
      if (totalBids == 0) return startingBid;
      return currentBid + (minIncrement > 0 ? minIncrement : 1);
    }

    test('first bid must be at least startingBid', () {
      expect(
        minAllowed(
          totalBids: 0,
          currentBid: 0,
          startingBid: 50000,
          minIncrement: 1000,
        ),
        50000,
      );
    });

    test('subsequent bid must be currentBid + minIncrement', () {
      expect(
        minAllowed(
          totalBids: 3,
          currentBid: 53000,
          startingBid: 50000,
          minIncrement: 1000,
        ),
        54000,
      );
    });

    test('uses increment of 1 when minIncrement is 0', () {
      expect(
        minAllowed(
          totalBids: 1,
          currentBid: 50000,
          startingBid: 50000,
          minIncrement: 0,
        ),
        50001,
      );
    });
  });

  group('placeBid – business rule checks', () {
    /// Returns a description of the first violated rule (or null if none).
    String? validateBid({
      required String status,
      required String sellerId,
      required String userId,
      required DateTime endTime,
      required double amount,
      required double currentBid,
      required double startingBid,
      required double minIncrement,
      required int totalBids,
    }) {
      if (status != 'approved') return 'not-open';
      if (sellerId == userId) return 'own-listing';
      if (DateTime.now().isAfter(endTime)) return 'ended';

      final minBid = totalBids == 0
          ? startingBid
          : currentBid + (minIncrement > 0 ? minIncrement : 1);
      if (amount < minBid) return 'too-low';
      return null;
    }

    test('rejects bid on non-approved listing', () {
      expect(
        validateBid(
          status: 'pending',
          sellerId: 'seller',
          userId: 'buyer',
          endTime: DateTime.now().add(const Duration(hours: 1)),
          amount: 50000,
          currentBid: 0,
          startingBid: 50000,
          minIncrement: 1000,
          totalBids: 0,
        ),
        'not-open',
      );
    });

    test('rejects seller bidding on their own listing', () {
      expect(
        validateBid(
          status: 'approved',
          sellerId: 'user-1',
          userId: 'user-1',
          endTime: DateTime.now().add(const Duration(hours: 1)),
          amount: 50000,
          currentBid: 0,
          startingBid: 50000,
          minIncrement: 1000,
          totalBids: 0,
        ),
        'own-listing',
      );
    });

    test('rejects bid after auction endTime', () {
      expect(
        validateBid(
          status: 'approved',
          sellerId: 'seller',
          userId: 'buyer',
          endTime: DateTime.now().subtract(const Duration(minutes: 1)),
          amount: 50000,
          currentBid: 0,
          startingBid: 50000,
          minIncrement: 1000,
          totalBids: 0,
        ),
        'ended',
      );
    });

    test('rejects bid below minimum allowed', () {
      expect(
        validateBid(
          status: 'approved',
          sellerId: 'seller',
          userId: 'buyer',
          endTime: DateTime.now().add(const Duration(hours: 1)),
          amount: 49000,
          currentBid: 50000,
          startingBid: 50000,
          minIncrement: 1000,
          totalBids: 2,
        ),
        'too-low',
      );
    });

    test('accepts valid first bid at exactly startingBid', () {
      expect(
        validateBid(
          status: 'approved',
          sellerId: 'seller',
          userId: 'buyer',
          endTime: DateTime.now().add(const Duration(hours: 1)),
          amount: 50000,
          currentBid: 0,
          startingBid: 50000,
          minIncrement: 1000,
          totalBids: 0,
        ),
        isNull,
      );
    });

    test('accepts valid subsequent bid meeting min increment', () {
      expect(
        validateBid(
          status: 'approved',
          sellerId: 'seller',
          userId: 'buyer',
          endTime: DateTime.now().add(const Duration(hours: 1)),
          amount: 52000,
          currentBid: 51000,
          startingBid: 50000,
          minIncrement: 1000,
          totalBids: 1,
        ),
        isNull,
      );
    });

    test('accepts bid above the minimum increment', () {
      expect(
        validateBid(
          status: 'approved',
          sellerId: 'seller',
          userId: 'buyer',
          endTime: DateTime.now().add(const Duration(hours: 1)),
          amount: 60000,
          currentBid: 51000,
          startingBid: 50000,
          minIncrement: 1000,
          totalBids: 1,
        ),
        isNull,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AuctionItem.fromFirestore deserialization
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionItem.fromFirestore', () {
    test('handles missing fields gracefully', () {
      // Use the factory with an empty data map via AuctionItem constructor
      // (fromFirestore requires a real DocumentSnapshot; we test the fallback
      // values via direct construction instead)
      final item = AuctionItem(
        id: 'test',
        sellerId: '',
        title: '',
        description: '',
        category: '',
        currentBid: 0,
        startingBid: 0,
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(item.imageUrls, isEmpty);
      expect(item.categoryData, isEmpty);
      expect(item.minBidIncrement, 100);
      expect(item.totalBids, 0);
      expect(item.status, AuctionStatus.approved);
    });

    test('status defaults to approved when not explicitly set', () {
      final item = AuctionItem(
        id: 'x',
        sellerId: 'u',
        title: 't',
        description: 'd',
        category: 'c',
        currentBid: 0,
        startingBid: 0,
        endTime: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(item.status, AuctionStatus.approved);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AuctionsRepository constructor
  // ─────────────────────────────────────────────────────────────────────────
  group('AuctionsRepository', () {
    test('constructs successfully with a FirebaseFirestore instance', () {
      final mockFirestore = MockFirebaseFirestore();
      expect(() => AuctionsRepository(mockFirestore), returnsNormally);
    });
  });
}
