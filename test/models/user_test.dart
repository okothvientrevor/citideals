import 'package:flutter_test/flutter_test.dart';

import 'package:citideals/models/user.dart';

void main() {
  User _user({String name = 'John Doe', String? avatarUrl}) {
    return User(
      id: 'user-1',
      name: name,
      email: 'john@example.com',
      avatarUrl: avatarUrl,
      joinedDate: DateTime(2024, 1, 15),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // initials
  // ─────────────────────────────────────────────────────────────────────────
  group('User.initials', () {
    test('returns first letters of first and last name', () {
      expect(_user(name: 'John Doe').initials, 'JD');
    });

    test('returns single letter for single-word name', () {
      expect(_user(name: 'Alice').initials, 'A');
    });

    test('is uppercase', () {
      expect(_user(name: 'jane smith').initials, 'JS');
    });

    test('uses first two names when more than two words given', () {
      expect(_user(name: 'Mary Jane Watson').initials, 'MJ');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // defaults
  // ─────────────────────────────────────────────────────────────────────────
  group('User defaults', () {
    test('isVerified defaults to false', () {
      expect(_user().isVerified, isFalse);
    });

    test('totalBids defaults to 0', () {
      expect(_user().totalBids, 0);
    });

    test('totalWins defaults to 0', () {
      expect(_user().totalWins, 0);
    });

    test('avatarUrl is null when not provided', () {
      expect(_user().avatarUrl, isNull);
    });
  });
}
