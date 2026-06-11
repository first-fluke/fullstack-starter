import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/auth/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@riverpod
/// The main router for the application.
GoRouter router(Ref ref) {
  // Listen to auth state changes so the router refreshes on login/logout.
  final authListenable = _AuthStateListenable(ref);

  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // While loading, do not redirect.
      if (authState.isLoading || authState.hasError) return null;

      final isAuthenticated = authState.value is Authenticated;
      final isOnLogin = state.uri.path == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
    ],
  );
}

/// A [ChangeNotifier] that listens to the auth state provider and notifies
/// go_router when the state changes, triggering the redirect callback.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    _subscription = ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (prev, next) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AsyncValue<AuthState>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// {@template home_page}
/// The home page of the application.
/// {@endtemplate}
class HomePage extends StatelessWidget {
  /// {@macro home_page}
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fullstack Starter')),
      body: const Center(child: Text('Welcome to Fullstack Starter')),
    );
  }
}

/// {@template login_page}
/// Placeholder login page shown to unauthenticated users.
/// {@endtemplate}
class LoginPage extends StatelessWidget {
  /// {@macro login_page}
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login')),
    );
  }
}
