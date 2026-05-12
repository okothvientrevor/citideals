import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.signInWithEmail(email: email, password: password);
    });
    _rethrowIfError();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.signUpWithEmail(name: name, email: email, password: password);
    });
    _rethrowIfError();
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signInWithGoogle);
    _rethrowIfError();
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signOut);
    _rethrowIfError();
  }

  void _rethrowIfError() {
    final s = state;
    if (s is AsyncError) {
      final err = s.error;
      if (err is FirebaseAuthException) throw err;
      throw Exception(err.toString());
    }
  }
}
