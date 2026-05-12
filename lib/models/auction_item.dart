import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final _comma = NumberFormat('#,##0', 'en_US');

enum AuctionStatus { pending, approved, rejected, ended, sold }

AuctionStatus _statusFrom(String? v) {
  return switch (v) {
    'pending' => AuctionStatus.pending,
    'approved' => AuctionStatus.approved,
    'rejected' => AuctionStatus.rejected,
    'ended' => AuctionStatus.ended,
    'sold' => AuctionStatus.sold,
    _ => AuctionStatus.pending,
  };
}

class AuctionItem {
  final String id;
  final String sellerId;
  final String? sellerName;

  final String title;
  final String description;
  final String category;
  final Map<String, dynamic> categoryData;

  final List<String> imageUrls;
  final String? thumbnailUrl;

  final double currentBid;
  final double startingBid;
  final double minBidIncrement;
  final double? reservePrice;
  final int totalBids;

  final DateTime endTime;

  final AuctionStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;

  final bool isFeatured;
  final bool isVerified;

  final int schemaVersion;
  final DateTime createdAt;

  // Legacy fields kept for UI compatibility — may be derived from categoryData.
  final String? location;
  final String? serialNumber;

  AuctionItem({
    required this.id,
    required this.sellerId,
    this.sellerName,
    required this.title,
    required this.description,
    required this.category,
    this.categoryData = const {},
    this.imageUrls = const [],
    this.thumbnailUrl,
    required this.currentBid,
    required this.startingBid,
    this.minBidIncrement = 100,
    this.reservePrice,
    this.totalBids = 0,
    required this.endTime,
    this.status = AuctionStatus.approved,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.isFeatured = false,
    this.isVerified = true,
    this.schemaVersion = 1,
    DateTime? createdAt,
    this.location,
    this.serialNumber,
  }) : createdAt = createdAt ?? DateTime.now();

  /// First image used wherever a single URL is expected.
  String get imageUrl =>
      thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : '');

  bool get isLive =>
      status == AuctionStatus.approved && DateTime.now().isBefore(endTime);

  Duration get timeRemaining => endTime.difference(DateTime.now());
  bool get hasEnded => DateTime.now().isAfter(endTime);

  String get formattedCurrentBid => 'UGX ${_comma.format(currentBid)}';

  factory AuctionItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    return AuctionItem(
      id: doc.id,
      sellerId: (d['sellerId'] as String?) ?? '',
      sellerName: d['sellerName'] as String?,
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      categoryData: Map<String, dynamic>.from(
        (d['categoryData'] as Map?) ?? const {},
      ),
      imageUrls: List<String>.from((d['imageUrls'] as List?) ?? const []),
      thumbnailUrl: d['thumbnailUrl'] as String?,
      currentBid: (d['currentBid'] as num?)?.toDouble() ?? 0,
      startingBid: (d['startingBid'] as num?)?.toDouble() ?? 0,
      minBidIncrement: (d['minBidIncrement'] as num?)?.toDouble() ?? 100,
      reservePrice: (d['reservePrice'] as num?)?.toDouble(),
      totalBids: (d['totalBids'] as num?)?.toInt() ?? 0,
      endTime: toDate(d['endTime']),
      status: _statusFrom(d['status'] as String?),
      approvedBy: d['approvedBy'] as String?,
      approvedAt: d['approvedAt'] is Timestamp
          ? (d['approvedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: d['rejectionReason'] as String?,
      isFeatured: (d['isFeatured'] as bool?) ?? false,
      isVerified: (d['isVerified'] as bool?) ?? true,
      schemaVersion: (d['schemaVersion'] as num?)?.toInt() ?? 1,
      createdAt: toDate(d['createdAt']),
      location: d['location'] as String?,
      serialNumber: d['serialNumber'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sellerId': sellerId,
    if (sellerName != null) 'sellerName': sellerName,
    'title': title,
    'description': description,
    'category': category,
    'categoryData': categoryData,
    'imageUrls': imageUrls,
    if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    'currentBid': currentBid,
    'startingBid': startingBid,
    'minBidIncrement': minBidIncrement,
    if (reservePrice != null) 'reservePrice': reservePrice,
    'totalBids': totalBids,
    'endTime': Timestamp.fromDate(endTime),
    'status': status.name,
    if (approvedBy != null) 'approvedBy': approvedBy,
    if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
    'isFeatured': isFeatured,
    'isVerified': isVerified,
    'schemaVersion': schemaVersion,
    'createdAt': Timestamp.fromDate(createdAt),
    if (location != null) 'location': location,
    if (serialNumber != null) 'serialNumber': serialNumber,
  };

  AuctionItem copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? title,
    String? description,
    String? category,
    Map<String, dynamic>? categoryData,
    List<String>? imageUrls,
    String? thumbnailUrl,
    double? currentBid,
    double? startingBid,
    double? minBidIncrement,
    double? reservePrice,
    int? totalBids,
    DateTime? endTime,
    AuctionStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    bool? isFeatured,
    bool? isVerified,
    int? schemaVersion,
    DateTime? createdAt,
    String? location,
    String? serialNumber,
  }) {
    return AuctionItem(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      categoryData: categoryData ?? this.categoryData,
      imageUrls: imageUrls ?? this.imageUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      currentBid: currentBid ?? this.currentBid,
      startingBid: startingBid ?? this.startingBid,
      minBidIncrement: minBidIncrement ?? this.minBidIncrement,
      reservePrice: reservePrice ?? this.reservePrice,
      totalBids: totalBids ?? this.totalBids,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }
}
