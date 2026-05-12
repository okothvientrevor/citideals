import 'package:cloud_firestore/cloud_firestore.dart';

enum RaffleStatus { draft, active, ended }

RaffleStatus _statusFrom(String? raw) {
  return switch (raw) {
    'active' => RaffleStatus.active,
    'ended' => RaffleStatus.ended,
    _ => RaffleStatus.draft,
  };
}

class Raffle {
  final String id;
  final String title;
  final String description;
  final String bannerImage;
  final double ticketPrice;
  final int maxTickets;
  final int soldTickets;
  final DateTime startAt;
  final DateTime endAt;
  final String prizeDetails;
  final DateTime winnerSelectionAt;
  final RaffleStatus status;
  final String? winningTicketNumber;
  final String? winnerUserId;

  const Raffle({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerImage,
    required this.ticketPrice,
    required this.maxTickets,
    required this.soldTickets,
    required this.startAt,
    required this.endAt,
    required this.prizeDetails,
    required this.winnerSelectionAt,
    required this.status,
    this.winningTicketNumber,
    this.winnerUserId,
  });

  bool get isActive => status == RaffleStatus.active;
  int get remainingTickets => (maxTickets - soldTickets).clamp(0, maxTickets);

  factory Raffle.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    DateTime parseTs(dynamic v, DateTime fallback) {
      return v is Timestamp ? v.toDate() : fallback;
    }

    return Raffle(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Untitled raffle',
      description: (d['description'] as String?) ?? '',
      bannerImage: (d['banner_image'] as String?) ?? '',
      ticketPrice: (d['ticket_price'] as num?)?.toDouble() ?? 0,
      maxTickets: (d['max_tickets'] as num?)?.toInt() ?? 0,
      soldTickets: (d['sold_tickets'] as num?)?.toInt() ?? 0,
      startAt: parseTs(d['start_date'], DateTime.now()),
      endAt: parseTs(
        d['end_date'],
        DateTime.now().add(const Duration(days: 1)),
      ),
      prizeDetails: (d['prize_details'] as String?) ?? '',
      winnerSelectionAt: parseTs(
        d['winner_selection_date'],
        DateTime.now().add(const Duration(days: 1)),
      ),
      status: _statusFrom(d['status'] as String?),
      winningTicketNumber: d['winning_ticket_number'] as String?,
      winnerUserId: d['winner_user_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'banner_image': bannerImage,
      'ticket_price': ticketPrice,
      'max_tickets': maxTickets,
      'sold_tickets': soldTickets,
      'start_date': Timestamp.fromDate(startAt),
      'end_date': Timestamp.fromDate(endAt),
      'prize_details': prizeDetails,
      'winner_selection_date': Timestamp.fromDate(winnerSelectionAt),
      'status': status.name,
      'winning_ticket_number': winningTicketNumber,
      'winner_user_id': winnerUserId,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}

class RaffleTicket {
  final String id;
  final String raffleId;
  final String userId;
  final String ticketNumber;
  final DateTime purchasedAt;

  const RaffleTicket({
    required this.id,
    required this.raffleId,
    required this.userId,
    required this.ticketNumber,
    required this.purchasedAt,
  });

  factory RaffleTicket.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['timestamp'];
    return RaffleTicket(
      id: doc.id,
      raffleId: (d['raffle_id'] as String?) ?? '',
      userId: (d['user_id'] as String?) ?? '',
      ticketNumber: (d['ticket_number'] as String?) ?? '',
      purchasedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
