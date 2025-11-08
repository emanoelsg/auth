// app_router.dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth/ui/controller/provider.dart';
import 'auth/ui/controller/state.dart';

import 'auth/ui/pages/loading_page.dart';
import 'auth/ui/pages/login_page.dart';
import 'auth/ui/pages/register_page.dart';
import 'auth/ui/pages/test_page.dart';

final goRouterProvider = Provider((ref) {
  final routerNotifier = ValueNotifier<bool>(true);

  ref.listen(authNotifierProvider, (previous, next) {
    routerNotifier.value = !routerNotifier.value;
  });

  return GoRouter(
    refreshListenable: routerNotifier,
    initialLocation: '/',
    debugLogDiagnostics: true,

    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const LoadingPage(),
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
    ],

    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.uri.path;
        debugPrint('Current auth state: $authState');
      if (authState is AuthLoading) {
        return location == '/' ? null : '/';
      }

      if (authState is AuthAuthenticated) {
        final isAuthRoute =
            location == '/' ||
            location == '/login' ||
            location == '/register';

        return isAuthRoute ? '/home' : null;
      }

      if (authState is AuthInitial || authState is AuthError) {
        final isProtectedRoute = location == '/home';

        if (isProtectedRoute) {
          return '/login';
        }

        return null;
      }
      return null;
    },

    errorBuilder: (context, state) =>
        const Center(child: Text('404 - Página não encontrada')),
  );
});
