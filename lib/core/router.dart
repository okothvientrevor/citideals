import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_repository.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../main_navigator.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => notifier.value++);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final session = ref.read(authStateProvider).value;
      final loggingIn = state.matchedLocation == '/sign-in' ||
          state.matchedLocation == '/sign-up';
      if (session == null) return loggingIn ? null : '/sign-in';
      if (loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const MainNavigator()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, __) => const SignUpScreen()),
    ],
  );
});
