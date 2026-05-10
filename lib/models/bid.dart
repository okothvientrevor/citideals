class Bid {
  final String id;
  final String auctionItemId;
  final String userId;
  final String userName;
  final double amount;
  final DateTime timestamp;
  final bool isWinning;

  Bid({
    required this.id,
    required this.auctionItemId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.timestamp,
    this.isWinning = false,
  });

  String get formattedAmount {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
