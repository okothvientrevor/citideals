class AuctionItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double currentBid;
  final double startingBid;
  final DateTime endTime;
  final String category;
  final bool isLive;
  final int totalBids;
  final String? location;
  final String? serialNumber;
  final bool isFeatured;
  final bool isVerified;

  AuctionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.currentBid,
    required this.startingBid,
    required this.endTime,
    required this.category,
    this.isLive = false,
    this.totalBids = 0,
    this.location,
    this.serialNumber,
    this.isFeatured = false,
    this.isVerified = true,
  });

  Duration get timeRemaining {
    return endTime.difference(DateTime.now());
  }

  bool get hasEnded {
    return DateTime.now().isAfter(endTime);
  }

  String get formattedCurrentBid {
    if (currentBid >= 1000000) {
      return '\$${(currentBid / 1000000).toStringAsFixed(1)}M';
    } else if (currentBid >= 1000) {
      return '\$${(currentBid / 1000).toStringAsFixed(0)}K';
    }
    return '\$${currentBid.toStringAsFixed(0)}';
  }

  AuctionItem copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? currentBid,
    double? startingBid,
    DateTime? endTime,
    String? category,
    bool? isLive,
    int? totalBids,
    String? location,
    String? serialNumber,
    bool? isFeatured,
    bool? isVerified,
  }) {
    return AuctionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      currentBid: currentBid ?? this.currentBid,
      startingBid: startingBid ?? this.startingBid,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      isLive: isLive ?? this.isLive,
      totalBids: totalBids ?? this.totalBids,
      location: location ?? this.location,
      serialNumber: serialNumber ?? this.serialNumber,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
