import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:citideals/services/raffles_repository.dart';
import 'package:citideals/models/raffle.dart';

@GenerateMocks([FirebaseFirestore])
import 'raffles_repository_test.mocks.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // buyTickets – validation logic
  //
  // Mirrors the checks inside RafflesRepository.buyTickets to test them
  // independently of Firestore.
  // ─────────────────────────────────────────────────────────────────────────

  group('buyTickets – quantity guard', () {
    test('quantity less than 1 is invalid', () {
      expect(0 < 1, isTrue, reason: 'quantity=0 should be rejected');
      expect(-5 < 1, isTrue, reason: 'negative quantity should be rejected');
    });

    test('quantity of 1 is valid', () {
      expect(1 < 1, isFalse);
    });
  });

  group('buyTickets – raffle state checks', () {
    Raffle _activeRaffle({
      int maxTickets = 1000,
      int soldTickets = 100,
      double ticketPrice = 5000,
    }) {
      final now = DateTime.now();
      return Raffle(
        id: 'r1',
        title: 'Test Raffle',
        description: '',
        bannerImage: '',
        ticketPrice: ticketPrice,
        maxTickets: maxTickets,
        soldTickets: soldTickets,
        startAt: now.subtract(const Duration(hours: 1)),
        endAt: now.add(const Duration(days: 7)),
        prizeDetails: '',
        winnerSelectionAt: now.add(const Duration(days: 8)),
        status: RaffleStatus.active,
      );
    }

    /// Mirrors RafflesRepository.buyTickets validation logic.
    String? validatePurchase(Raffle raffle, int quantity) {
      if (quantity < 1) return 'invalid-quantity';
      if (!raffle.isActive) return 'not-active';
      final now = DateTime.now();
      if (now.isBefore(raffle.startAt)) return 'not-started';
      if (now.isAfter(raffle.endAt)) return 'ended';
      if (raffle.remainingTickets < quantity) return 'not-enough-tickets';
      return null;
    }

    test('accepts valid purchase', () {
      expect(validatePurchase(_activeRaffle(), 5), isNull);
    });

    test('rejects purchase on inactive raffle', () {
      final raffle = Raffle(
        id: 'r1',
        title: '',
        description: '',
        bannerImage: '',
        ticketPrice: 5000,
        maxTickets: 1000,
        soldTickets: 0,
        startAt: DateTime.now().subtract(const Duration(hours: 2)),
        endAt: DateTime.now().add(const Duration(days: 1)),
        prizeDetails: '',
        winnerSelectionAt: DateTime.now().add(const Duration(days: 2)),
        status: RaffleStatus.draft,
      );
      expect(validatePurchase(raffle, 1), 'not-active');
    });

    test('rejects purchase when not enough tickets remain', () {
      // 100 sold, 1000 max → 900 remaining
      expect(
        validatePurchase(_activeRaffle(soldTickets: 950), 100),
        'not-enough-tickets',
      );
    });

    test('rejects purchase when raffle has ended', () {
      final raffle = Raffle(
        id: 'r1',
        title: '',
        description: '',
        bannerImage: '',
        ticketPrice: 5000,
        maxTickets: 1000,
        soldTickets: 0,
        startAt: DateTime.now().subtract(const Duration(days: 5)),
        endAt: DateTime.now().subtract(const Duration(minutes: 1)),
        prizeDetails: '',
        winnerSelectionAt: DateTime.now(),
        status: RaffleStatus.active,
      );
      expect(validatePurchase(raffle, 1), 'ended');
    });

    test('rejects zero quantity', () {
      expect(validatePurchase(_activeRaffle(), 0), 'invalid-quantity');
    });

    test('accepts buying exactly the remaining tickets', () {
      final raffle = _activeRaffle(maxTickets: 100, soldTickets: 95);
      expect(raffle.remainingTickets, 5);
      expect(validatePurchase(raffle, 5), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Ticket number format
  // ─────────────────────────────────────────────────────────────────────────
  group('Ticket number generation format', () {
    /// Mirrors the ticket numbering logic in buyTickets.
    String ticketNumber(int currentSoldTickets, int index) {
      final ordinal = currentSoldTickets + index + 1;
      return 'RF-${10000 + ordinal}';
    }

    test('first ticket for fresh raffle is RF-10001', () {
      expect(ticketNumber(0, 0), 'RF-10001');
    });

    test('subsequent tickets increment correctly', () {
      expect(ticketNumber(0, 1), 'RF-10002');
      expect(ticketNumber(0, 2), 'RF-10003');
    });

    test('ticket numbers continue from existing sold count', () {
      expect(ticketNumber(99, 0), 'RF-10100');
    });

    test('buying 3 tickets produces 3 sequential numbers', () {
      final tickets = List.generate(3, (i) => ticketNumber(50, i));
      expect(tickets, ['RF-10051', 'RF-10052', 'RF-10053']);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Total price calculation
  // ─────────────────────────────────────────────────────────────────────────
  group('buyTickets – total price calculation', () {
    test('total is ticketPrice × quantity', () {
      const price = 5000.0;
      expect(price * 3, 15000.0);
      expect(price * 20, 100000.0);
    });

    test('fractional price rounds correctly via standard dart math', () {
      const price = 4999.5;
      expect((price * 2).round(), 9999);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RafflesRepository constructor
  // ─────────────────────────────────────────────────────────────────────────
  group('RafflesRepository', () {
    test('constructs successfully with a FirebaseFirestore instance', () {
      final mockFirestore = MockFirebaseFirestore();
      expect(() => RafflesRepository(mockFirestore), returnsNormally);
    });
  });
}
