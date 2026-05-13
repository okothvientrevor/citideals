import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_repository.dart';
import '../models/auction_item.dart';
import '../models/bid.dart';

final auctionsRepositoryProvider = Provider<AuctionsRepository>((ref) {
  return AuctionsRepository(ref.watch(firestoreProvider));
});

/// Live feed of public, approved, still-running auctions.
final liveAuctionsStreamProvider = StreamProvider<List<AuctionItem>>((ref) {
  return ref.watch(auctionsRepositoryProvider).publicLive();
});

/// Ended / closed auctions (status ended or approved but endTime passed).
final endedAuctionsStreamProvider = StreamProvider<List<AuctionItem>>((ref) {
  return ref.watch(auctionsRepositoryProvider).publicEnded();
});

/// Trending = featured + approved, capped.
final trendingAuctionsStreamProvider = StreamProvider<List<AuctionItem>>((ref) {
  return ref.watch(auctionsRepositoryProvider).trending();
});

/// Pending queue (admin-only by security rules).
final pendingSubmissionsStreamProvider = StreamProvider<List<AuctionItem>>((
  ref,
) {
  return ref.watch(auctionsRepositoryProvider).pendingForAdmin();
});

/// Current user's own submissions, all statuses.
final mySubmissionsStreamProvider = StreamProvider<List<AuctionItem>>((ref) {
  final session = ref.watch(authStateProvider).value;
  if (session == null) return const Stream.empty();
  return ref.watch(auctionsRepositoryProvider).forSeller(session.user.uid);
});

/// Bids the current user has placed on other auctions.
final myPlacedBidsStreamProvider = StreamProvider<List<Bid>>((ref) {
  final session = ref.watch(authStateProvider).value;
  if (session == null) return const Stream.empty();
  return ref.watch(auctionsRepositoryProvider).myPlacedBids(session.user.uid);
});

/// Live stream of a single auction by its document ID.
final auctionByIdStreamProvider = StreamProvider.family<AuctionItem, String>((
  ref,
  id,
) {
  return ref.watch(auctionsRepositoryProvider).watch(id);
});

class AuctionsRepository {
  AuctionsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('auctions');

  Stream<List<AuctionItem>> publicLive() {
    return _col
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(AuctionItem.fromFirestore)
              .where((a) => !a.hasEnded)
              .toList(),
        );
  }

  Stream<List<AuctionItem>> publicEnded() {
    return _col
        .where('status', isEqualTo: 'approved')
        .orderBy('endTime', descending: true)
        .limit(40)
        .snapshots()
        .map(
          (s) => s.docs
              .map(AuctionItem.fromFirestore)
              .where((a) => a.hasEnded)
              .toList(),
        );
  }

  Stream<List<AuctionItem>> trending() {
    return _col
        .where('status', isEqualTo: 'approved')
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(12)
        .snapshots()
        .map(
          (s) => s.docs
              .map(AuctionItem.fromFirestore)
              .where(
                (a) => !a.hasEnded && a.status == AuctionStatus.approved,
              )
              .toList(),
        );
  }

  Stream<List<AuctionItem>> pendingForAdmin() {
    return _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AuctionItem.fromFirestore).toList());
  }

  Stream<List<AuctionItem>> forSeller(String uid) {
    return _col
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(AuctionItem.fromFirestore).toList());
  }

  Stream<AuctionItem> watch(String id) {
    return _col.doc(id).snapshots().map(AuctionItem.fromFirestore);
  }

  Future<String> createSubmission(AuctionItem item) async {
    final doc = await _col.add(item.toFirestore());
    return doc.id;
  }

  /// Admin: approve a pending submission and publish it.
  Future<void> approveItem(
    String id,
    String approvedByUid, {
    bool isTrending = false,
  }) {
    return _col.doc(id).update({
      'status': 'approved',
      'approvedBy': approvedByUid,
      'approvedAt': FieldValue.serverTimestamp(),
      'isFeatured': isTrending,
    });
  }

  /// Admin: toggle trending (isFeatured) on an approved item.
  Future<void> setTrending(String id, bool isTrending) {
    return _col.doc(id).update({'isFeatured': isTrending});
  }

  /// Bids the user has placed (collection group query).
  Stream<List<Bid>> myPlacedBids(String uid) {
    return _db
        .collectionGroup('bids')
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (doc) => Bid(
                  id: doc.id,
                  auctionItemId: doc.reference.parent.parent?.id ?? '',
                  userId: (doc.data()['userId'] as String?) ?? '',
                  userName: (doc.data()['userName'] as String?) ?? '',
                  amount: (doc.data()['amount'] as num?)?.toDouble() ?? 0,
                  timestamp: doc.data()['timestamp'] is Timestamp
                      ? (doc.data()['timestamp'] as Timestamp).toDate()
                      : DateTime.now(),
                  isWinning: (doc.data()['isWinning'] as bool?) ?? false,
                ),
              )
              .toList(),
        );
  }

  /// Admin: reject a pending submission with an optional reason.
  Future<void> rejectItem(String id, String approvedByUid, String reason) {
    return _col.doc(id).update({
      'status': 'rejected',
      'approvedBy': approvedByUid,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }

  /// Client-side bid placement fallback for Spark-plan deployments where
  /// Cloud Functions may be unavailable.
  Future<void> placeBid({
    required String auctionId,
    required String userId,
    required String userName,
    required double amount,
  }) {
    final auctionRef = _col.doc(auctionId);
    final bidRef = auctionRef.collection('bids').doc();

    return _db.runTransaction((tx) async {
      final snap = await tx.get(auctionRef);
      if (!snap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Auction not found.',
        );
      }

      final data = snap.data()!;
      final status = data['status'] as String? ?? 'pending';
      final sellerId = data['sellerId'] as String? ?? '';
      final currentBid = (data['currentBid'] as num?)?.toDouble() ?? 0;
      final startingBid = (data['startingBid'] as num?)?.toDouble() ?? 0;
      final minIncrement = (data['minBidIncrement'] as num?)?.toDouble() ?? 0;
      final totalBids = (data['totalBids'] as num?)?.toInt() ?? 0;
      final endTimeRaw = data['endTime'];
      final endTime = endTimeRaw is Timestamp
          ? endTimeRaw.toDate()
          : DateTime.now().subtract(const Duration(seconds: 1));

      if (status != 'approved') {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'This listing is not open for bidding.',
        );
      }
      if (sellerId == userId) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'You cannot bid on your own listing.',
        );
      }
      if (DateTime.now().isAfter(endTime)) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'failed-precondition',
          message: 'This auction has already ended.',
        );
      }

      final minAllowed = totalBids == 0
          ? startingBid
          : currentBid + (minIncrement > 0 ? minIncrement : 1);
      if (amount < minAllowed) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'invalid-argument',
          message: 'Bid must be at least UGX ${minAllowed.toStringAsFixed(0)}',
        );
      }

      tx.update(auctionRef, {
        'currentBid': amount,
        'totalBids': totalBids + 1,
        'lastBidderId': userId,
        'lastBidAt': FieldValue.serverTimestamp(),
      });

      tx.set(bidRef, {
        'userId': userId,
        'userName': userName,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
        'isWinning': true,
      });

      // Lifetime bid counter for profile stats.
      tx.set(_db.collection('users').doc(userId), {
        'lifetimeBidCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    });
  }

  /// Immediately closes an auction (sets status → ended and endTime → now).
  /// Only the seller should call this. The last bidder is recorded as the
  /// winner; their `lifetimeWinCount` is incremented by a Cloud Function
  /// listener (cross-user writes aren't permitted via security rules).
  Future<void> closeAuction(String id) async {
    final ref = _col.doc(id);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final lastBidder = data['lastBidderId'] as String?;
    await ref.update({
      'status': 'ended',
      'endTime': Timestamp.fromDate(DateTime.now()),
      if (lastBidder != null && lastBidder.isNotEmpty)
        'winnerUserId': lastBidder,
    });
  }
}

/// Streams the per-user lifetime counters from the `users/{uid}` document.
/// Falls back to (0, 0, 0) if the doc doesn't exist yet.
final userStatsStreamProvider =
    StreamProvider.family<({int bids, int wins, int tickets}), String>((
      ref,
      uid,
    ) {
      final db = ref.watch(firestoreProvider);
      return db.collection('users').doc(uid).snapshots().map((s) {
        final d = s.data() ?? const <String, dynamic>{};
        return (
          bids: (d['lifetimeBidCount'] as num?)?.toInt() ?? 0,
          wins: (d['lifetimeWinCount'] as num?)?.toInt() ?? 0,
          tickets: (d['lifetimeTicketCount'] as num?)?.toInt() ?? 0,
        );
      });
    });
