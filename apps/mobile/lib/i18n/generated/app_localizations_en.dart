// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fullstack Starter';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get login => 'Log in';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginWithEmail => 'Log in with email';

  @override
  String get loginWithPasskey => 'Log in with a passkey';

  @override
  String get registerPasskey => 'Add a passkey';

  @override
  String get passkeyRegistered => 'Passkey added';

  @override
  String get logout => 'Log out';

  @override
  String get emailRequired => 'Enter your email address';

  @override
  String get emailPasswordRequired => 'Enter your email address and password';
}
