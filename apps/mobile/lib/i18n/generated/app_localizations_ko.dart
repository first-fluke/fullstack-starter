// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '풀스택 스타터';

  @override
  String get loading => '로딩 중...';

  @override
  String get error => '오류가 발생했습니다';

  @override
  String get retry => '재시도';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get delete => '삭제';

  @override
  String get login => '로그인';

  @override
  String get email => '이메일';

  @override
  String get password => '비밀번호';

  @override
  String get loginWithEmail => '이메일로 로그인';

  @override
  String get loginWithPasskey => '패스키로 로그인';

  @override
  String get registerPasskey => '패스키 추가';

  @override
  String get passkeyRegistered => '패스키를 추가했습니다';

  @override
  String get logout => '로그아웃';

  @override
  String get emailRequired => '이메일을 입력해 주세요';

  @override
  String get emailPasswordRequired => '이메일과 비밀번호를 입력해 주세요';
}
