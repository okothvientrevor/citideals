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
        .map((s) => s.docs.map(AuctionItem.fromFirestore).toList());
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
    });
  }
}
