// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'フルスタックスターター';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラーが発生しました';

  @override
  String get retry => '再試行';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get delete => '削除';

  @override
  String get login => 'ログイン';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get loginWithEmail => 'メールでログイン';

  @override
  String get loginWithPasskey => 'パスキーでログイン';

  @override
  String get registerPasskey => 'パスキーを追加';

  @override
  String get passkeyRegistered => 'パスキーを追加しました';

  @override
  String get logout => 'ログアウト';

  @override
  String get emailRequired => 'メールアドレスを入力してください';

  @override
  String get emailPasswordRequired => 'メールアドレスとパスワードを入力してください';
}
