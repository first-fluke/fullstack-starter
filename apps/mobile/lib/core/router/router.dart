import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/auth/auth_state.dart';
import 'package:mobile/core/auth/providers.dart';
import 'package:mobile/i18n/generated/app_localizations.dart';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
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
class HomePage extends ConsumerWidget {
  /// {@macro home_page}
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    Future<void> registerPasskey() async {
      try {
        await ref.read(authStateProvider.notifier).registerPasskey();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.passkeyRegistered)),
          );
        }
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.error)),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        actions: [
          IconButton(
            tooltip: localizations.logout,
            onPressed: authState.isLoading
                ? null
                : () => ref.read(authStateProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: FilledButton.icon(
          onPressed: authState.isLoading ? null : registerPasskey,
          icon: const Icon(Icons.key),
          label: Text(localizations.registerPasskey),
        ),
      ),
    );
  }
}

/// {@template login_page}
/// Placeholder login page shown to unauthenticated users.
/// {@endtemplate}
class LoginPage extends ConsumerStatefulWidget {
  /// {@macro login_page}
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;

    Future<void> login(OAuthProvider provider) async {
      try {
        await ref.read(authStateProvider.notifier).loginWithOAuth(provider);
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.error)),
          );
        }
      }
    }

    Future<void> loginWithEmail() async {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.emailPasswordRequired)),
        );
        return;
      }
      try {
        await ref
            .read(authStateProvider.notifier)
            .loginWithEmail(email, password);
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.error)),
          );
        }
      }
    }

    Future<void> loginWithPasskey() async {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.emailRequired)),
        );
        return;
      }
      try {
        await ref.read(authStateProvider.notifier).loginWithPasskey(email);
      } on Exception {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.error)),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.login)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: localizations.email,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: isLoading ? null : (_) => loginWithEmail(),
                      decoration: InputDecoration(
                        labelText: localizations.password,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isLoading ? null : loginWithEmail,
                      child: Text(localizations.loginWithEmail),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : loginWithPasskey,
                      icon: const Icon(Icons.key),
                      label: Text(localizations.loginWithPasskey),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () => login(OAuthProvider.google),
                      child: const Text('Google'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => login(OAuthProvider.github),
                      child: const Text('GitHub'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => login(OAuthProvider.facebook),
                      child: const Text('Facebook'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
