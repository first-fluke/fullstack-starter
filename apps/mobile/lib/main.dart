import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mobile/core/router/router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/firebase_options.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FlutterError.onError = (errorDetails) {
        unawaited(
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails),
        );
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
        return true;
      };

      if (kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          false,
        );
      }

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
    },
  );
}

/// {@template my_app}
/// The root widget of the application.
/// {@endtemplate}
class MyApp extends ConsumerWidget {
  /// {@macro my_app}
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final fTheme = isDark ? FThemes.zinc.dark.touch : FThemes.zinc.light.touch;

    return FTheme(
      data: fTheme,
      child: MaterialApp.router(
        title: 'Fullstack Starter',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          ...FLocalizations.localizationsDelegates,
        ],
        supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      ),
    );
  }
}
