class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isVerified;
  final int totalBids;
  final int totalWins;
  final DateTime joinedDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isVerified = false,
    this.totalBids = 0,
    this.totalWins = 0,
    required this.joinedDate,
  });

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
