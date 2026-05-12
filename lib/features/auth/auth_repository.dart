import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// Snapshot of the current auth state, including the admin custom claim.
class AuthSession {
  final User user;
  final bool isAdmin;
  const AuthSession({required this.user, required this.isAdmin});
}

final authStateProvider = StreamProvider<AuthSession?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.sessionChanges();
});

class AuthRepository {
  AuthRepository({required this.auth, required this.firestore});
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  Stream<AuthSession?> sessionChanges() async* {
    await for (final user in auth.authStateChanges()) {
      if (user == null) {
        yield null;
        continue;
      }
      final token = await user.getIdTokenResult();
      yield AuthSession(
        user: user,
        isAdmin: token.claims?['admin'] == true,
      );
    }
  }

  /// Force a token refresh — used after admin claim is granted server-side.
  Future<void> refreshClaims() async {
    final user = auth.currentUser;
    if (user == null) return;
    await user.getIdToken(true);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    await _ensureUserDoc(cred.user!, fallbackName: name);
  }

  Future<void> signInWithGoogle() async {
    final google = GoogleSignIn.instance;
    await google.initialize();
    final account = await google.authenticate();
    final auth_ = account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: auth_.idToken);
    final cred = await auth.signInWithCredential(credential);
    if (cred.user != null) {
      await _ensureUserDoc(cred.user!, fallbackName: cred.user!.displayName);
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google not initialized — fine, just an email/password user.
    }
    await auth.signOut();
  }

  Future<void> _ensureUserDoc(User user, {String? fallbackName}) async {
    final doc = firestore.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (snap.exists) return;
    await doc.set({
      'name': fallbackName ?? user.displayName ?? user.email?.split('@').first,
      'email': user.email,
      'photoUrl': user.photoURL,
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'user',
    });
  }
}
