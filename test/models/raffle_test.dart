import 'package:flutter_test/flutter_test.dart';

import 'package:citideals/models/raffle.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Raffle _raffle({
    RaffleStatus status = RaffleStatus.active,
    int maxTickets = 1000,
    int soldTickets = 200,
    double ticketPrice = 5000,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    final now = DateTime.now();
    return Raffle(
      id: 'raffle-1',
      title: 'Grand Prize Raffle',
      description: 'Win big!',
      bannerImage: 'https://example.com/banner.jpg',
      ticketPrice: ticketPrice,
      maxTickets: maxTickets,
      soldTickets: soldTickets,
      startAt: startAt ?? now.subtract(const Duration(hours: 1)),
      endAt: endAt ?? now.add(const Duration(days: 3)),
      prizeDetails: 'A luxury car',
      winnerSelectionAt: now.add(const Duration(days: 4)),
      status: status,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RaffleStatus.isActive
  // ─────────────────────────────────────────────────────────────────────────
  group('Raffle.isActive', () {
    test('returns true for active status', () {
      expect(_raffle(status: RaffleStatus.active).isActive, isTrue);
    });

    test('returns false for draft status', () {
      expect(_raffle(status: RaffleStatus.draft).isActive, isFalse);
    });

    test('returns false for ended status', () {
      expect(_raffle(status: RaffleStatus.ended).isActive, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // remainingTickets
  // ─────────────────────────────────────────────────────────────────────────
  group('Raffle.remainingTickets', () {
    test('calculates remaining correctly', () {
      expect(_raffle(maxTickets: 1000, soldTickets: 300).remainingTickets, 700);
    });

    test('returns 0 when sold equals max', () {
      expect(_raffle(maxTickets: 500, soldTickets: 500).remainingTickets, 0);
    });

    test('clamps to 0 when soldTickets exceeds maxTickets', () {
      expect(_raffle(maxTickets: 100, soldTickets: 150).remainingTickets, 0);
    });

    test('returns maxTickets when nothing is sold', () {
      expect(_raffle(maxTickets: 2000, soldTickets: 0).remainingTickets, 2000);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RaffleTicket model
  // ─────────────────────────────────────────────────────────────────────────
  group('RaffleTicket', () {
    test('creates ticket with correct fields', () {
      final ticket = RaffleTicket(
        id: 'ticket-1',
        raffleId: 'raffle-1',
        userId: 'user-1',
        ticketNumber: 'RF-10001',
        purchasedAt: DateTime(2025, 5, 13),
      );
      expect(ticket.ticketNumber, 'RF-10001');
      expect(ticket.raffleId, 'raffle-1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RaffleActivity model
  // ─────────────────────────────────────────────────────────────────────────
  group('RaffleActivity', () {
    test('creates activity with correct fields', () {
      final activity = RaffleActivity(
        id: 'act-1',
        userName: 'Bob',
        ticketsBought: 5,
        timestamp: DateTime(2025, 5, 13),
      );
      expect(activity.ticketsBought, 5);
      expect(activity.userName, 'Bob');
      expect(activity.avatarUrl, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RaffleStatus parsing
  // ─────────────────────────────────────────────────────────────────────────
  group('RaffleStatus values', () {
    test('all enum values exist', () {
      expect(RaffleStatus.values.length, 3);
      expect(
        RaffleStatus.values,
        containsAll([
          RaffleStatus.draft,
          RaffleStatus.active,
          RaffleStatus.ended,
        ]),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Raffle.toMap
  // ─────────────────────────────────────────────────────────────────────────
  group('Raffle.toMap', () {
    test('includes all expected keys', () {
      final r = _raffle();
      final map = r.toMap();

      expect(map.containsKey('title'), isTrue);
      expect(map.containsKey('ticket_price'), isTrue);
      expect(map.containsKey('max_tickets'), isTrue);
      expect(map.containsKey('sold_tickets'), isTrue);
      expect(map.containsKey('status'), isTrue);
      expect(map.containsKey('start_date'), isTrue);
      expect(map.containsKey('end_date'), isTrue);
    });

    test('serializes status as string name', () {
      expect(_raffle(status: RaffleStatus.active).toMap()['status'], 'active');
      expect(_raffle(status: RaffleStatus.ended).toMap()['status'], 'ended');
      expect(_raffle(status: RaffleStatus.draft).toMap()['status'], 'draft');
    });

    test('serializes ticketPrice correctly', () {
      expect(_raffle(ticketPrice: 7500).toMap()['ticket_price'], 7500);
    });
  });
}
