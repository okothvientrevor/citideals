import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:citideals/features/auth/auth_controller.dart';
import 'package:citideals/features/auth/auth_repository.dart';

@GenerateMocks([AuthRepository, User])
import 'auth_controller_test.mocks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Creates a [ProviderContainer] with [authRepositoryProvider] overridden
/// so the [AuthController] uses the provided mock repository.
ProviderContainer _makeContainer(MockAuthRepository mockRepo) {
  return ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
  );
}

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // signIn
  // ─────────────────────────────────────────────────────────────────────────
  group('AuthController.signIn', () {
    test('calls signInWithEmail and succeeds', () async {
      when(
        mockRepo.signInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      final ctrl = container.read(authControllerProvider.notifier);

      await expectLater(
        ctrl.signIn(email: 'a@b.com', password: 'pass123'),
        completes,
      );

      verify(
        mockRepo.signInWithEmail(email: 'a@b.com', password: 'pass123'),
      ).called(1);
    });

    test('surfaces FirebaseAuthException on failure', () async {
      when(
        mockRepo.signInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        ),
      );

      final container = _makeContainer(mockRepo);
      final ctrl = container.read(authControllerProvider.notifier);

      expect(
        () => ctrl.signIn(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // signUp
  // ─────────────────────────────────────────────────────────────────────────
  group('AuthController.signUp', () {
    test('calls signUpWithEmail with all params', () async {
      when(
        mockRepo.signUpWithEmail(
          name: anyNamed('name'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      final ctrl = container.read(authControllerProvider.notifier);

      await ctrl.signUp(
        name: 'Alice',
        email: 'alice@test.com',
        password: 'secret99',
      );

      verify(
        mockRepo.signUpWithEmail(
          name: 'Alice',
          email: 'alice@test.com',
          password: 'secret99',
        ),
      ).called(1);
    });

    test('surfaces FirebaseAuthException when email already in use', () async {
      when(
        mockRepo.signUpWithEmail(
          name: anyNamed('name'),
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use.',
        ),
      );

      final container = _makeContainer(mockRepo);
      final ctrl = container.read(authControllerProvider.notifier);

      expect(
        () => ctrl.signUp(
          name: 'Bob',
          email: 'dup@test.com',
          password: 'pass123',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // signOut
  // ─────────────────────────────────────────────────────────────────────────
  group('AuthController.signOut', () {
    test('calls signOut on the repository', () async {
      when(mockRepo.signOut()).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      final ctrl = container.read(authControllerProvider.notifier);

      await ctrl.signOut();

      verify(mockRepo.signOut()).called(1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // signInWithGoogle
  // ─────────────────────────────────────────────────────────────────────────
  group('AuthController.signInWithGoogle', () {
    test('calls signInWithGoogle on the repository', () async {
      when(mockRepo.signInWithGoogle()).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      final ctrl = container.read(authControllerProvider.notifier);

      await expectLater(ctrl.signInWithGoogle(), completes);

      verify(mockRepo.signInWithGoogle()).called(1);
    });
  });
}
