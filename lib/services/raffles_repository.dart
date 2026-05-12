import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_repository.dart';
import '../models/raffle.dart';

final rafflesRepositoryProvider = Provider<RafflesRepository>((ref) {
  return RafflesRepository(ref.watch(firestoreProvider));
});

final activeRafflesStreamProvider = StreamProvider<List<Raffle>>((ref) {
  return ref.watch(rafflesRepositoryProvider).activeRaffles();
});

final winnersHistoryStreamProvider = StreamProvider<List<Raffle>>((ref) {
  return ref.watch(rafflesRepositoryProvider).winnerHistory();
});

final myRaffleTicketsStreamProvider =
    StreamProvider.family<List<RaffleTicket>, String>((ref, uid) {
      return ref.watch(rafflesRepositoryProvider).myTickets(uid);
    });

class RafflesRepository {
  RafflesRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _raffles =>
      _db.collection('raffles');

  Stream<List<Raffle>> activeRaffles() {
    return _raffles
        .where('status', isEqualTo: 'active')
        .orderBy('end_date')
        .snapshots()
        .map((s) => s.docs.map(Raffle.fromDoc).toList());
  }

  Stream<List<Raffle>> winnerHistory() {
    return _raffles
        .where('status', isEqualTo: 'ended')
        .orderBy('winner_selection_date', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map(Raffle.fromDoc).toList());
  }

  Stream<List<RaffleTicket>> myTickets(String uid) {
    return _db
        .collection('raffle_tickets')
        .where('user_id', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map(RaffleTicket.fromDoc).toList());
  }

  Future<void> createRaffle(Raffle raffle) {
    return _raffles.add(raffle.toMap());
  }

  Future<void> buyTickets({
    required Raffle raffle,
    required String userId,
    required String userName,
    required int quantity,
    required String paymentMethod,
  }) async {
    if (quantity < 1) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Quantity must be at least 1.',
      );
    }

    final raffleRef = _raffles.doc(raffle.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(raffleRef);
      if (!snap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Raffle not found.',
        );
      }
      final current = Raffle.fromDoc(snap);
      final now = DateTime.now();
      if (!current.isActive ||
          now.isBefore(current.startAt) ||
          now.isAfter(current.endAt)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Raffle is not active.',
        );
      }
      if (current.remainingTickets < quantity) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'Only ${current.remainingTickets} tickets remaining.',
        );
      }

      final soldAfter = current.soldTickets + quantity;
      tx.update(raffleRef, {'sold_tickets': soldAfter});

      final paymentRef =
          'PAY-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9000) + 1000}';
      final amount = current.ticketPrice * quantity;

      final paymentDoc = _db.collection('raffle_payments').doc();
      tx.set(paymentDoc, {
        'raffle_id': current.id,
        'user_id': userId,
        'user_name': userName,
        'amount': amount,
        'tickets_bought': quantity,
        'payment_method': paymentMethod,
        'payment_reference': paymentRef,
        'timestamp': FieldValue.serverTimestamp(),
      });

      for (var i = 0; i < quantity; i++) {
        final ticketOrdinal = current.soldTickets + i + 1;
        final ticketNumber = 'RF-${10000 + ticketOrdinal}';
        final ticketDoc = _db.collection('raffle_tickets').doc();
        tx.set(ticketDoc, {
          'raffle_id': current.id,
          'user_id': userId,
          'user_name': userName,
          'ticket_number': ticketNumber,
          'payment_reference': paymentRef,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Winner draw is intentionally backend-only.
  Future<void> drawWinnerBackend(String raffleId) async {
    final fn = FirebaseFunctions.instance.httpsCallable('drawRaffleWinner');
    await fn.call({'raffleId': raffleId});
  }
}
